-- =====================================================================
-- 0005 — Enable Realtime dla household_members
-- =====================================================================
-- Bug: gdy żona dołączyła do mojego gospodarstwa przez kod, moja apka
-- pokazywała wciąż "1 członek" mimo że w bazie było już 2. Powód:
-- `household_members` NIE była w publication `supabase_realtime`
-- (migracja 0003 dodała tylko transactions/categories/budgets).
--
-- Dla `householdMembersProvider` zmieniamy też z FutureProvider na
-- StreamProvider (po stronie Dart) — bez tej migracji stream by nie
-- przynosił INSERT eventów po dołączeniu nowego członka.

alter publication supabase_realtime add table household_members;
