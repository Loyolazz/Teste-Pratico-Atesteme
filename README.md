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

## Como Executar

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

### Docker completo

Sobe PostgreSQL, backend e web:

```bash
docker compose up --build
```

URLs:

```txt
Web: http://localhost:3000
API: http://localhost:8080
```

### Banco PostgreSQL opcional

O backend roda com H2 em memória por padrão. Para usar PostgreSQL:

```bash
docker compose up -d
```

### Backend

```bash
cd backend
mvn spring-boot:run
```

Com PostgreSQL:

```bash
cd backend
SPRING_PROFILES_ACTIVE=postgres mvn spring-boot:run
```

Swagger/OpenAPI:

```txt
http://localhost:8080/swagger-ui.html
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

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api
```

Use `http://localhost:8080/api` ao rodar em simulador iOS ou desktop.

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
