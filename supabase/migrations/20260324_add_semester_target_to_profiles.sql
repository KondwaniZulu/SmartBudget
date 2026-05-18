alter table public.profiles
add column if not exists semester_target_ngwee bigint not null default 300000
check (semester_target_ngwee > 0);
