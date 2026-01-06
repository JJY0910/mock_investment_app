import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// WebSocket 연결 상태
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Binance WebSocket 서비스 (단일 연결 최적화)
class BinanceWebSocketService {
  // Binance WebSocket 엔드포인트
  static const String _wsBaseUrl = 'wss://stream.binance.com:9443/stream';
  
  // 단일 WebSocket 연결
  WebSocketChannel? _channel;
  
  // 현재 구독 중인 스트림
  final Set<String> _subscribedStreams = {};
  
  // 감시 대상 심볼 (대문자 통일)
  Set<String> _watchlistSymbols = {};
  
  // 가격 데이터 스트림 컨트롤러
  final _priceController = StreamController<Map<String, PriceData>>.broadcast();
  
  // Kline 데이터 스트림 컨트롤러
  final _klineController = StreamController<KlineUpdate>.broadcast();
  
  // 연결 상태 스트림 컨트롤러
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  
  // 마지막 가격 (WS 기반, 서버 검증용)
  final Map<String, double> _lastPrices = {};
  DateTime? _lastPriceUpdateTime;
  
  // 현재 kline 버퍼 (symbol별)
  final Map<String, List<Kline>> _klineBuffer = {};
  
  // 재연결 관련
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // 최대 30초
  
  // 연결 상태
  ConnectionState _connectionState = ConnectionState.disconnected;
  bool _isDisposed = false;
  
  /// 가격 데이터 스트림
  Stream<Map<String, PriceData>> get priceStream => _priceController.stream;
  
  /// Kline 데이터 스트림
  Stream<KlineUpdate> get klineStream => _klineController.stream;
  
  /// 연결 상태 스트림
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// 현재 연결 상태
  ConnectionState get connectionState => _connectionState;
  
  /// 마지막 가격 업데이트 시간
  DateTime? get lastUpdateTime => _lastPriceUpdateTime;
  
  /// 마지막 가격 조회 (WS 기반, 서버 검증용)
  double? getLastPrice(String symbol) {
    return _lastPrices[symbol.toUpperCase()];
  }
  
