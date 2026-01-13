import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_quote.dart';

/// Binance 공개 API 서비스
/// 실시간 폴링/스트림 금지, 1회 로드만 지원
class BinanceApiService {
  static const String _baseUrl = 'https://api.binance.com';
  static const Duration _timeout = Duration(seconds: 10);

  /// 여러 심볼의 24시간 티커 정보를 한 번에 가져오기
  /// symbols: ["BTCUSDT", "ETHUSDT", "XRPUSDT", ...]
  /// 반환: Map<symbol, MarketQuote>
  Future<Map<String, MarketQuote>> fetchTickers(List<String> symbols) async {
    final Map<String, MarketQuote> quotes = {};

    if (symbols.isEmpty) {
      print('[BinanceAPI] No symbols to fetch');
      return quotes;
    }

    try {
      print('[BinanceAPI] Fetching ${symbols.length} symbols: ${symbols.take(5).join(", ")}...');

      // Binance ticker/24hr endpoint (여러 심볼을 한 번에 조회)
      // 참고: symbols 파라미터를 배열로 전달하려면 ["BTCUSDT","ETHUSDT"] 형태
      final symbolsParam = '[${symbols.map((s) => '"$s"').join(',')}]';
      final url = Uri.parse('$_baseUrl/api/v3/ticker/24hr?symbols=$symbolsParam');

      print('[BinanceAPI] Request URL: $url');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('[BinanceAPI] Received ${data.length} tickers');

        for (var item in data) {
          try {
            final quote = MarketQuote.fromBinanceJson(item as Map<String, dynamic>);
            quotes[quote.symbol] = quote;
          } catch (e) {
            print('[BinanceAPI] Error parsing ticker: $e');
          }
        }

        print('[BinanceAPI] Successfully parsed ${quotes.length} quotes');
        
        // 샘플 출력 (처음 3개)
        quotes.entries.take(3).forEach((entry) {
          print('[BinanceAPI] Sample: ${entry.value}');
        });

      } else {
        print('[BinanceAPI] HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Binance API returned ${response.statusCode}');
      }
    } on TimeoutException {
      print('[BinanceAPI] Request timeout');
      throw Exception('요청 시간 초과. 네트워크 연결을 확인해주세요.');
    } on http.ClientException catch (e) {
      print('[BinanceAPI] Network error: $e');
      throw Exception('네트워크 오류가 발생했습니다.');
    } catch (e) {
      print('[BinanceAPI] Unexpected error: $e');
      throw Exception('시세 정보를 불러오는 중 오류가 발생했습니다: $e');
    }

    return quotes;
  }

  /// 단일 심볼 조회 (필요 시)
  Future<MarketQuote?> fetchSingleTicker(String symbol) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v3/ticker/24hr?symbol=$symbol');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MarketQuote.fromBinanceJson(data);
      } else {
        print('[BinanceAPI] Single ticker error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[BinanceAPI] Single ticker fetch error: $e');
      return null;
    }
  }
}
