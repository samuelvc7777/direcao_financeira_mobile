# Data Model - Consumir API Google do Admin no Mobile

## Entidade: GoogleApiConfig

- `googleApiKey`: valor remoto recebido da configuracao global.
- `updatedAt`: data de atualizacao remota, quando disponivel.

## Entidade: ResolvedGoogleApiKey

- `value`: chave final usada pelos servicos.
- `source`: origem do valor (`remote` ou `fallback`).
- `isAvailable`: indica se existe valor utilizavel apos resolucao.

## Regras de Validacao

- Valor remoto deve ser normalizado com `trim`.
- Valor remoto nulo, vazio ou apenas com espacos e considerado ausente.
- Valor remoto valido tem prioridade sobre fallback local.
- Fallback local tambem deve ser normalizado antes do uso.

## Relacionamentos

- `ResolvedGoogleApiKey` depende de `GoogleApiConfig` remoto e de `AppEnvironment.googleMapsApiKey`.

## Transicoes de Estado

1. Sem remoto carregado -> usar fallback local.
2. Remoto carregado valido -> trocar origem para remoto.
3. Remoto falha/ausente -> manter fallback local sem erro visivel.
4. Nova sincronizacao remota valida -> atualizar chave resolvida e reenviar ao nativo.
