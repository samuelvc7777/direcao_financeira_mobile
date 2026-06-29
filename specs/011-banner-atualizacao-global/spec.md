# Feature Specification: Banner global de atualizacao

**Feature Branch**: `011-banner-atualizacao-global`
**Created**: 2026-05-28
**Status**: Draft
**Input**: User description: "quero que nosso app tenha controle de versao, se sair uma nova versao, ao abrir o app deve aparecer um banner sobre tudo, pra que o usuario clique em atualizar ou cancelar"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Avisar sobre nova versao ao abrir o app (Priority: P1)

Como usuario do Direcao Financeira, quero ser avisado logo ao abrir o app quando existir uma nova versao disponivel, para atualizar sem depender de encontrar um aviso em uma tela especifica.

**Why this priority**: Esse e o fluxo principal da feature. O valor do controle de versao depende de o aviso aparecer cedo e em qualquer ponto inicial do app, reduzindo o uso de versoes antigas.

**Independent Test**: Simular uma versao nova disponivel, abrir o app em qualquer rota inicial suportada e confirmar que o aviso aparece acima do conteudo da tela sem impedir a visualizacao do app.

**Acceptance Scenarios**:

1. **Given** que existe uma nova versao disponivel, **When** o usuario abre o app, **Then** o app exibe um banner global de atualizacao acima da tela atual.
2. **Given** que existe uma nova versao disponivel, **When** o usuario esta em uma tela diferente da Home, **Then** o mesmo banner global continua visivel acima da tela atual.
3. **Given** que nenhuma nova versao esta disponivel, **When** o usuario abre o app, **Then** nenhum aviso de atualizacao e exibido.

---

### User Story 2 - Atualizar pela acao principal do banner (Priority: P2)

Como usuario avisado sobre uma nova versao, quero tocar em Atualizar para ir ao local correto de atualizacao do app.

**Why this priority**: O banner so gera valor completo se a acao principal levar o usuario diretamente para atualizar o aplicativo.

**Independent Test**: Simular o banner visivel, tocar em Atualizar e confirmar que o usuario e direcionado para a pagina oficial de atualizacao do app.

**Acceptance Scenarios**:

1. **Given** que o banner global esta visivel, **When** o usuario toca em `Atualizar`, **Then** o app tenta abrir a pagina oficial de atualizacao.
2. **Given** que nao e possivel abrir a pagina de atualizacao, **When** o usuario toca em `Atualizar`, **Then** o app informa que nao foi possivel abrir a loja naquele momento sem travar a navegacao.

---

### User Story 3 - Cancelar o aviso na sessao atual (Priority: P3)

Como usuario, quero cancelar o aviso de atualizacao para continuar usando o app naquele momento sem ser interrompido novamente na mesma sessao.

**Why this priority**: A feature deve incentivar a atualizacao sem bloquear o uso do app no MVP.

**Independent Test**: Simular o banner visivel, tocar em Cancelar, navegar entre telas e confirmar que o banner nao reaparece ate a proxima abertura do app.

**Acceptance Scenarios**:

1. **Given** que o banner global esta visivel, **When** o usuario toca em `Cancelar`, **Then** o banner desaparece.
2. **Given** que o usuario cancelou o banner, **When** navega para outras telas na mesma sessao, **Then** o banner nao reaparece.
3. **Given** que o app e aberto em uma nova sessao e ainda existe nova versao disponivel, **When** a verificacao termina, **Then** o banner pode aparecer novamente.

---

### Edge Cases

- A verificacao de versao demora mais que o esperado: o app continua carregando e navegando normalmente sem mostrar estado de espera intrusivo.
- A verificacao de versao falha: nenhum banner e exibido e o usuario continua usando o app normalmente.
- O app esta em uma plataforma sem suporte para atualizacao pela loja oficial do MVP: nenhum banner e exibido.
- A tela atual tem conteudo importante: o overlay deve cobrir a tela de forma intencional, mantendo o aviso em destaque sem quebrar a renderizacao da rota por baixo.
- O usuario esta em tela pequena: o card deve ficar compacto, centralizado, rolavel quando necessario e manter titulo, mensagem e acoes legiveis sem cortar textos essenciais.
- Ja existe outro aviso de atualizacao na tela atual: o usuario nao deve ver dois avisos de atualizacao ao mesmo tempo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app MUST verificar, ao abrir, se existe uma nova versao disponivel para o usuario.
- **FR-002**: O app MUST exibir um banner global quando houver nova versao disponivel.
- **FR-003**: O banner global MUST aparecer acima da tela atual, independentemente de o usuario estar na Home, Login, Settings, Subscription ou outra rota suportada.
- **FR-004**: O banner MUST conter titulo claro, mensagem curta, acao `Atualizar` e acao `Cancelar`.
- **FR-005**: Ao tocar em `Atualizar`, o app MUST tentar direcionar o usuario para a pagina oficial de atualizacao do aplicativo.
- **FR-006**: Se nao for possivel abrir a pagina de atualizacao, o app MUST mostrar uma mensagem amigavel informando que a loja nao pode ser aberta naquele momento.
- **FR-007**: Ao tocar em `Cancelar`, o app MUST esconder o banner durante a sessao atual.
- **FR-008**: Depois de cancelado, o banner MUST permanecer oculto ao navegar entre telas na mesma sessao.
- **FR-009**: Se nao houver nova versao disponivel, o app MUST manter a experiencia atual sem exibir aviso.
- **FR-010**: Falhas na verificacao de versao MUST NOT bloquear abertura do app, login, navegacao ou uso das telas.
- **FR-011**: O app MUST evitar exibicao duplicada de avisos de atualizacao.
- **FR-012**: O banner MUST funcionar em tema claro e escuro com contraste suficiente.
- **FR-013**: O banner MUST ser legivel e acionavel em telas pequenas suportadas pelo app.
- **FR-014**: O comportamento de versao MUST ser verificavel sem depender de uma atualizacao real publicada.
- **FR-015**: O overlay MUST escurecer e desfocar visualmente a tela atual para deixar claro que o aviso global esta em primeiro plano.
- **FR-016**: O aviso MUST usar card central compacto com largura maxima definida, espacamento seguro e rolagem interna/externa quando a altura da tela for limitada.
- **FR-017**: O card MUST seguir a direcao visual aprovada: visual escuro premium, icone de atualizacao, selo superior de origem/versao, bloco de destaque para a mensagem, botao principal verde e botao secundario discreto.
- **FR-018**: O texto principal do card MUST comunicar que existe uma nova versao disponivel e que a atualizacao traz melhorias, correcoes e estabilidade.
- **FR-019**: O design MUST prever o estado futuro de atualizacao obrigatoria sem ativar bloqueio obrigatorio no MVP.

