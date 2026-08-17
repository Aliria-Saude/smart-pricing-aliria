# Guia de Setup: Firebase + GitHub Pages
## Smart Pricing — Aliria Saúde

> Siga os passos **na ordem**. Tempo estimado: 30–40 minutos.

---

## PARTE 1 — Criar o Projeto Firebase

### 1.1 — Acessar o Firebase Console
1. Acesse **[console.firebase.google.com](https://console.firebase.google.com)**
2. Entre com sua conta Google (pode ser a conta @eualiria se tiver Gmail, ou conta pessoal)
3. Clique em **"Criar um projeto"**

### 1.2 — Configurar o projeto
- **Nome do projeto:** `aliria-smart-pricing`
- **Google Analytics:** pode desativar (não é necessário)
- Clique em **"Criar projeto"** e aguarde

---

## PARTE 2 — Configurar o Firestore (banco de dados)

### 2.1 — Ativar o Firestore
1. No painel do projeto, clique em **Firestore Database** (menu lateral)
2. Clique em **"Criar banco de dados"**
3. Escolha **"Iniciar no modo de produção"** (não no modo de teste)
4. Região: selecione **`southamerica-east1` (São Paulo)** — dados ficam no Brasil
5. Clique em **"Ativar"**

### 2.2 — Aplicar as regras de segurança
1. Na aba **"Regras"** do Firestore
2. Apague o conteúdo existente
3. Cole o conteúdo do arquivo `firestore.rules` (que está na pasta do projeto)
4. Clique em **"Publicar"**

### 2.3 — Criar os índices compostos
1. Na aba **"Índices"** do Firestore
2. Clique em **"Adicionar índice"** e crie cada um abaixo:

| Coleção | Campo 1 | Campo 2 | Escopo |
|---------|---------|---------|--------|
| `auditoria` | `user_id` (Crescente) | `created_at` (Decrescente) | Coleção |
| `auditoria` | `acao` (Crescente) | `created_at` (Decrescente) | Coleção |
| `pregoes` | `status` (Crescente) | `data_sessao` (Decrescente) | Coleção |
| `pregao_itens` | `pregao_id` (Crescente) | `item_num` (Crescente) | Coleção |

> **Alternativa:** Use o Firebase CLI para aplicar os índices automaticamente:
> ```bash
> npm install -g firebase-tools
> firebase login
> firebase deploy --only firestore:indexes
> ```

---

## PARTE 3 — Configurar a Autenticação

### 3.1 — Ativar e-mail/senha
1. No menu lateral, clique em **Authentication**
2. Clique em **"Começar"**
3. Em **"Provedores de login"**, clique em **E-mail/senha**
4. Ative a opção **"E-mail/senha"**
5. Deixe **"Link de e-mail (login sem senha)"** desativado
6. Clique em **"Salvar"**

### 3.2 — Configurar segurança de senha
1. Vá em **Authentication → Configurações → Política de senha**
2. Configure:
   - **Comprimento mínimo:** `10`
   - ✅ Letras maiúsculas
   - ✅ Letras minúsculas
   - ✅ Números
   - ✅ Caracteres especiais
3. Salve

### 3.3 — Criar seu usuário
1. Vá em **Authentication → Usuários**
2. Clique em **"Adicionar usuário"**
3. **E-mail:** `vbaptista@eualiria.com.br`
4. **Senha:** Escolha uma senha forte (mín. 10 caracteres, com maiúsculas, números e símbolo)
5. Clique em **"Adicionar usuário"**

### 3.4 — Adicionar outros usuários da equipe
Repita o passo 3.3 para cada colaborador que precisar de acesso.

> **Para enviar convite por e-mail** (em vez de definir a senha):
> No Firebase Console não há "invite" direto. Use a opção de **"Redefinir senha"**
> após criar o usuário — o sistema envia o e-mail automaticamente.

---

## PARTE 4 — Obter as credenciais do Firebase

### 4.1 — Criar o app Web
1. Na página inicial do projeto, clique no ícone **`</>`** (Web)
2. **Nome do app:** `Smart Pricing Web`
3. Marque **"Também configurar o Firebase Hosting"** — NÃO precisa marcar
4. Clique em **"Registrar app"**
5. O Firebase exibirá um bloco como este — **copie os valores**:

```javascript
const firebaseConfig = {
  apiKey:            "AIzaSy...",        // ← FIREBASE_API_KEY
  authDomain:        "aliria-smart-pricing.firebaseapp.com",
  projectId:         "aliria-smart-pricing",  // ← FIREBASE_PROJECT_ID
  storageBucket:     "aliria-smart-pricing.appspot.com",
  messagingSenderId: "123456789012",      // ← FIREBASE_SENDER_ID
  appId:             "1:123456789012:web:abc123def456"  // ← FIREBASE_APP_ID
};
```

6. Clique em **"Continuar para o console"**

---

## PARTE 5 — Criar o Repositório no GitHub

### 5.1 — Criar o repositório
1. Acesse **[github.com/new](https://github.com/new)**
2. **Nome do repositório:** `smart-pricing-aliria`
3. **Visibilidade:** `Private` (privado — importante para segurança!)
4. Não marque nenhuma opção de inicialização
5. Clique em **"Create repository"**

### 5.2 — Adicionar os Secrets do GitHub
As credenciais do Firebase **não ficam no código** — ficam como segredos do repositório.

1. No repositório criado, vá em **Settings → Secrets and variables → Actions**
2. Clique em **"New repository secret"** para cada um abaixo:

| Nome do Secret | Valor (da etapa 4.1) |
|---------------|---------------------|
| `FIREBASE_API_KEY` | O valor de `apiKey` |
| `FIREBASE_PROJECT_ID` | O valor de `projectId` |
| `FIREBASE_SENDER_ID` | O valor de `messagingSenderId` |
| `FIREBASE_APP_ID` | O valor de `appId` |

### 5.3 — Ativar o GitHub Pages
1. No repositório, vá em **Settings → Pages**
2. Em **"Source"**, selecione **"GitHub Actions"**
3. Salve

---

## PARTE 6 — Enviar o código para o GitHub

No Terminal do Mac, execute:

```bash
cd "/Users/viniciusbaptista/Library/CloudStorage/OneDrive-eualiria/AUTOMATIZAÇÃO ALIRIA/smart_pricing_v2"

# Inicializa o repositório Git
git init
git branch -M main

# Adiciona o repositório remoto (substitua SEU_USUARIO pelo seu usuário GitHub)
git remote add origin https://github.com/SEU_USUARIO/smart-pricing-aliria.git

# Cria o .gitignore para não subir arquivos desnecessários
cat > .gitignore << 'EOF'
*.xlsx
*.command
*.py
node_modules/
.DS_Store
EOF

# Sobe o código
git add .
git commit -m "feat: Smart Pricing v2 — Firebase + GitHub Pages"
git push -u origin main
```

Após o push, o **GitHub Actions** vai:
1. Injetar as credenciais Firebase automaticamente
2. Publicar o site no GitHub Pages

O link do sistema será: `https://SEU_USUARIO.github.io/smart-pricing-aliria/`

---

## PARTE 7 — Migrar os dados do Supabase

### 7.1 — Exportar dados do Supabase
1. Acesse o **[Supabase → Table Editor](https://supabase.com/dashboard/project/fmivqhsfkvfunznrlxde/editor)**
2. Para cada tabela (`precos_compra`, `pregoes`, `pregao_itens`):
   - Clique em **"..."** → **"Export as CSV"**
   - Salve o arquivo

### 7.2 — Importar no Firestore
Após a migração estar funcionando, use a função de **Upload de planilha** já existente no sistema para reimportar os produtos via XLSX — o sistema salva diretamente no Firestore.

Para pregões, recadastre manualmente (normalmente são poucos).

---

## PARTE 8 — Excluir o Supabase (após validação)

Só faça isso **após confirmar que tudo funciona no Firebase**:

1. Acesse **[supabase.com/dashboard](https://supabase.com/dashboard)**
2. Selecione o projeto `fmivqhsfkvfunznrlxde`
3. Vá em **Settings → General → Danger Zone**
4. Clique em **"Delete project"**

---

## Resumo de Segurança

| Item | Status |
|------|--------|
| Credenciais nunca no código | ✅ Secrets do GitHub |
| Dados no Brasil (São Paulo) | ✅ Region `southamerica-east1` |
| Acesso somente autenticado | ✅ Firestore Rules |
| HTTPS obrigatório | ✅ GitHub Pages |
| Repositório privado | ✅ GitHub Private |
| Auditoria de todas as ações | ✅ Coleção `auditoria` |
| Senha forte obrigatória | ✅ Firebase Auth Policy |

---

## Suporte

Em caso de dúvida em qualquer etapa, entre em contato com Claude Code
e informe em qual passo está — a configuração pode ser concluída remotamente.
