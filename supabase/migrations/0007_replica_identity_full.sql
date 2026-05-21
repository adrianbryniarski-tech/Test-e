-- =====================================================================
-- 0007 — REPLICA IDENTITY FULL dla tabel z filtrowanym Realtime
-- =====================================================================
-- Problem: `supabase.from(X).stream(...).eq('household_id', ...)` nie
-- usuwał wierszy po DELETE. Powód: domyślnie payload eventu DELETE z
-- Postgres logical replication zawiera TYLKO klucz główny (id). Filtr
-- Realtime po `household_id` nie ma więc na czym dopasować eventu DELETE
-- → klient nigdy nie dostaje informacji o usunięciu → lista i sumy
-- (np. wartość portfela inwestycji) zostają nieaktualne.
--
-- Fix: REPLICA IDENTITY FULL → payload DELETE/UPDATE zawiera WSZYSTKIE
-- kolumny (w tym household_id), więc filtr Realtime dopasowuje event i
-- klient poprawnie usuwa/aktualizuje wiersz w strumieniu.
--
-- Koszt: minimalnie więcej danych w WAL dla tych tabel — dla apki dla
-- 2 osób bez znaczenia.

alter table transactions       replica identity full;
alter table categories         replica identity full;
alter table budgets            replica identity full;
alter table household_members  replica identity full;
alter table investments        replica identity full;
alter table portfolio_snapshots replica identity full;
