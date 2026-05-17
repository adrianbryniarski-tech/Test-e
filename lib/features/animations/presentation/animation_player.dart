import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/animations/application/animation_settings.dart';
import 'package:nasz_budzet_domowy/features/animations/presentation/bills_attack.dart';
import 'package:nasz_budzet_domowy/features/animations/presentation/car_rush.dart';
import 'package:nasz_budzet_domowy/features/animations/presentation/emoji_burst.dart';
import 'package:nasz_budzet_domowy/features/animations/presentation/expense_flash.dart';
import 'package:nasz_budzet_domowy/features/animations/presentation/money_rain.dart';
import 'package:nasz_budzet_domowy/features/animations/presentation/pharmacy_heal.dart';
import 'package:nasz_budzet_domowy/features/animations/presentation/trex_food_feast.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

/// Wybiera animację+dźwięk na podstawie typu transakcji, kategorii
/// i włączonych togglów w ustawieniach. Reusowane przez:
/// - `AddTransactionScreen` — po lokalnym sukcesie insertu
/// - `HomeShell` — gdy realtime przyniesie nową transakcję partnera
///   (jeśli `partnerFullAnimations` włączone)
class AnimationPlayer {
  const AnimationPlayer(this.ref);

  final WidgetRef ref;

  void play({
    required BuildContext context,
    required TransactionType type,
    required Category? category,
  }) {
    final settings = ref.read(animationSettingsProvider);

    if (type == TransactionType.income) {
      if (settings.isOn(AppAnimation.moneyRainOnIncome)) {
        MoneyRain.show(context);
      }
      if (settings.isOn(AppAnimation.chaChingOnIncome)) {
        // Dźwięk leci równolegle do animacji, fire-and-forget.
        ref.read(soundServiceProvider).playChaChing();
      }
      return;
    }

    // Wydatek — priorytet od dedykowanych scen do generycznego emoji burst:
    final name = category?.name.toLowerCase() ?? '';
    bool nameHas(List<String> keys) => keys.any(name.contains);

    if (nameHas(['spożywcze', 'jedzenie']) &&
        settings.isOn(AppAnimation.trexFoodFeast)) {
      TrexFoodFeast.show(context);
      return;
    }
    if (nameHas(['transport', 'paliw', 'samoch']) &&
        settings.isOn(AppAnimation.carRushOnTransport)) {
      CarRush.show(context);
      return;
    }
    if (nameHas(['zdrow', 'aptek', 'lekarz', 'medyc']) &&
        settings.isOn(AppAnimation.pharmacyHealOnHealth)) {
      PharmacyHeal.show(context);
      return;
    }
    if (nameHas(['rachun', 'prąd', 'gaz', 'wod', 'internet']) &&
        settings.isOn(AppAnimation.billsAttackOnBills)) {
      BillsAttack.show(context);
      return;
    }
    final glyphs = category == null ? null : emojisForCategory(category.name);
    if (glyphs != null && settings.isOn(AppAnimation.categoryEmojiRain)) {
      EmojiBurst.show(context, glyphs: glyphs);
      return;
    }
    if (settings.isOn(AppAnimation.expenseFlashOnExpense)) {
      ExpenseFlash.show(context);
    }
  }
}
