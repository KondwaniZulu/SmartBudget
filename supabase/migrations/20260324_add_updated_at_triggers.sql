-- Shared trigger function to keep updated_at current on row updates.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Profiles

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

-- Transactions

drop trigger if exists set_transactions_updated_at on public.transactions;
create trigger set_transactions_updated_at
before update on public.transactions
for each row
execute function public.set_updated_at();

-- Budget limits

drop trigger if exists set_budget_limits_updated_at on public.budget_limits;
create trigger set_budget_limits_updated_at
before update on public.budget_limits
for each row
execute function public.set_updated_at();
