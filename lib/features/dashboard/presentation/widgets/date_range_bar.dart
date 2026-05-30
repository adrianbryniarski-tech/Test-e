import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/date_range_filter.dart';

/// Pasek wyboru zakresu dat: czytelna etykieta aktywnego okresu + chipy
/// z presetami i „Własny…". Persistuje wybór przez [DateRangeFilterNotifier].
class DateRangeBar extends ConsumerWidget {
  const DateRangeBar({super.key});

  static const _presets = DateRangePreset.values;

  /// Czytelny opis aktywnego zakresu, np. „9 maj – 15 maj 2026”.
  static String _rangeLabel(DateRangeFilter f) {
    final sameYear = f.start.year == f.end.year;
    final dm = DateFormat('d MMM', 'pl_PL');
    final dmy = DateFormat('d MMM y', 'pl_PL');
    final start = sameYear ? dm.format(f.start) : dmy.format(f.start);
    return '$start – ${dmy.format(f.end)}';
  }

  /// Krótka etykieta na chipie „Własny”, gdy jest aktywny (np. „9.05–15.05”).
  static String _customChipLabel(DateRangeFilter f) {
    final d = DateFormat('d.MM', 'pl_PL');
    return '${d.format(f.start)}–${d.format(f.end)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(dateRangeFilterProvider);
    final notifier = ref.read(dateRangeFilterProvider.notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Pokazuję: ${_rangeLabel(current)}',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final preset = _presets[i];
              final selected = current.preset == preset;
              final isCustom = preset == DateRangePreset.custom;
              final label = isCustom && selected
                  ? _customChipLabel(current)
                  : preset.label;
              return FilterChip(
                label: Text(label),
                selected: selected,
                showCheckmark: false,
                onSelected: (on) async {
                  if (!on) return;
                  if (isCustom) {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(
                        start: current.start,
                        end: current.end,
                      ),
                      locale: const Locale('pl'),
                      helpText: 'Wybierz zakres dat',
                      saveText: 'Zatwierdź',
                      builder: (ctx, child) =>
                          Theme(data: Theme.of(ctx), child: child!),
                    );
                    if (range != null) {
                      await notifier.selectCustom(range);
                    }
                  } else {
                    await notifier.selectPreset(preset);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
