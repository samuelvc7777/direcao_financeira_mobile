# Contract - Resolved Google API Key

## Objetivo

Definir como o mobile obtem e distribui a API Google ativa para fluxos de endereco, rota, importacao de print e servico nativo de OCR/semafaro.

## Fonte remota

- Origem: Supabase `public."Company"`, registro `id = 1`.
- Campo: `googleApiKey`.
- Valor ausente, nulo, vazio ou com apenas espacos deve ser tratado como indisponivel.

## Fonte local

- Origem: `AppEnvironment.googleMapsApiKey`.
- Uso: fallback quando a fonte remota nao retorna valor valido.

## Resolucao

1. Tentar carregar configuracao remota.
2. Normalizar `googleApiKey` remoto.
3. Se remoto for valido, retornar remoto.
4. Caso contrario, normalizar e retornar fallback local.
5. Se nenhum valor existir, retornar string vazia sem lancar erro para UI.

## Consumidores obrigatorios

- `AddressAutocompleteService`.
- `RideRouteEstimator`.
- `AccessibilityController.syncSettingsWithNative()`.
- Bindings de `add_ride` e `import_ride_photo`.

## Contrato com nativo

- Campo enviado no payload: `google_maps_api_key`.
- Valor enviado: chave resolvida pelo contrato acima.
