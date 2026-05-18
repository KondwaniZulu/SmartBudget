-- Auto-create a profile row whenever a new auth user is created.
-- Works for Google OAuth and other providers.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  provider_full_name text;
  provider_avatar_url text;
begin
  provider_full_name := coalesce(
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'name',
    ''
  );

  provider_avatar_url := coalesce(
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'picture',
    ''
  );

  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    nullif(provider_full_name, ''),
    nullif(provider_avatar_url, '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
