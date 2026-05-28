---
name: nextjs-clean-architecture
description: Estruturar, criar, revisar ou refatorar apps e features Next.js com Clean Architecture, separacao entre domain/application/infrastructure/interface, App Router, Server Components, Server Actions, API routes, casos de uso, repositories e padroes senior de testabilidade. Use quando a tarefa envolver organizacao arquitetural em Next.js, definicao de camadas, fronteiras entre server/client, modularizacao por feature, integracao com banco ou servicos externos, padronizacao de pastas, ou revisao tecnica de arquitetura profissional.
---

# Next.js Clean Architecture

Siga esta skill para manter o projeto previsivel, escalavel e facil de evoluir.

## Executar fluxo

1. Identificar a feature, o fluxo de negocio e os pontos de entrada em `app`.
2. Definir fronteiras entre `domain`, `application`, `infrastructure` e `interface`.
3. Modelar entidades, contratos e regras de negocio antes da integracao concreta.
4. Implementar casos de uso na camada `application`.
5. Implementar repositories, gateways e adapters na infraestrutura.
6. Conectar Server Components, Client Components, Server Actions ou Route Handlers sem vazar regra de negocio para a UI.
7. Validar erro, loading, cache, revalidacao e testabilidade.

## Regras obrigatorias

- Manter `domain` sem dependencias de Next.js, React ou detalhes de infraestrutura.
- Manter `application` orquestrando casos de uso e contratos, sem conhecer ORM, HTTP client ou UI.
- Concentrar acesso a banco, APIs externas, auth providers, cache e filesystem em `infrastructure`.
- Tratar `app/` como camada de interface e composicao.
- Evitar regra de negocio em `page.tsx`, `layout.tsx`, componentes visuais, hooks de UI ou handlers HTTP.
- Evitar acesso direto do componente a ORM, SDK externo ou fetch sensivel quando isso quebrar a fronteira arquitetural.
- Preferir DTOs claros entre interface e casos de uso quando houver transformacao relevante.
- Fazer dependencias fluirem de fora para dentro: `interface -> application -> domain`.
- Decidir explicitamente o que roda no servidor e o que precisa ser cliente.

## Sequencia recomendada por feature

1. Definir o caso de uso e a regra de negocio.
2. Criar ou ajustar `Entity`, `Value Object` ou contratos do dominio.
3. Definir interfaces de `Repository` ou `Gateway`.
4. Implementar o `Use Case` na camada `application`.
5. Implementar adapters concretos em `infrastructure`.
6. Ligar a feature em `app/` com Server Component, Server Action ou Route Handler.
7. Adicionar validacao de entrada, mapeamento de erro e estrategia de cache.
8. Revisar testabilidade e cobertura minima do fluxo critico.

## Heuristicas para Next.js

- Preferir Server Components para leitura de dados e composicao inicial.
- Usar Client Components apenas quando houver interatividade, estado local, APIs de browser ou bibliotecas que exigem cliente.
- Usar Server Actions para mutacoes simples ligadas a formularios ou interacoes do App Router.
- Usar Route Handlers quando o fluxo precisar expor endpoint, webhook, integracao externa ou contrato HTTP reutilizavel.
- Manter parsing e validacao de entrada perto da borda, mas deixar a regra de negocio no caso de uso.
- Isolar adaptadores de `Prisma`, `Drizzle`, `fetch`, `axios`, `cookies`, `headers` e SDKs externos.
- Ser explicito sobre cache, `revalidatePath`, `revalidateTag`, `no-store` e consistencia do dado.

## Ler referencias quando necessario

- Ler [references/architecture.md](references/architecture.md) para estrutura recomendada e responsabilidades.
- Ler [references/server-client-boundaries.md](references/server-client-boundaries.md) para decidir entre Server Component, Client Component, Server Action e Route Handler.
- Ler [references/review-checklist.md](references/review-checklist.md) antes de concluir uma entrega arquitetural em Next.js.
