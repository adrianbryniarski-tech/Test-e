import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/categories/application/category_providers.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category_repository.dart';
import 'package:nasz_budzet_domowy/features/categories/presentation/widgets/color_picker.dart';
import 'package:nasz_budzet_domowy/features/categories/presentation/widgets/icon_picker.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:nasz_budzet_domowy/shared/widgets/category_avatar.dart';

/// Bottom sheet do tworzenia / edycji kategorii. Edycja systemowej
/// (`isSystem=true`) jest blokowana w UI — wywołanie z taką kategorią
/// rzuca [ArgumentError].
class CategoryEditSheet extends ConsumerStatefulWidget {
  CategoryEditSheet({this.existing, super.key})
      : assert(
          existing?.isSystem != true,
          'Systemowe kategorie są read-only',
        );

  /// `null` = tworzenie nowej. Inaczej edycja istniejącej.
  final Category? existing;

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final TextEditingController _name;
  late String _icon;
  late String _colorHex;
  late TransactionType _type;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _icon = e?.icon ?? 'shopping_cart';
    _colorHex = e?.colorHex ?? '#7AB87A';
    _type = e?.type ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nazwa nie może być pusta.');
      return;
    }
    if (name.length > 30) {
      setState(() => _error = 'Maksymalnie 30 znaków.');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    final repo = ref.read(categoryRepositoryProvider);
    final CategoryWriteResult result;
    if (_isEdit) {
      result = await repo.update(
        id: widget.existing!.id,
        name: name,
        icon: _icon,
        colorHex: _colorHex,
        type: _type,
      );
    } else {
      final householdId = ref.read(currentHouseholdIdProvider).value;
      if (householdId == null) {
        setState(() {
          _error = 'Brak gospodarstwa.';
          _submitting = false;
        });
        return;
      }
      result = await repo.insert(
        householdId: householdId,
        name: name,
        icon: _icon,
        colorHex: _colorHex,
        type: _type,
      );
    }

    if (!mounted) return;
    switch (result) {
      case CategoryWriteSuccess():
        Navigator.of(context).pop(true);
      case CategoryDuplicateName():
        setState(() {
          _error = 'Kategoria o tej nazwie już istnieje.';
          _submitting = false;
        });
      case CategoryWriteFailure(:final message):
        setState(() {
          _error = 'Nie udało się zapisać: $message';
          _submitting = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewCategory = Category(
      id: 'preview',
      householdId: 'preview',
      name: _name.text.isEmpty ? 'Podgląd' : _name.text,
      icon: _icon,
      colorHex: _colorHex,
      type: _type,
      isSystem: false,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
            ),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Edytuj kategorię' : 'Nowa kategoria',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CategoryAvatar(category: previewCategory, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa',
                      hintText: 'np. Subskrypcje',
                    ),
                    maxLength: 30,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Wydatek'),
                  icon: Icon(Icons.south),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Dochód'),
                  icon: Icon(Icons.north),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),
            Text('Kolor', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            ColorPicker(
              selectedHex: _colorHex,
              onSelected: (hex) => setState(() => _colorHex = hex),
            ),
            const SizedBox(height: 20),
            Text('Ikona', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            IconPicker(
              selected: _icon,
              onSelected: (name) => setState(() => _icon = name),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Zapisz zmiany' : 'Dodaj kategorię'),
            ),
            TextButton(
              onPressed:
                  _submitting ? null : () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
          ],
        ),
      ),
    );
  }
}
