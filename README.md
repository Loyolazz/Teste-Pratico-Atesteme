# Task Manager — Teste Prático Atesteme

Sistema de gerenciamento de tarefas pessoais com backend Spring Boot, painel web React e aplicativo mobile Flutter consumindo a mesma API REST.

## Visão Geral

A aplicação permite cadastro, login, persistência de sessão, CRUD de projetos, CRUD de tarefas, filtros por status/prioridade e atualização de status. O backend é a fonte das regras de negócio: web e mobile não enviam `userId` para criar ou alterar recursos.

## Tecnologias

- Backend: Java 17, Spring Boot, Spring Security, JWT + refresh token, JPA/Hibernate, H2 local e PostgreSQL via Docker.
- Web: React, TypeScript, React Router, Context API, TanStack React Query, SQLite no navegador com `sql.js` e IndexedDB.
- Mobile: Flutter, Dart, Flutter Modular, MobX, Dio, SQLite com `sqflite` e `flutter_secure_storage`.

## Estrutura

```txt
backend  API REST, segurança, regras de negócio e persistência
web      painel React para gestão de projetos e tarefas
mobile   app Flutter para login, projetos e tarefas
```

## Pré-requisitos

Para rodar tudo no macOS:

```bash
brew install maven
brew install --cask flutter
brew install cocoapods
brew install --cask docker
```

Abra o Docker Desktop antes de subir o projeto:

```bash
open -a Docker
docker info
```

Confira o Flutter:

```bash
flutter doctor
```

Se o Flutter reclamar de licenças Android:

```bash
flutter doctor --android-licenses
```

Se faltar Android SDK/API recente:

```bash
sdkmanager --install "platforms;android-36" "build-tools;36.0.0" "build-tools;28.0.3" "platform-tools" "cmdline-tools;latest"
```

Se `sdkmanager` não existir, instale ou abra o Android Studio e instale pelo menu de SDK:

```bash
brew install --cask android-studio
open -a "Android Studio"
```

No Android Studio, instale Android SDK Platform 36, Android SDK Build-Tools e Android SDK Command-line Tools.

## Como Executar

### Docker completo

Sobe PostgreSQL, backend e web:

```bash
docker compose up --build
```

URLs:

```txt
Web: http://localhost:3000
API: http://localhost:8080
Swagger: http://localhost:8080/swagger-ui.html
OpenAPI JSON: http://localhost:8080/v3/api-docs
```

### Swagger/OpenAPI

O Swagger abre sem login:

```txt
http://localhost:8080/swagger-ui.html
```

Para testar endpoints protegidos:

1. Chame `POST /api/auth/register` ou `POST /api/auth/login`.
2. Copie o `accessToken` da resposta.
3. Clique em `Authorize`.
4. Cole o token no formato:

```txt
Bearer SEU_ACCESS_TOKEN_AQUI
```

### Makefile

Na raiz do projeto:

```bash
make up
```

Comandos úteis:

```bash
make rebuild  # rebuilda e sobe tudo
make logs     # acompanha logs
make down     # derruba os containers
make clean    # remove containers e volumes
```

### Banco PostgreSQL

O Docker Compose cria o banco com estas credenciais:

```txt
Host: localhost
Port: 5432
Database: taskmanager
Username: postgres
Password: postgres
```

Use esses dados para conectar por DataGrip, IntelliJ, DBeaver ou outro cliente PostgreSQL.

Se aparecer o erro abaixo ao testar a conexão:

```txt
FATAL: role "postgres" does not exist
```

Provavelmente o PostgreSQL local do Homebrew está usando a porta `5432` em vez do banco do Docker. Pare o serviço local e suba o compose novamente:

```bash
brew services stop postgresql@18

docker compose down
docker compose up --build
```

Se preferir manter o PostgreSQL local ligado, altere o mapeamento de porta do serviço `postgres` no `docker-compose.yml` para `5433:5432` e conecte usando `Port: 5433`.

