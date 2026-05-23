import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/application/investment_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment_repository.dart';
import 'package:nasz_budzet_domowy/features/investments/data/price_service.dart';
import 'package:nasz_budzet_domowy/shared/widgets/comic_shadow.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';
import 'package:nasz_budzet_domowy/shared/widgets/loading_filled_button.dart';
import 'package:nasz_budzet_domowy/shared/widgets/manga_icons.dart';

/// Waluta wpisywanej ceny zakupu. Aktywa bywają kupowane za USD/EUR —
/// przeliczamy na PLN po kursie średnim NBP z dnia zakupu.
enum _BuyCurrency {
  pln('PLN', 'zł'),
  usd('USD', r'$'),
  eur('EUR', '€');

  const _BuyCurrency(this.code, this.symbol);

  final String code;
  final String symbol;
}

/// Dodawanie / edycja pozycji inwestycyjnej: typ → symbol (krypto =
/// wyszukiwarka) → ilość → cena zakupu. Przy krypto można wpisać cenę w
/// PLN/USD/EUR (USD/EUR przeliczane na PLN po kursie NBP) i podpowiadamy
/// aktualny kurs. Gdy [existing] != null — tryb edycji (typ i aktywo
/// zablokowane, edytujemy ilość i cenę).
class AddInvestmentScreen extends ConsumerStatefulWidget {
  const AddInvestmentScreen({super.key, this.existing});

  final Investment? existing;

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

