---
name: supabase-rls-patterns
description: Wzorce Row Level Security (RLS) w Supabase dla aplikacji multi-user. Używaj gdy piszesz migracje SQL z RLS policies, tworzysz helper-funkcje typu is_household_member, wywołujesz RPC funkcje przez supabase.rpc(), lub debugujesz "PostgrestException" / "permission denied" / "infinite recursion in RLS policy".
---

# Supabase RLS — wzorce i pułapki

## ⚠️ #1 — Helper-funkcje w RLS MUSZĄ być `security definer`

Klasyczna pułapka. Helper typu `is_household_member(hh_id)` używany w policy
na `household_members` powoduje **nieskończoną rekurencję** jeśli ma
`security invoker`:

```sql
-- ❌ ŹLE — rekurencja
create function is_household_member(hh_id uuid) returns boolean
language sql stable security invoker as $$
  select exists (select 1 from household_members where ...);
$$;

create policy "members can read membership"
  on household_members for select
  using (is_household_member(household_id));
```

Wywołanie SELECT na `household_members`:
1. RLS rewriter dodaje `WHERE is_household_member(household_id)`
2. Funkcja SELECT-uje z `household_members`
3. RLS znów odpala `is_household_member` → krok 2 → loop

Postgres detektuje rekurencję i zwraca błąd / pusty wynik. Tabele wyglądają
"puste" mimo że dane są. INSERT-y z `WITH CHECK (is_household_member(...))`
też padają.

**Fix:** zmień na `security definer` — funkcja wykonuje SELECT jako owner
(zwykle `postgres`), który bypassuje RLS:

```sql
-- ✅ DOBRZE
create function is_household_member(hh_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from household_members
    where household_id = hh_id and user_id = auth.uid()
  );
$$;
```

Bezpieczeństwo OK bo zwracamy true tylko dla `auth.uid() = user_id`, a
`auth.uid()` to tożsamość klienta z JWT (niefałszowalna).

## ⚠️ #2 — RPC dla operacji multi-tabelowych

Operacje typu "stwórz X i powiąż z Y" rób przez RPC z `security definer`
zamiast łańcucha INSERT-ów z klienta. Powody:
- atomowość (jedna transakcja)
- omijają RLS na bridge-tabelach (np. `household_members` ma być write-only
  przez RPC)
- typed error codes (`raise exception ... using errcode = 'P0010'`)

Pattern:
```sql
create or replace function create_X_with_owner(p_name text)
returns uuid
language plpgsql
security definer set search_path = public as $$
declare new_id uuid;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = '42501';
  end if;
  insert into X (name) values (p_name) returning id into new_id;
  insert into X_members (X_id, user_id, role) values (new_id, auth.uid(), 'owner');
  return new_id;
end$$;
```

Klient Dart:
```dart
try {
  final result = await supabase.rpc<String>('create_X_with_owner', params: {'p_name': name});
} on PostgrestException catch (e) {
  // ZAWSZE pokaż code + message, nie tylko runtimeType!
  // e.code: '42501', 'P0010', '23505', etc.
  // e.message: czytelny opis
  showError('${e.code ?? "?"} ${e.message}');
}
```

## ⚠️ #3 — NIGDY nie pokazuj samego `e.runtimeType` w UI

```dart
// ❌ ŹLE — user widzi tylko "PostgrestException." bez treści
'Nie udało się: ${e.runtimeType}.'

// ✅ DOBRZE
on PostgrestException catch (e) {
  'Nie udało się: ${e.code ?? "?"} ${e.message}'
} on Object catch (e) {
  'Nie udało się: $e'
}
```

Bez tego debugowanie staje się zgadywaniem — user wysyła screenshot bez
informacji co właściwie padło, a Ty domyślasz się przyczyny.

## ⚠️ #4 — Custom error codes z RPC

Dla typed-error w kliencie używaj `raise exception ... using errcode = 'PXXXX'`:
```sql
raise exception 'cannot_delete_system_category' using errcode = 'P0010';
```

W Dart mapuj:
```dart
String _humanizeError(PostgrestException e) {
  return switch (e.code) {
    '23505' => 'Duplikat (UNIQUE violation)',
    '42501' => 'Brak uprawnień',
    '42P01' => 'Tabela nie istnieje (migracja niezaaplikowana?)',
    'P0010' => 'Nie można usunąć kategorii systemowej',
    _ => e.message,
  };
}
```

Standardowe kody Postgres:
- `23505` UNIQUE violation — duplikat na unique constraint
- `23503` FK violation — referencja na nieistniejący wiersz
- `42501` insufficient privilege — RLS odrzuciło / brak GRANT
- `42P01` undefined table — tabela nie istnieje
- `42883` undefined function — RPC funkcja nie istnieje (migracja stara?)
- `PT406` PostgREST: row not found dla `.single()`

## Lekcja meta

Migracje SQL z RLS są nietrywialne. Po każdej dłuższej migracji uruchom
test smoke: zaloguj się jako anon user → spróbuj INSERT / SELECT / RPC
i sprawdź czy dostajesz oczekiwane wyniki. Bez tego błędy typu RLS
recursion wychodzą dopiero w produkcji.
