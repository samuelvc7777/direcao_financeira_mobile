# Feature Specification: Bloqueio por assinatura vigente

**Feature Branch**: `010-bloqueio-assinatura`  
**Created**: 2026-05-28  
**Status**: Draft  
**Input**: User description: "Precisamos criar um bloqueio para quando o usuario nao tiver conta com assinatura. Esse bloqueio so deve acontecer se a assinatura tiver vencida ou se nao tiver assinatura. Caso ele cancelou, mas ainda esta no periodo, ele nao deve ser bloqueado. Caso nao tenha assinatura ativa dentro do periodo, ele nao deve conseguir clicar nas opcoes do app, exceto nas navegacoes, no botao de sair e no botao de ver plano. Todos os outros botoes devem abrir um banner premium igual ao da foto."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bloquear acoes sem assinatura vigente (Priority: P1)

Como usuario sem assinatura vigente, quero ser impedido de executar acoes internas do app e receber uma chamada clara para ver os planos, para entender que preciso assinar para liberar os recursos premium.

**Why this priority**: E a regra central de monetizacao e evita que usuarios sem direito vigente usem funcionalidades protegidas sem explicacao.

**Independent Test**: Entrar no app com uma conta sem assinatura ou com assinatura vencida, tocar em botoes de funcionalidades protegidas e verificar que a acao original nao acontece e que o banner premium aparece.

**Acceptance Scenarios**:

1. **Given** um usuario autenticado sem assinatura cadastrada, **When** ele toca em qualquer botao protegido do app, **Then** a acao original nao e executada e um banner premium e exibido.
2. **Given** um usuario autenticado com assinatura vencida, **When** ele toca em qualquer botao protegido do app, **Then** a acao original nao e executada e um banner premium e exibido.
3. **Given** o banner premium aberto para um usuario bloqueado, **When** ele toca em "Ver assinatura" ou acao equivalente de ver plano, **Then** ele e levado para a tela de planos/assinatura.

---

### User Story 2 - Permitir uso durante periodo vigente apos cancelamento (Priority: P1)

Como usuario que cancelou a assinatura, mas ainda esta dentro do periodo pago, quero continuar usando o app normalmente ate o fim desse periodo, para nao perder acesso antes do prazo contratado.

**Why this priority**: Evita bloqueio indevido de usuarios que ainda possuem direito de uso e reduz suporte por cobranca/permissao incorreta.

**Independent Test**: Entrar com uma conta cuja assinatura esta cancelada, mas ainda possui periodo vigente, tocar em acoes protegidas e verificar que o uso segue liberado sem banner de bloqueio.

**Acceptance Scenarios**:

1. **Given** um usuario com assinatura cancelada e periodo vigente, **When** ele toca em uma opcao protegida, **Then** a funcionalidade original abre ou executa normalmente.
2. **Given** um usuario com assinatura cancelada cujo periodo vigente acabou, **When** ele toca em uma opcao protegida, **Then** a funcionalidade original nao executa e o banner premium aparece.

---

### User Story 3 - Manter navegacao e saida acessiveis (Priority: P2)

Como usuario bloqueado por falta de assinatura vigente, quero continuar navegando pelo app, sair da conta e acessar a tela de planos, para conseguir revisar informacoes, assinar ou encerrar minha sessao sem ficar preso.

**Why this priority**: O bloqueio nao deve impedir recuperacao, compra de plano, troca de conta ou deslocamento basico entre areas do app.

**Independent Test**: Entrar com conta sem assinatura vigente e verificar que itens de navegacao, botao de sair e botao de ver plano continuam funcionando.

**Acceptance Scenarios**:

1. **Given** um usuario sem assinatura vigente, **When** ele toca em itens de navegacao principal do app, **Then** a navegacao acontece normalmente.
2. **Given** um usuario sem assinatura vigente, **When** ele toca no botao de sair, **Then** o fluxo de saida funciona normalmente.
3. **Given** um usuario sem assinatura vigente, **When** ele toca no botao de ver plano ou ver assinatura, **Then** a tela de planos/assinatura abre normalmente.

---

### User Story 4 - Preservar operacoes administrativas (Priority: P2)

Como administrador, quero continuar gerenciando usuarios ativos pelo painel admin sem ser afetado pelo bloqueio aplicado ao app mobile, para manter suporte, atendimento e ajustes administrativos funcionando normalmente.

