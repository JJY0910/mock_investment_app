// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/selected_coin_provider.dart';
import '../../../services/binance_rest_service.dart';
import '../../../services/binance_websocket_service.dart';
import '../../../web/js_bridge.dart' as js_bridge;

/// 실시간 트레이딩 차트 패널 (Web 전용)
class ChartPanel extends StatefulWidget {
  final String timeframe;
  
  const ChartPanel({Key? key, this.timeframe = '1m'}) : super(key: key);

  @override
  State<ChartPanel> createState() => _ChartPanelState();
}

class _ChartPanelState extends State<ChartPanel> {
  // 기존 서비스 사용
  final BinanceRestService _rest = BinanceRestService();
  final BinanceWebSocketService _ws = BinanceWebSocketService();
  
  StreamSubscription<KlineUpdate>? _klineSubscription;
  
  // Symbol from Provider only (SSOT)
  String? _currentSymbol;
  // Unused fields removed: _currentPrice
  // Unused fields removed: _priceChange, _isLoading
  String? _errorMessage;
  
  // Unique view type to avoid registry conflicts
  late final String _viewType;
  bool _viewRegistered = false;
  bool _chartReady = false;
  
  double _chartWidth = 0;
  double _chartHeight = 0;

  @override
  void initState() {
    super.initState();
    // Generate TRULY unique viewType with microseconds to avoid Hot Restart conflicts
    _viewType = 'trading-chart-${DateTime.now().microsecondsSinceEpoch}';
    print('[ChartPanel] init viewType=$_viewType');
    _registerViewFactory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  
  // ignore: undefined_prefixed_name
  void _registerViewFactory() {
    if (_viewRegistered) return;
    
    try {
      // Use ui_web.platformViewRegistry without ignore if possible, but keep ignore just in case
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          final div = html.DivElement()
            ..id = _viewType
            ..style.width = '100%'
            ..style.height = '100%';
          return div;
        },
      );
      _viewRegistered = true;
      print('[ChartPanel] View factory registered: $_viewType');
    } catch (e) {
      print('[ChartPanel] Error registering view factory: $e');
      // Try to clean up any existing registration
      try {
        final existingDiv = html.document.getElementById(_viewType);
        existingDiv?.remove();
      } catch (cleanupError) {
        print('[ChartPanel] Cleanup error: $cleanupError');
      }
    }
  }

  /// Kline 모델 → TradingView Lightweight Charts 형식 변환
  List<Map<String, dynamic>> _toTvCandles(List<Kline> klines) {
    return klines.map((k) {
      return {
        'time': (k.openTime ~/ 1000), // ms to seconds
        'open': k.open,
        'high': k.high,
        'low': k.low,
        'close': k.close,
      };
    }).toList();
  }

  /// KlineUpdate → TradingView 캔들 변환
  Map<String, dynamic> _toTvCandleFromUpdate(Kline k) {
    return {
      'time': (k.openTime ~/ 1000),
      'open': k.open,
      'high': k.high,
      'low': k.low,
      'close': k.close,
    };
  }

  Future<void> _initChart(double width, double height) async {
    if (_chartReady && width == _chartWidth && height == _chartHeight) {
      return; // Already created with same size
    }
    
    _chartWidth = width;
    _chartHeight = height;
    
    // Wait for DOM to be ready
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if JS functions exist
    if (!_checkJSFunctions()) {
      print('[ChartPanel] TradingView Charts not loaded yet');
      setState(() => _errorMessage = 'Chart library loading...');
      return;
    }
    
    // Create chart via JS
    try {
      final result = js_bridge.callMethod(
        js_bridge.window,
        'createChart',
        [_viewType, width.floor(), height.floor()],
      );
      
      if (result == true) {
        _chartReady = true;
        print('[ChartPanel] Chart created successfully');
        _loadChartData();
      } else {
        print('[ChartPanel] Failed to create chart');
        setState(() => _errorMessage = 'Failed to create chart');
      }
    } catch (e) {
      print('[ChartPanel] Error creating chart: $e');
      setState(() => _errorMessage = 'Chart error: $e');
    }
  }

  bool _checkJSFunctions() {
    try {
      return js_bridge.hasProperty(js_bridge.window, 'createChart') &&
             js_bridge.hasProperty(js_bridge.window, 'setChartData') &&
             js_bridge.hasProperty(js_bridge.window, 'updateCandle');
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadChartData() async {
    if (!_chartReady) return;
    
    setState(() {
      _errorMessage = null;
    });

    try {
      // [1] 기존 구독 정리 (누적 방지)
      await _klineSubscription?.cancel();
      _klineSubscription = null;
      await _ws.unsubscribeFromKline();

      if (_currentSymbol == null || _currentSymbol!.isEmpty) return;
      
      final baseSymbol = _currentSymbol!.split(String.fromCharCodes([85, 83, 68, 84]))[0];
      final market = '$baseSymbol/KRW';
      print('[Candles] market=$market tf=${widget.timeframe} loading...');
      
      // [2] REST로 초기 500개 캔들 로드
      final klines = await _rest.fetchKlines(
        symbol: _currentSymbol!,
        interval: widget.timeframe,
        limit: 500,
      );
      
      print('[Candles] market=$market tf=${widget.timeframe} count=${klines.length} lastTs=${klines.isNotEmpty ? klines.last.openTime : 0}');

      if (klines.isNotEmpty) {
        // [3] TradingView 형식으로 변환 후 차트에 세팅
        final tvCandles = _toTvCandles(klines);
        
        js_bridge.callMethod(
          js_bridge.window,
          'setChartData',
          [_viewType, js_bridge.jsify(tvCandles)],
        );
        
        // [4] WebSocket 구독 시작
        await _ws.subscribeToKline(_currentSymbol!, widget.timeframe);
        
        _klineSubscription = _ws.klineStream.listen(
          (klineUpdate) {
            if (!mounted) return;
            
            // 최신 캔들 가져오기
            final latestKline = klineUpdate.latestKline;
            final tvCandle = _toTvCandleFromUpdate(latestKline);
            
            // 차트 업데이트
            js_bridge.callMethod(
              js_bridge.window,
              'updateCandle',
              [_viewType, js_bridge.jsify(tvCandle)],
            );
          },
          onError: (error) {
            print('[ChartPanel] WebSocket error: $error');
          },
        );
        
        print('[ChartPanel] Chart loaded and subscribed');
      }
    } catch (e) {
      print('[ChartPanel] Error loading chart: $e');
      setState(() => _errorMessage = 'Failed to load data: $e');
    } finally {
      // setState(() => _isLoading = false);
    }
  }


  
  // _onSymbolChanged 및 Header UI 제거 -> 외부에서 제어됨을 가정
  // (실제로는 TradeLayout에서 key 변경 등으로 rebuild를 유도하거나, 여기서 Provider를 listen해야 함)
  // 현재 구조상 key가 바뀌면 새로 생성되므로 initChart가 호출됨.

  void _onLayoutChanged(double width, double height) {
    if (width > 0 && height > 0) {
      if (!_chartReady) {
        _initChart(width, height);
      } else if (width != _chartWidth || height != _chartHeight) {
        // Resize existing chart
        _chartWidth = width;
        _chartHeight = height;
        js_bridge.callMethod(
          js_bridge.window,
          'resizeChart',
          [_viewType, width.floor(), height.floor()],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCoinProvider = Provider.of<SelectedCoinProvider>(context);
    final coin = selectedCoinProvider.selectedCoin;
    final newSymbol = coin != null ? '${coin.base}USDT' : 'BTCUSDT';

    if (newSymbol != _currentSymbol) {
      _currentSymbol = newSymbol;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadChartData();
      });
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header 제거됨 (MarketSummaryBar 통합)
          
          // Error message
          
          // Chart area
          
          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Chart area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Trigger layout change
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onLayoutChanged(constraints.maxWidth, constraints.maxHeight);
                });
                
                return Container(
                  color: Colors.white,
                  child: HtmlElementView(viewType: _viewType),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('[ChartPanel] Disposing...');
    _klineSubscription?.cancel();
    _ws.unsubscribeFromKline();
    _ws.dispose();
    super.dispose();
  }
}
