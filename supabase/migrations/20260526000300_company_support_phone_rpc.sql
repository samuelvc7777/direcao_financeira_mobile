create or replace function public.get_company_support_phone()
returns text
language sql
security definer
set search_path = public
as $$
  select nullif(trim("companyPhone"), '')
  from public."User"
  where "companyPhone" is not null
    and trim("companyPhone") <> ''
  order by
    case
      when role::text = 'ADMIN' then 0
      when role::text = 'ATTENDANT' then 1
      else 2
    end,
    "updatedAt" desc nulls last,
    id desc
  limit 1;
$$;

revoke all on function public.get_company_support_phone() from public;
grant execute on function public.get_company_support_phone() to anon, authenticated;
