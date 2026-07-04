create or replace function public.validate_registration_inputs(
  p_phone text,
  p_referral_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text;
  v_referral_code text;
  v_referrer_id integer;
begin
  v_phone := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
  v_referral_code := upper(trim(coalesce(p_referral_code, '')));

  if length(v_phone) < 10 or length(v_phone) > 11 then
    return jsonb_build_object(
      'valid', false,
      'code', 'invalid_phone',
      'message', 'Informe um telefone valido.'
    );
  end if;

  if exists (
    select 1
    from public."User"
    where phone = v_phone
  ) then
    return jsonb_build_object(
      'valid', false,
      'code', 'phone_already_exists',
      'message', 'Este telefone ja esta cadastrado. Use outro numero ou faca login.'
    );
  end if;

  if v_referral_code <> '' then
    select id
      into v_referrer_id
    from public."User"
    where upper(trim("referralCode")) = v_referral_code
    limit 1;

    if v_referrer_id is null then
      return jsonb_build_object(
        'valid', false,
        'code', 'invalid_referral_code',
        'message', 'Codigo de indicacao invalido.'
      );
    end if;
  end if;

  return jsonb_build_object(
    'valid', true,
    'code', 'ok',
    'message', 'Dados validos.'
  );
end;
$$;

revoke all on function public.validate_registration_inputs(text, text) from public;
grant execute on function public.validate_registration_inputs(text, text) to anon, authenticated;
