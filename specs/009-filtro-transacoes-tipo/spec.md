# Feature Specification: Filtro de Tipo de Transacao

**Feature Branch**: `009-filtro-transacoes-tipo`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: User description: "Na tela de transacoes, substituir as opcoes/secoes de abrir transacoes de cartao e recorrentes por filtros no mesmo padrao do filtro Todos, Entrada e Saida. Os novos filtros devem permitir visualizar Cartao, Recorrentes e transacoes normais chamadas Avulsas. Cartao mostra transacoes de cartao, Recorrentes mostra transacoes recorrentes, Avulsas mostra transacoes que nao sao de cartao nem recorrentes. O comportamento deve preservar os filtros atuais de Todos, Entrada e Saida e deixar claro qual filtro esta ativo."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Filtrar transacoes por tipo operacional (Priority: P1)

Como usuario da tela de transacoes, quero trocar entre transacoes de cartao, recorrentes e avulsas usando um filtro visual no mesmo padrao dos filtros ja existentes, para encontrar rapidamente o grupo de transacoes que desejo revisar sem abrir secoes separadas.

**Why this priority**: Esta e a mudanca central da feature: transformar os acessos de cartao e recorrentes em filtros consistentes com a experiencia atual da tela.

**Independent Test**: Abrir a tela de transacoes com dados mistos e selecionar os filtros Cartao, Recorrentes e Avulsas, verificando se a lista exibida muda de acordo com o filtro selecionado e se o estado ativo fica evidente.

**Acceptance Scenarios**:

1. **Given** que existem transacoes de cartao, recorrentes e avulsas no periodo exibido, **When** o usuario seleciona `Cartao`, **Then** a lista mostra somente transacoes de cartao e o filtro `Cartao` aparece como ativo.
2. **Given** que existem transacoes recorrentes no periodo exibido, **When** o usuario seleciona `Recorrentes`, **Then** a lista mostra somente transacoes recorrentes e o filtro `Recorrentes` aparece como ativo.
3. **Given** que existem transacoes que nao sao de cartao nem recorrentes no periodo exibido, **When** o usuario seleciona `Avulsas`, **Then** a lista mostra somente essas transacoes e o filtro `Avulsas` aparece como ativo.

---

### User Story 2 - Preservar filtros financeiros atuais (Priority: P2)

Como usuario, quero continuar usando os filtros `Todos`, `Entrada` e `Saida` junto da nova classificacao por tipo, para nao perder a forma atual de separar receitas e despesas.

**Why this priority**: A nova classificacao nao deve regredir a navegacao financeira existente, porque os filtros atuais ja sao parte do fluxo principal da tela.

**Independent Test**: Alternar entre `Todos`, `Entrada` e `Saida` enquanto um filtro de tipo esta ativo, verificando se a lista respeita os dois criterios selecionados.

**Acceptance Scenarios**:

1. **Given** que o usuario selecionou `Cartao`, **When** ele alterna entre `Entrada` e `Saida`, **Then** a lista continua limitada a transacoes de cartao e aplica tambem o sentido financeiro escolhido.
2. **Given** que o usuario esta em `Todos`, **When** ele remove ou troca o filtro de tipo, **Then** o comportamento de `Todos`, `Entrada` e `Saida` permanece previsivel e coerente com o estado visivel da tela.

---

### User Story 3 - Entender estados vazios por filtro (Priority: P3)

Como usuario, quero receber uma mensagem clara quando um filtro nao tiver transacoes, para entender que nao ha itens naquele recorte em vez de pensar que a tela falhou.

**Why this priority**: Filtros mais especificos aumentam a chance de listas vazias; a tela precisa explicar o recorte atual com clareza.

**Independent Test**: Selecionar cada filtro em um periodo sem transacoes daquele tipo e verificar se a tela mostra um estado vazio contextual, sem esconder os controles de filtro.

**Acceptance Scenarios**:

1. **Given** que nao existem transacoes recorrentes no periodo atual, **When** o usuario seleciona `Recorrentes`, **Then** a tela informa que nao ha transacoes recorrentes nesse recorte e mantem os filtros disponiveis.
2. **Given** que nao existem transacoes avulsas no periodo atual, **When** o usuario seleciona `Avulsas`, **Then** a tela informa que nao ha transacoes avulsas nesse recorte.

---

### Edge Cases

