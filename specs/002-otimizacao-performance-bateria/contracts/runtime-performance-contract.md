# Runtime Performance Contract

## Location Tracking

- O stream de localizacao de turno deve usar alta precisao, mas com filtro de deslocamento maior que zero.
- Android nao deve usar intervalo fixo curto de 5 segundos combinado com deslocamento zero.
- A alteracao deve preservar mensagens de permissao e fluxo de inicio/fim de turno existentes.

## Lazy Lists

- `RidesListSection` deve manter filtros, contador, date range picker, empty/error state, acoes de card e footer de paginacao.
- `ShiftHistorySection` deve manter painel de turno ativo/inicio, cabecalho, contador, empty/error state, delete de turno e footer de paginacao.
- A migracao deve evitar `Column(children: [for (...)])` para colecoes crescentes.

## OCR

- O fluxo deve manter `isReadingImage` correto durante todo o processamento.
- Em caso de falha, deve manter o aviso atual ao usuario.
- Qualquer compressao/redimensionamento deve ser reversivel por fallback para a imagem original se o OCR perder dados.

## Realtime e Background

- O cliente socket deve continuar expondo `connect`, `disconnect`, `on`, `off` e `dispose`.
- O background service deve continuar encerrando com `stopSelf` nos fluxos ja previstos.
- Mudancas nessa area exigem evidencia de recurso aberto indevidamente.
