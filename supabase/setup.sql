-- =====================================================================
-- VILLA BOXING GV — Setup de seguridad + pagos
-- Correr en: Supabase > SQL Editor > New query > pegar todo > Run
-- Es idempotente: se puede correr más de una vez sin romper nada.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) TABLA DE ADMINISTRADORES
--    Solo los usuarios de Auth que estén aquí pueden ver/editar datos.
-- ---------------------------------------------------------------------
create table if not exists public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nombre     text,
  created_at timestamptz not null default now()
);

create or replace function public.es_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

alter table public.admins enable row level security;

drop policy if exists "admins_self_read" on public.admins;
create policy "admins_self_read" on public.admins
  for select to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- 2) ALUMNOS: columnas que usa el sistema + RLS
-- ---------------------------------------------------------------------
alter table public.alumnos add column if not exists whatsapp_renovacion_enviado boolean default false;

alter table public.alumnos enable row level security;

-- Borra TODAS las políticas anteriores de alumnos (incluidas las que
-- daban acceso público con la anon key)
do $$
declare p record;
begin
  for p in select policyname from pg_policies
           where schemaname = 'public' and tablename = 'alumnos'
  loop
    execute format('drop policy %I on public.alumnos', p.policyname);
  end loop;
end $$;

create policy "alumnos_admin_all" on public.alumnos
  for all to authenticated
  using (public.es_admin())
  with check (public.es_admin());

-- ---------------------------------------------------------------------
-- 3) PAGOS: historial real de ingresos
-- ---------------------------------------------------------------------
create table if not exists public.pagos (
  id             uuid primary key default gen_random_uuid(),
  alumno_id      uuid references public.alumnos(id) on delete set null,
  alumno_nombre  text not null,                 -- copia por si se borra el alumno
  concepto       text not null default 'mensualidad'
                 check (concepto in ('matricula','mensualidad','renovacion','otro')),
  monto          numeric(10,2) not null check (monto >= 0),
  metodo         text not null default 'efectivo'
                 check (metodo in ('efectivo','yape','plin','transferencia','otro')),
  fecha_pago     date not null default (now() at time zone 'America/Lima')::date,
  periodo_desde  date,
  periodo_hasta  date,
  nota           text,
  created_at     timestamptz not null default now()
);

create index if not exists pagos_fecha_idx  on public.pagos (fecha_pago);
create index if not exists pagos_alumno_idx on public.pagos (alumno_id);

alter table public.pagos enable row level security;

do $$
declare p record;
begin
  for p in select policyname from pg_policies
           where schemaname = 'public' and tablename = 'pagos'
  loop
    execute format('drop policy %I on public.pagos', p.policyname);
  end loop;
end $$;

create policy "pagos_admin_all" on public.pagos
  for all to authenticated
  using (public.es_admin())
  with check (public.es_admin());

-- ---------------------------------------------------------------------
-- 4) MIGRAR HISTORIAL: un pago por cada alumno existente (su último
--    periodo registrado) para que "Ingresos del mes" no arranque en 0.
--    Solo se inserta si el alumno aún no tiene pagos.
-- ---------------------------------------------------------------------
insert into public.pagos (alumno_id, alumno_nombre, concepto, monto, metodo,
                          fecha_pago, periodo_desde, periodo_hasta, nota)
select a.id, a.nombre, 'mensualidad', coalesce(a.monto,0), 'efectivo',
       coalesce(a.fecha_vence - 30, a.fecha_inicio),
       coalesce(a.fecha_vence - 30, a.fecha_inicio), a.fecha_vence,
       'Migrado automáticamente'
from public.alumnos a
where not exists (select 1 from public.pagos p where p.alumno_id = a.id);

-- ---------------------------------------------------------------------
-- 5) REGISTRAR AL ADMIN
--    Antes: Authentication > Users > Add user > Create new user
--           (correo + contraseña, marcar "Auto Confirm User").
--    Luego cambia el correo de abajo y corre SOLO este bloque.
-- ---------------------------------------------------------------------
-- insert into public.admins (user_id, nombre)
-- select id, 'Gonzalo Villanueva' from auth.users
-- where email = 'CORREO_DEL_ADMIN@gmail.com'
-- on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------
-- 6) VERIFICACIÓN (debe mostrar rowsecurity = true en las 3 tablas)
-- ---------------------------------------------------------------------
select tablename, rowsecurity from pg_tables
where schemaname = 'public' and tablename in ('alumnos','pagos','admins');
