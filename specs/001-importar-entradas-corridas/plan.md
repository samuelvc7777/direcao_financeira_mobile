# Implementation Plan: Importacao de entradas por corridas

**Branch**: `001-importar-entradas-corridas` | **Date**: 2026-03-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-importar-entradas-corridas/spec.md`

## Summary

Adicionar, na tela de nova transacao do tipo entrada, um fluxo de importacao de corridas finalizadas que recupere corridas elegiveis, apresente um consolidado inicial por forma de pagamento, permita expandir os detalhes das corridas e distribua o total entre contas ativas antes de registrar as entradas correspondentes. A abordagem tecnica sera manter a tela de transacao como ponto de entrada, introduzir um fluxo dedicado de importacao no modulo de `transactions`, encapsular as regras de elegibilidade, consolidacao e distribuicao no `domain`, e expandir os contratos de `transaction` e `ride` apenas no necessario para impedir reimportacao e registrar multiplas entradas coerentes com a distribuicao confirmada.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x  
**Primary Dependencies**: Flutter, GetX, dartz, dio, intl, currency_text_input_formatter, supabase_flutter  
**Storage**: APIs remotas via Nest e Supabase para transacoes; corridas via repositorio remoto de journey/rides; persistencia local existente nao e alvo desta feature  
**Testing**: flutter_test com foco em testes de controller, entidades/use cases e datasource remoto  
**Target Platform**: Android e iOS, com views responsivas para diferentes larguras mobile  
**Project Type**: mobile-app  
**Performance Goals**: carregamento perceptivelmente rapido da importacao, estados de loading/empty/error claros, sem rebuilds desnecessarios durante distribuicao entre contas  
**Constraints**: manter GetX como fonte de estado da presentation; preservar fronteiras entre `presentation`, `domain` e `data`; nao mover regra de negocio para view/controller; preservar a tela de transacao com responsabilidade de layout macro e extrair blocos visuais em widgets menores  
**Scale/Scope**: feature concentrada no modulo `transactions`, com integracao pontual ao dominio de `rides` e aos contratos de `transaction`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `presentation`, `domain` e `data` permanecem separados: interface e estado no modulo `transactions`, regras de importacao/distribuicao no `domain`, integracoes e persistencia no `data`.
- `bindings`, `controllers`, `use cases`, `repositories` e `datasources` permanecem em suas camadas corretas; o binding de `transactions` sera expandido para injetar o fluxo de importacao.
- GetX continua como fonte de estado de presentation para o formulario e para o fluxo de importacao.
- A view continuara responsavel pela estrutura macro; secoes como resumo importado, lista expandivel e distribuicao por conta serao widgets extraidos.
- Regras de elegibilidade, bloqueio de duplicidade, consolidacao e validacao da distribuicao ficarao fora da UI.
- A estrategia inclui testes nas camadas afetadas: domain, data e presentation.
- A tela afetada mantera responsividade com cards/secoes empilhadas e comportamento seguro em larguras menores.

## Project Structure

### Documentation (this feature)

```text
specs/001-importar-entradas-corridas/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- importacao-entradas-ui.md
`-- tasks.md
```

### Source Code (repository root)

```text
lib/
`-- app/
    |-- data/
    |   |-- datasources/
    |   |   `-- transaction_datasource.dart
    |   |-- providers/
    |   |   |-- nest/finance/nest_transaction_remote_datasource.dart
    |   |   `-- supabase/finance/supabase_transaction_remote_datasource.dart
    |   `-- repositories/
    |       |-- ride_repository_impl.dart
    |       `-- transaction_repository.dart
    |-- domain/
    |   |-- entities/
    |   |   |-- ride_entity.dart
    |   |   `-- transaction_entity.dart
    |   |-- repositories/
    |   |   |-- i_ride_repository.dart
    |   |   `-- i_transaction_repository.dart
    |   `-- usecases/
    |       |-- get_rides_usecase.dart
    |       `-- transaction_use_cases.dart
    `-- presentation/
        `-- modules/
            |-- journey/
            `-- transactions/
                |-- transactions_binding.dart
                |-- transactions_controller.dart
                |-- views/
                |   `-- transaction_form_view.dart
                `-- widgets/
                    |-- transactions_summary_cards.dart
                    `-- ...