### Backend

Rodando localmente com H2:

```bash
cd backend
mvn spring-boot:run
```

Com PostgreSQL:

```bash
cd backend
SPRING_PROFILES_ACTIVE=postgres mvn spring-boot:run
```

### Web

```bash
cd web
npm install
npm run dev
```

URL padrão:

```txt
http://localhost:5173
```

### Mobile

Na primeira execução, instale as dependências:

```bash
cd mobile
flutter pub get
```

Se o Flutter encontrar o emulador, mas disser que ele não é suportado pelo projeto, gere a plataforma Android:

```bash
flutter create --platforms=android .
flutter pub get
```

Com o emulador Android aberto:

```bash
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8080/api
```

O projeto usa `flutter_local_notifications`; por isso o Android precisa de core library desugaring habilitado em `android/app/build.gradle.kts`. Se o Gradle exibir a mensagem `requires core library desugaring to be enabled`, confira se o arquivo contém:

```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
```

Para listar os dispositivos disponíveis:

```bash
flutter devices
```

Use `http://10.0.2.2:8080/api` no emulador Android, porque `localhost` dentro do Android aponta para o próprio emulador. Use `http://localhost:8080/api` ao rodar em simulador iOS ou desktop.

## Variáveis de Ambiente

Backend:

```env
DATABASE_URL=jdbc:postgresql://localhost:5432/taskmanager
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
JWT_SECRET=change-me-to-a-long-secret-with-at-least-32-bytes
JWT_EXPIRATION=900000
JWT_REFRESH_EXPIRATION=604800000
```

Web:

```env
VITE_API_URL=http://localhost:8080/api
```

Mobile:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api
```

## CI/CD

O repositório tem GitHub Actions configurado para validar backend, web, mobile e Docker.

- `CI`: roda em Pull Requests para `main`, pushes na `main` e execução manual.
- `CD`: roda em pushes na `main`, tags `v*` e execução manual.
- `Checks`: workflow reutilizável chamado pelo CI e pelo CD.

O CD só publica imagens no GitHub Container Registry depois que o mesmo portão de qualidade do CI passa. Para configurar a URL da API usada no build web de produção, crie a variável `VITE_API_URL` em `Settings > Secrets and variables > Actions > Variables`.

Mais detalhes estão em `docs/deploy.md`.

## Endpoints Principais

```txt
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh
POST   /api/auth/logout
GET    /api/auth/me

GET    /api/projects
POST   /api/projects
PUT    /api/projects/{projectId}
DELETE /api/projects/{projectId}

