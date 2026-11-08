-- Rode este arquivo inteiro: Supabase > SQL Editor > New query > Run
-- Pode ser rodado mais de uma vez sem dar erro.

-- ============ TABELAS ============
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(10,2) default 0,
  category text default 'Outros',
  description text default '',
  image_url text default '',
  sold_out boolean default false,
  created_at timestamptz default now()
);
alter table products add column if not exists old_price numeric(10,2);

create table if not exists settings (
  id int primary key default 1 check (id = 1),
  store_name text default 'Vellora',
  tagline text default 'Brilho que conta a sua história',
  whatsapp text default ''
);
alter table settings add column if not exists installments int default 5;
insert into settings (id) values (1) on conflict do nothing;

create table if not exists categories (name text primary key, video_url text);

-- Sacola de cada cliente (cada pessoa só enxerga a própria)
create table if not exists cart_items (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  qty int not null default 1 check (qty > 0),
  primary key (user_id, product_id)
);

-- ============ QUEM É A DONA DA LOJA ============
-- TROQUE pelo e-mail que você usa para entrar no admin.html
create table if not exists admins (email text primary key);
insert into admins (email) values ('kaique@5514.com') on conflict do nothing;
alter table admins enable row level security;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')))
$$;

-- ============ SEGURANÇA ============
alter table products enable row level security;
alter table settings enable row level security;
alter table categories enable row level security;
alter table cart_items enable row level security;

-- produtos: todos leem, só a dona escreve
drop policy if exists "catalogo publico" on products;
create policy "catalogo publico" on products for select using (true);
drop policy if exists "dona insere" on products;
create policy "dona insere" on products for insert to authenticated with check (public.is_admin());
drop policy if exists "dona edita" on products;
create policy "dona edita" on products for update to authenticated using (public.is_admin());
drop policy if exists "dona exclui" on products;
create policy "dona exclui" on products for delete to authenticated using (public.is_admin());

-- dados da loja
drop policy if exists "config publica" on settings;
create policy "config publica" on settings for select using (true);
drop policy if exists "dona insere config" on settings;
create policy "dona insere config" on settings for insert to authenticated with check (public.is_admin());
drop policy if exists "dona edita config" on settings;
create policy "dona edita config" on settings for update to authenticated using (public.is_admin());

-- vídeos das categorias
drop policy if exists "categorias publicas" on categories;
create policy "categorias publicas" on categories for select using (true);
drop policy if exists "dona insere categoria" on categories;
create policy "dona insere categoria" on categories for insert to authenticated with check (public.is_admin());
drop policy if exists "dona edita categoria" on categories;
create policy "dona edita categoria" on categories for update to authenticated using (public.is_admin());
drop policy if exists "dona exclui categoria" on categories;
create policy "dona exclui categoria" on categories for delete to authenticated using (public.is_admin());

-- sacola: cada cliente só mexe na sua
drop policy if exists "sacola propria" on cart_items;
create policy "sacola propria" on cart_items for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============ FOTOS E VÍDEOS ============
insert into storage.buckets (id, name, public) values ('produtos', 'produtos', true) on conflict do nothing;
drop policy if exists "fotos publicas" on storage.objects;
create policy "fotos publicas" on storage.objects for select using (bucket_id = 'produtos');
drop policy if exists "dona envia fotos" on storage.objects;
create policy "dona envia fotos" on storage.objects for insert to authenticated with check (bucket_id = 'produtos' and public.is_admin());
drop policy if exists "dona troca fotos" on storage.objects;
create policy "dona troca fotos" on storage.objects for update to authenticated using (bucket_id = 'produtos' and public.is_admin());
drop policy if exists "dona apaga fotos" on storage.objects;
create policy "dona apaga fotos" on storage.objects for delete to authenticated using (bucket_id = 'produtos' and public.is_admin());
