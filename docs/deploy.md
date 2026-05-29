# Deploy

Este projeto está pronto para deploy via Docker.

## Opção simples

1. Provisionar PostgreSQL.
2. Publicar a imagem do `backend/Dockerfile`.
3. Publicar a imagem do `web/Dockerfile`.
4. Configurar variáveis:

```env
DATABASE_URL=jdbc:postgresql://host:5432/taskmanager
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
JWT_SECRET=use-a-long-production-secret
JWT_EXPIRATION=900000
JWT_REFRESH_EXPIRATION=604800000
VITE_API_URL=https://api.seu-dominio.com/api
```

## Observações

- O backend deve ficar atrás de HTTPS em produção.
- O `JWT_SECRET` precisa ser diferente do valor de desenvolvimento.
- O web é estático e pode ser servido por Nginx, Vercel, Netlify ou qualquer CDN.
- O mobile deve apontar `API_URL` para a URL pública da API no build final.