GET    /api/projects/{projectId}/tasks
POST   /api/projects/{projectId}/tasks
PUT    /api/projects/{projectId}/tasks/{taskId}
PATCH  /api/projects/{projectId}/tasks/{taskId}/status
DELETE /api/projects/{projectId}/tasks/{taskId}
```

## Decisões Técnicas

O backend segue camadas simples: controllers recebem DTOs, services concentram regras de negócio, repositories acessam dados e o handler global padroniza erros para web e mobile. As respostas de erro incluem código, mensagem, campos inválidos quando houver, path e `requestId`; os mesmos dados são registrados no console em JSON.

A autenticação usa access token JWT curto e refresh token rotativo. O refresh token é salvo no banco apenas como hash e é revogado/rotacionado a cada renovação. O usuário autenticado é extraído do token no backend, e as operações usam consultas com `userId` para validar ownership antes de listar, editar ou excluir projetos e tarefas.

Na web, Context API guarda apenas sessão e usuário autenticado. React Query cuida de listas, mutations, loading, erro, cache e invalidação, evitando transformar o Context em cache manual da API.

No frontend web, falhas HTTP e de rede são normalizadas em um formato único, registradas no console com contexto da operação e exibidas na tela quando afetam o fluxo do usuário. Erros globais de renderização, promises não tratadas e falhas de sincronização offline também são capturados.

Web e mobile exibem alertas visíveis para erros de validação local, credenciais inválidas, sessão expirada, ausência de permissão, conflitos, registros não encontrados, API fora do ar, falhas de sincronização offline e erros inesperados. Mensagens técnicas ficam nos logs; a interface recebe mensagens amigáveis para orientar a ação do usuário.

Além do cache em memória do React Query, a web usa SQLite via WebAssembly (`sql.js`) persistido em IndexedDB. Essa camada guarda projetos e tarefas como cache local e possui fila de mutações pendentes para sincronizar quando a conexão voltar. Ao sair da sessão, o cache local é limpo para evitar vazamento entre usuários.

No mobile, Flutter Modular organiza rotas e dependências; MobX mantém estado reativo de autenticação, projetos e tarefas. Repositories isolam chamadas HTTP para as stores não conhecerem detalhes da API.

No mobile, Dio converte falhas da API em exceções de app com código, status, path, requestId e campos inválidos. Stores e repositories registram erro, stack trace e contexto no console, e somente erros de rede entram no fluxo offline/cache.

O mobile usa `sqflite` para persistir projetos e tarefas localmente, fila de operações pendentes e `flutter_secure_storage` para guardar access/refresh token. Assim como na web, SQLite é cache/offline de UX, não fonte das regras de negócio.

A fila offline do web e do mobile compacta mutações antes da sincronização: edições repetidas mantêm só o último estado, alterações em registros recém-criados são incorporadas ao próprio `CREATE`, e `CREATE` seguido de `DELETE` é descartado. Ao sincronizar, respostas `404` em mutações que apontam para registros já removidos são tratadas como conflito resolvido pelo servidor e a cópia local é removida.

## Diferenciais Incluídos

- Swagger/OpenAPI.
- Docker Compose para PostgreSQL, backend e web.
- H2 em memória para execução rápida.
- Refresh token rotativo.
- SQLite local no web e mobile para cache/persistência entre aberturas.
- Fila offline de mutações no web e no mobile, com compactação e resolução simples de conflitos.
- Tela mobile para visualizar, sincronizar e limpar a fila offline.
- CRUD completo de projetos no mobile.
- Armazenamento seguro de token no mobile.
- Dark mode na web e suporte a tema escuro do sistema no mobile.
- Notificações locais para alterações de tarefas.
- Logs estruturados em JSON no backend.
- Erros tipados e logs de console no backend, web e mobile.
- CI/CD com GitHub Actions.
- Tratamento global de erros.
- Alertas de erro no web e mobile para validação, autenticação, rede, API, sessão e sincronização offline.
- Validação de ownership.
- Estrutura modular em backend, web e mobile.

## Trade-offs

- A resolução de conflitos offline usa uma estratégia local simples de último estado vence. Ainda não há versionamento por registro, merge semântico de campos concorrentes ou revisão manual de conflito.
- A persistência local em SQLite é cache complementar. As mutações podem ser enfileiradas offline, mas a API continua validando ownership e regras ao sincronizar.
- O deploy real depende de uma conta/alvo externo. O repositório inclui Dockerfiles, workflow de publicação de imagens e guia em `docs/deploy.md`.
- H2 é o padrão para facilitar revisão local, mas há profile PostgreSQL para um banco relacional persistente.
- Testes automatizados não foram priorizados nesta entrega inicial; o próximo passo natural é cobrir services de ownership e autenticação.

## Plano de Commits Sugerido

```txt
chore(repo): setup monorepo structure
feat(backend): implement authentication and JWT security
feat(backend): add project and task CRUD with ownership validation
feat(web): implement protected task dashboard with React Query
feat(mobile): implement Modular and MobX task flow
feat(shared): add refresh token and offline sync
chore(ci): add CI and Docker image publishing
docs(readme): document setup and architecture decisions
chore(docker): add full compose setup
```

## Próximos Passos

- Adicionar testes unitários e de integração no backend.
- Publicar em um provedor específico depois de definir a conta de deploy.
