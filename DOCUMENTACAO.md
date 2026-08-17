# Smart Pricing — Aliria Saúde
## Documentação Técnica Completa

> **Versão:** v2  
> **Última atualização:** Agosto 2026  
> **Responsável:** Aliria Medicamentos Especiais LTDA  
> **Contato:** contato@eualiria.com.br

---

## Índice

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura do Sistema](#2-arquitetura-do-sistema)
3. [Estrutura de Arquivos](#3-estrutura-de-arquivos)
4. [Banco de Dados — Supabase](#4-banco-de-dados--supabase)
5. [Módulos do Aplicativo](#5-módulos-do-aplicativo)
6. [Geração de PDF](#6-geração-de-pdf)
7. [Identidade Visual no PDF](#7-identidade-visual-no-pdf)
8. [Dependências Externas](#8-dependências-externas)
9. [Como Rodar Localmente](#9-como-rodar-localmente)
10. [Fluxo de Dados](#10-fluxo-de-dados)
11. [Pontos de Atenção e Riscos](#11-pontos-de-atenção-e-riscos)
12. [Próximos Passos Sugeridos](#12-próximos-passos-sugeridos)

---

## 1. Visão Geral

O **Smart Pricing** é uma aplicação web single-page (SPA) desenvolvida inteiramente em HTML/CSS/JavaScript puro, sem framework, hospedada localmente e sincronizada com o banco de dados **Supabase** (PostgreSQL gerenciado na nuvem).

**Objetivo principal:** centralizar a gestão de preços de compra de medicamentos especiais, calcular margens de forma automática, gerar orçamentos em PDF com identidade visual da Aliria, e gerenciar participações em licitações públicas (pregões eletrônicos).

**Quem usa:** equipe interna da Aliria — atendimento, compras e gestão.

---

## 2. Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    NAVEGADOR (Chrome)                    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              index.html  (SPA)                  │   │
│  │                                                 │   │
│  │  CSS inline + JS inline (~4.500 linhas)         │   │
│  │                                                 │   │
│  │  Módulos:                                       │   │
│  │  • Dashboard          • Simulador de Preços     │   │
│  │  • Tabela de Produtos • Upload de Planilhas     │   │
│  │  • Orçamento PDF      • Módulo Licitações       │   │
│  └───────────────┬─────────────────────────────────┘   │
│                  │ HTTPS (Supabase REST API)             │
└──────────────────┼──────────────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │   SUPABASE (Cloud)  │
        │   PostgreSQL        │
        │                     │
        │  • precos_compra    │
        │  • pregoes          │
        │  • pregao_itens     │
        │  • cmed (tabela     │
        │    de preços ANVISA)│
        └─────────────────────┘
```

**Tecnologia stack:**
| Camada | Tecnologia |
|--------|-----------|
| Frontend | HTML5 + CSS3 + JavaScript ES2020 (vanilla) |
| Banco de dados | Supabase (PostgreSQL) |
| PDF | jsPDF 2.5.1 |
| QR Code | qrcode.js 1.5.4 |
| Planilhas | SheetJS (xlsx) 0.20.1 |
| Ícones | SVG inline |

---

## 3. Estrutura de Arquivos

```
smart_pricing_v2/
│
├── index.html              ← Aplicação completa (SPA principal)
├── vendedor.html           ← Interface simplificada para vendedores
├── config.js               ← Credenciais Supabase + chave Gemini
│                              ⚠️ NÃO é carregado pelo index.html!
│                              As constantes estão embutidas inline.
│
├── schema.sql              ← DDL da tabela precos_compra + RLS
├── schema_licitacoes.sql   ← DDL das tabelas pregoes + pregao_itens
│
├── assets/
│   ├── logo.png            ← Cópia do círculo laranja (não usado no PDF atual)
│   └── mascots.png         ← COMPRIMIDOS SORRINDO.png (629×372px)
│                              Contém os 3 mascotes lado a lado:
│                              • Laranja (x=5..210, y=10..365)
│                              • Azul    (x=215..430, y=0..365) ← não usado
│                              • Verde   (x=430..625, y=65..372)
│
├── ABRIR.command           ← Script macOS para abrir a aplicação
├── RESTAURAR_BANCO.command ← Script para restaurar backup do banco
├── restaurar_banco.py      ← Lógica de restauração via API Supabase
├── corrigir_nomes.py       ← Utilitário de normalização de nomes
│
├── SMART PRICING - 2026.xlsx          ← Planilha de referência de preços
├── Carga ultimos preços v1 25.03.xlsx ← Base de carga inicial
└── DOCUMENTACAO.md         ← Este arquivo
```

> **⚠️ IMPORTANTE:** O arquivo `config.js` existe mas **não é carregado** pelo `index.html`. Todas as constantes críticas (`SUPABASE_URL`, `SUPABASE_ANON`, `BRAND_LOGO_WORD_B64`, `BRAND_MASCOTS_B64`) estão definidas **diretamente no bloco `<script>` inline** do `index.html`, a partir da linha ~1207.

---

## 4. Banco de Dados — Supabase

### Credenciais

```
URL:   https://fmivqhsfkvfunznrlxde.supabase.co
ANON:  eyJhbGci... (ver bloco <script> do index.html, linha ~1208)
```

> As credenciais `anon` do Supabase são públicas por design — o acesso real é controlado pelas políticas de **Row Level Security (RLS)**.

---

### Tabela: `precos_compra`

Armazena os preços de compra de cada medicamento por distribuidor.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid | PK gerada automaticamente |
| `ean` | text | Código EAN/GTIN |
| `produto` | text | Nome comercial do produto |
| `principio_ativo` | text | DCI/princípio ativo |
| `laboratorio` | text | Fabricante |
| `nacionalidade` | text | `Nacional` ou `Importado` |
| `tributacao` | text | Regime tributário (T1, T2...) |
| `integralmed` | numeric(12,2) | Preço do distribuidor Integralmed |
| `viveo` | numeric(12,2) | Preço Viveo |
| `ciamed` | numeric(12,2) | Preço Ciamed |
| `pl` | numeric(12,2) | Preço PL |
| `santa_cruz` | numeric(12,2) | Preço Santa Cruz |
| `santa_rita` | numeric(12,2) | Preço Santa Rita |
| `gam` | numeric(12,2) | Preço GAM |
| `pontual` | numeric(12,2) | Preço Pontual |
| `agille` | numeric(12,2) | Preço Agille |
| `unimed` | numeric(12,2) | Preço Unimed |
| `medlive` | numeric(12,2) | Preço Medlive |
| `onco` | numeric(12,2) | Preço Onco |
| `menor_preco` | numeric(12,2) | Calculado: mínimo entre todos |
| `melhor_fornecedor` | text | Nome do fornecedor mais barato |
| `data_cotacao` | date | Data da cotação |
| `portaria_344` | boolean | Medicamento controlado? |

---

### Tabela: `pregoes`

Cabeçalho de cada pregão eletrônico acompanhado.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid | PK |
| `orgao` | text | Órgão público comprador |
| `cnpj` | text | CNPJ do órgão |
| `numero` | text | Número do pregão |
| `objeto` | text | Descrição do objeto |
| `data_sessao` | date | Data da disputa |
| `estado` | text | UF (padrão: SC) |
| `status` | text | `ativo` ou `participado` |

---

### Tabela: `pregao_itens`

Itens de cada pregão com cálculo de margem e valor de proposta.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `pregao_id` | uuid | FK → pregoes.id |
| `item_num` | int | Número do item no edital |
| `descricao_edital` | text | Descrição original do edital |
| `ean` | text | EAN identificado |
| `produto_id` | uuid | Referência ao produto em precos_compra |
| `produto_nome` | text | Nome do produto |
| `preco_caixa` | numeric | Preço de compra por caixa |
| `qtd_caixa` | int | Unidades por caixa |
| `preco_unitario` | numeric | Preço de custo por unidade |
| `margem` | numeric(5,2) | Margem aplicada (%) |
| `qtd_edital` | int | Quantidade solicitada no edital |
| `valor_total` | numeric | Total da proposta |
| `sem_preco` | boolean | Item sem cotação disponível |

---

## 5. Módulos do Aplicativo

### 5.1 Dashboard

Exibe KPIs rápidos do banco:
- Total de produtos cadastrados
- Cotações recentes (últimos 30 dias)
- Alertas de preços desatualizados
- Status de conexão com Supabase

**Função principal:** `updateDashboard()` — linha ~1426

---

### 5.2 Tabela de Produtos

Listagem paginada de todos os produtos com busca full-text no lado cliente.

- Renderização por página: `renderPage()` — linha ~1488
- Edição inline de preço por célula: `editPriceCell()` — linha ~1554
- Portaria 344 (medicamentos controlados): `salvarPortaria344()` — linha ~1608

---

### 5.3 Simulador de Preços

O coração comercial do sistema. Calcula o preço de venda ideal com base nos custos, impostos e margem desejada.

**Fluxo de cálculo — `calcular()` — linha ~1674:**

```
Preço de Compra (menor cotação)
  → + Frete (% configurável)
  → + ICMS interestadual (tabela por UF)
  → + Margem comercial (%)
  → = Preço de Venda sugerido
  → → Cálculo de parcelas (modal)
```

**ICMS interestadual:** `getAliqInter(origem, destino, importado)` — linha ~1624  
Tabela de alíquotas interestaduais conforme legislação vigente (SC → outros estados).

---

### 5.4 Upload de Planilhas

Três modos de importação de dados:

| Modo | Função | Descrição |
|------|--------|-----------|
| **Atualizar Preços** | `onFileSelectPrecos()` | Importa planilha com cotações de distribuidores |
| **Cadastrar Novos** | `onFileSelectNovos()` | Cadastra produtos novos com consulta à CMED |
| **Upload CMED** | `onFileSelectCmed()` | Importa tabela oficial de preços ANVISA |

**Templates para download:**
- `downloadTemplatePrecos()` — linha ~2096
- `downloadTemplateNovos()` — linha ~2261

---

### 5.5 Módulo de Licitações

Gerencia a participação da Aliria em pregões eletrônicos do setor público.

**Funcionalidades:**
- Cadastro de pregões com dados do edital
- Importação de itens via PDF ou XLSX
- Simulação de margens por item
- Farol de competitividade (verde/amarelo/vermelho)
- Exportação de proposta em Excel
- Arquivamento automático de pregões vencidos

**Funções principais:**
```
initLicitacoesPage()      → carrega lista de pregões
abrirPregaoDetalhe(id)    → abre tela de itens
_parseEditalItens(file)   → lê PDF/XLSX do edital
renderDetAlertas()        → exibe alertas de margem
salvarPregaoDetalhe()     → persiste no Supabase
exportarPregaoExcel()     → gera planilha de proposta
```

---

### 5.6 Orçamento para Pacientes

Gera PDF de orçamento individualizado com identidade visual Aliria.

**Função de disparo:** `gerarOrcamentoPDF()` — linha ~3132  
**Builder compartilhado:** `_buildOrcPDF()` — linha ~2819 (ver seção 6)

---

## 6. Geração de PDF

### Função: `_buildOrcPDF(params)`

Função `async` compartilhada entre orçamento de paciente e licitação. Recebe um objeto com os dados e gera o PDF via jsPDF.

**Parâmetros:**
```javascript
{
  titulo,           // "ORÇAMENTO DE MEDICAMENTOS"
  dadosLinha1,      // array de strings — linha 1 de info do cliente
  dadosLinha2,      // array de strings — linha 2
  itens,            // [{ nome, qtd, un, vl }]
  total,            // número — valor total
  validade,         // string — data de validade
  qrSel,            // seletor CSS do canvas do QR code
  nomeArq,          // nome do arquivo (sem .pdf)
  disclaimerJudicial // texto dos termos
}
```

### Layout da página A4 (210 × 297 mm)

```
┌──────────────────────────────────────────────────────┐
│ [Logo aliria]   [Razão Social / CNPJ / Endereço]     │◄ y=8..45
│                                                [○◯]  │  Decoração sup-dir
├──────────────────────────────────────────────────────┤
│          ORÇAMENTO DE MEDICAMENTOS (laranja)          │◄ y=48..60
├──────────────────────────────────────────────────────┤
│  Nome: ...   Data: ...   Validade: ...               │
│                                                      │
│  ┌──────────────┬──────────┬─────────┬──────────┐   │
│  │ Medicamento  │ Vl Uni   │   Qtd   │  Valor   │   │
│  ├──────────────┼──────────┼─────────┼──────────┤   │
│  │ Item 1       │ R$ xx    │    1    │ R$ xx    │   │
│  └──────────────┴──────────┴─────────┴──────────┘   │
│                                     VALOR TOTAL $$   │
├──────────────────────────────────────────────────────┤
│          TERMOS E CONDIÇÕES (laranja)                 │
│  [texto do disclaimer]                               │
│                                                      │
│              Florianópolis, XX de Mês de XXXX        │
├──────────────────────────────────────────────────────┤
│ [●◯]  [texto laranja]          [mascote 🟠] [QR]    │◄ y=252..285
│  Decoração inf-esq                                   │
└──────────────────────────────────────────────────────┘
```

### Helper de recorte de imagem

```javascript
function cropB64(b64, sx, sy, sw, sh) {
  // Recorta uma região de uma imagem base64
  // Parâmetros: source x, source y, source width, source height
  // Retorna Promise<string> — base64 da região recortada
}
```

---

## 7. Identidade Visual no PDF

### Assets embutidos no `index.html` (base64 inline)

Todos os assets de marca são convertidos em base64 e embutidos diretamente no `<script>` do `index.html`. **Não dependem de arquivos externos** — funcionam offline.

| Constante | Fonte | Dimensões | Uso |
|-----------|-------|-----------|-----|
| `BRAND_LOGO_WORD_B64` | `aliria.png` | 228×128px | Logo horizontal laranja no cabeçalho |
| `BRAND_MASCOTS_B64` | `mascots.png` | 629×372px | Sprite com os 3 mascotes |

### Coordenadas de recorte dos mascotes

O arquivo `assets/mascots.png` contém 3 mascotes dispostos horizontalmente:

```
mascots.png (629 × 372 px)
┌─────────────┬─────────────┬─────────────┐
│   LARANJA   │    AZUL     │    VERDE    │
│  x: 5–210  │ x: 215–430  │ x: 430–625  │
│  y: 10–365  │  y: 0–365   │  y: 65–372  │
│  (vertical) │(horizontal) │  (círculo)  │
└─────────────┴─────────────┴─────────────┘
```

**Uso atual no PDF:**
- **Mascote laranja** `cropB64(BRAND_MASCOTS_B64, 5, 10, 205, 355)` → rodapé direito
- **Mascote verde** → não usado no layout atual
- **Mascote azul** → não usado no layout atual

### Elementos decorativos (canvas-drawn)

Gerados em tempo de execução via Canvas API, sem depender de arquivos externos:

#### Decoração superior direita
```javascript
// Bolinha laranja (#F97316) + swirl azul escuro (#1D4ED8)
// Canvas: 180×240px → renderizado em 48×58mm no PDF (canto sup-dir)
```

#### Decoração inferior esquerda
```javascript
// Círculo azul marinho (#1E3A8A) sólido Ø≈72px
// + Curva swirl azul claro (#93C5FD) abaixo
// Canvas: 130×200px → renderizado em 28×43mm no PDF (canto inf-esq)
```

---

## 8. Dependências Externas

| Biblioteca | Versão | CDN | Uso |
|-----------|--------|-----|-----|
| SheetJS | 0.20.1 | cdn.sheetjs.com | Leitura/escrita de arquivos XLSX |
| Supabase JS | 2.x | jsdelivr | Comunicação com banco PostgreSQL |
| jsPDF | 2.5.1 | cdnjs | Geração de arquivos PDF |
| qrcode.js | 1.5.4 | jsdelivr | QR code no rodapé do PDF |
| PDF.js | latest | cdnjs | Leitura de editais em PDF (módulo licitações) |

> **⚠️ Dependência de internet:** A aplicação requer conexão ativa para carregar as bibliotecas CDN e para sincronizar com o Supabase. Para uso offline completo, seria necessário baixar e servir as bibliotecas localmente.

---

## 9. Como Rodar Localmente

### Pré-requisito
- macOS com Python 3 instalado
- Pasta `smart_pricing_v2/` acessível

### Opção 1 — Duplo clique (recomendado)
```
Abrir ABRIR.command
```
Script que inicia automaticamente um servidor HTTP local e abre o Chrome.

### Opção 2 — Terminal manual
```bash
cd "AUTOMATIZAÇÃO ALIRIA/smart_pricing_v2"
python3 -m http.server 8788
# Abrir no Chrome: http://localhost:8788/
```

> **Por que servidor HTTP?** O jsPDF e o Supabase JS exigem que a página seja servida via HTTP (não `file://`) para funcionar corretamente.

---

## 10. Fluxo de Dados

### Upload de preços

```
Arquivo XLSX do usuário
  → SheetJS parseia linhas
  → normalização de cabeçalhos (resolveForn)
  → cálculo de menor_preco e melhor_fornecedor
  → upsert no Supabase (por EAN ou nome)
  → renderTable() atualiza a UI
```

### Simulação de preço

```
Usuário seleciona produto no dropdown
  → onProdutoChange() carrega dados do produto
  → Usuário ajusta margem, UF destino, parcelas
  → calcular() aplica fórmula de precificação
  → resultado exibido em tempo real
```

### Geração de PDF

```
Usuário clica "Gerar PDF"
  → valida campos obrigatórios
  → _buildOrcPDF() monta o documento:
     1. Cabeçalho com logo + decoração
     2. Título laranja
     3. Dados do cliente
     4. Tabela de itens
     5. Total + termos
     6. Rodapé com mascote + QR code
  → doc.save() → download no navegador
```

---

## 11. Pontos de Atenção e Riscos

### 🔴 Crítico

| Risco | Situação Atual | Mitigação Sugerida |
|-------|----------------|-------------------|
| **config.js não carregado** | As constantes estão embutidas no HTML — se alguém editar apenas o config.js, não surtirá efeito | Adicionar `<script src="config.js">` no `index.html` ou manter documentação clara |
| **Chave ANON exposta** | O `SUPABASE_ANON` está visível no source HTML | Normal para Supabase — garantir que o RLS esteja ativo e restritivo |
| **Sem autenticação de usuário** | Qualquer pessoa com a URL pode acessar | Implementar Supabase Auth se houver risco de acesso não autorizado |

### 🟡 Atenção

| Risco | Situação Atual | Mitigação Sugerida |
|-------|----------------|-------------------|
| **Dependência CDN** | Sem internet, a aplicação não funciona | Baixar bibliotecas e servir localmente |
| **Arquivo único de 4.500 linhas** | Dificulta manutenção | Modularizar em arquivos JS separados a longo prazo |
| **Backup de dados** | Existe `RESTAURAR_BANCO.command`, mas backup automático não está configurado | Agendar pg_dump periódico via Supabase |
| **PDF gerado no browser** | Downloads bloqueados em alguns contextos | Testar sempre via `http://localhost:8788/` |

### 🟢 Positivo

- Assets de marca embutidos em base64 → PDF funciona sem internet
- Schema SQL versionado nos arquivos `.sql`
- RLS ativado em todas as tabelas

---

## 12. Próximos Passos Sugeridos

### Curto prazo
- [ ] **Separar config.js** — fazer o `index.html` carregar `config.js` via `<script src>` e remover as constantes do inline
- [ ] **Backup automático** — configurar pg_dump semanal via cron + OneDrive
- [ ] **Ajuste fino do PDF** — alinhar exatamente ao template PPT de referência

### Médio prazo
- [ ] **Autenticação** — implementar login via Supabase Auth (email/senha) para restringir acesso
- [ ] **Histórico de orçamentos** — salvar PDFs gerados no Supabase Storage
- [ ] **Biblioteca local** — baixar jsPDF/SheetJS para funcionamento offline
- [ ] **Módulo de estoque** — integrar controle de estoque ao simulador

### Longo prazo
- [ ] **Modularização** — separar o `index.html` em módulos ES6 (`sim.js`, `licitacoes.js`, `pdf.js`...)
- [ ] **App mobile** — versão simplificada para uso em campo
- [ ] **Integração com distribuidores** — cotação automática via API dos fornecedores

---

## Apêndice A — Variáveis CSS Globais

```css
:root {
  --orange:    #F97316;   /* laranja principal */
  --orange-dk: #EA6B0A;   /* laranja hover */
  --sidebar:   #1C1C2E;   /* fundo do menu lateral */
  --bg:        #F4F5F7;   /* fundo da página */
  --card:      #FFFFFF;   /* cards brancos */
  --text:      #1A1A2E;   /* texto principal */
  --muted:     #6B7280;   /* texto secundário */
  --border:    #E5E7EB;   /* bordas */
}
```

## Apêndice B — Paleta de Cores do PDF

| Cor | Hex | RGB | Uso |
|-----|-----|-----|-----|
| Laranja principal | `#F97316` | 249,115,22 | Barras de título, textos de destaque |
| Azul escuro (navy) | `#1E3A8A` | 30,58,138 | Círculo decorativo inf-esq |
| Azul royal | `#1D4ED8` | 29,78,216 | Swirl decorativo |
| Azul claro | `#93C5FD` | 147,197,253 | Swirl inf-esq |
| Texto escuro | `#282828` | 40,40,40 | Corpo do texto |
| Cinza claro | `#F0F0F0` | 240,240,240 | Cabeçalho da tabela |

---

*Documentação gerada em agosto de 2026 — Smart Pricing v2 — Aliria Saúde*
