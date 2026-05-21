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

/// Dodawanie pozycji inwestycyjnej: typ → symbol (krypto = wyszukiwarka) →
/// ilość → cena zakupu (PLN za jednostkę). Przy krypto podpowiadamy
/// aktualny kurs jako sugestię ceny.
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

    final inv = Investment(
      id: '',
      householdId: householdId,
      assetType: _type,
      symbol: symbol,
      displayName: displayName,
      quantity: qty,
      buyPriceCents: (price * 100).round(),
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
                    ? 'Cena zakupu (PLN za 1 $unitLabel)'
                    : 'Cena zakupu (PLN za 1 gram)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'np. 280000',
                  suffixText: 'zł',
                ),
                validator: (v) =>
                    _parseNum(v ?? '') == null ? 'Wpisz cenę' : null,
              ),
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
