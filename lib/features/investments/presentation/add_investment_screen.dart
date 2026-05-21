import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/application/investment_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment_repository.dart';
import 'package:nasz_budzet_domowy/features/investments/data/price_service.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';
import 'package:nasz_budzet_domowy/shared/widgets/loading_filled_button.dart';

/// Waluta wpisywanej ceny zakupu. Krypto często kupowane za USD/EUR —
/// przeliczamy na PLN po aktualnym kursie średnim NBP.
enum _BuyCurrency {
  pln('PLN', 'zł'),
  usd('USD', r'$'),
  eur('EUR', '€');

  const _BuyCurrency(this.code, this.symbol);

  final String code;
  final String symbol;
}

/// Dodawanie pozycji inwestycyjnej: typ → symbol (krypto = wyszukiwarka) →
/// ilość → cena zakupu. Przy krypto można wpisać cenę w PLN/USD/EUR
/// (USD/EUR przeliczane na PLN po kursie NBP) i podpowiadamy aktualny kurs.
class AddInvestmentScreen extends ConsumerStatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  ConsumerState<AddInvestmentScreen> createState() =>
      _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends ConsumerState<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _searchController = TextEditingController();

  AssetType _type = AssetType.crypto;

  // Dla krypto: wybrany coin z wyszukiwarki.
  CryptoSearchResult? _selectedCrypto;
  List<CryptoSearchResult> _searchResults = const [];
  bool _searching = false;
  Timer? _debounce;

  // Waluta ceny zakupu (tylko dla krypto). Domyślnie PLN.
  _BuyCurrency _buyCurrency = _BuyCurrency.pln;
  // Kurs wybranej waluty do PLN (cache, żeby pokazać podgląd przeliczenia).
  double? _fxRate;
  bool _fetchingFx = false;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final results =
          await ref.read(priceServiceProvider).searchCrypto(q);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  Future<void> _pickCrypto(CryptoSearchResult c) async {
    setState(() {
      _selectedCrypto = c;
      _searchResults = const [];
      _searchController.text = '${c.name} (${c.symbol})';
    });
    // Podpowiedz aktualny kurs jako cenę zakupu (user może nadpisać).
    final price = await ref.read(priceServiceProvider).currentCryptoPrice(c.id);
    if (!mounted) return;
    if (price != null && _priceController.text.trim().isEmpty) {
      _priceController.text = price.toStringAsFixed(2);
    }
  }

  Future<void> _onCurrencyChanged(_BuyCurrency c) async {
    if (c == _buyCurrency) return;
    setState(() {
      _buyCurrency = c;
      _fxRate = c == _BuyCurrency.pln ? 1 : null;
      // Wyczyść pole — sugerowany kurs był w innej walucie.
      _priceController.clear();
    });
    if (c == _BuyCurrency.pln) return;
    setState(() => _fetchingFx = true);
    final rate = await ref.read(priceServiceProvider).fxToPln(c.code);
    if (!mounted) return;
    setState(() {
      _fxRate = rate;
      _fetchingFx = false;
    });
  }

  double? _parseNum(String raw) {
    final cleaned = raw.replaceAll(' ', '').replaceAll(',', '.');
    final v = double.tryParse(cleaned);
    if (v == null || v <= 0) return null;
    return v;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String symbol;
    final String displayName;
    if (_type == AssetType.crypto) {
      if (_selectedCrypto == null) {
        setState(() => _error = 'Wybierz kryptowalutę z listy.');
        return;
      }
      symbol = _selectedCrypto!.id;
      displayName = _selectedCrypto!.name;
    } else {
      symbol = _type == AssetType.gold ? 'XAU' : 'XAG';
      displayName = _type == AssetType.gold ? 'Złoto' : 'Srebro';
    }

    final qty = _parseNum(_quantityController.text);
    final price = _parseNum(_priceController.text);
    if (qty == null) {
      setState(() => _error = 'Wpisz prawidłową ilość.');
      return;
    }
    if (price == null) {
      setState(() => _error = 'Wpisz prawidłową cenę zakupu.');
      return;
    }

    final householdId = ref.read(currentHouseholdIdProvider).value;
    if (householdId == null) {
      setState(() => _error = 'Brak gospodarstwa.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    // Krypto kupione za USD/EUR → przelicz na PLN po aktualnym kursie NBP.
    var pricePln = price;
    if (_type == AssetType.crypto && _buyCurrency != _BuyCurrency.pln) {
      final rate = _fxRate ??
          await ref.read(priceServiceProvider).fxToPln(_buyCurrency.code);
      if (!mounted) return;
      if (rate == null) {
        setState(() {
          _saving = false;
          _error = 'Nie udało się pobrać kursu ${_buyCurrency.code}/PLN. '
              'Spróbuj ponownie lub wpisz cenę w PLN.';
        });
        return;
      }
      pricePln = price * rate;
    }

    final inv = Investment(
      id: '',
      householdId: householdId,
      assetType: _type,
      symbol: symbol,
      displayName: displayName,
      quantity: qty,
      buyPriceCents: (pricePln * 100).round(),
      createdAt: DateTime.now(),
    );
    final result = await ref.read(investmentRepositoryProvider).insert(inv);
    if (!mounted) return;
    switch (result) {
      case InvestmentWriteSuccess():
        ref.invalidate(pricesProvider);
        context.pop();
      case InvestmentWriteFailure(:final message):
        setState(() {
          _saving = false;
          _error = 'Nie udało się zapisać: $message';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCrypto = _type == AssetType.crypto;
    final unitLabel = isCrypto
        ? (_selectedCrypto?.symbol ?? 'szt.')
        : 'gram';

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj inwestycję')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text('Typ aktywa', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<AssetType>(
                segments: const [
                  ButtonSegment(
                    value: AssetType.crypto,
                    label: Text('Krypto'),
                    icon: Icon(Icons.currency_bitcoin),
                  ),
                  ButtonSegment(
                    value: AssetType.gold,
                    label: Text('Złoto'),
                    icon: Icon(Icons.circle, color: Color(0xFFE8C24A)),
                  ),
                  ButtonSegment(
                    value: AssetType.silver,
                    label: Text('Srebro'),
                    icon: Icon(Icons.circle, color: Color(0xFFB0B7C3)),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _selectedCrypto = null;
                  _searchController.clear();
                  _searchResults = const [];
                  // Metale wyceniamy w PLN — reset waluty.
                  _buyCurrency = _BuyCurrency.pln;
                  _fxRate = 1;
                }),
              ),
              const SizedBox(height: 20),

              // Krypto: wyszukiwarka. Metale: nazwa stała.
              if (isCrypto) ...[
                Text('Kryptowaluta', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Szukaj (Bitcoin, Solana…)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (q) {
                    _selectedCrypto = null;
                    _onSearchChanged(q);
                  },
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final c in _searchResults)
                          ListTile(
                            dense: true,
                            title: Text(c.name),
                            trailing: Text(
                              c.symbol,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            onTap: () => _pickCrypto(c),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              Text(
                isCrypto
                    ? 'Ile masz (w sztukach $unitLabel)'
                    : 'Ile masz (w gramach)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                decoration: InputDecoration(
                  hintText: isCrypto ? '0.15' : '25',
                  suffixText: isCrypto ? unitLabel : 'g',
                ),
                validator: (v) =>
                    _parseNum(v ?? '') == null ? 'Wpisz ilość' : null,
              ),
              const SizedBox(height: 20),

              Text(
                isCrypto
                    ? 'Cena zakupu (za 1 $unitLabel)'
                    : 'Cena zakupu (PLN za 1 gram)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (isCrypto) ...[
                SegmentedButton<_BuyCurrency>(
                  segments: const [
                    ButtonSegment(value: _BuyCurrency.pln, label: Text('PLN')),
                    ButtonSegment(value: _BuyCurrency.usd, label: Text('USD')),
                    ButtonSegment(value: _BuyCurrency.eur, label: Text('EUR')),
                  ],
                  selected: {_buyCurrency},
                  onSelectionChanged: (s) => _onCurrencyChanged(s.first),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                onChanged: (_) {
                  // Odśwież podgląd przeliczenia przy zmianie kwoty.
                  if (isCrypto && _buyCurrency != _BuyCurrency.pln) {
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                  hintText: isCrypto
                      ? (_buyCurrency == _BuyCurrency.pln
                          ? 'np. 280000'
                          : 'np. 65000')
                      : 'np. 280',
                  suffixText: isCrypto ? _buyCurrency.symbol : 'zł',
                ),
                validator: (v) =>
                    _parseNum(v ?? '') == null ? 'Wpisz cenę' : null,
              ),
              if (isCrypto && _buyCurrency != _BuyCurrency.pln) ...[
                const SizedBox(height: 6),
                _ConversionHint(
                  amount: _parseNum(_priceController.text),
                  currency: _buyCurrency,
                  fxRate: _fxRate,
                  loading: _fetchingFx,
                ),
              ],
              const SizedBox(height: 24),

              if (_error != null) ...[
                InlineError(message: _error!),
                const SizedBox(height: 16),
              ],
              LoadingFilledButton(
                label: 'Dodaj do portfela',
                isLoading: _saving,
                icon: Icons.add,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Podgląd przeliczenia ceny na PLN po kursie NBP (krypto w USD/EUR).
class _ConversionHint extends StatelessWidget {
  const _ConversionHint({
    required this.amount,
    required this.currency,
    required this.fxRate,
    required this.loading,
  });

  final double? amount;
  final _BuyCurrency currency;
  final double? fxRate;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (loading) {
      return Text('Pobieram kurs ${currency.code}/PLN…', style: style);
    }
    if (fxRate == null) {
      return Text(
        'Kurs ${currency.code}/PLN niedostępny — przeliczę przy zapisie.',
        style: style,
      );
    }
    final rateText = fxRate!.toStringAsFixed(4);
    if (amount == null) {
      return Text(
        'Kurs NBP: 1 ${currency.code} = $rateText zł',
        style: style,
      );
    }
    final pln = (amount! * fxRate!).toStringAsFixed(2);
    return Text(
      '≈ $pln zł (kurs NBP 1 ${currency.code} = $rateText zł)',
      style: style,
    );
  }
}
