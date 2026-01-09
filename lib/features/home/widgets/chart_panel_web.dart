import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;
// Use dart:ui_web for platformViewRegistry
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../../services/binance_rest_service.dart';
import '../../../services/binance_websocket_service.dart';

/// 실시간 트레이딩 차트 패널 (Web 전용)
class ChartPanel extends StatefulWidget {
  const ChartPanel({Key? key}) : super(key: key);

  @override
  State<ChartPanel> createState() => _ChartPanelState();
}

class _ChartPanelState extends State<ChartPanel> {
  // 기존 서비스 사용
  final BinanceRestService _rest = BinanceRestService();
  final BinanceWebSocketService _ws = BinanceWebSocketService();
  
  StreamSubscription<KlineUpdate>? _klineSubscription;
  
  String _selectedSymbol = 'BTCUSDT';
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isLoading = false;
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
    // Generate unique viewType with timestamp to avoid conflicts
    _viewType = 'trading-chart-${DateTime.now().microsecondsSinceEpoch}';
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (_viewRegistered) return;
    
    try {
      // Use ui_web.platformViewRegistry instead of ui.platformViewRegistry
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
      final result = js_util.callMethod(
        html.window,
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
      return js_util.hasProperty(html.window, 'createChart') &&
             js_util.hasProperty(html.window, 'setChartData') &&
             js_util.hasProperty(html.window, 'updateCandle');
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadChartData() async {
    if (!_chartReady) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // [1] 기존 구독 정리 (누적 방지)
      await _klineSubscription?.cancel();
      _klineSubscription = null;
      await _ws.unsubscribeFromKline();
      
      print('[ChartPanel] Loading data for $_selectedSymbol');
      
      // [2] REST로 초기 500개 캔들 로드
      final klines = await _rest.fetchKlines(
        symbol: _selectedSymbol,
        interval: '1m',
        limit: 500,
      );
      
      if (klines.isNotEmpty) {
        // Set initial price
        setState(() => _currentPrice = klines.last.close);
        
        // [3] TradingView 형식으로 변환 후 차트에 세팅
        final tvData = _toTvCandles(klines);
        js_util.callMethod(
          html.window,
          'setChartData',
          [_viewType, js_util.jsify(tvData)],
        );
        
        // [4] WebSocket 구독 시작
        await _ws.subscribeToKline(_selectedSymbol, '1m');
        
        _klineSubscription = _ws.klineStream.listen(
          (klineUpdate) {
            if (!mounted) return;
            
            // 최신 캔들 가져오기
            final latestKline = klineUpdate.latestKline;
            final tvCandle = _toTvCandleFromUpdate(latestKline);
            
            // 차트 업데이트
            js_util.callMethod(
              html.window,
              'updateCandle',
              [_viewType, js_util.jsify(tvCandle)],
            );
            
            // 현재가 업데이트
            final newPrice = latestKline.close;
            setState(() {
              _priceChange = newPrice - _currentPrice;
              _currentPrice = newPrice;
            });
          },
          onError: (error) {
            print('[ChartPanel] WebSocket error: $error');
            setState(() => _errorMessage = 'Connection error');
          },
        );
        
        print('[ChartPanel] Chart loaded and subscribed');
      }
    } catch (e) {
      print('[ChartPanel] Error loading chart: $e');
      setState(() => _errorMessage = 'Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSymbolChanged(String? symbol) {
    if (symbol == null || symbol == _selectedSymbol) return;
    
    setState(() {
      _selectedSymbol = symbol;
      _currentPrice = 0.0;
      _priceChange = 0.0;
    });
    
    _loadChartData();
  }
  
  void _onLayoutChanged(double width, double height) {
    if (width > 0 && height > 0) {
      if (!_chartReady) {
        _initChart(width, height);
      } else if (width != _chartWidth || height != _chartHeight) {
        // Resize existing chart
        _chartWidth = width;
        _chartHeight = height;
        js_util.callMethod(
          html.window,
          'resizeChart',
          [_viewType, width.floor(), height.floor()],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Symbol selector + Current price
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Symbol dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSymbol,
                    underline: const SizedBox(),
                    items: ['BTCUSDT', 'ETHUSDT', 'XRPUSDT']
                        .map((symbol) => DropdownMenuItem(
                              value: symbol,
                              child: Text(
                                symbol,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: _isLoading ? null : _onSymbolChanged,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Current price
                if (_currentPrice > 0) ...[
                  Text(
                    '\$${_currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_priceChange != 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _priceChange > 0 ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_priceChange > 0 ? '+' : ''}${_priceChange.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: _priceChange > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
                
                const Spacer(),
                
                // Loading indicator
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
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
