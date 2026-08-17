-- ════════════════════════════════════════════════════════════════════════════
--  Smart Pricing — Aliria Saúde  |  Módulo de Licitações
--  Execute no Supabase → SQL Editor
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Tabela de pregões (cabeçalho)
create table if not exists public.pregoes (
  id          uuid primary key default gen_random_uuid(),
  orgao       text not null,
  cnpj        text,
  numero      text,
  objeto      text,
  data_sessao date,
  estado      text default 'SC',
  status      text default 'ativo',   -- 'ativo' | 'participado'
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

create index if not exists idx_pregoes_status      on public.pregoes(status);
create index if not exists idx_pregoes_data_sessao on public.pregoes(data_sessao desc);

-- Trigger updated_at
drop trigger if exists trg_pregoes_updated_at on public.pregoes;
create trigger trg_pregoes_updated_at
  before update on public.pregoes
  for each row execute function update_updated_at();

alter table public.pregoes enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename='pregoes' and policyname='allow_all_pregoes') then
    create policy allow_all_pregoes on public.pregoes for all using (true) with check (true);
  end if;
end $$;


-- 2. Tabela de itens por pregão
create table if not exists public.pregao_itens (
  id               uuid primary key default gen_random_uuid(),
  pregao_id        uuid references public.pregoes(id) on delete cascade,
  item_num         int,
  descricao_edital text,
  catmat           text,
  ean              text,
  principio_ativo  text,
  produto_id       uuid,               -- referência a precos_compra.id (sem FK para flexibilidade)
  produto_nome     text,
  preco_caixa      numeric(12,4) default 0,
  qtd_caixa        int default 1,
  preco_unitario   numeric(12,6) default 0,
  margem           numeric(5,2)  default 0,
  qtd_edital       int default 1,
  unidade          text default 'UN',
  valor_total      numeric(14,2) default 0,
  sem_preco        boolean default false,
  created_at       timestamptz default now()
);

create index if not exists idx_pregao_itens_pregao_id on public.pregao_itens(pregao_id);
create index if not exists idx_pregao_itens_produto_id on public.pregao_itens(produto_id);

alter table public.pregao_itens enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename='pregao_itens' and policyname='allow_all_pregao_itens') then
    create policy allow_all_pregao_itens on public.pregao_itens for all using (true) with check (true);
  end if;
end $$;
