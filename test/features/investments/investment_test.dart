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

  group('InvestmentValuation z częściową sprzedażą', () {
    final inv = Investment(
      id: 'i1',
      householdId: 'h1',
      assetType: AssetType.crypto,
      symbol: 'bitcoin',
      ticker: 'BTC',
      displayName: 'Bitcoin',
      quantity: 1, // 1 BTC
      buyPriceCents: 24000000, // 240 000 zł / szt.
      createdAt: DateTime(2025, 3, 10),
      purchasedAt: DateTime(2024),
    );

    test('bez sprzedaży → remaining = pełna ilość', () {
      final v = InvestmentValuation(investment: inv, pricePln: 300000);
      expect(v.remainingQuantity, 1);
      expect(v.isFullyClosed, false);
      expect(v.currentValuePln, 300000);
      expect(v.profitPln, 60000); // 300k - 240k
    });

    test('po sprzedaży połowy → remaining i wartości liczone z połowy', () {
      final v = InvestmentValuation(
        investment: inv,
        pricePln: 300000, // aktualnie 300 000 zł / szt.
        soldQuantity: 0.5,
      );
      expect(v.remainingQuantity, 0.5);
      expect(v.isFullyClosed, false);
      expect(v.remainingBuyValuePln, 120000); // 0.5 × 240 000
      expect(v.currentValuePln, 150000); // 0.5 × 300 000
      expect(v.profitPln, 30000);
      expect(v.isProfit, true);
    });

    test('sprzedane wszystko → fully closed, wartość 0', () {
      final v = InvestmentValuation(
        investment: inv,
        pricePln: 300000,
        soldQuantity: 1,
      );
      expect(v.remainingQuantity, 0);
      expect(v.isFullyClosed, true);
      expect(v.currentValuePln, 0);
      expect(v.profitPln, 0);
    });

    test('sprzedane więcej niż jest → remaining nie schodzi poniżej 0', () {
      final v = InvestmentValuation(
        investment: inv,
        pricePln: 300000,
        soldQuantity: 1.5,
      );
      expect(v.remainingQuantity, 0);
      expect(v.isFullyClosed, true);
    });
  });

  group('InvestmentSale wynik realizacji', () {
    InvestmentSale sale(int proceeds, int costBasis) => InvestmentSale(
          id: 's1',
          householdId: 'h1',
          investmentId: 'i1',
          quantity: 0.5,
          proceedsCents: proceeds,
          costBasisCents: costBasis,
          soldAt: DateTime(2026, 5, 10),
        );

    test('odzyskane > koszt → zysk dodatni', () {
      final s = sale(15000000, 12000000); // 150k vs 120k
      expect(s.realizedPln, 30000);
      expect(s.isProfit, true);
    });

    test('odzyskane < koszt → strata ujemna', () {
      final s = sale(10000000, 12000000); // 100k vs 120k
      expect(s.realizedPln, -20000);
      expect(s.isProfit, false);
    });

    test('całkowita strata (odzyskane 0) → wynik = -koszt', () {
      final s = sale(0, 12000000);
      expect(s.realizedPln, -120000);
      expect(s.isProfit, false);
    });
  });
}
