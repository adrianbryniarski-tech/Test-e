-- =====================================================================
-- 0002 — Fix: rekurencja RLS w is_household_member
-- =====================================================================
-- Bug: funkcja `is_household_member` była `security invoker` — czyli
-- uruchamiała się jako wywołujący user. Kiedy była użyta w RLS policy
-- na `household_members` (SELECT), wpadała w rekurencję:
--
--   client → SELECT household_members
--          → RLS policy: USING (is_household_member(household_id))
--          → funkcja: SELECT FROM household_members WHERE ...
--          → RLS policy znów odpala is_household_member → loop
--
-- Postgres detektował to (zwracał błąd / pusty wynik), przez co
-- bezpośrednie INSERT-y typu `createInvitation` padały na `with check
-- (is_household_member(...))` mimo że user był prawomocnym członkiem.
--
-- Fix: zmiana na `security definer`. Funkcja teraz wykonuje SELECT jako
-- owner (postgres / supabase_admin, który bypassuje RLS) — czyta z
-- household_members bez triggerowania policy → brak rekurencji.
-- Logika "czy widzę gospodarstwo X" jest bezpieczna: zwracamy true tylko
-- gdy auth.uid() = user_id, a auth.uid() to tożsamość samego klienta
-- (nie da się sfałszować).

create or replace function is_household_member(hh_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from household_members
    where household_id = hh_id and user_id = auth.uid()
  );
$$;
