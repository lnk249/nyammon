-- 냠몬 방문자 수 · Supabase SQL Editor에 붙여 넣고 Run
create table if not exists public.visits (
  visitor_id uuid primary key,
  first_seen timestamptz not null default now(),
  last_seen  timestamptz not null default now(),
  views      integer not null default 1
);

-- 표를 직접 읽거나 지우지 못하게 잠금 (아래 함수로만 접근)
alter table public.visits enable row level security;

-- 방문 기록: 처음 온 사람은 1줄 추가, 다시 온 사람은 방문 횟수 +1
create or replace function public.record_visit(vid uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into visits (visitor_id) values (vid)
  on conflict (visitor_id)
  do update set views = visits.views + 1, last_seen = now();
  return json_build_object(
    'visitors', (select count(*) from visits),
    'views',    (select coalesce(sum(views), 0) from visits)
  );
end;
$$;

-- 숫자만 읽기 (같은 탭에서 새로고침할 때)
create or replace function public.get_stats()
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object(
    'visitors', (select count(*) from visits),
    'views',    (select coalesce(sum(views), 0) from visits)
  );
$$;

grant execute on function public.record_visit(uuid) to anon;
grant execute on function public.get_stats() to anon;
