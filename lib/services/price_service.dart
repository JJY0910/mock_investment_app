import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

// 시세 데이터 Fetching 서비스
class PriceService {
  // Yahoo Finance API를 통한 주식 시세 조회
  Future<AssetPrice?> fetchStockPrice(String symbol) async {
    try {
      final url = Uri.parse(
          '${AppConstants.yahooFinanceBaseUrl}/v8/finance/chart/$symbol');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final meta = result['meta'];

        final price = meta['regularMarketPrice']?.toDouble() ?? 0.0;
        final previousClose = meta['previousClose']?.toDouble() ?? price;
        final change = price - previousClose;
        final changePercent = previousClose > 0
            ? ((price - previousClose) / previousClose) * 100
            : 0.0;

        return AssetPrice(
          symbol: symbol,
          price: price,
          change: change,
          changePercent: changePercent,
        );
      } else {
        print('주식 시세 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('주식 시세 조회 오류: $e');
      return null;
    }
  }

  // Upbit API를 통한 암호화폐 시세 조회 (원화 KRW 마켓)
  Future<AssetPrice?> fetchCryptoPrice(String symbol) async {
    try {
      final market = 'KRW-$symbol'; // 예: KRW-XRP, KRW-BTC
      final url = Uri.parse(
          '${AppConstants.upbitBaseUrl}/v1/ticker?markets=$market');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isEmpty) {
          print('암호화폐 데이터 없음: $symbol');
          return null;
        }

        final ticker = data[0];
        final price = ticker['trade_price']?.toDouble() ?? 0.0;
        final changePrice = ticker['signed_change_price']?.toDouble() ?? 0.0;
        final changePercent = ticker['signed_change_rate']?.toDouble() ?? 0.0;

        return AssetPrice(
          symbol: symbol,
          price: price,
          change: changePrice,
          changePercent: changePercent * 100, // 백분율 변환
        );
      } else {
        print('암호화폐 시세 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('암호화폐 시세 조회 오류: $e');
      return null;
    }
  }

  // 자산 유형에 따라 자동으로 적절한 API 호출
  Future<AssetPrice?> fetchPrice(String symbol, String assetType) async {
    if (assetType == AppConstants.assetTypeCrypto) {
      return await fetchCryptoPrice(symbol);
    } else if (assetType == AppConstants.assetTypeStock) {
      return await fetchStockPrice(symbol);
    }
    return null;
  }

  // 여러 종목의 시세를 한 번에 조회
  Future<Map<String, AssetPrice>> fetchMultiplePrices(
      Map<String, String> symbolsWithTypes) async {
    final Map<String, AssetPrice> prices = {};

    for (var entry in symbolsWithTypes.entries) {
      final symbol = entry.key;
      final assetType = entry.value;
      
      final price = await fetchPrice(symbol, assetType);
      if (price != null) {
        prices[symbol] = price;
      }
    }

    return prices;
  }
}

// 자산 가격 데이터 모델
class AssetPrice {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;

  AssetPrice({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
  });
}
