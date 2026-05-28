# Feature Specification: Tela de metas

**Feature Branch**: `[006-tela-metas]`  
**Created**: 2026-05-25  
**Status**: Draft  
**Input**: User description: "Criar a tela de metas do app mobile, aproveitando o item Configurar Metas que ja existe em Settings e a secao Minhas Metas que ja aparece na Home, substituindo o placeholder por uma experiencia real para listar, criar, editar, acompanhar progresso e concluir metas financeiras/pessoais."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Abrir e acompanhar metas (Priority: P1)

Como pessoa usuaria, eu quero tocar em "Configurar Metas" nas configuracoes e abrir uma tela real de metas, para acompanhar quais metas estao ativas, quanto falta para cada uma e quais ja foram concluidas.

**Why this priority**: hoje o app ja mostra a entrada de metas em Settings e um resumo na Home, mas a configuracao ainda nao entrega uma experiencia real de gestao.

**Independent Test**: abrir Settings, tocar em "Configurar Metas" e verificar que a tela de metas aparece com estados claros para lista carregada, lista vazia, erro e carregamento.

**Acceptance Scenarios**:

1. **Given** que existem metas cadastradas, **When** eu abro "Configurar Metas", **Then** vejo uma lista de metas com nome, valor atual, valor objetivo, percentual de progresso e status.
2. **Given** que ainda nao existem metas cadastradas, **When** eu abro "Configurar Metas", **Then** vejo um estado vazio com uma acao clara para criar a primeira meta.
3. **Given** que a tela demora para carregar, **When** eu aguardo a abertura, **Then** vejo um estado de carregamento estavel ate a lista, o vazio ou o erro aparecer.

---

### User Story 2 - Criar e editar uma meta (Priority: P2)

Como pessoa usuaria, eu quero criar e editar metas financeiras ou pessoais informando nome, objetivo e progresso inicial, para transformar planos de faturamento, reserva ou compromisso em algo acompanhavel dentro do app.

**Why this priority**: acompanhar metas so tem valor se a pessoa conseguir manter metas reais, nao apenas ver dados fixos demonstrativos.

**Independent Test**: criar uma meta a partir da tela, editar seus dados em seguida e confirmar que a lista e o resumo refletem os novos valores.

**Acceptance Scenarios**:

1. **Given** que estou na tela de metas, **When** eu crio uma meta com nome e valor objetivo validos, **Then** a meta aparece na lista como ativa.
2. **Given** que uma meta ativa existe, **When** eu altero seu nome, objetivo ou valor atual, **Then** a meta atualizada aparece com progresso recalculado.
3. **Given** que tento salvar uma meta sem nome ou sem objetivo valido, **When** eu confirmo o formulario, **Then** recebo uma orientacao clara e a meta nao e salva.

---

### User Story 3 - Concluir, pausar ou remover metas (Priority: P3)

Como pessoa usuaria, eu quero encerrar metas que ja nao preciso acompanhar, para manter a tela focada no que ainda importa sem perder clareza sobre metas concluidas.

**Why this priority**: metas precisam de ciclo de vida para evitar uma lista acumulada e confusa ao longo do uso.

**Independent Test**: marcar uma meta como concluida, remover ou arquivar uma meta e verificar que a listagem e os totais mudam de forma previsivel.

**Acceptance Scenarios**:

1. **Given** que uma meta esta ativa, **When** eu marco a meta como concluida, **Then** ela passa a aparecer como concluida e deixa de contar como pendente.
2. **Given** que uma meta nao deve mais ser acompanhada, **When** eu removo ou arquivo essa meta, **Then** ela deixa de aparecer na lista principal de metas ativas.
3. **Given** que existem metas ativas e concluidas, **When** eu consulto a tela, **Then** consigo diferenciar rapidamente o que esta em andamento do que ja foi finalizado.

---

### User Story 4 - Refletir metas no resumo da Home (Priority: P4)

Como pessoa usuaria, eu quero que a secao "Minhas Metas" da Home reflita as metas configuradas, para ter uma visao rapida do progresso sem abrir a tela completa.

**Why this priority**: a Home ja possui uma secao de metas; a nova tela deve transformar esse resumo em informacao real e coerente.

**Independent Test**: alterar metas na tela de metas, voltar para a Home e confirmar que o resumo mostra as metas e totais atualizados.

**Acceptance Scenarios**:

1. **Given** que eu criei ou editei uma meta, **When** volto para a Home, **Then** a secao "Minhas Metas" mostra progresso e totais coerentes com a tela de metas.
2. **Given** que nao existem metas ativas, **When** visualizo a Home, **Then** o resumo nao mostra dados demonstrativos como se fossem metas reais.

---

### Edge Cases

