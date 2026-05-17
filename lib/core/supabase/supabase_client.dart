import 'package:supabase_flutter/supabase_flutter.dart';

/// Wygodny alias `supabase` zamiast `Supabase.instance.client`.
///
/// Używać tylko po wywołaniu `Supabase.initialize(...)` w `main()`.
SupabaseClient get supabase => Supabase.instance.client;