  // Data zakupu (dla wszystkich typów). Domyślnie dziś.
  DateTime _purchasedAt = DateTime.now();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.assetType;
      _purchasedAt = e.purchasedAt;
      _quantityController.text = e.quantity == e.quantity.roundToDouble()
          ? e.quantity.toStringAsFixed(0)
          : e.quantity.toString();
      _priceController.text = (e.buyPriceCents / 100).toStringAsFixed(2);
    }
  }

  // Dla krypto: wybrany coin z wyszukiwarki.
  CryptoSearchResult? _selectedCrypto;
  List<CryptoSearchResult> _searchResults = const [];
  bool _searching = false;
  Timer? _debounce;

  // Waluta ceny zakupu. Domyślnie PLN.
  _BuyCurrency _buyCurrency = _BuyCurrency.pln;
  // Kurs wybranej waluty do PLN z dnia zakupu (cache do podglądu).
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
      final results = await ref.read(priceServiceProvider).searchCrypto(q);
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
    await _refreshFx();
  }

  /// Pobiera kurs wybranej waluty do PLN z dnia zakupu (do podglądu i zapisu).
  Future<void> _refreshFx() async {
    if (_buyCurrency == _BuyCurrency.pln) {
      setState(() => _fxRate = 1);
      return;
    }
    setState(() => _fetchingFx = true);
    final rate = await ref
        .read(priceServiceProvider)
        .fxToPlnOnDate(_buyCurrency.code, _purchasedAt);
    if (!mounted) return;
    setState(() {
      _fxRate = rate;
      _fetchingFx = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedAt,
      firstDate: DateTime(2009),
      lastDate: now,
      helpText: 'Data zakupu',
    );
    if (picked == null || !mounted) return;
    setState(() => _purchasedAt = picked);
    // Kurs zależy od daty — odśwież podgląd dla walut obcych.
    await _refreshFx();
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
    final String? ticker;
    final existing = widget.existing;
    if (existing != null) {
      symbol = existing.symbol;
      displayName = existing.displayName;
      ticker = existing.ticker;
    } else if (_type == AssetType.crypto) {
      if (_selectedCrypto == null) {
        setState(() => _error = 'Wybierz kryptowalutę z listy.');
        return;
      }
      symbol = _selectedCrypto!.id;
      displayName = _selectedCrypto!.name;
      ticker = _selectedCrypto!.symbol;
    } else {
      symbol = _type == AssetType.gold ? 'XAU' : 'XAG';
      displayName = _type == AssetType.gold ? 'Złoto' : 'Srebro';
      ticker = symbol;
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

    // Kupione za USD/EUR → przelicz na PLN po kursie NBP z dnia zakupu.
    var pricePln = price;
    if (_buyCurrency != _BuyCurrency.pln) {
      final rate = _fxRate ??
          await ref
              .read(priceServiceProvider)
              .fxToPlnOnDate(_buyCurrency.code, _purchasedAt);
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

    final repo = ref.read(investmentRepositoryProvider);
    final buyPriceCents = (pricePln * 100).round();
    final InvestmentWriteResult result;
    if (existing != null) {
      result = await repo.update(
        id: existing.id,
        quantity: qty,
        buyPriceCents: buyPriceCents,
      );
    } else {
      result = await repo.insert(
        Investment(
          id: '',
          householdId: householdId,
          assetType: _type,
          symbol: symbol,
          ticker: ticker,
          displayName: displayName,
          quantity: qty,
          buyPriceCents: buyPriceCents,
          createdAt: DateTime.now(),
          purchasedAt: _purchasedAt,
        ),
      );
    }
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
    final existing = widget.existing;
    final unitLabel = isCrypto
        ? (_selectedCrypto?.symbol ?? existing?.unitLabel ?? 'szt.')
        : 'gram';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edytuj pozycję' : 'Dodaj inwestycję'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Tryb edycji: typ i aktywo są stałe — pokazujemy je tylko
              // jako podgląd, nie do zmiany.
              if (_isEditing) ...[
                ComicCard(
                  child: ListTile(
                    leading: Icon(
                      switch (_type) {
                        AssetType.crypto => Icons.currency_bitcoin,
                        AssetType.gold => Icons.circle,
                        AssetType.silver => Icons.circle,
                      },
                      color: switch (_type) {
                        AssetType.crypto => theme.colorScheme.primary,
                        AssetType.gold => const Color(0xFFE8C24A),
                        AssetType.silver => const Color(0xFFB0B7C3),
                      },
                    ),
                    title: Text(existing!.displayName),
                    subtitle: Text(
                      switch (_type) {
                        AssetType.crypto => 'Kryptowaluta',
                        AssetType.gold => 'Złoto',
                        AssetType.silver => 'Srebro',
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Text('Typ aktywa', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<AssetType>(
                  segments: const [
                    ButtonSegment(
                      value: AssetType.crypto,
                      label: Text('Krypto'),
                      icon: AppIcon(Icons.currency_bitcoin),
                    ),
                    ButtonSegment(
                      value: AssetType.gold,
                      label: Text('Złoto'),
                      icon: AppIcon(Icons.circle, color: Color(0xFFE8C24A)),
                    ),
                    ButtonSegment(
                      value: AssetType.silver,
                      label: Text('Srebro'),
                      icon: AppIcon(Icons.circle, color: Color(0xFFB0B7C3)),
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
              ],

              // Krypto (tylko przy dodawaniu): wyszukiwarka.
              if (isCrypto && !_isEditing) ...[
                Text('Kryptowaluta', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Szukaj (Bitcoin, Solana…)',
                    prefixIcon: const AppIcon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
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

              // Data zakupu (wszystkie typy). Dla walut obcych decyduje o
              // historycznym kursie NBP.
              Text('Data zakupu', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const AppIcon(Icons.calendar_today_outlined, size: 18),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('d MMMM yyyy', 'pl_PL').format(_purchasedAt),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isCrypto
                    ? 'Cena zakupu (za 1 $unitLabel)'
                    : 'Cena zakupu (za 1 gram)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
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
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                onChanged: (_) {
                  // Odśwież podgląd przeliczenia przy zmianie kwoty.
                  if (_buyCurrency != _BuyCurrency.pln) {
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                  hintText: _buyCurrency == _BuyCurrency.pln
                      ? (isCrypto ? 'np. 280000' : 'np. 280')
                      : 'np. 65000',
                  suffixText: _buyCurrency.symbol,
                ),
                validator: (v) =>
                    _parseNum(v ?? '') == null ? 'Wpisz cenę' : null,
              ),
              if (_buyCurrency != _BuyCurrency.pln) ...[
                const SizedBox(height: 6),
                _ConversionHint(
                  amount: _parseNum(_priceController.text),
                  currency: _buyCurrency,
                  fxRate: _fxRate,
                  loading: _fetchingFx,
                  purchasedAt: _purchasedAt,
                ),
              ],
              const SizedBox(height: 24),

              if (_error != null) ...[
                InlineError(message: _error!),
                const SizedBox(height: 16),
              ],
              LoadingFilledButton(
                label: _isEditing ? 'Zapisz zmiany' : 'Dodaj do portfela',
                isLoading: _saving,
                icon: _isEditing ? Icons.check : Icons.add,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Podgląd przeliczenia ceny na PLN po kursie NBP z dnia zakupu.
class _ConversionHint extends StatelessWidget {
  const _ConversionHint({
    required this.amount,
    required this.currency,
    required this.fxRate,
    required this.loading,
    required this.purchasedAt,
  });

  final double? amount;
  final _BuyCurrency currency;
  final double? fxRate;
  final bool loading;
  final DateTime purchasedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final dateText = DateFormat('d.MM.yyyy', 'pl_PL').format(purchasedAt);

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
        'Kurs NBP z $dateText: 1 ${currency.code} = $rateText zł',
        style: style,
      );
    }
    final pln = (amount! * fxRate!).toStringAsFixed(2);
    return Text(
      '≈ $pln zł (kurs NBP z $dateText: 1 ${currency.code} = $rateText zł)',
      style: style,
    );
  }
}
