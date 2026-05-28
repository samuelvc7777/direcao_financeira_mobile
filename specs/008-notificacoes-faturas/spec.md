# Feature Specification: Notificacoes de Faturas

**Feature Branch**: `008-notificacoes-faturas`  
**Created**: 2026-05-26  
**Status**: Draft  
**Input**: User description: "quero ter agora notificacoes pra faturas vencidas, e quando a fatura fechar, a notificacao vai vir todos os dias de fechamento e vencimento cadastrado as 10h da manha"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Avisar faturas vencidas diariamente (Priority: P1)

Como usuario que acompanha cartoes no app, quero receber uma notificacao todos os dias as 10h quando existir fatura vencida ainda nao paga, para nao esquecer uma pendencia financeira importante.

**Why this priority**: Fatura vencida tem impacto financeiro imediato. O maior valor da feature e reduzir esquecimento, atraso e perda de controle sobre compromissos ja vencidos.

**Independent Test**: Cadastrar um cartao com fatura vencida e valor pendente, simular a verificacao diaria das 10h e confirmar que a notificacao de atraso e apresentada com cartao, valor e acao clara para conferir ou pagar a fatura.

**Acceptance Scenarios**:

1. **Given** existe uma fatura vencida com valor pendente, **When** chega 10h em um novo dia, **Then** o usuario recebe uma notificacao informando que a fatura esta vencida.
2. **Given** uma fatura vencida foi paga ou ficou sem valor pendente, **When** chega 10h no dia seguinte, **Then** o usuario nao recebe nova notificacao dessa fatura.
3. **Given** existem varias faturas vencidas em cartoes diferentes, **When** chega 10h, **Then** o usuario recebe informacao suficiente para identificar quais cartoes exigem atencao.

---

### User Story 2 - Avisar fechamento da fatura (Priority: P2)

Como usuario que usa cartao de credito, quero receber uma notificacao as 10h no dia de fechamento cadastrado do cartao, para saber que a fatura fechou e que os gastos daquele ciclo devem ser conferidos.

**Why this priority**: O fechamento e o momento em que a fatura deixa de ser apenas acompanhamento e passa a exigir revisao antes do pagamento.

**Independent Test**: Cadastrar um cartao com dia de fechamento igual ao dia da verificacao, manter valor de fatura fechada ou aberta relevante e confirmar que a notificacao de fechamento aparece as 10h.

**Acceptance Scenarios**:

1. **Given** um cartao ativo tem dia de fechamento cadastrado para hoje, **When** chega 10h, **Then** o usuario recebe uma notificacao informando que a fatura daquele cartao fechou.
2. **Given** o usuario toca na notificacao de fechamento, **When** o app abre, **Then** ele encontra um caminho claro para revisar a fatura do cartao citado.
3. **Given** um cartao esta inativo, **When** chega o dia de fechamento cadastrado, **Then** nenhuma notificacao de fechamento e enviada para esse cartao.

---

### User Story 3 - Avisar vencimento da fatura (Priority: P3)

Como usuario, quero receber uma notificacao as 10h no dia de vencimento cadastrado do cartao, para pagar a fatura no prazo quando ainda houver valor pendente.

**Why this priority**: O vencimento e o ultimo aviso antes da fatura virar atraso. Ele complementa o alerta diario de vencidas sem substituir a rotina de cobranca apos vencimento.

**Independent Test**: Cadastrar um cartao com dia de vencimento igual ao dia da verificacao, manter valor pagavel pendente e confirmar que a notificacao de vencimento aparece as 10h.

**Acceptance Scenarios**:

1. **Given** um cartao ativo tem fatura com valor pendente e vencimento hoje, **When** chega 10h, **Then** o usuario recebe uma notificacao informando que a fatura vence hoje.
2. **Given** a fatura do cartao ja foi paga antes das 10h, **When** chega 10h no dia de vencimento, **Then** o usuario nao recebe notificacao de vencimento para essa fatura.
3. **Given** o dia de fechamento e o dia de vencimento caem na mesma data para um cartao, **When** chega 10h, **Then** o usuario recebe comunicacao sem duplicidade confusa para o mesmo cartao e ciclo.

---

### Edge Cases

