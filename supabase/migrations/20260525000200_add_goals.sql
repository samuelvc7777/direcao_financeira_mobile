create table if not exists public."Goal" (
  id bigserial primary key,
  "userId" bigint not null references public."User" (id) on delete cascade,
  name text not null,
  description text null,
  "targetAmountCents" bigint not null,
  "currentAmountCents" bigint not null default 0,
  status text not null default 'ACTIVE',
  "targetDate" timestamptz null,
  "completedAt" timestamptz null,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint goal_name_not_empty check (length(trim(name)) > 0),
  constraint goal_target_positive check ("targetAmountCents" > 0),
  constraint goal_current_non_negative check ("currentAmountCents" >= 0),
  constraint goal_status_valid check (status in ('ACTIVE', 'COMPLETED', 'ARCHIVED')),
  constraint goal_completed_at_status check (
    ("completedAt" is null and status <> 'COMPLETED')
    or ("completedAt" is not null and status = 'COMPLETED')
  )
);

create index if not exists goal_user_status_idx
  on public."Goal" ("userId", status);

create index if not exists goal_user_created_idx
  on public."Goal" ("userId", "createdAt" desc);

alter table public."Goal" enable row level security;

drop policy if exists "goal_select_own" on public."Goal";
drop policy if exists "goal_insert_own" on public."Goal";
drop policy if exists "goal_update_own" on public."Goal";

create policy "goal_select_own"
  on public."Goal"
  for select
  using (
    exists (
      select 1
      from public."User" u
      where u.id = "Goal"."userId"
        and lower(u.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  );

create policy "goal_insert_own"
  on public."Goal"
  for insert
  with check (
    exists (
      select 1
      from public."User" u
      where u.id = "Goal"."userId"
        and lower(u.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  );

create policy "goal_update_own"
  on public."Goal"
  for update
  using (
    exists (
      select 1
      from public."User" u
      where u.id = "Goal"."userId"
        and lower(u.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  )
  with check (
    exists (
      select 1
      from public."User" u
      where u.id = "Goal"."userId"
        and lower(u.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  );
