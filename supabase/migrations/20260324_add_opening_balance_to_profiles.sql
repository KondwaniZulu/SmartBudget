alter table public.profiles
add column if not exists opening_balance_ngwee bigint not null default 0
check (opening_balance_ngwee >= 0);
