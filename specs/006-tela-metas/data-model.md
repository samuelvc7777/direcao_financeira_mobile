# Data Model: Tela de metas

## Goal

Objetivo financeiro ou pessoal acompanhado pela pessoa usuaria.

### Campos

| Campo | Tipo | Obrigatorio | Regra |
|-------|------|-------------|-------|
| `id` | int | sim | Identificador gerado pelo banco |
| `userId` | int | sim | Dono da meta; sempre escopado pelo usuario autenticado |
| `name` | string | sim | Texto aparado, nao vazio |
| `description` | string? | nao | Observacao curta opcional |
| `targetAmountCents` | int | sim | Maior que zero |
| `currentAmountCents` | int | sim | Maior ou igual a zero; default 0 |
| `status` | GoalStatus | sim | `ACTIVE`, `COMPLETED` ou `ARCHIVED` |
| `targetDate` | DateTime? | nao | Prazo opcional para a meta |
| `completedAt` | DateTime? | nao | Preenchido quando status vira `COMPLETED` |
| `createdAt` | DateTime | sim | Gerado pelo banco |
| `updatedAt` | DateTime | sim | Atualizado em cada mutacao |

### Propriedades derivadas no domain mobile

- `targetAmount`: `targetAmountCents / 100.0`
- `currentAmount`: `currentAmountCents / 100.0`
- `progressRatio`: se `targetAmountCents <= 0`, retorna `0`; senao `currentAmountCents / targetAmountCents`
- `progressPercent`: `progressRatio * 100`
- `isReached`: `currentAmountCents >= targetAmountCents`
- `isActive`: `status == GoalStatus.active`

### Validacoes

- `name.trim()` nao pode ser vazio.
- `targetAmountCents` deve ser maior que 0.
- `currentAmountCents` deve ser maior ou igual a 0.
- `Goal` sempre pertence ao usuario autenticado.
- `completedAt` so deve existir quando `status == COMPLETED`.
- `ARCHIVED` nao aparece na lista principal de metas ativas da Home.

### Transicoes de estado

```text
ACTIVE -> COMPLETED
ACTIVE -> ARCHIVED
COMPLETED -> ARCHIVED
ARCHIVED -> ACTIVE (opcional para reativacao futura; fora do MVP se nao houver UI)
```

## GoalSummary

Resumo derivado para a Home e cabecalho da tela.

### Campos derivados

| Campo | Regra |
|-------|-------|
| `totalGoals` | quantidade de Goals nao arquivadas |
| `activeGoals` | quantidade com status `ACTIVE` |
| `completedGoals` | quantidade com status `COMPLETED` |
| `overallProgressPercent` | media do progresso das Goals nao arquivadas, com cada meta limitada visualmente a 100 no resumo |

## Relacionamentos

- `User 1 -> N Goal`
- `Goal` nao possui relacionamento automatico com `CostsGainsSettings`.
- `CostsGainsSettings.desiredMonthlyProfitCents` continua representando apenas o objetivo mensal operacional de trabalho.

## Prisma proposto

```prisma
enum GoalStatus {
  ACTIVE
  COMPLETED
  ARCHIVED
}

model Goal {
  id                 Int        @id @default(autoincrement())
  userId             Int
  name               String
  description        String?
  targetAmountCents  Int
  currentAmountCents Int        @default(0)
  status             GoalStatus @default(ACTIVE)
  targetDate         DateTime?
  completedAt        DateTime?
  user               User       @relation(fields: [userId], references: [id])
  createdAt          DateTime   @default(now())
  updatedAt          DateTime   @updatedAt

  @@index([userId, status])
  @@index([userId, createdAt])
}
```
