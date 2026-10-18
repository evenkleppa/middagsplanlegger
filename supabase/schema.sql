-- Middagsplanen: database for Supabase
-- Kjør hele denne filen én gang i Supabase: SQL Editor → New query → lim inn → Run.
-- Trygg å kjøre på nytt (den hopper over det som allerede finnes).

-- Husstander: en gruppe som deler meny, retter og handleliste
create table if not exists public.households (
  id         uuid primary key default gen_random_uuid(),
  name       text not null default 'Vår husstand',
  join_code  text not null unique default upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6)),
  created_at timestamptz not null default now()
);

-- Hvem som er med i hvilken husstand
create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  joined_at    timestamptz not null default now(),
  primary key (household_id, user_id)
);

-- Alle data i appen (retter, menyer, pakkestørrelser, hjemme-liste, innstillinger).
-- path er f.eks. "recipes/taco", "plans/2026-10", "settings/main".
create table if not exists public.docs (
  household_id uuid not null references public.households(id) on delete cascade,
  path         text not null check (char_length(path) between 3 and 300),
  data         jsonb not null,
  updated_at   timestamptz not null default now(),
  primary key (household_id, path)
);

-- Sanntid: endringer på én telefon dukker opp på den andre
alter table public.docs replica identity full;
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'docs'
  ) then
    alter publication supabase_realtime add table public.docs;
  end if;
end $$;

-- Tilgangsregler: man ser og endrer bare sin egen husstand
alter table public.households        enable row level security;
alter table public.household_members enable row level security;
alter table public.docs              enable row level security;

create or replace function public.is_member(hid uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.household_members
    where household_id = hid and user_id = auth.uid()
  );
$$;

drop policy if exists "medlemmer ser husstanden" on public.households;
create policy "medlemmer ser husstanden" on public.households
  for select to authenticated using (public.is_member(id));

drop policy if exists "medlemmer ser medlemmer" on public.household_members;
create policy "medlemmer ser medlemmer" on public.household_members
  for select to authenticated using (user_id = auth.uid() or public.is_member(household_id));

drop policy if exists "medlemmer leser data" on public.docs;
create policy "medlemmer leser data" on public.docs
  for select to authenticated using (public.is_member(household_id));

drop policy if exists "medlemmer legger til data" on public.docs;
create policy "medlemmer legger til data" on public.docs
  for insert to authenticated with check (public.is_member(household_id));

drop policy if exists "medlemmer endrer data" on public.docs;
create policy "medlemmer endrer data" on public.docs
  for update to authenticated using (public.is_member(household_id)) with check (public.is_member(household_id));

drop policy if exists "medlemmer sletter data" on public.docs;
create policy "medlemmer sletter data" on public.docs
  for delete to authenticated using (public.is_member(household_id));

-- Opprett en ny husstand og bli med i den
create or replace function public.create_household(hname text default 'Vår husstand')
returns public.households
language plpgsql security definer
set search_path = public
as $$
declare h public.households;
begin
  if auth.uid() is null then
    raise exception 'Du må være logget inn';
  end if;
  insert into public.households(name) values (coalesce(nullif(trim(hname), ''), 'Vår husstand')) returning * into h;
  insert into public.household_members(household_id, user_id) values (h.id, auth.uid());
  return h;
end $$;

-- Bli med i en husstand med en kode (f.eks. fra partneren)
create or replace function public.join_household(code text)
returns public.households
language plpgsql security definer
set search_path = public
as $$
declare h public.households;
begin
  if auth.uid() is null then
    raise exception 'Du må være logget inn';
  end if;
  select * into h from public.households where join_code = upper(trim(code));
  if h.id is null then
    raise exception 'Fant ingen husstand med koden %', upper(trim(code));
  end if;
  insert into public.household_members(household_id, user_id) values (h.id, auth.uid())
    on conflict do nothing;
  return h;
end $$;

revoke all on function public.create_household(text) from public, anon;
revoke all on function public.join_household(text) from public, anon;
revoke all on function public.is_member(uuid) from public, anon;
grant execute on function public.create_household(text) to authenticated;
grant execute on function public.join_household(text) to authenticated;
grant execute on function public.is_member(uuid) to authenticated;

grant select on public.households, public.household_members to authenticated;
grant select, insert, update, delete on public.docs to authenticated;
