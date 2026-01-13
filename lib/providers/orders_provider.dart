import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/limit_order.dart';
import '../models/coin_info.dart';
import 'portfolio_provider.dart';
import 'market_quotes_provider.dart';
import 'exchange_rate_provider.dart';
import 'trade_history_provider.dart';

/// 지정가 주문 Provider
class OrdersProvider extends ChangeNotifier {
  static const String _storageKey = 'limit_orders_v1';

  List<LimitOrder> _orders = [];
  bool _loading = false;

  /// 미체결 주문 목록
  List<LimitOrder> get openOrders => _orders.where((o) => o.status == 'open').toList();

  /// 모든 주문
  List<LimitOrder> get allOrders => List.unmodifiable(_orders);

  /// 로딩 상태
  bool get loading => _loading;

  /// 로드
  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _orders = jsonList.map((json) => LimitOrder.fromJson(json)).toList();
        print('[OrdersProvider] Loaded ${_orders.length} orders');
      }
    } catch (e) {
      print('[OrdersProvider] Error loading orders: $e');
      _orders = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 저장
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _orders.map((o) => o.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_storageKey, jsonString);
      print('[OrdersProvider] Saved ${_orders.length} orders');
    } catch (e) {
      print('[OrdersProvider] Error saving orders: $e');
    }
  }

  /// 주문 추가
  Future<void> addOrder(LimitOrder order) async {
    _orders.add(order);
    await save();
    notifyListeners();
    print('[OrdersProvider] Added order: $order');
  }

  /// 주문 취소
  Future<void> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].status = 'canceled';
      await save();
      notifyListeners();
      print('[OrdersProvider] Canceled order: $orderId');
    }
  }

  /// 체결 체크 (수동)
  Future<int> tryMatchAll({
    required MarketQuotesProvider quotesProvider,
    required ExchangeRateProvider exchangeRateProvider,
    required PortfolioProvider portfolioProvider,
    required TradeHistoryProvider historyProvider,
  }) async {
    int matchedCount = 0;

    for (var order in List.from(_orders)) {
      if (order.status != 'open') continue;

      // 현재가 가져오기
      final symbol = '${order.base}USDT';
      final quote = quotesProvider.getQuote(symbol);
      if (quote == null) continue;

      final currentPriceKrw = exchangeRateProvider.usdtToKrw(quote.lastPrice);

      // 체결 조건 체크
      bool shouldMatch = false;
      if (order.side == 'buy') {
        // 매수: 현재가 <= 지정가
        shouldMatch = currentPriceKrw <= order.priceKrw;
      } else {
        // 매도: 현재가 >= 지정가
        shouldMatch = currentPriceKrw >= order.priceKrw;
      }

      if (shouldMatch) {
        // 체결 시도: source='limit' 전달
        final coin = CoinInfo(
          base: order.base,
          quote: 'KRW',
          displayName: order.base,
        );

        bool success;
        try {
          if (order.side == 'buy') {
            success = await portfolioProvider.marketBuy(
              coin: coin,
              krwAmount: order.quantity,
              priceKrw: order.priceKrw, // 지정가로 체결
              historyProvider: historyProvider,
              source: 'limit',
            );
          } else {
            success = await portfolioProvider.marketSell(
              coin: coin,
              quantity: order.quantity,
              priceKrw: order.priceKrw, // 지정가로 체결
              historyProvider: historyProvider,
              source: 'limit',
            );
          }

          if (success) {
            order.status = 'filled';
            matchedCount++;
            print('[OrdersProvider] Matched order: ${order.id}');
          }
        } catch (e) {
          print('[OrdersProvider] Match failed: $e');
        }
      }
    }

    if (matchedCount > 0) {
      await save();
      notifyListeners();
    }

    return matchedCount;
  }
}