test/
|-- app/
|   |-- data/providers/supabase/finance/
|   |-- domain/entities/
|   `-- presentation/modules/
`-- presentation/controllers/
```

**Structure Decision**: Concentrar a feature dentro do modulo `transactions`, criando objetos e widgets especializados para importacao de corridas, e reutilizar o contrato de `rides` apenas por novos casos de uso e adaptacoes de repositorio. Evitar criar um novo modulo de tela separado para nao fragmentar o fluxo de nova entrada.

## Layer Responsibilities

### Presentation

- `TransactionsController` passa a orquestrar o fluxo de importacao, delegando regras ao dominio e expondo estado observavel para resumo, detalhes, distribuicao e validacao.
- `TransactionFormView` permanece como estrutura macro da tela e ganha um gatilho para abrir/iniciar a importacao no modo entrada.
- Novos widgets em `transactions/widgets/` encapsulam resumo consolidado, lista expandivel de corridas, estados de inconsistencia e distribuicao por conta.
- `TransactionsBinding` injeta os novos use cases/repositorios necessarios para o fluxo.

### Domain

- Novas entidades/value objects representam corrida importavel, consolidado por forma de pagamento, distribuicao por conta e comando de registro das entradas importadas.
- Novos use cases cobrem: buscar corridas elegiveis, montar consolidado, validar distribuicao e registrar entradas importadas.
- O contrato de `ITransactionRepository` sera expandido para suportar registro atomico/logico de multiplas entradas derivadas da distribuicao.
- O contrato de `IRideRepository` ou um servico de dominio associado definira a busca das corridas elegiveis e o bloqueio de reimportacao.

### Data

- `transaction_datasource.dart` e implementacoes remotas serao expandidos apenas se o backend precisar de um endpoint/lote dedicado; caso contrario, a persistencia pode compor chamadas existentes de criacao de transacao no repositorio.
- `ride_repository_impl.dart` continuara buscando corridas paginadas, com adaptacao para filtro de elegibilidade e exclusao das ja importadas.
- O `data` tambem fica responsavel por mapear qualquer marcador de corrida importada ou vinculo corrida-transacao exigido para bloquear duplicidade futura.

## Pesquisa e Decisoes

- A pesquisa consolidada esta em [research.md](./research.md).
- As principais decisoes sao: abrir por consolidado inicial, bloquear corridas ja importadas, manter o fluxo dentro de `transactions` e tratar registro final como um comando de multiplas entradas vinculadas a uma mesma sessao de importacao.

## Estrategia de Implementacao

1. Introduzir modelos de dominio para importacao: corrida elegivel, grupo por forma de pagamento, distribuicao por conta e comando de confirmacao.
2. Expandir o dominio com use cases especificos para carregar corridas elegiveis, consolidar resumo, validar distribuicao e persistir entradas derivadas.
3. Adaptar contratos de repositorio/datasource para:
   - buscar corridas finalizadas com dados minimos;
   - excluir corridas ja importadas;
   - registrar multiplas entradas com referencia consistente da sessao de importacao;
   - marcar o vinculo entre corrida e entrada importada.
4. Refatorar `TransactionsController` para manter um subestado de importacao separado do formulario manual, evitando misturar regras no widget.
5. Atualizar `TransactionFormView` para mostrar o gatilho de importacao apenas em entrada e delegar a composicao detalhada a widgets novos.
6. Cobrir o fluxo com testes de dominio, datasource/repositorio e controller.

## Testing Strategy

### Domain Tests

- Validar elegibilidade de corridas para importacao.
- Validar consolidacao por forma de pagamento.
- Validar regra de conciliacao exata entre total importado e distribuicao por conta.
- Validar bloqueio de corridas ja importadas.

### Data Tests

- Cobrir adaptacoes nos contratos de `transaction` e `ride`, especialmente filtros de elegibilidade, enriquecimento e persistencia do registro importado.
- Expandir testes do datasource remoto de transacao quando houver novo payload ou lote de criacao.
- Validar tratamento de erro ao tentar registrar distribuicao inconsistente ou quando o backend rejeitar duplicidade.

### Presentation Tests

- Testar `TransactionsController` para estados de loading, sem corridas, com inconsistencias, distribuicao valida e confirmacao.
- Testar que a tela de nova entrada habilita o fluxo de importacao apenas para `income`.
- Testar comportamento do resumo consolidado e da expansao de detalhes sem depender de layout frágil.

## Responsiveness Strategy

- Em larguras menores, resumo, lista expandivel e distribuicao por conta permanecem empilhados verticalmente.
- Cards de consolidado e itens de conta devem evitar colunas fixas e privilegiar quebra de linha segura para valores e labels.
- A expansao dos detalhes nao pode comprometer scroll principal nem ocultar a acao de confirmacao.
- Estados vazios e de erro devem continuar legiveis sem depender de grandes larguras.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Nenhuma | Nao ha violacoes planejadas da constituicao | N/A |
