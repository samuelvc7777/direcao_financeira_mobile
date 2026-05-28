# Research: Tela de metas

## Decisao 1: `Goal` como entidade propria

**Decision**: Criar uma entidade/tabela `Goal` independente de `CostsGainsSettings`.

**Rationale**: `CostsGainsSettings.desiredMonthlyProfitCents` representa apenas "quanto quero ganhar por mes" dentro do calculo operacional de custos e ganhos. A tela "Minhas Metas" precisa listar varias metas pessoais/financeiras, com ciclo de vida e progresso proprio.

**Alternatives considered**:

- Reaproveitar `CostsGainsSettings`: rejeitado porque mistura configuracao operacional com cadastro de varias metas.
- Manter metas mockadas no `HomeController`: rejeitado porque contradiz a spec e deixa a Home mostrando dado demonstrativo.

## Decisao 2: Suporte aos dois providers do app

**Decision**: Implementar contrato de data source para Nest e Supabase, registrando `IGoalDataSource` no `ProviderBinding` conforme provider ativo.

**Rationale**: O app ja alterna entre `BackendProviderKind.nest` e `BackendProviderKind.supabase`. Contas, cartoes, categorias e transacoes possuem datasources equivalentes. A feature deve seguir esse padrao para nao quebrar ambientes existentes.

**Alternatives considered**:

- Implementar apenas Supabase: rejeitado porque o app possui provider Nest e backend financeiro real.
- Implementar apenas Nest: rejeitado porque o app tambem tem caminho Supabase direto e tabela names centralizada.

## Decisao 3: Status de meta

**Decision**: Usar status controlado para Goal: `ACTIVE`, `COMPLETED`, `ARCHIVED`.

**Rationale**: A spec exige diferenciar metas ativas, concluidas e removidas/arquivadas. Status evita exclusao fisica inicial, preserva historico e permite esconder metas arquivadas da lista principal.

**Alternatives considered**:

- `isActive` booleano: rejeitado porque nao diferencia concluida de arquivada.
- Exclusao definitiva no primeiro MVP: rejeitado porque reduz rastreabilidade e dificulta desfazer acoes.

## Decisao 4: Valores em centavos

**Decision**: Guardar `targetAmountCents` e `currentAmountCents` como inteiros.

**Rationale**: O app ja usa centavos para valores financeiros (`amountCents`, `limitCents`, `desiredMonthlyProfitCents`). Isso evita erro de ponto flutuante e mantem padrao de arquivos/modelos.

**Alternatives considered**:

- `double`/decimal no mobile: rejeitado por inconsistÃªncia com o dominio financeiro existente.

## Decisao 5: Calculo de progresso

**Decision**: Progresso da meta = `currentAmountCents / targetAmountCents`, com target positivo obrigatorio e valor atual minimo 0.

**Rationale**: A regra esta na spec e deve ficar fora da view. A entidade pode expor `progressRatio`, `progressPercent` e `isReached` para presentation usar sem recalcular.

**Alternatives considered**:

- Calcular direto no widget: rejeitado por violar a constituicao.
- Persistir percentual no banco: rejeitado porque percentual e derivado dos valores e pode ficar inconsistente.

## Decisao 6: Atualizacao da Home

**Decision**: `HomeController` deve carregar Goals reais por use case e alimentar `GoalsSection`; quando nao houver metas, a secao nao mostra mock.

**Rationale**: A Home ja possui secao visual, mas hoje usa lista mockada. A spec exige refletir metas configuradas e evitar dados demonstrativos.

**Alternatives considered**:

- Deixar a Home para fase futura: rejeitado porque a spec inclui explicitamente o resumo da Home.

## Decisao 7: Formulario em bottom sheet

**Decision**: Criar/editar metas por bottom sheet responsivo, seguindo o padrao de contas/cartoes.

**Rationale**: O app ja usa bottom sheets para formularios CRUD em modulos financeiros. Isso reduz mudanca de navegacao, mantem o contexto da lista e reaproveita padrao de UX.

**Alternatives considered**:

- Tela separada para formulario: possivel, mas desnecessaria para o MVP e menos alinhada aos modulos similares.
