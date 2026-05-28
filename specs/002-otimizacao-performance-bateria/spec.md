# Feature Specification: Otimizacao de performance e bateria

**Feature Branch**: `002-otimizacao-performance-bateria`  
**Created**: 2026-05-17  
**Status**: Planejado  
**Input**: Analise de gargalos em GPS continuo, listas extensas, OCR de imagens e ciclo de vida de servicos em background/realtime.

## User Scenarios & Testing

### User Story 1 - Reduzir consumo de bateria durante turnos (Priority: P1)

Como motorista, quero que o rastreamento de localizacao durante o turno continue funcional sem manter o GPS em coleta agressiva quando estou parado, para preservar bateria durante varias horas de trabalho.

**Independent Test**: Iniciar um turno e verificar que a configuracao de localizacao usa filtro minimo de deslocamento e nao solicita atualizacoes Android a cada 5 segundos com `distanceFilter: 0`.

**Acceptance Scenarios**:

1. **Given** que o usuario iniciou um turno no Android, **When** o app cria o stream de localizacao, **Then** ele usa uma politica com filtro de distancia maior que zero e intervalo menos agressivo ou sem intervalo fixo curto.
2. **Given** que o usuario esta parado, **When** nao ha deslocamento relevante, **Then** o app evita solicitar pontos continuos sem ganho operacional.

### User Story 2 - Melhorar memoria e fluidez em listas crescentes (Priority: P2)

Como usuario com muitas corridas, turnos, categorias, contas ou cartoes, quero que as telas continuem rolando com fluidez, sem construir todos os cards de uma vez.

**Independent Test**: Popular listas com volume alto e verificar que as secoes crescentes usam construcao lazy (`ListView.builder`, `SliverList` ou composicao equivalente), mantendo cabecalhos e estados existentes.

**Acceptance Scenarios**:

1. **Given** que existem muitas corridas carregadas, **When** o usuario abre a aba de corridas, **Then** apenas os itens necessarios para a viewport sao construidos.
2. **Given** que existem muitos turnos carregados, **When** o usuario rola o historico, **Then** a paginacao continua acionando perto do fim sem construir todos os cards em um `Column`.
3. **Given** que categorias, contas ou cartoes crescem, **When** a tela e aberta, **Then** as listas internas de itens devem ser lazy quando o volume justificar.

### User Story 3 - Controlar picos de CPU/RAM no OCR (Priority: P3)

Como usuario importando corrida por print, quero que a leitura da imagem nao trave a tela nem gere picos evitaveis de memoria, principalmente com imagens grandes da galeria.

**Independent Test**: Selecionar imagem grande e verificar que existe uma etapa de pre-processamento ou decisao explicita documentada para reduzir dimensao/compressao antes do `TextRecognizer.processImage`, sem perder legibilidade do OCR.

### User Story 4 - Auditar servicos persistentes (Priority: P4)

Como usuario, quero que servicos de background e realtime sejam encerrados quando nao forem necessarios, para evitar consumo oculto de rede e bateria.

**Independent Test**: Encerrar sessao/turno e verificar que background service e cliente realtime executam `stopSelf`, `disconnect` ou `dispose` nos pontos de ciclo de vida existentes.

## Requirements

### Functional Requirements

- **FR-001**: O sistema MUST alterar a politica de rastreamento em `location_tracking_service.dart` para nao usar `distanceFilter: 0` em producao de turno.
- **FR-002**: O sistema SHOULD adotar um filtro inicial entre 10 e 25 metros para rastreamento de turno, salvo justificativa tecnica registrada em teste ou documentacao.
- **FR-003**: O sistema MUST evitar `intervalDuration` Android curto de 5 segundos para rastreamento padrao quando o deslocamento puder conduzir a coleta.
- **FR-004**: O sistema MUST preservar a precisao alta quando ela for necessaria para calculo operacional do turno.
- **FR-005**: O sistema MUST trocar listas crescentes confirmadas por construcao lazy, preservando estado vazio, erro, loading, refresh, paginacao e callbacks.
- **FR-006**: O sistema MUST priorizar `rides_list_section.dart` e `shift_history_section.dart`, porque elas ja usam paginacao e acumulam historico operacional.
- **FR-007**: O sistema SHOULD revisar `categories_view.dart`, `bank_accounts_content.dart` e `credit_cards_content.dart`, diferenciando listas realmente crescentes de paginas com poucos itens e cabecalhos estaticos.
- **FR-008**: O sistema SHOULD introduzir pre-processamento de imagem antes do OCR se os testes manuais confirmarem imagens grandes causando picos perceptiveis.
- **FR-009**: O sistema MUST manter `TextRecognizer.close()` e nao deve vazar recursos apos leitura de OCR.
- **FR-010**: O sistema MUST auditar o ciclo de vida de `SocketIoRealtimeClient` e do background service antes de alterar comportamento, porque ja existem chamadas de `disconnect`, `dispose` e `stopSelf` no codigo atual.

## Key Entities

- **LocationTrackingPolicy**: Configuracao operacional de localizacao para turno, incluindo precisao, filtro de distancia e intervalo.
- **LazyListMigration**: Migracao de uma lista que cresce com dados do usuario para construcao sob demanda.
- **OcrProcessingPolicy**: Decisao de pre-processamento de imagem antes da leitura por ML Kit.
- **PersistentServiceLifecycle**: Contrato de abertura e encerramento de servicos de background ou realtime.

## Business Rules

- **BR-001**: O app nao deve sacrificar a confiabilidade do turno para economizar bateria sem criterio operacional claro.
- **BR-002**: Otimizacoes de UI nao podem alterar dados exibidos, filtros, paginacao, ordenacao ou acoes dos cards.
- **BR-003**: OCR deve priorizar legibilidade dos dados da corrida; compressao agressiva demais nao e aceitavel.
- **BR-004**: Servicos persistentes devem existir somente enquanto houver sessao, turno ou necessidade explicita de realtime.

## Success Criteria

- **SC-001**: A configuracao padrao de GPS deixa de solicitar localizacao a cada 5 segundos com deslocamento zero.
- **SC-002**: Historico de turnos e lista de corridas deixam de construir todos os cards carregados dentro de `Column`.
- **SC-003**: O fluxo de OCR possui decisao documentada e testavel sobre pre-processamento de imagem.
- **SC-004**: A auditoria de socket/background identifica se ha mudanca necessaria ou registra que o ciclo atual ja fecha recursos corretamente.

## Assumptions

- A prioridade imediata e bateria no rastreamento de turno.
- A implementacao deve evitar mudancas de dominio se o ajuste for apenas configuracao, renderizacao ou ciclo de vida.
- Nao ha evidencia suficiente neste momento para afirmar que o socket esta vazando; o codigo atual ja possui `disconnect` e `dispose`.
