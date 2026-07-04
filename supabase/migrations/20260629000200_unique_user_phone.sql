create unique index if not exists user_phone_unique_key
on public."User" (phone)
where phone is not null
  and trim(phone) <> '';
