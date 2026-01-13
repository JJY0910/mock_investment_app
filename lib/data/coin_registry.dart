import '../models/coin_info.dart';

/// 중앙 코인 레지스트리
/// 모든 코인 데이터를 한 곳에서 관리
class CoinRegistry {
  // Singleton pattern
  static final CoinRegistry _instance = CoinRegistry._internal();
  factory CoinRegistry() => _instance;
  CoinRegistry._internal();

  /// KRW 마켓 코인 목록 (실제로는 USDT 사용, 표시는 원화처럼)
  static final List<CoinInfo> krwMarket = [
    CoinInfo(
      base: 'BTC',
      quote: 'USDT',
      displayName: 'Bitcoin',
      currentPrice: 44250.50,
      change24h: 2.35,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'ETH',
      quote: 'USDT',
      displayName: 'Ethereum',
      currentPrice: 2380.20,
      change24h: -1.12,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'XRP',
      quote: 'USDT',
      displayName: 'Ripple',
      currentPrice: 0.5234,
      change24h: 0.85,
      priceDecimals: 4,
    ),
    CoinInfo(
      base: 'ADA',
      quote: 'USDT',
      displayName: 'Cardano',
      currentPrice: 0.4821,
      change24h: -0.45,
      priceDecimals: 4,
    ),
    CoinInfo(
      base: 'SOL',
      quote: 'USDT',
      displayName: 'Solana',
      currentPrice: 98.75,
      change24h: 3.21,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'DOGE',
      quote: 'USDT',
      displayName: 'Dogecoin',
      currentPrice: 0.0892,
      change24h: 1.54,
      priceDecimals: 4,
    ),
    CoinInfo(
      base: 'MATIC',
      quote: 'USDT',
      displayName: 'Polygon',
      currentPrice: 0.8234,
      change24h: -0.23,
      priceDecimals: 4,
    ),
    CoinInfo(
      base: 'DOT',
      quote: 'USDT',
      displayName: 'Polkadot',
      currentPrice: 7.12,
      change24h: 0.67,
      priceDecimals: 3,
    ),
    CoinInfo(
      base: 'AVAX',
      quote: 'USDT',
      displayName: 'Avalanche',
      currentPrice: 36.54,
      change24h: 2.11,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'LINK',
      quote: 'USDT',
      displayName: 'Chainlink',
      currentPrice: 14.23,
      change24h: -0.89,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'BCH',
      quote: 'USDT',
      displayName: 'Bitcoin Cash',
      currentPrice: 235.87,
      change24h: 1.34,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'LTC',
      quote: 'USDT',
      displayName: 'Litecoin',
      currentPrice: 78.92,
      change24h: 0.56,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'UNI',
      quote: 'USDT',
      displayName: 'Uniswap',
      currentPrice: 6.43,
      change24h: -1.23,
      priceDecimals: 3,
    ),
    CoinInfo(
      base: 'ATOM',
      quote: 'USDT',
      displayName: 'Cosmos',
      currentPrice: 9.87,
      change24h: 2.45,
      priceDecimals: 3,
    ),
    CoinInfo(
      base: 'ETC',
      quote: 'USDT',
      displayName: 'Ethereum Classic',
      currentPrice: 21.45,
      change24h: -0.67,
      priceDecimals: 2,
    ),
    CoinInfo(
      base: 'APT',
      quote: 'USDT',
      displayName: 'Aptos',
      currentPrice: 8.92,
      change24h: 3.12,
      priceDecimals: 3,
    ),
    CoinInfo(
      base: 'NEAR',
      quote: 'USDT',
      displayName: 'NEAR Protocol',
      currentPrice: 4.56,
      change24h: 1.87,
      priceDecimals: 3,
    ),
    CoinInfo(
      base: 'FTM',
      quote: 'USDT',
      displayName: 'Fantom',
      currentPrice: 0.4523,
      change24h: -2.11,
      priceDecimals: 4,
    ),
    CoinInfo(
      base: 'LDO',
      quote: 'USDT',
      displayName: 'Lido DAO',
      currentPrice: 1.87,
      change24h: 0.92,
      priceDecimals: 3,
    ),
    CoinInfo(
      base: 'GRT',
      quote: 'USDT',
      displayName: 'The Graph',
      currentPrice: 0.1645,
      change24h: 1.45,
      priceDecimals: 4,
    ),
  ];

  /// Get all KRW market coins
  List<CoinInfo> getKrwMarket() => List.unmodifiable(krwMarket);

  /// Get coin by pairKey
  CoinInfo? getCoinByPairKey(String pairKey) {
    try {
      return krwMarket.firstWhere((coin) => coin.pairKey == pairKey);
    } catch (e) {
      return null;
    }
  }

  /// Check if coin exists
  bool hasCoin(String pairKey) {
    return krwMarket.any((coin) => coin.pairKey == pairKey);
  }
}
