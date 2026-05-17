-- =====================================================================
-- 0003 — Enable Supabase Realtime dla tabel z których streamujemy
-- =====================================================================
-- Bug: Supabase domyślnie ma WYŁĄCZONĄ replikację (publikację
-- `supabase_realtime`) dla user-space tables. `supabase.from(X).stream(...)`
-- w kliencie wykonuje pierwszy SELECT przy starcie subskrypcji, ale potem
-- nie dostaje pushów o INSERT/UPDATE/DELETE. Konsekwencja: po dodaniu
-- transakcji dashboard pokazuje stare wartości aż do restartu apki.
--
-- Fix: dodajemy do publikacji `supabase_realtime` wszystkie tabele,
-- z których robimy `.stream()` po stronie Flutter:
--   - transactions (transaction_repository.watchAll)
--   - categories   (category_repository.watchAll)
--   - budgets      (budget_repository.watchAll)
--
-- Realtime respektuje RLS — user dostanie pushe tylko o wierszach,
-- które ma prawo widzieć (przez `is_household_member`).

alter publication supabase_realtime add table transactions;
alter publication supabase_realtime add table categories;
alter publication supabase_realtime add table budgets;