**Why this priority**: O bloqueio deve proteger o uso premium dentro do app mobile, sem quebrar operacoes administrativas necessarias para a gestao de usuarios.

**Independent Test**: Usar o painel admin para consultar ou alterar dados permitidos de um usuario ativo e verificar que a operacao continua funcionando mesmo com a regra de bloqueio existente no app mobile.

**Acceptance Scenarios**:

1. **Given** um administrador usando o painel admin, **When** ele acessa ou gerencia usuarios ativos conforme permissoes atuais, **Then** o painel continua funcionando sem exibir o banner premium do app mobile.
2. **Given** um usuario ativo gerenciado pelo painel admin, **When** o administrador executa uma acao administrativa permitida, **Then** a acao administrativa nao e bloqueada pela regra de clique do app mobile.

---

### User Story 5 - Comunicar o bloqueio com banner premium consistente (Priority: P2)

Como usuario bloqueado, quero ver um banner premium visualmente claro e coerente com a referencia enviada, para entender rapidamente o motivo do bloqueio e a proxima acao.

**Why this priority**: A comunicacao correta reduz confusao e transforma o bloqueio em um caminho claro para assinatura.

**Independent Test**: Simular qualquer botao protegido com usuario bloqueado e verificar que o banner apresenta titulo, explicacao, beneficios e CTA de assinatura de forma legivel.

**Acceptance Scenarios**:

1. **Given** um usuario sem assinatura vigente, **When** ele toca em um botao protegido, **Then** o banner premium aparece com destaque visual amarelo/dourado, titulo de assinatura premium, explicacao do bloqueio, beneficios e CTA para ver assinatura.
2. **Given** o banner premium aberto em telas pequenas, **When** o usuario visualiza o conteudo, **Then** os textos e a acao principal permanecem legiveis, sem sobreposicao ou corte indevido.

### Edge Cases

- Quando o estado da assinatura ainda esta carregando, acoes protegidas nao devem executar ate existir uma decisao confiavel de liberado ou bloqueado.
- Quando a consulta de assinatura falha, o app deve evitar liberar indevidamente recursos protegidos e deve orientar o usuario de forma clara sobre tentar novamente ou verificar o plano.
- Quando a data de fim do periodo vigente chega ao dia atual, a regra deve tratar o acesso de forma consistente ate o limite real do periodo contratado.
- Quando dados de assinatura chegam incompletos, conflitantes ou atrasados, o app deve preferir uma decisao baseada no periodo vigente confirmado.
- Quando o usuario toca repetidamente em botoes protegidos, o app nao deve empilhar banners duplicados nem executar a acao original.
- Quando o usuario esta offline, o bloqueio nao deve depender apenas de um estado local potencialmente antigo se houver sinal de que a assinatura pode estar vencida.
- Operacoes administrativas feitas no painel admin para usuarios ativos devem continuar fora do escopo do bloqueio visual do app mobile.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST determinar se o usuario possui direito de acesso vigente antes de permitir a execucao de acoes protegidas.
- **FR-002**: O sistema MUST bloquear acoes protegidas quando o usuario nao possui assinatura cadastrada.
- **FR-003**: O sistema MUST bloquear acoes protegidas quando a assinatura existe, mas o periodo vigente terminou.
- **FR-004**: O sistema MUST permitir acoes protegidas quando a assinatura foi cancelada, mas o periodo vigente ainda nao terminou.
- **FR-005**: O sistema MUST manter liberados os itens de navegacao, o botao de sair e o botao de ver plano/ver assinatura mesmo para usuarios bloqueados.
- **FR-006**: O sistema MUST impedir que a acao original de um botao protegido seja executada quando o usuario esta bloqueado.
- **FR-007**: O sistema MUST exibir o banner premium sempre que um usuario bloqueado tocar em uma acao protegida.
- **FR-008**: O banner premium MUST conter uma chamada de assinatura, uma explicacao curta de que a conta esta sem plano ativo vigente, beneficios do plano e uma acao principal para ver assinatura/plano.
- **FR-009**: O banner premium MUST seguir a referencia visual enviada: superficie escura com destaque amarelo/dourado, selo premium, texto de alto contraste e CTA principal destacado.
- **FR-010**: O sistema MUST evitar banners duplicados ou sobrepostos quando o usuario toca varias vezes em acoes protegidas.
- **FR-011**: O sistema MUST apresentar estado de carregamento, erro ou indisponibilidade de assinatura sem liberar recursos protegidos por engano.
- **FR-012**: O bloqueio MUST ser aplicado de forma consistente nas principais telas e fluxos acionados por botoes do app.
- **FR-013**: O sistema MUST manter operacoes administrativas do painel admin para usuarios ativos fora do bloqueio de cliques aplicado no app mobile.

