import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 환율 API 서비스
/// USD→KRW 환율을 단발로 가져옴 (USDT≈USD 가정)
class ExchangeRateApiService {
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';
  static const Duration _timeout = Duration(seconds: 10);

  /// USD→KRW 환율 가져오기
  /// 실패 시 null 반환 (fallback 사용)
  Future<double?> fetchUsdToKrw() async {
    try {
      print('[ExchangeRateApi] Fetching USD→KRW rate...');

      final url = Uri.parse(_apiUrl);
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null && rates.containsKey('KRW')) {
          final rateValue = rates['KRW'];
          final rate = double.tryParse(rateValue.toString());

          if (rate != null && rate > 0) {
            print('[ExchangeRateApi] Successfully fetched rate: $rate');
            return rate;
          }
        }

        print('[ExchangeRateApi] Invalid response format');
        return null;
      } else {
        print('[ExchangeRateApi] HTTP ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      print('[ExchangeRateApi] Request timeout');
      return null;
    } catch (e) {
      print('[ExchangeRateApi] Error: $e');
      return null;
    }
  }
}
