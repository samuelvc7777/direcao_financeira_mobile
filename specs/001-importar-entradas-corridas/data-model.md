# Data Model: Importacao de entradas por corridas

## 1. CorridaImportavel

- Papel: representa uma corrida finalizada elegivel para compor uma importacao de entrada.
- Origem: derivada de `RideEntity` com enriquecimento de status de elegibilidade.

### Campos

| Campo | Tipo | Origem | Regra |
|------|------|--------|-------|
| `rideId` | int | `RideEntity.id` | Obrigatorio, unico por corrida |
| `status` | String | `RideEntity.status` | Deve ser `FINISHED` para elegibilidade |
| `paymentMethod` | String | `RideEntity.paymentMethod` | Obrigatorio para entrar no consolidado |
| `grossValueCents` | int | `RideEntity.grossValueCents` | Deve ser maior que zero |
| `occurredAtLabel` | String | `RideEntity.date` + `RideEntity.time` | Usado para exibicao/conferencia |
| `appName` | String | `RideEntity.appName` | Opcional para resumo visual |
| `isAlreadyImported` | bool | vinculo corrida-importacao | Quando `true`, exclui da lista elegivel |
| `ineligibilityReason` | String? | derivado | Preenchido quando nao puder compor importacao |

### Validacoes

- Corridas com `status` diferente de `FINISHED` nao entram como elegiveis.
- Corridas com `grossValueCents <= 0` nao entram como elegiveis.
- Corridas sem `paymentMethod` valida nao entram no total confirmado.
- Corridas ja importadas nao podem reaparecer como elegiveis.

## 2. GrupoImportacaoPorPagamento

- Papel: consolidado inicial apresentado ao usuario por forma de pagamento.

### Campos

| Campo | Tipo | Regra |
|------|------|-------|
| `paymentMethodCode` | String | Obrigatorio |
| `paymentMethodLabel` | String | Obrigatorio, legivel para UI |
| `totalCents` | int | Soma das corridas elegiveis do grupo |
| `ridesCount` | int | Quantidade de corridas no grupo |
| `rides` | List<CorridaImportavel> | Detalhes expandiveis |

### Relacoes

- 1 grupo contem N `CorridaImportavel`.
- Uma `CorridaImportavel` participa de exatamente 1 grupo no consolidado.

## 3. DistribuicaoContaEntrada

- Papel: representa quanto do total importado sera registrado em uma conta especifica.

### Campos

| Campo | Tipo | Regra |
|------|------|-------|
| `bankAccountId` | int | Deve apontar para conta ativa |
| `bankAccountName` | String | Necessario para exibicao |
| `allocatedCents` | int | Deve ser maior que zero para persistencia |

### Validacoes

- Somente contas ativas podem receber distribuicao.
- Itens com `allocatedCents <= 0` nao geram entrada no registro final.

## 4. SessaoImportacaoEntradas

- Papel: agrega o estado de dominio da importacao antes da confirmacao.

### Campos

| Campo | Tipo | Regra |
|------|------|-------|
| `eligibleRides` | List<CorridaImportavel> | Corridas validas consideradas |
| `ineligibleRides` | List<CorridaImportavel> | Corridas excluidas com motivo |
| `paymentGroups` | List<GrupoImportacaoPorPagamento> | Consolidado inicial |
| `distribution` | List<DistribuicaoContaEntrada> | Valores por conta |
| `importedTotalCents` | int | Soma das corridas elegiveis |
| `distributedTotalCents` | int | Soma dos valores distribuidos |
| `differenceCents` | int | `importedTotalCents - distributedTotalCents` |

### Regras

- A sessao so pode ser confirmada quando `differenceCents == 0`.
- A sessao deve expor quais corridas ficaram fora e por qual motivo.
- A distribuicao pode envolver 1..N contas.

## 5. ComandoRegistroEntradaImportada

- Papel: payload de dominio usado para persistir a confirmacao da importacao.

### Campos

| Campo | Tipo | Regra |
|------|------|-------|
| `categoryId` | int | Obrigatorio |
| `transactionDate` | DateTime | Obrigatorio |
| `description` | String | Pode ser padronizada ou editavel |
| `rides` | List<CorridaImportavel> | Deve refletir apenas corridas elegiveis confirmadas |
| `distribution` | List<DistribuicaoContaEntrada> | Deve fechar exatamente o total |

### Resultado esperado

- Gera N entradas, onde N = quantidade de contas com valor maior que zero.
- Persiste o vinculo entre as corridas da sessao e o registro importado, para bloquear reimportacao futura.

## 6. Transicoes de Estado

```text
Inicial
  -> Carregando corridas
  -> Sem corridas elegiveis
  -> Corridas carregadas
       -> Distribuicao pendente
       -> Distribuicao inconsistente
       -> Pronta para confirmar
            -> Registrando entradas
            -> Sucesso
            -> Erro de persistencia
```
