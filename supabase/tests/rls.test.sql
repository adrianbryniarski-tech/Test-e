-- =====================================================================
-- Testy RLS dla migracji 0001.
-- Uruchamiać: `supabase test db` (lokalnie) lub przez psql jeśli pgTAP.
-- =====================================================================
--
-- Bez pgTAP w środowisku CI free tier możemy zrobić smoke testy
-- z psql w formie asercji do wyników SELECT. Plik gotowy do rozszerzenia
-- gdy projekt dorobi się pgTAP.

begin;

-- 1. Próba SELECT z transactions jako anon (bez auth.uid()) powinna zwrócić 0
--    nie błąd 42501 — bo RLS filtruje rekordy. Sprawdzamy że nie ma rekordów
--    "przeciekających" mimo posiadania jakichkolwiek transakcji w DB.

-- (Wstawić scenariusze gdy będą prawdziwe dane testowe — placeholder.)

-- 2. Insert do transactions z `created_by != auth.uid()` powinien być odrzucony
--    przez polityki "members can insert transactions".

-- TODO: pgTAP fixtures po setupie Supabase + służy do tej pory jako placeholder.

rollback;