  /// 연결 상태 업데이트
  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState == newState) return;
    
    _connectionState = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
    
    if (kDebugMode) {
      print('[BinanceWS] Connection state: $newState');
    }
  }
  
  /// 티커 구독 (멀티 심볼)
  Future<void> subscribeToTickers(List<String> symbols) async {
    // 심볼 대문자 통일
    _watchlistSymbols = symbols.map((s) => s.toUpperCase()).toSet();
    
    // !miniTicker@arr 스트림 추가
    const stream = '!miniTicker@arr';
    
    if (_subscribedStreams.contains(stream)) {
      if (kDebugMode) {
        print('[BinanceWS] Already subscribed to miniTicker');
      }
      return;
    }
    
    await _ensureConnection();
    await _subscribe([stream]);
    _subscribedStreams.add(stream);
    
    if (kDebugMode) {
      print('[BinanceWS] Subscribed to miniTicker for symbols: $_watchlistSymbols');
    }
  }
  
  /// Kline 구독 (단일 심볼만)
  Future<void> subscribeToKline(String symbol, String interval) async {
    // 기존 kline 구독 해제
    await unsubscribeFromKline();
    
    final normalizedSymbol = symbol.toUpperCase();
    final stream = '${symbol.toLowerCase()}@kline_$interval';
    
    await _ensureConnection();
    await _subscribe([stream]);
    _subscribedStreams.add(stream);
    
    // 버퍼 초기화
    _klineBuffer[normalizedSymbol] = [];
    
    if (kDebugMode) {
      print('[BinanceWS] Subscribed to kline: $stream');
    }
  }
  
  /// Kline 구독 해제
  Future<void> unsubscribeFromKline() async {
    final klineStreams = _subscribedStreams
        .where((s) => s.contains('@kline_'))
        .toList();
    
    if (klineStreams.isEmpty) return;
    
    await _unsubscribe(klineStreams);
    _subscribedStreams.removeWhere((s) => s.contains('@kline_'));
    _klineBuffer.clear();
    
    if (kDebugMode) {
      print('[BinanceWS] Unsubscribed from kline streams');
    }
  }
  
  /// WebSocket 연결 확보
  Future<void> _ensureConnection() async {
    if (_connectionState == ConnectionState.connected && _channel != null) {
      return;
    }
    
    await _connect();
  }
  
  /// WebSocket 연결
  Future<void> _connect() async {
    try {
      _updateConnectionState(
        _reconnectAttempts > 0 
          ? ConnectionState.reconnecting 
          : ConnectionState.connecting
      );
      
      if (kDebugMode) {
        print('[BinanceWS] Connecting to Binance WebSocket...');
      }
      
      _channel = WebSocketChannel.connect(Uri.parse(_wsBaseUrl));
      
      // 메시지 수신 리스너
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          if (kDebugMode) {
            print('[BinanceWS] WebSocket error: $error');
          }
          _reconnect();
        },
        onDone: () {
          if (kDebugMode) {
            print('[BinanceWS] WebSocket connection closed');
          }
          _updateConnectionState(ConnectionState.disconnected);
          _reconnect();
        },
      );
      
      _updateConnectionState(ConnectionState.connected);
      _reconnectAttempts = 0;
      
      if (kDebugMode) {
        print('[BinanceWS] Connected to Binance WebSocket');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BinanceWS] Failed to connect: $e');
      }
      _reconnect();
    }
  }
  
  /// 메시지 처리
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      
      // 스트림 데이터 확인
      if (data['stream'] == null || data['data'] == null) {
        // Ping/pong, subscribe response 등 무시
        return;
      }
      
      final stream = data['stream'] as String;
      final payload = data['data'];
      
      if (stream == '!miniTicker@arr') {
        // 멀티 티커 데이터
        _handleMiniTickerArray(payload as List<dynamic>);
      } else if (stream.contains('@kline_')) {
        // Kline 데이터
        _handleKline(payload);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BinanceWS] Error handling message: $e');
      }
    }
  }
  
  /// MiniTicker 배열 처리
  void _handleMiniTickerArray(List<dynamic> tickers) {
    final priceMap = <String, PriceData>{};
    
    for (final ticker in tickers) {
      final symbol = (ticker['s'] as String).toUpperCase();
      
      // 필터링: 감시 대상 심볼만 처리
      if (!_watchlistSymbols.contains(symbol)) continue;
      
      final price = double.parse(ticker['c'] as String);
      final changePercent = double.parse(ticker['P'] as String);
      final volume = double.parse(ticker['v'] as String);
      final high = double.parse(ticker['h'] as String);
      final low = double.parse(ticker['l'] as String);
      
      final priceData = PriceData(
        symbol: symbol,
        price: price,
        changePercent: changePercent,
        volume: volume,
        high24h: high,
        low24h: low,
      );
      
      priceMap[symbol] = priceData;
      
      // WS 최근가 저장 (서버 검증용)
      _lastPrices[symbol] = price;
    }
    
    if (priceMap.isNotEmpty) {
      // 마지막 업데이트 시간 갱신
      _lastPriceUpdateTime = DateTime.now();
      
      // 스트림으로 전송
      if (!_priceController.isClosed) {
        _priceController.add(priceMap);
      }
    }
  }
  
  /// Kline 데이터 처리
  void _handleKline(Map<String, dynamic> data) {
    final k = data['k'];
    final symbol = (k['s'] as String).toUpperCase();
    
    final kline = Kline(
      openTime: k['t'],
      open: double.parse(k['o'] as String),
      high: double.parse(k['h'] as String),
      low: double.parse(k['l'] as String),
      close: double.parse(k['c'] as String),
      volume: double.parse(k['v'] as String),
      closeTime: k['T'],
      isFinal: k['x'] as bool, // 캔들 완성 여부
    );
    
    // 버퍼 확인
    final buffer = _klineBuffer[symbol] ?? [];
    
    KlineUpdateType updateType;
    
    if (kline.isFinal) {
      // 캔들 완성 → 새 캔들 추가
      buffer.add(kline);
      updateType = KlineUpdateType.newCandle;
      
      if (kDebugMode) {
        print('[BinanceWS] New candle: $symbol @ ${kline.closeTime}');
      }
    } else {
      // 진행 중인 캔들 → 마지막 캔들 업데이트
      if (buffer.isNotEmpty && 
          buffer.last.openTime == kline.openTime) {
        buffer[buffer.length - 1] = kline;
        updateType = KlineUpdateType.updateLast;
      } else {
        // 첫 실시간 캔들
        buffer.add(kline);
        updateType = KlineUpdateType.newCandle;
      }
    }
    
    _klineBuffer[symbol] = buffer;
    
    // 스트림으로 전송
    if (!_klineController.isClosed) {
      _klineController.add(KlineUpdate(
        symbol: symbol,
        klines: List.from(buffer),
        updateType: updateType,
        latestKline: kline,
      ));
    }
  }
  
  /// 스트림 구독
  Future<void> _subscribe(List<String> streams) async {
    if (_channel == null || _connectionState != ConnectionState.connected) {
      return;
    }
    
    final message = {
      'method': 'SUBSCRIBE',
      'params': streams,
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel!.sink.add(json.encode(message));
    
    if (kDebugMode) {
      print('[BinanceWS] Subscribing to: $streams');
    }
  }
  
  /// 스트림 구독 해제
  Future<void> _unsubscribe(List<String> streams) async {
    if (_channel == null || _connectionState != ConnectionState.connected) {
      return;
    }
    
    final message = {
      'method': 'UNSUBSCRIBE',
      'params': streams,
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel!.sink.add(json.encode(message));
    
    if (kDebugMode) {
      print('[BinanceWS] Unsubscribing from: $streams');
    }
  }
  
  /// 재연결 로직 (exponential backoff)
  void _reconnect() {
    if (_isDisposed) return;
    
    _reconnectTimer?.cancel();
    _updateConnectionState(ConnectionState.reconnecting);
    
    // 지수 백오프 계산
    final delay = (_reconnectAttempts * 2).clamp(1, _maxReconnectDelay);
    _reconnectAttempts++;
    
    if (kDebugMode) {
      print('[BinanceWS] Reconnecting in $delay seconds... (attempt $_reconnectAttempts)');
    }
    
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      await _connect();
      
      // 기존 구독 복원
      if (_subscribedStreams.isNotEmpty) {
        await _subscribe(_subscribedStreams.toList());
      }
    });
  }
  
  /// 리소스 정리
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _priceController.close();
    _klineController.close();
    _connectionStateController.close();
    _lastPrices.clear();
    _klineBuffer.clear();
    _subscribedStreams.clear();
    _watchlistSymbols.clear();
    
    if (kDebugMode) {
      print('[BinanceWS] WebSocket service disposed');
    }
  }
}

/// 가격 데이터 모델
class PriceData {
  final String symbol;
  final double price;
  final double changePercent;
  final double volume;
  final double high24h;
  final double low24h;
  
  PriceData({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.volume,
    required this.high24h,
    required this.low24h,
  });
}

/// 캔들 데이터 모델
class Kline {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTime;
  final bool isFinal; // 캔들 완성 여부
  
  Kline({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
    required this.isFinal,
  });
}

/// Kline 업데이트 타입
enum KlineUpdateType {
  newCandle,    // 새 캔들 추가
  updateLast,   // 마지막 캔들 업데이트
}

/// Kline 업데이트 이벤트
class KlineUpdate {
  final String symbol;
  final List<Kline> klines;
  final KlineUpdateType updateType;
  final Kline latestKline;
  
  KlineUpdate({
    required this.symbol,
    required this.klines,
    required this.updateType,
    required this.latestKline,
  });
}

/// 캐시된 가격 (삭제됨 - 허용 오차 검증 중심으로 변경)
@Deprecated('Use getLastPrice() with validation tolerance instead')
class CachedPrice {
  final double price;
  final DateTime timestamp;
  
  CachedPrice({
    required this.price,
    required this.timestamp,
  });
}
