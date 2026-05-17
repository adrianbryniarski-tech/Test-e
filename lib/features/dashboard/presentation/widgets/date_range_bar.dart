import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/date_range_filter.dart';

/// Poziomy pasek chipów z presetami zakresu dat + "Własny…".
/// Persistuje wybór przez [DateRangeFilterNotifier].
class DateRangeBar extends ConsumerWidget {
  const DateRangeBar({super.key});

  static const _presets = DateRangePreset.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(dateRangeFilterProvider);
    final notifier = ref.read(dateRangeFilterProvider.notifier);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final preset = _presets[i];
          final selected = current.preset == preset;
          return FilterChip(
            label: Text(preset.label),
            selected: selected,
            showCheckmark: false,
            onSelected: (on) async {
              if (!on) return;
              if (preset == DateRangePreset.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start: current.start,
                    end: current.end,
                  ),
                  locale: const Locale('pl'),
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
    );
  }
}
