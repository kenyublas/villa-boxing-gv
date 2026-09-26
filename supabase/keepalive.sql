-- =====================================================================
-- VILLA BOXING GV — Keep-alive (evita que Supabase Free pause el proyecto)
-- Correr UNA vez en: Supabase > SQL Editor > New query > Run
-- Lo llama a diario el workflow .github/workflows/supabase-keepalive.yml
-- =====================================================================

-- Tabla de 1 fila: guarda el último ping (sirve para verificar que funciona)
create table if not exists public.keepalive (
  id          int primary key default 1 check (id = 1),
  ultimo_ping timestamptz not null default now(),
  total_pings bigint not null default 0
);
insert into public.keepalive (id) values (1) on conflict (id) do nothing;

-- RLS activo y SIN políticas: nadie la lee/escribe directo con la anon key
alter table public.keepalive enable row level security;

-- Función pública: hace una lectura real + una escritura real en la BD
-- No devuelve ningún dato de alumnos (solo 'ok' y la hora).
create or replace function public.keepalive()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  select count(*) into n from public.alumnos;   -- consulta real
  update public.keepalive
     set ultimo_ping = now(), total_pings = total_pings + 1
   where id = 1;                                 -- escritura real
  return json_build_object('ok', true, 'at', now());
end;
$$;

revoke all on function public.keepalive() from public;
grant execute on function public.keepalive() to anon, authenticated;

-- Verificación: debe devolver {"ok": true, ...}
select public.keepalive();
select * from public.keepalive;
