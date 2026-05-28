---
name: flutter-clean-architecture-getx
description: Estruturar, criar, revisar ou refatorar apps e features Flutter com Clean Architecture, GetX, entities, repositories, use cases, bindings e tratamento de erros com Either/Failure. Use quando a tarefa envolver organizacao de camadas, fluxo Domain/Data/App, injecao de dependencias, controllers GetX ou padronizacao arquitetural senior em Flutter.
---

# Flutter Clean Architecture GetX

Siga esta skill para manter o app previsivel, testavel e consistente.

## Executar fluxo

1. Identificar o escopo da feature ou correcao.
2. Mapear o impacto nas camadas `domain`, `data`, `core` e `app`.
3. Criar ou ajustar contratos no `domain` antes da implementacao concreta.
4. Implementar `datasource`, `model` e `repository_impl` no `data`.
5. Ligar `usecases`, `controller` e `binding` no `app`.
6. Validar loading, sucesso e falha no controller e na UI.

## Regras obrigatorias

- Manter `domain` sem dependencias de Flutter.
- Retornar `Either<Failure, T>` em repositories e use cases quando o fluxo puder falhar.
- Concentrar `try/catch` em `repository_impl` ou camada de infraestrutura equivalente.
- Converter excecoes tecnicas em `Failure` com mensagem util.
- Fazer o controller decidir como expor loading, erro e sucesso.
- Evitar regra de negocio em widget.
- Evitar acesso direto a datasource dentro de controller.

## Sequencia recomendada por feature

1. Criar ou ajustar `Entity`.
2. Definir interface do `Repository`.
3. Criar `UseCase` com assinatura clara.
4. Implementar `Model` com serializacao necessaria.
5. Implementar `DataSource`.
6. Implementar `RepositoryImpl`.
7. Registrar dependencias no `Binding`.
8. Atualizar `Controller`.
9. Conectar a `Page` ou widgets.

## Ler referencias quando necessario

- Ler [references/architecture.md](references/architecture.md) para estrutura de pastas e responsabilidades.
- Ler [references/error-handling.md](references/error-handling.md) para padrao de `Failure`, `Either` e `.fold()`.
- Ler [references/feature-checklist.md](references/feature-checklist.md) antes de concluir uma entrega arquitetural.
