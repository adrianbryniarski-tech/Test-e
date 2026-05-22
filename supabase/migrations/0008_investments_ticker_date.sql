-- =====================================================================
-- 0008 — Inwestycje: ticker + data zakupu
-- =====================================================================
-- ticker: krótki symbol do wyświetlania (np. 'BTC'). Wcześniej trzymaliśmy
--   tylko `symbol` = CoinGecko id ('bitcoin'), przez co lista pokazywała
--   "0,15 BITCOIN" zamiast "0,15 BTC". Dla metali ticker = symbol (XAU/XAG).
-- purchased_at: data zakupu. Pozwala pokazać kiedy kupiono oraz (dla
--   walut obcych) przeliczyć cenę po historycznym kursie NBP z tego dnia.

alter table investments
  add column if not exists ticker text,
  add column if not exists purchased_at date;

-- Backfill istniejących wierszy:
update investments
  set purchased_at = created_at::date
  where purchased_at is null;

-- Metale: ticker = symbol (XAU/XAG). Krypto bez tickera zostają null
-- (UI ma fallback na symbol).
update investments
  set ticker = symbol
  where ticker is null and asset_type in ('gold', 'silver');