- Quando a tela estiver carregando, os filtros devem manter feedback visual adequado e nao sugerir uma lista final antes do carregamento terminar.
- Quando houver erro ao carregar transacoes, a tela deve preservar a mensagem de erro existente e nao apresentar filtros como se o resultado estivesse completo.
- Quando um periodo nao tiver transacoes para o filtro selecionado, o estado vazio deve mencionar o recorte atual.
- Em telas estreitas ou com rotulos maiores, os filtros devem continuar legiveis, clicaveis e sem vazamento visual.
- Se uma transacao atender a mais de uma classificacao, `Cartao` deve ter prioridade sobre `Recorrentes` apenas quando a transacao for efetivamente vinculada a cartao; `Avulsas` nunca inclui cartao nem recorrencia.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tela de transacoes MUST oferecer filtros de tipo com os rotulos `Cartao`, `Recorrentes` e `Avulsas`.
- **FR-002**: O filtro `Cartao` MUST exibir apenas transacoes vinculadas a cartao.
- **FR-003**: O filtro `Recorrentes` MUST exibir apenas transacoes marcadas como parte de recorrencia.
- **FR-004**: O filtro `Avulsas` MUST exibir apenas transacoes que nao sejam de cartao e nao sejam recorrentes.
- **FR-005**: A experiencia MUST substituir a necessidade de abrir secoes separadas de transacoes de cartao e recorrentes por selecao direta de filtro.
- **FR-006**: Os filtros `Todos`, `Entrada` e `Saida` MUST continuar disponiveis e funcionando apos a inclusao dos filtros de tipo.
- **FR-007**: Quando houver filtros de sentido financeiro e tipo operacional ativos ao mesmo tempo, a lista MUST refletir a intersecao desses filtros.
- **FR-008**: A tela MUST deixar visualmente claro qual filtro de sentido financeiro e qual filtro de tipo estao ativos.
- **FR-009**: A tela MUST apresentar estado vazio contextual quando nao houver transacoes para o recorte selecionado.
- **FR-010**: A mudanca MUST preservar as acoes existentes de uma transacao visivel, como visualizar, editar, alterar status ou excluir, conforme ja disponiveis na tela.
- **FR-011**: A interface MUST permanecer utilizavel e legivel em larguras pequenas, sem controles cortados ou sobrepostos.

### Key Entities *(include if feature involves data)*

- **Transacao**: Registro financeiro exibido na tela de transacoes, com informacoes suficientes para diferenciar sentido financeiro, vinculo com cartao e recorrencia.
- **Filtro de sentido financeiro**: Recorte atual entre `Todos`, `Entrada` e `Saida`.
- **Filtro de tipo operacional**: Recorte atual entre todos os tipos, `Cartao`, `Recorrentes` e `Avulsas`.

### Business Rules *(include when relevant)*

- **BR-001**: Uma transacao `Avulsa` e toda transacao que nao esta vinculada a cartao e nao pertence a uma recorrencia.
- **BR-002**: Uma transacao de `Cartao` e toda transacao vinculada a cartao, independentemente de ser entrada ou saida.
- **BR-003**: Uma transacao `Recorrente` e toda transacao pertencente a uma serie recorrente, independentemente de ser entrada ou saida.
- **BR-004**: Filtros de sentido financeiro e tipo operacional sao cumulativos: selecionar `Saida` e `Cartao` mostra apenas saidas de cartao.
- **BR-005**: Selecionar um filtro nao deve alterar os dados da transacao; deve alterar apenas o recorte exibido.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em teste com transacoes mistas, 100% das transacoes exibidas em `Cartao`, `Recorrentes` e `Avulsas` pertencem ao tipo selecionado.
- **SC-002**: O usuario consegue alternar entre qualquer filtro de tipo em ate 2 toques a partir da tela de transacoes.
- **SC-003**: O estado ativo dos filtros fica identificavel visualmente em 100% dos estados de lista com dados, vazia e carregando.
- **SC-004**: A combinacao entre filtros de sentido financeiro e tipo operacional retorna resultados coerentes em todos os pares testados.
- **SC-005**: A tela permanece legivel e sem sobreposicao visual em larguras pequenas suportadas pelo app.

## Assumptions

- O rótulo escolhido para transacoes normais sera `Avulsas`, por comunicar que sao lancamentos independentes, sem cartao e sem recorrencia.
- A tela ja possui dados suficientes para distinguir transacoes de cartao e recorrentes; se algum dado vier incompleto, a transacao so deve entrar em `Avulsas` quando nao houver indicio de cartao nem recorrencia.
- A opcao geral de tipo deve continuar existindo de forma equivalente a visualizar todos os tipos, mesmo que o rotulo final seja definido no desenho da interface.
- A mudanca e de organizacao e filtragem visual da tela de transacoes; nao altera criacao, edicao, pagamento, recorrencia ou persistencia das transacoes.
