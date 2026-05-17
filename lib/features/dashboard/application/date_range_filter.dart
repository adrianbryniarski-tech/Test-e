import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Predefiniowane zakresy dat na dashboardzie.
enum DateRangePreset {
  currentMonth,
  previousMonth,
  last3Months,
  last6Months,
  last12Months,
  currentYear,
  previousYear,
  allTime,
  custom;

  String get label => switch (this) {
        DateRangePreset.currentMonth => 'Ten miesiąc',
        DateRangePreset.previousMonth => 'Poprzedni',
        DateRangePreset.last3Months => '3 miesiące',
        DateRangePreset.last6Months => '6 miesięcy',
        DateRangePreset.last12Months => '12 miesięcy',
        DateRangePreset.currentYear => 'Ten rok',
        DateRangePreset.previousYear => 'Poprzedni rok',
        DateRangePreset.allTime => 'Wszystko',
        DateRangePreset.custom => 'Własny',
      };
}

/// Aktywny zakres dat: preset + obliczone start/end.
class DateRangeFilter {
  const DateRangeFilter._({
    required this.preset,
    required this.start,
    required this.end,
  });

  factory DateRangeFilter.fromPreset(DateRangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final (s, e) = _bounds(preset, now, today);
    return DateRangeFilter._(preset: preset, start: s, end: e);
  }

  factory DateRangeFilter.custom(DateTime start, DateTime end) {
    return DateRangeFilter._(
      preset: DateRangePreset.custom,
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  final DateRangePreset preset;
  final DateTime start;
  final DateTime end;

  /// Poprzedni równy okres — do wyliczenia delty salda.
  DateRangeFilter get previousPeriod {
    final duration = end.difference(start);
    return DateRangeFilter._(
      preset: preset,
      start: start.subtract(duration + const Duration(seconds: 1)),
      end: start.subtract(const Duration(seconds: 1)),
    );
  }

  static (DateTime, DateTime) _bounds(
    DateRangePreset preset,
    DateTime now,
    DateTime todayEnd,
  ) =>
      switch (preset) {
        DateRangePreset.currentMonth => (
            DateTime(now.year, now.month),
            todayEnd,
          ),
        DateRangePreset.previousMonth => (
            DateTime(now.year, now.month - 1),
            DateTime(now.year, now.month, 0, 23, 59, 59),
          ),
        DateRangePreset.last3Months => (
            DateTime(now.year, now.month - 2),
            todayEnd,
          ),
        DateRangePreset.last6Months => (
            DateTime(now.year, now.month - 5),
            todayEnd,
          ),
        DateRangePreset.last12Months => (
            DateTime(now.year, now.month - 11),
            todayEnd,
          ),
        DateRangePreset.currentYear => (
            DateTime(now.year),
            todayEnd,
          ),
        DateRangePreset.previousYear => (
            DateTime(now.year - 1),
            DateTime(now.year, 1, 0, 23, 59, 59),
          ),
        DateRangePreset.allTime => (
            DateTime(2000),
            todayEnd,
          ),
        DateRangePreset.custom => (
            DateTime(now.year, now.month),
            todayEnd,
          ),
      };

  DateRangeFilter copyWithCustom(DateTimeRange range) =>
      DateRangeFilter.custom(range.start, range.end);
}

// ---------------------------------------------------------------------------
// Riverpod provider + SharedPreferences persistence
// ---------------------------------------------------------------------------

const _kPresetKey = 'dashboard_preset';
const _kStartKey = 'dashboard_start_ms';
const _kEndKey = 'dashboard_end_ms';

/// Mutable provider dla aktywnego zakresu dat.
/// Persystowany w `shared_preferences`.
class DateRangeFilterNotifier extends Notifier<DateRangeFilter> {
  @override
  DateRangeFilter build() {
    _loadFromPrefs();
    return DateRangeFilter.fromPreset(DateRangePreset.currentMonth);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final presetName = prefs.getString(_kPresetKey);
    if (presetName == null) return;
    final preset = DateRangePreset.values.firstWhere(
      (p) => p.name == presetName,
      orElse: () => DateRangePreset.currentMonth,
    );
    if (preset == DateRangePreset.custom) {
      final startMs = prefs.getInt(_kStartKey);
      final endMs = prefs.getInt(_kEndKey);
      if (startMs != null && endMs != null) {
        state = DateRangeFilter.custom(
          DateTime.fromMillisecondsSinceEpoch(startMs),
          DateTime.fromMillisecondsSinceEpoch(endMs),
        );
        return;
      }
    }
    state = DateRangeFilter.fromPreset(preset);
  }

  Future<void> selectPreset(DateRangePreset preset) async {
    final filter = DateRangeFilter.fromPreset(preset);
    state = filter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPresetKey, preset.name);
  }

  Future<void> selectCustom(DateTimeRange range) async {
    final filter = DateRangeFilter.custom(range.start, range.end);
    state = filter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPresetKey, DateRangePreset.custom.name);
    await prefs.setInt(
      _kStartKey,
      range.start.millisecondsSinceEpoch,
    );
    await prefs.setInt(
      _kEndKey,
      range.end.millisecondsSinceEpoch,
    );
  }
}

final dateRangeFilterProvider =
    NotifierProvider<DateRangeFilterNotifier, DateRangeFilter>(
  DateRangeFilterNotifier.new,
);