- O usuario negou permissao de notificacao do sistema: o app deve deixar claro, em area apropriada, que os avisos dependem da permissao ativa.
- O aparelho estava desligado, sem bateria ou sem permissao no horario das 10h: a pendencia ainda deve ser reconhecida na proxima verificacao possivel sem criar alertas duplicados para o mesmo dia.
- Um cartao foi desativado: nao deve gerar novas notificacoes de fechamento, vencimento ou atraso.
- Um mes nao possui o dia cadastrado para fechamento ou vencimento: o evento deve considerar o ultimo dia valido daquele mes.
- Uma fatura foi paga parcialmente: os avisos continuam enquanto houver valor pendente.
- Existem muitas faturas no mesmo horario: o usuario deve conseguir identificar as pendencias sem receber mensagens contraditorias.
- Dados de fatura chegam incompletos ou atrasados: a notificacao deve priorizar informacoes confiaveis e evitar afirmar valores ou estados nao confirmados.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST identificar cartoes ativos com faturas vencidas e valor pendente.
- **FR-002**: O sistema MUST enviar notificacao diaria as 10h para faturas vencidas enquanto houver valor pendente.
- **FR-003**: O sistema MUST enviar notificacao as 10h no dia de fechamento cadastrado do cartao quando existir fatura relevante para revisao.
- **FR-004**: O sistema MUST enviar notificacao as 10h no dia de vencimento cadastrado do cartao quando existir fatura com valor pendente.
- **FR-005**: O sistema MUST evitar notificacoes duplicadas para o mesmo cartao, ciclo de fatura, tipo de evento e dia.
- **FR-006**: O sistema MUST parar de notificar uma fatura quando ela for paga integralmente ou nao possuir valor pendente.
- **FR-007**: O sistema MUST ignorar cartoes inativos para todos os avisos desta feature.
- **FR-008**: O sistema MUST apresentar texto de notificacao que permita ao usuario reconhecer o cartao, o estado da fatura e a acao esperada.
- **FR-009**: O sistema MUST oferecer um caminho claro, a partir da notificacao ou do app, para o usuario revisar a fatura relacionada.
- **FR-010**: O sistema MUST lidar com ausencia de permissao de notificacao sem bloquear o restante do uso do app.
- **FR-011**: O sistema MUST respeitar o horario local do usuario para executar os avisos as 10h.
- **FR-012**: O sistema MUST preservar as regras de negocio de fatura fora da camada visual.

### Key Entities

- **Cartao de credito**: Cartao cadastrado pelo usuario com nome, status, dia de fechamento, dia de vencimento e valores de fatura.
- **Fatura**: Ciclo financeiro de um cartao, com estado aberto, fechado, vencendo hoje, vencido, pago parcialmente ou pago integralmente.
- **Aviso de fatura**: Comunicacao enviada ao usuario para fechamento, vencimento ou atraso de uma fatura especifica.
- **Registro de aviso enviado**: Historico minimo necessario para evitar notificacoes repetidas no mesmo dia para o mesmo cartao, ciclo e tipo de evento.

### Business Rules

- **BR-001**: Fatura vencida e aquela cujo vencimento ja passou e ainda possui valor pendente.
- **BR-002**: Fatura paga integralmente nao deve gerar aviso de vencimento nem aviso de atraso.
- **BR-003**: Aviso de fechamento deve ocorrer no dia de fechamento cadastrado do cartao, as 10h.
- **BR-004**: Aviso de vencimento deve ocorrer no dia de vencimento cadastrado do cartao, as 10h.
- **BR-005**: Aviso de atraso deve ocorrer diariamente as 10h apos o vencimento enquanto a fatura continuar pendente.
- **BR-006**: Se fechamento ou vencimento cadastrado nao existir no mes atual, o ultimo dia valido do mes deve ser usado.
- **BR-007**: Quando mais de um aviso se aplicar ao mesmo cartao e fatura no mesmo dia, a comunicacao deve ser consolidada ou priorizada para evitar duplicidade confusa.
- **BR-008**: Cartoes inativos nao participam da rotina de avisos.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das faturas vencidas com valor pendente geram aviso diario as 10h em condicoes normais de permissao e aparelho ativo.
- **SC-002**: 100% dos cartoes ativos com fatura relevante geram aviso no dia de fechamento cadastrado as 10h.
- **SC-003**: 100% das faturas com vencimento no dia e valor pendente geram aviso as 10h.
- **SC-004**: Nenhuma fatura paga integralmente gera novos avisos de vencimento ou atraso.
- **SC-005**: O mesmo cartao, ciclo de fatura, tipo de aviso e dia nao gera mais de uma notificacao.
- **SC-006**: O usuario consegue identificar cartao e motivo do aviso em ate 5 segundos lendo a notificacao.
- **SC-007**: A feature pode ser verificada com testes de regra de negocio para fechamento, vencimento, atraso, pagamento e deduplicacao.

## Assumptions

- "Faturas" nesta feature se refere as faturas de cartao de credito ja acompanhadas pelo app.
- O horario fixo solicitado e 10h da manha no horario local do aparelho do usuario.
- Avisos de fatura vencida continuam diariamente ate pagamento integral ou ausencia de valor pendente.
- Avisos de fechamento e vencimento usam os dias ja cadastrados no cartao.
- A feature nao cria notificacoes promocionais, marketing, mensagens remotas ou disparos para usuarios sem relacao com suas proprias faturas.
- A entrega sera baseada em avisos locais do proprio app/aparelho, sem dependencia de Firebase ou push remoto para esta feature.
- A entrega desta feature sera restrita ao Android.
