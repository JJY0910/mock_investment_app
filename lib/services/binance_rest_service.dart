import 'dart:convert';
import 'package:http/http.dart' as http;
import 'binance_websocket_service.dart';

/// Binance REST API 서비스
class BinanceRestService {
  static const String _baseUrl = 'https://api.binance.com';
  
  /// 초기 Kline 데이터 조회
  /// [symbol]: 심볼 (예: BTCUSDT)
  /// [interval]: 인터벌 (1m, 5m, 15m, 1h, 1d 등)
  /// [limit]: 조회할 캔들 개수 (기본 100, 최대 1000)
  Future<List<Kline>> fetchKlines({
    required String symbol,
    required String interval,
    int limit = 100,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v3/klines').replace(queryParameters: {
        'symbol': symbol.toUpperCase(),
        'interval': interval,
        'limit': limit.toString(),
      });
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        return data.map((k) {
          return Kline(
            openTime: k[0],
            open: double.parse(k[1].toString()),
            high: double.parse(k[2].toString()),
            low: double.parse(k[3].toString()),
            close: double.parse(k[4].toString()),
            volume: double.parse(k[5].toString()),
            closeTime: k[6],
            isFinal: true, // REST 데이터는 모두 완료된 캔들
          );
        }).toList();
      } else {
        print('Failed to fetch klines: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching klines: $e');
      return [];
    }
  }
  
  /// 24시간 통계 조회
  Future<Ticker24h?> fetch24hTicker(String symbol) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v3/ticker/24hr').replace(queryParameters: {
        'symbol': symbol.toUpperCase(),
      });
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return Ticker24h(
          symbol: data['symbol'],
          priceChange: double.parse(data['priceChange']),
          priceChangePercent: double.parse(data['priceChangePercent']),
          lastPrice: double.parse(data['lastPrice']),
          highPrice: double.parse(data['highPrice']),
          lowPrice: double.parse(data['lowPrice']),
          volume: double.parse(data['volume']),
        );
      } else {
        print('Failed to fetch 24h ticker: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching 24h ticker: $e');
      return null;
    }
  }
  
  /// 현재가 조회 (서버 검증용)
  Future<double?> fetchCurrentPrice(String symbol) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v3/ticker/price').replace(queryParameters: {
        'symbol': symbol.toUpperCase(),
      });
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.parse(data['price']);
      } else {
        print('Failed to fetch price: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching price: $e');
      return null;
    }
  }
  
  /// Order Book 조회
  Future<OrderBook?> fetchOrderBook({
    required String symbol,
    int limit = 100,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v3/depth').replace(queryParameters: {
        'symbol': symbol.toUpperCase(),
        'limit': limit.toString(),
      });
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final bids = (data['bids'] as List).map((bid) {
          return OrderBookEntry(
            price: double.parse(bid[0]),
            quantity: double.parse(bid[1]),
          );
        }).toList();
        
        final asks = (data['asks'] as List).map((ask) {
          return OrderBookEntry(
            price: double.parse(ask[0]),
            quantity: double.parse(ask[1]),
          );
        }).toList();
        
        return OrderBook(bids: bids, asks: asks);
      } else {
        print('Failed to fetch order book: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching order book: $e');
      return null;
    }
  }
}

/// 24시간 통계 데이터 모델
class Ticker24h {
  final String symbol;
  final double priceChange;
  final double priceChangePercent;
  final double lastPrice;
  final double highPrice;
  final double lowPrice;
  final double volume;
  
  Ticker24h({
    required this.symbol,
    required this.priceChange,
    required this.priceChangePercent,
    required this.lastPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
  });
}

/// Order Book 데이터 모델
class OrderBook {
  final List<OrderBookEntry> bids; // 매수 호가
  final List<OrderBookEntry> asks; // 매도 호가
  
  OrderBook({
    required this.bids,
    required this.asks,
  });
}

/// Order Book 엔트리
class OrderBookEntry {
  final double price;
  final double quantity;
  
  OrderBookEntry({
    required this.price,
    required this.quantity,
  });
}
