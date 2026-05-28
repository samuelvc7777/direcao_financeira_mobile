# Research: Otimizacao de performance e bateria

## Decision: Ajustar politica de GPS por deslocamento minimo

**Rationale**: O estado real do codigo em `lib/app/core/location/location_tracking_service.dart` usa `LocationAccuracy.high`, `distanceFilter: 0` e, no Android, `intervalDuration: const Duration(seconds: 5)`. Isso confirma o gargalo de bateria apontado. Para turno de motorista, manter alta precisao faz sentido, mas solicitar ponto com deslocamento zero e intervalo curto cria custo alto quando o aparelho esta parado.

**Alternatives considered**:

- Manter `distanceFilter: 0`: rejeitado por consumo alto sem beneficio quando parado.
- Reduzir `accuracy`: rejeitado como primeira acao porque pode afetar calculos de rota/turno.
- Usar `distanceFilter` entre 10 e 25 metros: escolhido como primeira mudanca por reduzir chamadas mantendo utilidade operacional.

## Decision: Migrar primeiro listas operacionais paginadas

**Rationale**: `rides_list_section.dart` e `shift_history_section.dart` usam `ListView` externo, mas constroem os cards de dados em `Column` com `for`. Mesmo com paginacao, todos os itens ja carregados sao widgets vivos no mesmo build. Elas devem migrar para `CustomScrollView` com `SliverToBoxAdapter` nos blocos fixos e `SliverList.builder` nos itens, ou para estrutura equivalente com `ListView.builder`.

**Alternatives considered**:

- Trocar tudo por `ListView.builder` simples: pode dificultar cabecalhos complexos e footers.
- `CustomScrollView` + `SliverList`: escolhido para preservar cabecalhos, filtros, paineis, empty states e footer de paginacao.

## Decision: Tratar categorias/contas/cartoes como segunda onda

**Rationale**: `categories_view.dart`, `bank_accounts_content.dart` e `credit_cards_content.dart` usam `ListView(children: [...])`, mas parte do conteudo e uma pagina com secoes e cabecalhos fixos. A migracao deve focar nas secoes internas que renderizam listas de entidades, nao necessariamente substituir todo o scroll por builder sem ganho real.

**Alternatives considered**:

- Refatorar todas as telas imediatamente: rejeitado por risco visual maior e ganho incerto.
- Auditar volume real e migrar secoes internas: escolhido.

## Decision: OCR exige pre-processamento validado

**Rationale**: `ImportRidePhotoController.readSelectedImage()` chama `TextRecognizer.processImage(InputImage.fromFilePath(imagePath))` direto e depois faz parse local. O recognizer e fechado corretamente no `finally`. A melhoria mais provavel e reduzir dimensao/compressao antes do OCR, mas precisa preservar nitidez. A dependencia `flutter_image_compress` nao existe no `pubspec.yaml`, entao adicionar pacote deve ser decisao explicita.

**Alternatives considered**:

- Adicionar compressao imediatamente: pendente de validacao para nao quebrar OCR.
- Usar `compute` para todo parse: nao priorizado porque o gargalo confirmado e `processImage`; parse deve ser medido antes.

## Decision: Socket/background devem ser auditados antes de alterar

**Rationale**: O projeto usa `flutter_background_service` e `socket_io_client`, mas o estado real mostra `service.stopSelf()` em pontos do background service, `SocketIoRealtimeClient.disconnect()`, `dispose()` e `SessionCoordinator` chamando `realtimeClient.disconnect()`. Nao ha base suficiente para afirmar vazamento. A acao correta e criar checklist de ciclo de vida e testes manuais.

**Alternatives considered**:

- Remover realtime/background: rejeitado porque pode quebrar funcionalidades existentes.
- Auditar pontos de entrada/saida antes de mudar: escolhido.
