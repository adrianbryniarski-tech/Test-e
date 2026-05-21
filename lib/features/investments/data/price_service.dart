import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';

/// Wynik wyszukiwania krypto (CoinGecko search).
class CryptoSearchResult {
  const CryptoSearchResult({
    required this.id,
    required this.symbol,
    required this.name,
  });

  final String id; // coingecko id, np. 'bitcoin'
  final String symbol; // 'btc'
  final String name; // 'Bitcoin'
}

/// Pobiera aktualne kursy z darmowych, wiarygodnych źródeł:
/// - krypto: CoinGecko (ceny w PLN, bez klucza)
/// - złoto: NBP (oficjalna cena złota PLN/gram)
/// - srebro: stooq.pl (XAG/USD) przeliczone przez kurs USD/PLN z NBP
///
/// Wszystkie metody są best-effort — gdy API padnie, zwracają to co się
/// udało, brakujące pomijają (UI pokaże "kurs niedostępny").
class PriceService {
  PriceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 12);

  /// Zwraca mapę `symbol → cena PLN za jednostkę` dla podanych pozycji.
  /// Krypto: cena za 1 coin. Złoto/srebro: cena za 1 gram.
  Future<Map<String, double>> fetchPrices(List<Investment> items) async {
    final result = <String, double>{};
    if (items.isEmpty) return result;

    final cryptoIds = items
        .where((i) => i.assetType == AssetType.crypto)
        .map((i) => i.symbol)
        .toSet();
    final needsGold = items.any((i) => i.assetType == AssetType.gold);
    final needsSilver = items.any((i) => i.assetType == AssetType.silver);

    // Równolegle — niezależne źródła.
    final futures = <Future<void>>[
      if (cryptoIds.isNotEmpty)
        _fetchCrypto(cryptoIds).then(result.addAll),
      if (needsGold) _fetchGoldPlnPerGram().then((p) {
        if (p != null) result['XAU'] = p;
      }),
      if (needsSilver) _fetchSilverPlnPerGram().then((p) {
        if (p != null) result['XAG'] = p;
      }),
    ];
    await Future.wait(futures);
    return result;
  }

  /// CoinGecko `/coins/markets` — ceny krypto w PLN. Jeden batch request.
  Future<Map<String, double>> _fetchCrypto(Set<String> ids) async {
    final out = <String, double>{};
    try {
      final uri = Uri.https('api.coingecko.com', '/api/v3/coins/markets', {
        'vs_currency': 'pln',
        'ids': ids.join(','),
      });
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return out;
      final list = jsonDecode(resp.body) as List;
      for (final raw in list.cast<Map<String, dynamic>>()) {
        final id = raw['id'] as String?;
        final price = (raw['current_price'] as num?)?.toDouble();
        if (id != null && price != null) out[id] = price;
      }
    } on Object {
      // best-effort — brak ceny → UI pokaże "niedostępny"
    }
    return out;
  }

  /// NBP — cena złota próby 1000 (24k) w PLN za gram. Oficjalne, darmowe.
  Future<double?> _fetchGoldPlnPerGram() async {
    try {
      final uri = Uri.https('api.nbp.pl', '/api/cenyzlota');
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final list = jsonDecode(resp.body) as List;
      if (list.isEmpty) return null;
      return (list.last as Map<String, dynamic>)['cena'] as double?;
    } on Object {
      return null;
    }
  }

  /// stooq.pl XAGUSD (USD za uncję trojańską) → PLN za gram.
  /// Konwersja: (USD/oz × USD→PLN) / 31.1035.
  Future<double?> _fetchSilverPlnPerGram() async {
    try {
      final usdPerOz = await _fetchStooq('xagusd');
      if (usdPerOz == null) return null;
      final usdPln = await _fetchUsdPln();
      if (usdPln == null) return null;
      return usdPerOz * usdPln / 31.1035;
    } on Object {
      return null;
    }
  }

  /// stooq CSV: ostatnia cena instrumentu. Format: Symbol,Date,Time,O,H,L,C,V
  Future<double?> _fetchStooq(String symbol) async {
    try {
      final uri = Uri.https('stooq.pl', '/q/l/', {
        's': symbol,
        'f': 'sd2t2ohlcv',
        'h': '',
        'e': 'csv',
      });
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final lines = const LineSplitter().convert(resp.body);
      if (lines.length < 2) return null;
      final cols = lines[1].split(',');
      // close = index 6 (Symbol,Date,Time,Open,High,Low,Close,Volume)
      if (cols.length < 7) return null;
      return double.tryParse(cols[6]);
    } on Object {
      return null;
    }
  }

  /// NBP — kurs średni USD/PLN (ile PLN za 1 USD).
  Future<double?> _fetchUsdPln() async {
    try {
      final uri = Uri.https('api.nbp.pl', '/api/exchangerates/rates/a/usd');
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final rates = json['rates'] as List;
      if (rates.isEmpty) return null;
      return (rates.first as Map<String, dynamic>)['mid'] as double?;
    } on Object {
      return null;
    }
  }

  /// Wyszukiwarka krypto (CoinGecko `/search`). Zwraca top dopasowania.
  Future<List<CryptoSearchResult>> searchCrypto(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final uri = Uri.https('api.coingecko.com', '/api/v3/search', {
        'query': query.trim(),
      });
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return const [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final coins = (json['coins'] as List).cast<Map<String, dynamic>>();
      return coins
          .take(20)
          .map(
            (c) => CryptoSearchResult(
              id: c['id'] as String,
              symbol: (c['symbol'] as String).toUpperCase(),
              name: c['name'] as String,
            ),
          )
          .toList();
    } on Object {
      return const [];
    }
  }

  /// Aktualna cena pojedynczego krypto (PLN za 1 coin) — przy dodawaniu,
  /// żeby podpowiedzieć cenę zakupu.
  Future<double?> currentCryptoPrice(String coingeckoId) async {
    final prices = await _fetchCrypto({coingeckoId});
    return prices[coingeckoId];
  }

  void dispose() => _client.close();
}
