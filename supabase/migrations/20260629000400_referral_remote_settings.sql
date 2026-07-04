alter table public."Company"
add column if not exists "referralSettings" jsonb not null default jsonb_build_object(
  'enabled', true,
  'showEntryPoint', true,
  'showRegisterInput', true,
  'rewardCents', 500,
  'minimumWithdrawalCents', 2500,
  'requiresPaidSubscription', true
);

update public."Company"
set "referralSettings" = jsonb_build_object(
  'enabled', coalesce(("referralSettings"->>'enabled')::boolean, true),
  'showEntryPoint', coalesce(("referralSettings"->>'showEntryPoint')::boolean, true),
  'showRegisterInput', coalesce(("referralSettings"->>'showRegisterInput')::boolean, true),
  'rewardCents', greatest(coalesce(("referralSettings"->>'rewardCents')::integer, 500), 0),
  'minimumWithdrawalCents', greatest(coalesce(("referralSettings"->>'minimumWithdrawalCents')::integer, 2500), 1),
  'requiresPaidSubscription', coalesce(("referralSettings"->>'requiresPaidSubscription')::boolean, true)
)
where id = 1;

create or replace function public.get_referral_settings()
returns jsonb
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    (
      select "referralSettings"
      from public."Company"
      where id = 1
      limit 1
    ),
    jsonb_build_object(
      'enabled', true,
      'showEntryPoint', true,
      'showRegisterInput', true,
      'rewardCents', 500,
      'minimumWithdrawalCents', 2500,
      'requiresPaidSubscription', true
    )
  );
$$;

revoke all on function public.get_referral_settings() from public;
grant execute on function public.get_referral_settings() to anon, authenticated;

create or replace function public.register_referral_by_code(
  p_referred_user_id integer,
  p_referral_code text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_referrer_user_id integer;
  v_code text;
  v_settings jsonb;
  v_enabled boolean;
  v_reward_cents integer;
begin
  v_code := upper(trim(coalesce(p_referral_code, '')));

  if v_code = '' then
    return;
  end if;

  select coalesce("referralSettings", '{}'::jsonb)
    into v_settings
  from public."Company"
  where id = 1;

  v_enabled := coalesce((v_settings->>'enabled')::boolean, true);
  v_reward_cents := greatest(
    coalesce((v_settings->>'rewardCents')::integer, 500),
    0
  );

  if not v_enabled or v_reward_cents <= 0 then
    return;
  end if;

  select id
    into v_referrer_user_id
  from public."User"
  where upper(trim("referralCode")) = v_code
  limit 1;

  if v_referrer_user_id is null then
    raise exception 'Codigo de indicacao invalido.';
  end if;

  if v_referrer_user_id = p_referred_user_id then
    raise exception 'Nao e possivel usar seu proprio codigo de indicacao.';
  end if;

  insert into public."Referral" (
    "referrerUserId",
    "referredUserId",
    "referralCode",
    status,
    "rewardCents",
    "updatedAt"
  )
  values (
    v_referrer_user_id,
    p_referred_user_id,
    v_code,
    'registered',
    v_reward_cents,
    now()
  )
  on conflict ("referredUserId") do nothing;
end;
$$;

grant execute on function public.register_referral_by_code(integer, text) to authenticated;