### Visual Direction

- **VD-001**: O aviso deve ser um overlay central sobre toda a tela, com fundo escurecido e desfocado.
- **VD-002**: O card deve ter aparencia premium e compacta, com cantos arredondados, sombra forte, borda sutil e gradiente escuro.
- **VD-003**: O topo do card deve mostrar um icone de atualizacao e um selo pequeno. Quando nao houver texto especifico para o selo, o padrao visual deve indicar `PLAY STORE`.
- **VD-004**: O miolo do card deve destacar a mensagem com um bloco interno, titulo forte e texto curto.
- **VD-005**: A acao principal deve ser `Atualizar agora`; a acao secundaria deve permitir continuar sem atualizar no MVP.
- **VD-006**: O card deve ser responsivo para celulares pequenos, evitando overflow horizontal, corte de texto e botoes apertados.
- **VD-007**: O overlay deve respeitar area segura da tela e manter o conteudo acionavel mesmo com teclado, barras do sistema ou telas de menor altura.

### Key Entities

- **Estado do aviso de atualizacao**: Representa se o app esta verificando versao, se existe atualizacao disponivel e se o usuario cancelou o aviso na sessao atual.
- **Resultado de verificacao de versao**: Representa se uma nova versao esta disponivel, se nao existe atualizacao ou se a verificacao falhou.

### Business Rules

- **BR-001**: O aviso de atualizacao e informativo no MVP e nao pode impedir o usuario de continuar usando o app.
- **BR-002**: O cancelamento do aviso vale somente para a sessao atual.
- **BR-003**: O aviso deve aparecer no maximo uma vez por sessao apos cancelamento pelo usuario.
- **BR-004**: A ausencia de suporte da plataforma ou falha externa de verificacao deve resultar em nenhum banner visivel.
- **BR-005**: O app deve ter apenas uma experiencia ativa de aviso de atualizacao para evitar mensagens duplicadas.
- **BR-006**: O estado de atualizacao obrigatoria nao faz parte do MVP; qualquer suporte visual a esse estado deve permanecer inativo ate existir regra de negocio especifica.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% dos testes com nova versao simulada, o usuario ve o banner global ao abrir o app apos a verificacao terminar.
- **SC-002**: Em 100% dos testes com nova versao simulada, o banner aparece sobre pelo menos tres rotas diferentes, incluindo uma rota que nao seja a Home.
- **SC-003**: Em 100% dos testes com o banner visivel, tocar em `Cancelar` remove o aviso e ele nao reaparece durante navegacao na mesma sessao.
- **SC-004**: Em 100% dos testes com nenhuma atualizacao disponivel, nenhum banner de atualizacao e exibido.
- **SC-005**: Em 100% dos testes com falha na verificacao, o app continua navegavel e nao mostra erro tecnico para o usuario.
- **SC-006**: Em 100% dos testes com falha ao abrir a pagina de atualizacao, o usuario recebe uma mensagem compreensivel e permanece no app.
- **SC-007**: Em telas pequenas suportadas, titulo, mensagem e botoes do banner permanecem legiveis e acionaveis sem sobreposicao incoerente.
- **SC-008**: Em 100% dos testes visuais em tema claro e escuro, o overlay mantem contraste suficiente entre fundo, card, textos e acoes.
- **SC-009**: Em 100% dos testes em telas de baixa altura, o usuario consegue acessar a acao principal e a acao secundaria sem overflow bloqueante.

## Assumptions

- A verificacao de nova versao usa a fonte de disponibilidade ja aceita pelo app para Android.
- O MVP nao tera atualizacao obrigatoria; o usuario sempre podera cancelar.
- O MVP nao tera configuracao remota de versao minima, changelog remoto ou regras diferentes por perfil de usuario.
- O aviso deve ser exibido para usuarios logados e nao logados quando a plataforma suportar a verificacao.
- O cancelamento nao sera persistido entre aberturas do app nesta primeira versao.
- O design de referencia enviado pelo usuario e a base visual esperada, ajustado apenas para responsividade, compactacao e padroes arquiteturais do app.