- A tela deve tratar carregamento demorado sem duplicar feedback visual ou deixar a lista piscando.
- A lista vazia deve orientar a criacao da primeira meta sem parecer erro.
- Metas com valor atual maior que o objetivo devem aparecer como 100% ou mais de progresso, sem quebrar barras, textos ou totais.
- Valores monetarios devem ser legiveis e consistentes com o restante do app.
- Textos longos de nome de meta devem continuar legiveis em telas pequenas.
- Falhas ao carregar, salvar, editar ou remover metas devem preservar os dados que ja estavam visiveis quando possivel.
- Alteracoes feitas na tela de metas nao devem deixar o resumo da Home com dados antigos ou demonstrativos.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O item "Configurar Metas" em Settings MUST abrir uma tela real de metas em vez de mostrar uma mensagem de placeholder.
- **FR-002**: A tela de metas MUST exibir metas ativas com nome, valor atual, valor objetivo, percentual de progresso e status.
- **FR-003**: A tela de metas MUST oferecer estado vazio com acao para criar a primeira meta quando nao houver metas cadastradas.
- **FR-004**: A tela de metas MUST permitir criar metas com pelo menos nome e valor objetivo.
- **FR-005**: A tela de metas MUST permitir editar nome, valor objetivo e valor atual de uma meta existente.
- **FR-006**: O sistema MUST validar que uma meta nao seja salva sem nome legivel ou sem objetivo numerico positivo.
- **FR-007**: O sistema MUST calcular e apresentar o progresso da meta a partir do valor atual em relacao ao valor objetivo.
- **FR-008**: O sistema MUST permitir marcar uma meta como concluida.
- **FR-009**: O sistema MUST permitir remover ou arquivar metas que nao devem mais aparecer na lista principal de metas ativas.
- **FR-010**: A tela MUST diferenciar metas ativas, concluidas e removidas/arquivadas de forma clara para a pessoa usuaria.
- **FR-011**: A secao "Minhas Metas" da Home MUST refletir as metas reais configuradas, evitando dados demonstrativos quando nao houver metas reais.
- **FR-012**: A experiencia MUST apresentar feedback claro para carregamento, salvamento, erro, sucesso e lista vazia.
- **FR-013**: A tela MUST permanecer legivel e operavel em larguras menores, sem cortes incoerentes de textos, botoes ou valores.

### Key Entities

- **Meta**: objetivo financeiro ou pessoal acompanhado pela pessoa usuaria, com nome, valor objetivo, valor atual, progresso e status.
- **Status da Meta**: estado que indica se a meta esta ativa, concluida ou removida/arquivada.
- **Resumo de Metas**: consolidado exibido na Home com quantidade de metas, concluidas e progresso geral.

### Business Rules

- **BR-001**: Uma meta so pode ser salva quando tiver nome legivel e valor objetivo maior que zero.
- **BR-002**: O progresso de uma meta corresponde ao valor atual dividido pelo valor objetivo.
- **BR-003**: Metas com progresso igual ou maior que 100% podem ser apresentadas como concluidas ou prontas para conclusao.
- **BR-004**: Metas removidas ou arquivadas nao devem contar na lista principal de metas ativas.
- **BR-005**: O progresso geral deve considerar apenas metas que ainda fazem sentido para o acompanhamento principal da pessoa usuaria.
- **BR-006**: Quando nao houver metas reais, a Home nao deve exibir uma meta demonstrativa como se fosse informacao da pessoa usuaria.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% dos acessos pelo item "Configurar Metas", a pessoa usuaria chega a uma tela de metas ou a um erro claro, nunca ao placeholder atual.
- **SC-002**: Uma pessoa usuaria consegue criar uma meta valida em ate 1 minuto a partir da tela de metas.
- **SC-003**: Uma pessoa usuaria consegue editar ou concluir uma meta existente em ate 30 segundos.
- **SC-004**: Em 100% das metas exibidas, o percentual apresentado corresponde ao valor atual dividido pelo valor objetivo.
- **SC-005**: A Home deixa de exibir dados demonstrativos de metas quando nao houver metas reais configuradas.
- **SC-006**: A tela cobre estados de carregamento, vazio, erro e sucesso de forma verificavel em testes de comportamento.

## Assumptions

- O item "Configurar Metas" ja existente em Settings e a secao "Minhas Metas" ja existente na Home sao os pontos de entrada e resumo desta feature.
- O escopo inicial cobre metas com valores monetarios ou progresso numerico simples; categorias avancadas, recorrencia automatica e metas compartilhadas ficam fora desta especificacao.
- Remover ou arquivar uma meta significa tira-la da lista principal de acompanhamento; a decisao final entre exclusao definitiva e arquivamento historico deve ser detalhada no plano tecnico sem alterar o valor principal da feature.
- A tela deve preservar os padroes visuais e de navegacao ja usados pelo app.
