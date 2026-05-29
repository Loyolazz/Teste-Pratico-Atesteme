COMPOSE = docker compose

.PHONY: help up down build rebuild logs ps restart clean api web db

help:
	@echo "Comandos disponíveis:"
	@echo "  make up       Sobe banco, backend e web"
	@echo "  make down     Derruba os containers"
	@echo "  make build    Faz build das imagens"
	@echo "  make rebuild  Rebuilda e sobe tudo"
	@echo "  make logs     Mostra logs dos serviços"
	@echo "  make ps       Lista containers"
	@echo "  make restart  Reinicia os serviços"
	@echo "  make clean    Remove containers, volumes e imagens órfãs"
	@echo "  make api      Sobe apenas backend e dependências"
	@echo "  make web      Sobe web, backend e dependências"
	@echo "  make db       Sobe apenas PostgreSQL"

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

build:
	$(COMPOSE) build

rebuild:
	$(COMPOSE) up -d --build

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

restart:
	$(COMPOSE) restart

clean:
	$(COMPOSE) down -v --remove-orphans

api:
	$(COMPOSE) up -d postgres backend

web:
	$(COMPOSE) up -d postgres backend web

db:
	$(COMPOSE) up -d postgres

