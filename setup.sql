-- Rode este arquivo inteiro no Supabase: SQL Editor > New query > Run

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

-- Segurança: todo mundo LÊ, só quem está logado ESCREVE
alter table products enable row level security;
alter table settings enable row level security;

create policy "catalogo publico" on products for select using (true);
create policy "dona insere" on products for insert to authenticated with check (true);
create policy "dona edita" on products for update to authenticated using (true);
create policy "dona exclui" on products for delete to authenticated using (true);

create policy "config publica" on settings for select using (true);
create policy "dona insere config" on settings for insert to authenticated with check (true);
create policy "dona edita config" on settings for update to authenticated using (true);

-- Pasta das fotos
insert into storage.buckets (id, name, public) values ('produtos', 'produtos', true) on conflict do nothing;
create policy "fotos publicas" on storage.objects for select using (bucket_id = 'produtos');
create policy "dona envia fotos" on storage.objects for insert to authenticated with check (bucket_id = 'produtos');
create policy "dona troca fotos" on storage.objects for update to authenticated using (bucket_id = 'produtos');
create policy "dona apaga fotos" on storage.objects for delete to authenticated using (bucket_id = 'produtos');
