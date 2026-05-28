# Architecture

## Estrutura base sugerida

```text
src/
  app/
    (routes e composicao de interface)
  modules/
    billing/
      domain/
        entities/
        value-objects/
        services/
        repositories/
      application/
        dto/
        use-cases/
        mappers/
      infrastructure/
        repositories/
        gateways/
        persistence/
        schemas/
      interface/
        components/
        hooks/
        presenters/
        actions/
```

## Responsabilidades por camada

- `domain/`: entidades, regras puras, contratos, invariantes e linguagem de negocio.
- `application/`: casos de uso, orquestracao, DTOs, comandos, queries e coordenacao entre contratos.
- `infrastructure/`: implementacoes concretas de repository, adapters, ORM, HTTP, auth e storage.
- `interface/`: componentes, presenters, hooks de tela e bindings com `app/`.
- `app/`: ponto de entrada do Next.js; compoe a interface, aplica metadata, layout, navegacao e bordas HTTP.

## Convencoes recomendadas

- Organizar por feature quando o dominio crescer.
- Evitar pastas globais gigantes misturando tudo por tipo tecnico.
- Nomear casos de uso com verbo de negocio, como `CreateInvoiceUseCase` ou `ListTransactionsUseCase`.
- Nomear contratos por intencao, como `InvoiceRepository` e nao `PrismaInvoiceRepository` no dominio.
- Implementacoes concretas ficam na infraestrutura, como `PrismaInvoiceRepository`.
- Criar `mapper` quando houver traducao entre entidade, persistencia e resposta de interface.

## Fluxo ideal

1. A interface recebe input.
2. A borda valida e normaliza o input.
3. O caso de uso executa a regra.
4. O repository ou gateway concreto acessa dependencias externas.
5. O resultado volta mapeado para a interface.

## Anti-padroes a evitar

- `page.tsx` chamando ORM diretamente para fluxo de negocio complexo.
- Hook de UI decidindo regra fiscal, financeira ou permissao de negocio.
- DTO de API virando entidade sem mapeamento explicito.
- Dominio importando `next/cache`, `next/headers`, `react` ou `zod` por conveniencia.
- Repository de dominio conhecendo detalhes de query SQL ou shape de resposta HTTP.
