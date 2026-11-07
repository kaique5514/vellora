-- Rode este arquivo inteiro no Supabase: SQL Editor > New query > Run
-- Pode ser rodado mais de uma vez sem dar erro.

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

create table if not exists settings (
  id int primary key default 1 check (id = 1),
  store_name text default 'Vellora',
  tagline text default 'Brilho que conta a sua história',
  whatsapp text default ''
);
insert into settings (id) values (1) on conflict do nothing;

alter table products add column if not exists old_price numeric(10,2);
alter table settings add column if not exists installments int default 5;

-- Segurança: todo mundo LÊ, só quem está logado ESCREVE
alter table products enable row level security;
alter table settings enable row level security;

drop policy if exists "catalogo publico" on products;
create policy "catalogo publico" on products for select using (true);
drop policy if exists "dona insere" on products;
create policy "dona insere" on products for insert to authenticated with check (true);
drop policy if exists "dona edita" on products;
create policy "dona edita" on products for update to authenticated using (true);
drop policy if exists "dona exclui" on products;
create policy "dona exclui" on products for delete to authenticated using (true);

drop policy if exists "config publica" on settings;
create policy "config publica" on settings for select using (true);
drop policy if exists "dona insere config" on settings;
create policy "dona insere config" on settings for insert to authenticated with check (true);
drop policy if exists "dona edita config" on settings;
create policy "dona edita config" on settings for update to authenticated using (true);

-- Pasta das fotos
insert into storage.buckets (id, name, public) values ('produtos', 'produtos', true) on conflict do nothing;
drop policy if exists "fotos publicas" on storage.objects;
create policy "fotos publicas" on storage.objects for select using (bucket_id = 'produtos');
drop policy if exists "dona envia fotos" on storage.objects;
create policy "dona envia fotos" on storage.objects for insert to authenticated with check (bucket_id = 'produtos');
drop policy if exists "dona troca fotos" on storage.objects;
create policy "dona troca fotos" on storage.objects for update to authenticated using (bucket_id = 'produtos');
drop policy if exists "dona apaga fotos" on storage.objects;
create policy "dona apaga fotos" on storage.objects for delete to authenticated using (bucket_id = 'produtos');

-- Vídeos das categorias (faixas Brincos, Colares...)
create table if not exists categories (name text primary key, video_url text);
alter table categories enable row level security;
drop policy if exists "categorias publicas" on categories;
create policy "categorias publicas" on categories for select using (true);
drop policy if exists "dona insere categoria" on categories;
create policy "dona insere categoria" on categories for insert to authenticated with check (true);
drop policy if exists "dona edita categoria" on categories;
create policy "dona edita categoria" on categories for update to authenticated using (true);
drop policy if exists "dona exclui categoria" on categories;
create policy "dona exclui categoria" on categories for delete to authenticated using (true);
