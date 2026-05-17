import 'package:flutter/material.dart';

/// Ikona po nazwie (string) — Material Icons mają `IconData` jako
/// compile-time constants (`Icons.shopping_cart`), więc lookup wymaga
/// statycznej mapy. Synchronizowana z `assets/icons/category_icons.json`.
///
/// Lista zawiera wszystkie 78 ikon używanych w pickerze kategorii
/// (Ticket 7) — sortowanie/search po `tags` z JSON jest po stronie
/// IconPicker'a.
class MaterialSymbolIcon extends StatelessWidget {
  const MaterialSymbolIcon({
    required this.name,
    this.size,
    this.color,
    super.key,
  });

  final String name;
  final double? size;
  final Color? color;

  /// Mapa nazwa → IconData. Source of truth dla wszystkich ikon
  /// renderowalnych w aplikacji.
  static const Map<String, IconData> map = {
    // Zakupy
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'store': Icons.store,
    'local_grocery_store': Icons.local_grocery_store,
    // Rachunki
    'receipt_long': Icons.receipt_long,
    'request_quote': Icons.request_quote,
    'wifi': Icons.wifi,
    'phone': Icons.phone,
    'bolt': Icons.bolt,
    'water_drop': Icons.water_drop,
    'local_fire_department': Icons.local_fire_department,
    'tv': Icons.tv,
    'subscriptions': Icons.subscriptions,
    'cloud': Icons.cloud,
    // Transport
    'directions_car': Icons.directions_car,
    'local_gas_station': Icons.local_gas_station,
    'directions_bus': Icons.directions_bus,
    'train': Icons.train,
    'flight': Icons.flight,
    'directions_bike': Icons.directions_bike,
    'directions_walk': Icons.directions_walk,
    // Rozrywka
    'theaters': Icons.theaters,
    'music_note': Icons.music_note,
    'sports_esports': Icons.sports_esports,
    // Zdrowie
    'local_pharmacy': Icons.local_pharmacy,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center,
    'psychology': Icons.psychology,
    // Dzieci / rodzina
    'child_care': Icons.child_care,
    'school': Icons.school,
    'elderly': Icons.elderly,
    'family_restroom': Icons.family_restroom,
    'diversity_3': Icons.diversity_3,
    // Mieszkanie / dom
    'home_work': Icons.home_work,
    'house': Icons.house,
    'bed': Icons.bed,
    'build': Icons.build,
    'construction': Icons.construction,
    'yard': Icons.yard,
    'local_florist': Icons.local_florist,
    // Ubrania
    'checkroom': Icons.checkroom,
    'watch': Icons.watch,
    // Dochód / bank
    'payments': Icons.payments,
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'trending_up': Icons.trending_up,
    'credit_card': Icons.credit_card,
    'currency_exchange': Icons.currency_exchange,
    'attach_money': Icons.attach_money,
    // Jedzenie
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'fastfood': Icons.fastfood,
    'icecream': Icons.icecream,
    // Hobby / sport / natura
    'pets': Icons.pets,
    'park': Icons.park,
    'beach_access': Icons.beach_access,
    'hiking': Icons.hiking,
    'sports_soccer': Icons.sports_soccer,
    'sports_basketball': Icons.sports_basketball,
    'palette': Icons.palette,
    'menu_book': Icons.menu_book,
    'videocam': Icons.videocam,
    'camera_alt': Icons.camera_alt,
    // Prezenty / okazje
    'card_giftcard': Icons.card_giftcard,
    'redeem': Icons.redeem,
    'volunteer_activism': Icons.volunteer_activism,
    'celebration': Icons.celebration,
    'favorite': Icons.favorite,
    // Uroda
    'spa': Icons.spa,
    'content_cut': Icons.content_cut,
    // Elektronika
    'phone_iphone': Icons.phone_iphone,
    'laptop': Icons.laptop,
    'headphones': Icons.headphones,
    // Wakacje / podróże
    'luggage': Icons.luggage,
    'hotel': Icons.hotel,
    'explore': Icons.explore,
    // Edukacja
    'language': Icons.language,
    // Catch-all
    'more_horiz': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return Icon(
      map[name] ?? Icons.more_horiz,
      size: size,
      color: color,
    );
  }
}
