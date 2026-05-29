# Deploy

Este projeto está pronto para CI/CD com GitHub Actions e deploy via Docker.

## CI

O workflow `CI` roda em Pull Requests para `main`, pushes na `main` e execução manual pela aba Actions.

Ele valida:

- backend Spring Boot com `mvn test`;
- web React/Vite com `npm ci` e `npm run build`;
- mobile Flutter com `flutter analyze` e `flutter test`;
- build das imagens Docker de backend e web via `docker compose build backend web`.

As checagens ficam centralizadas em `.github/workflows/checks.yml`, que é reutilizado tanto pelo CI quanto pelo CD.

## CD

O workflow `CD` roda em pushes na `main`, tags no formato `v*` e execução manual.

Antes de publicar qualquer imagem, ele executa o mesmo portão de qualidade do CI. Se alguma checagem falhar, a publicação não acontece.

Quando tudo passa, ele publica imagens no GitHub Container Registry:

```txt
ghcr.io/<dono>/<repositorio>/backend:<sha-do-commit>
ghcr.io/<dono>/<repositorio>/backend:latest
ghcr.io/<dono>/<repositorio>/web:<sha-do-commit>
ghcr.io/<dono>/<repositorio>/web:latest
```

## Variáveis

Para a imagem web apontar para a API correta em produção, configure a variável de repositório:

```txt
VITE_API_URL=https://api.seu-dominio.com/api
```

No GitHub, isso fica em:

```txt
Settings > Secrets and variables > Actions > Variables
```

Se `VITE_API_URL` não for definida, o workflow usa `http://localhost:8080/api`.

## Deploy em um provedor

O CD atual publica as imagens. O último passo, que depende do provedor escolhido, é adicionar um job depois de `publish-images` para atualizar o ambiente real.

Variáveis comuns para produção:

```env
DATABASE_URL=jdbc:postgresql://host:5432/taskmanager
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
JWT_SECRET=use-a-long-production-secret
JWT_EXPIRATION=900000
JWT_REFRESH_EXPIRATION=604800000
VITE_API_URL=https://api.seu-dominio.com/api
```

Recomendações:

- guarde senhas em GitHub Secrets, nunca no YAML;
- use `environment: production` para exigir aprovação antes de deploy real;
- mantenha o backend atrás de HTTPS;
- use um `JWT_SECRET` diferente do valor de desenvolvimento;
- publique o web em Nginx, CDN, Vercel, Netlify ou outro serviço estático.
