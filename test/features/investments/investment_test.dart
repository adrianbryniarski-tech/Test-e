import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';

void main() {
  group('Investment.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 'i1',
          'household_id': 'h1',
          'created_by': 'u1',
          'asset_type': 'crypto',
          'symbol': 'bitcoin',
          'display_name': 'Bitcoin',
          'quantity': 0.5,
          'buy_price_cents': 24000000,
          'created_at': '2025-03-10T12:00:00Z',
        };

    test('purchased_at obecne → parsuje datę zakupu', () {
      final inv = Investment.fromJson(base()..['purchased_at'] = '2024-01-15');
      expect(inv.purchasedAt, DateTime.parse('2024-01-15'));
    });

    test('brak purchased_at (stary wiersz) → fallback na created_at', () {
      final inv = Investment.fromJson(base());
      expect(inv.purchasedAt, DateTime.parse('2025-03-10T12:00:00Z'));
    });

    test('ticker obecny → unitLabel = ticker', () {
      final inv = Investment.fromJson(base()..['ticker'] = 'btc');
      expect(inv.unitLabel, 'BTC');
    });

    test('krypto bez tickera → fallback na symbol (uppercase)', () {
      final inv = Investment.fromJson(base());
      expect(inv.unitLabel, 'BITCOIN');
    });

    test('metale → unitLabel = g', () {
      final gold = Investment.fromJson(
        base()
          ..['asset_type'] = 'gold'
          ..['symbol'] = 'XAU'
          ..['ticker'] = 'XAU',
      );
      expect(gold.unitLabel, 'g');
    });
  });

  group('Investment ceny', () {
    final inv = Investment(
      id: 'i1',
      householdId: 'h1',
      assetType: AssetType.crypto,
      symbol: 'bitcoin',
      ticker: 'BTC',
      displayName: 'Bitcoin',
      quantity: 0.5,
      buyPriceCents: 24000000, // 240 000 zł / szt.
      createdAt: DateTime(2025, 3, 10),
      purchasedAt: DateTime(2024),
    );

    test('buyPricePerUnitPln = grosze/100', () {
      expect(inv.buyPricePerUnitPln, 240000);
    });

    test('buyValuePln = ilość × cena', () {
      expect(inv.buyValuePln, 120000);
    });

    test('toInsert zawiera ticker i purchased_at jako YYYY-MM-DD', () {
      final map = inv.toInsert('u1');
      expect(map['ticker'], 'BTC');
      expect(map['purchased_at'], '2024-01-01');
    });
  });
}
