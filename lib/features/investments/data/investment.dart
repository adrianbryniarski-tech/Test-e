/// Typ aktywa inwestycyjnego. Determinuje źródło kursu i jednostkę.
enum AssetType {
  crypto, // jednostka: sztuki coina (np. 0.15 BTC)
  gold, // jednostka: gramy
  silver; // jednostka: gramy

  String toDbValue() => name;

  static AssetType fromDbValue(String raw) => switch (raw) {
        'crypto' => AssetType.crypto,
        'gold' => AssetType.gold,
        'silver' => AssetType.silver,
        _ => throw ArgumentError('Unknown asset_type: $raw'),
      };

  /// Jednostka do wyświetlenia ('szt.' nie pasuje do krypto, więc symbol
  /// coina; metale w gramach).
  String unitLabel(String symbol) => switch (this) {
        AssetType.crypto => symbol.toUpperCase(),
        AssetType.gold || AssetType.silver => 'g',
      };
}

/// Pozycja w portfelu inwestycyjnym. Mirror tabeli `investments`.
///
/// `buyPriceCents` = grosze PLN za JEDNĄ jednostkę (1 coin / 1 gram).
/// `quantity` = ile jednostek (double, krypto bywa ułamkowe).
class Investment {
  const Investment({
    required this.id,
    required this.householdId,
    required this.assetType,
    required this.symbol,
    required this.displayName,
    required this.quantity,
    required this.buyPriceCents,
    required this.createdAt,
    this.createdBy,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String?,
      assetType: AssetType.fromDbValue(json['asset_type'] as String),
      symbol: json['symbol'] as String,
      displayName: json['display_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      buyPriceCents: (json['buy_price_cents'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String householdId;
  final String? createdBy;
  final AssetType assetType;
  final String symbol;
  final String displayName;
  final double quantity;
  final int buyPriceCents;
  final DateTime createdAt;

  /// Wartość zakupu w PLN (quantity × cena_zakupu).
  double get buyValuePln => quantity * buyPriceCents / 100;

  Map<String, Object?> toInsert(String createdByUserId) => {
        'household_id': householdId,
        'created_by': createdByUserId,
        'asset_type': assetType.toDbValue(),
        'symbol': symbol,
        'display_name': displayName,
        'quantity': quantity,
        'buy_price_cents': buyPriceCents,
      };
}

/// Wyliczona pozycja z aktualnym kursem — łączy [Investment] z bieżącą
/// ceną rynkową (PLN za jednostkę). Gdy kurs niedostępny → `pricePln` null.
class InvestmentValuation {
  const InvestmentValuation({
    required this.investment,
    required this.pricePln,
  });

  final Investment investment;

  /// Aktualna cena PLN za 1 jednostkę. null = kurs niedostępny.
  final double? pricePln;

  bool get hasPrice => pricePln != null;

  /// Aktualna wartość pozycji w PLN.
  double get currentValuePln => pricePln == null
      ? investment.buyValuePln
      : investment.quantity * pricePln!;

  /// Zysk/strata w PLN (dodatni = zysk).
  double get profitPln => currentValuePln - investment.buyValuePln;

  /// Zysk/strata w procentach.
  double get profitPercent {
    final base = investment.buyValuePln;
    if (base == 0) return 0;
    return profitPln / base * 100;
  }

  bool get isProfit => profitPln >= 0;
}

/// Punkt na wykresie wartości portfela.
class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.totalValueCents,
    required this.capturedAt,
  });

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      totalValueCents: (json['total_value_cents'] as num).toInt(),
      capturedAt: DateTime.parse(json['captured_at'] as String),
    );
  }

  final int totalValueCents;
  final DateTime capturedAt;

  double get valuePln => totalValueCents / 100;
}
