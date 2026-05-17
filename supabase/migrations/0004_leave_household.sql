-- =====================================================================
-- 0004 — RPC `leave_household`: user opuszcza swoje gospodarstwo
-- =====================================================================
-- Use case: żona stworzyła osobne gospodarstwo zamiast dołączyć przez
-- kod od Adriana. Trzeba mieć mechanizm "opuść aktualne, dołącz do
-- nowego przez kod" bez kontaktowania administratora bazy.
--
-- Reguła bezpieczeństwa: każdy user może opuścić TYLKO swoje gospodarstwo
-- (auth.uid() = user_id w usuwanym wierszu).
--
-- Edge case: ostatni member (czyli właściciel pustego gospodarstwa) —
-- gospodarstwo zostaje "sierotą" bez członków. Można je później wymieść
-- (`pg_cron`), ale dla 2-osobowej apki to mało istotne. RLS bez członka
-- = nikt nie widzi → orphan jest niewidoczny.
--
-- Po opuszczeniu user nie ma już żadnego gospodarstwa →
-- `currentHouseholdIdProvider` zwraca null → router auto-redirect na
-- `/onboarding` gdzie wpisze kod od Adriana.

create or replace function leave_household(p_household_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = '42501';
  end if;

  -- Sprawdź że user jest faktycznie członkiem tego gospodarstwa.
  if not exists (
    select 1 from household_members
    where household_id = p_household_id and user_id = auth.uid()
  ) then
    raise exception 'not_a_member' using errcode = 'P0006';
  end if;

  delete from household_members
  where household_id = p_household_id and user_id = auth.uid();
end$$;