### Key Entities *(include if feature involves data)*

- **Usuario**: Pessoa autenticada no app, associada a uma conta e ao estado de assinatura usado para decidir o acesso.
- **Assinatura**: Registro que indica existencia de plano, situacao atual, cancelamento e periodo de acesso vigente.
- **Periodo vigente**: Intervalo de datas em que o usuario ainda tem direito de usar recursos premium, mesmo se o cancelamento ja tiver sido solicitado.
- **Acao protegida**: Botao ou comando do app que executa funcionalidade premium e deve ser interceptado quando nao houver assinatura vigente.
- **Acao permitida**: Navegacao, saida da conta e acesso a ver plano/ver assinatura, que continuam disponiveis mesmo quando o usuario esta bloqueado.
- **Operacao administrativa**: Acao realizada por usuario administrador no painel admin para consultar, manter ou ajustar usuarios ativos conforme permissoes existentes.
- **Banner premium**: Comunicacao visual exibida no bloqueio, com motivo, beneficios e caminho para assinatura.

### Business Rules *(include when relevant)*

- **BR-001**: Usuario sem assinatura cadastrada e considerado sem acesso vigente.
- **BR-002**: Assinatura vencida e considerada sem acesso vigente.
- **BR-003**: Assinatura cancelada ainda libera acesso enquanto o periodo vigente nao terminou.
- **BR-004**: O fim do periodo vigente e a referencia principal para decidir bloqueio em casos de cancelamento.
- **BR-005**: Navegacoes, sair da conta e ver plano/ver assinatura nunca devem ser bloqueados por esta regra.
- **BR-006**: Toda acao protegida bloqueada deve trocar a execucao original por exibicao do banner premium.
- **BR-007**: O bloqueio de assinatura desta feature se aplica ao uso do app mobile pelo usuario final e nao deve impedir operacoes administrativas permitidas no painel admin.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% dos cenarios testados sem assinatura ou com periodo vencido, botoes protegidos nao executam a acao original e exibem o banner premium.
- **SC-002**: Em 100% dos cenarios testados com assinatura cancelada ainda dentro do periodo vigente, botoes protegidos continuam funcionando sem banner de bloqueio.
- **SC-003**: Em 100% dos cenarios testados com usuario bloqueado, navegacao, sair e ver plano/ver assinatura continuam acessiveis.
- **SC-004**: O banner premium aparece em ate 1 segundo apos o toque em uma acao protegida quando o estado de bloqueio ja esta conhecido.
- **SC-005**: O banner premium permanece legivel e sem corte critico nos tamanhos de tela suportados pelo app.
- **SC-006**: Toques repetidos em acoes protegidas nao geram mais de um banner visivel ao mesmo tempo.
- **SC-007**: Em 100% dos cenarios administrativos testados para usuarios ativos, o painel admin continua executando as operacoes permitidas sem acionar o bloqueio visual do app mobile.

## Assumptions

- "Ver plan" citado pelo usuario significa o caminho atual do app para ver plano, ver assinatura ou escolher uma assinatura.
- O bloqueio deve proteger botoes/comandos de funcionalidades, nao impedir o usuario de abrir abas, menus ou telas por navegacao.
- A referencia visual da foto define a direcao do banner, mas os textos podem ser ajustados para o portugues e para o padrao visual do app.
- A decisao de acesso deve considerar assinatura vigente de forma confiavel, evitando depender somente de informacao armazenada anteriormente quando houver risco de ela estar desatualizada.
- A feature seguira as convencoes atuais do app para separacao entre tela, composicao visual e regras de negocio.
- O painel admin possui suas proprias permissoes e fluxos; esta feature nao altera essas permissoes, apenas garante que elas nao sejam afetadas pelo bloqueio do app mobile.
