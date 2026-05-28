# Goals API Contract

Base: endpoints protegidos por JWT no controller financeiro.

## Listar metas

```http
GET /finance/goals
```

### Response 200

```json
[
  {
    "id": 1,
    "userId": 7,
    "name": "Reserva do carro",
    "description": "Manutencao preventiva",
    "targetAmountCents": 500000,
    "currentAmountCents": 125000,
    "status": "ACTIVE",
    "targetDate": "2026-12-31T00:00:00.000Z",
    "completedAt": null,
    "createdAt": "2026-05-25T12:00:00.000Z",
    "updatedAt": "2026-05-25T12:00:00.000Z"
  }
]
```

## Criar meta

```http
POST /finance/goals
Content-Type: application/json
```

### Request

```json
{
  "name": "Reserva do carro",
  "description": "Manutencao preventiva",
  "targetAmountCents": 500000,
  "currentAmountCents": 125000,
  "targetDate": "2026-12-31T00:00:00.000Z"
}
```

### Response 201

```json
{
  "message": "Meta criada com sucesso.",
  "goal": {
    "id": 1,
    "userId": 7,
    "name": "Reserva do carro",
    "description": "Manutencao preventiva",
    "targetAmountCents": 500000,
    "currentAmountCents": 125000,
    "status": "ACTIVE",
    "targetDate": "2026-12-31T00:00:00.000Z",
    "completedAt": null,
    "createdAt": "2026-05-25T12:00:00.000Z",
    "updatedAt": "2026-05-25T12:00:00.000Z"
  }
}
```

## Atualizar meta

```http
PATCH /finance/goals/:id
Content-Type: application/json
```

### Request

```json
{
  "name": "Reserva e pneus",
  "description": "Troca de pneus e revisao",
  "targetAmountCents": 650000,
  "currentAmountCents": 200000,
  "targetDate": "2026-12-31T00:00:00.000Z"
}
```

### Response 200

```json
{
  "message": "Meta atualizada com sucesso.",
  "goal": {}
}
```

## Concluir meta

```http
PATCH /finance/goals/:id/complete
```

### Response 200

```json
{
  "message": "Meta concluida com sucesso.",
  "goal": {
    "status": "COMPLETED",
    "completedAt": "2026-05-25T12:30:00.000Z"
  }
}
```

## Arquivar meta

```http
DELETE /finance/goals/:id
```

### Response 200

```json
{
  "message": "Meta arquivada com sucesso.",
  "goal": {
    "status": "ARCHIVED"
  }
}
```

## Regras de erro

- `400`: nome vazio, objetivo menor/igual a zero, valor atual negativo ou status invalido.
- `401`: usuario nao autenticado.
- `404`: meta nao encontrada para o usuario autenticado.
- `409`: transicao de status invalida.

## Supabase direto

Quando o provider do app for Supabase, o mobile acessa a tabela `Goal` diretamente com:

- `select().eq('userId', currentUserId).order('createdAt', ascending: false)`
- `insert` sempre preenchendo `userId` do usuario autenticado.
- `update`/`delete logico` sempre usando `id` e `userId`.
