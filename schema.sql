-- ════════════════════════════════════════════════════
--  Execute este SQL no Supabase → SQL Editor
--  Smart Pricing — Aliria Saúde  |  v2
-- ════════════════════════════════════════════════════

-- Recria a tabela com a estrutura correta
drop table if exists public.precos_compra;

create table public.precos_compra (
  id                uuid primary key default gen_random_uuid(),
  ean               text,
  produto           text not null,
  principio_ativo   text,
  laboratorio       text,
  nacionalidade     text,
  tributacao        text,
  integralmed       numeric(12,2),
  viveo             numeric(12,2),
  ciamed            numeric(12,2),
  pl                numeric(12,2),
  santa_cruz        numeric(12,2),
  santa_rita        numeric(12,2),
  gam               numeric(12,2),
  pontual           numeric(12,2),
  agille            numeric(12,2),
  unimed            numeric(12,2),
  medlive           numeric(12,2),
  onco              numeric(12,2),
  menor_preco       numeric(12,2),
  melhor_fornecedor text,
  data_cotacao      date default current_date,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create index idx_precos_produto on public.precos_compra(produto);
create index idx_precos_ean     on public.precos_compra(ean);
create index idx_precos_data    on public.precos_compra(data_cotacao desc);

-- Trigger updated_at
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_precos_updated_at on public.precos_compra;
create trigger trg_precos_updated_at
  before update on public.precos_compra
  for each row execute function update_updated_at();

-- RLS
alter table public.precos_compra enable row level security;
create policy "allow_all" on public.precos_compra
  for all using (true) with check (true);

-- Adiciona coluna Portaria 344 (medicamentos controlados)
alter table public.precos_compra
  add column if not exists portaria_344 boolean default null;
