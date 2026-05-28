# Research: Importacao de entradas por corridas

## Decisao 1: Reaproveitar a tela de nova transacao como ponto de entrada

- Decision: O fluxo de importacao sera iniciado dentro da tela atual de nova transacao do tipo entrada, sem criar um modulo de navegacao separado.
- Rationale: O requisito nasce explicitamente nessa tela, e o modulo `transactions` ja concentra formulario, binding e controller de criacao/edicao. Isso reduz dispersao de estado e mantem o fluxo de entrada em um unico contexto de UI.
- Alternatives considered:
  - Criar uma tela independente de importacao e depois retornar para a transacao: rejeitado porque fragmenta a experiencia e aumenta complexidade de navegacao.
  - Colocar o fluxo no modulo `journey`: rejeitado porque o resultado da feature e um registro financeiro, nao uma operacao primaria de jornada.

## Decisao 2: Consolidar por forma de pagamento antes de expor detalhes

- Decision: A importacao abrira com um consolidado de totais por forma de pagamento, com possibilidade de expandir para visualizar as corridas individuais.
- Rationale: O usuario quer rapidez para registrar entrada, e o proprio modulo `journey` ja trabalha com resumo de formas de pagamento. O consolidado reduz carga visual sem perder rastreabilidade.
- Alternatives considered:
  - Mostrar lista individual de corridas desde o inicio: rejeitado porque piora a legibilidade em um fluxo operacional recorrente.
  - Mostrar apenas consolidado sem detalhes: rejeitado porque enfraquece confianca e auditoria antes da confirmacao.

## Decisao 3: Bloquear corridas ja importadas

- Decision: Corridas utilizadas em importacoes anteriores nao voltam como elegiveis para nova importacao.
- Rationale: O risco principal da feature e duplicidade financeira. O bloqueio automatico atende a decisao de produto ja tomada e reduz dependencia de atencao manual do usuario.
- Alternatives considered:
  - Permitir reimportacao com aviso: rejeitado por manter risco operacional alto.
  - Permitir livremente: rejeitado por conflitar com a regra de seguranca definida na especificacao.

## Decisao 4: Tratar distribuicao por conta como regra de dominio

- Decision: A conciliacao entre total importado e distribuicao nas contas sera representada por objetos/use cases de dominio, nao por validacoes espalhadas no controller.
- Rationale: A regra central da feature nao e visual; ela e financeira e precisa ser testavel sem UI. Isso tambem facilita reutilizar a validacao em diferentes pontos do fluxo.
- Alternatives considered:
  - Validar tudo diretamente no `TransactionsController`: rejeitado por violar a constituicao e dificultar testes deterministas.

## Decisao 5: Registrar a confirmacao como operacao de multiplas entradas coerentes

- Decision: O registro final sera modelado como um comando unico de importacao que pode gerar varias entradas, uma por conta com valor maior que zero.
- Rationale: A especificacao determina distribuicao entre uma ou mais contas. Modelar isso como sessao/comando unico permite manter rastreabilidade entre corridas importadas e entradas geradas.
- Alternatives considered:
  - Criar transacoes soltas em loop a partir do controller: rejeitado porque dificulta atomicidade logica, rastreamento e tratamento consistente de falhas.
  - Obrigar uma unica conta por importacao: rejeitado porque entra em conflito direto com o requisito de distribuicao.

## Decisao 6: Reaproveitar o contrato de corridas existente com filtro de elegibilidade

- Decision: A busca de corridas deve partir do contrato atual de `IRideRepository`, com filtro para corridas finalizadas, dados minimos validos e exclusao das ja importadas.
- Rationale: O repositorio de corridas ja expoe paginação, status e integra com o modulo de jornada. Expandir esse contrato e mais coerente do que duplicar uma fonte de dados no dominio financeiro.
- Alternatives considered:
  - Duplicar consulta de corridas dentro de `transaction_datasource`: rejeitado por acoplamento indevido entre contextos.
  - Ler corridas a partir do estado carregado em `JourneyController`: rejeitado porque criaria dependencia entre controllers de modulos diferentes.
