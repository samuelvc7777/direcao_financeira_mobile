# Data Model: Otimizacao de performance e bateria

## LocationTrackingPolicy

Representa a politica operacional de coleta de localizacao durante turno.

**Fields**:

- `accuracy`: precisao usada pelo geolocator.
- `distanceFilterMeters`: deslocamento minimo antes de novo ponto.
- `androidIntervalDuration`: intervalo Android quando realmente necessario.
- `platform`: Android ou fallback generico.

**Validation Rules**:

- `distanceFilterMeters` MUST ser maior que zero no rastreamento padrao de turno.
- `accuracy` SHOULD permanecer `high` enquanto a regra operacional exigir rastreio preciso.
- `androidIntervalDuration` MUST NOT permanecer em 5 segundos com `distanceFilterMeters` zero.

## LazyListMigration

Representa uma lista de UI que deve construir itens sob demanda.

**Fields**:

- `filePath`: arquivo afetado.
- `dataSource`: colecao renderizada.
- `fixedHeaderCount`: blocos estaticos antes dos itens.
- `itemBuilder`: builder por entidade.
- `paginationFooter`: footer de carregamento/contador, quando existir.

**Validation Rules**:

- A migracao MUST preservar `PageStorageKey`, scroll physics, padding efetivo e callbacks.
- A migracao MUST manter estados empty/error/loading.
- Para listas paginadas, o gatilho de `loadMore` MUST continuar funcionando perto do fim.

## OcrProcessingPolicy

Representa decisao de tratamento da imagem antes do ML Kit.

**Fields**:

- `sourcePath`: caminho original selecionado pelo usuario.
- `processedPath`: caminho temporario quando houver compressao/redimensionamento.
- `maxDimension`: dimensao maxima alvo, quando definida.
- `quality`: qualidade de compressao, quando definida.
- `preserveOriginalFallback`: indica se o app tenta OCR original em caso de falha.

**Validation Rules**:

- Compressao nao pode tornar textos de valores, origem/destino ou horario ilegíveis.
- Arquivos temporarios devem ter ciclo de vida controlado.
- `TextRecognizer.close()` MUST continuar no `finally`.

## PersistentServiceLifecycle

Representa contrato de abertura e encerramento de recursos persistentes.

**Fields**:

- `resource`: background service, socket ou stream realtime.
- `startTrigger`: evento que abre o recurso.
- `stopTrigger`: evento que encerra o recurso.
- `cleanupMethod`: `stopSelf`, `disconnect`, `dispose` ou equivalente.

**Validation Rules**:

- Todo recurso persistente MUST ter stop/cleanup documentado.
- Encerramento de sessao e fim de turno SHOULD encerrar recursos nao necessarios.
