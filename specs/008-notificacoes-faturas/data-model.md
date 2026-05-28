# Data Model: Notificacoes de Faturas

## CreditCardNotificationSource

Representa os dados de cartao/fatura necessarios para avaliar avisos.

**Fields**:

- `cardId`: identificador do cartao.
- `cardName`: nome exibivel do cartao.
- `isActive`: indica se o cartao deve participar dos avisos.
- `closingDay`: dia cadastrado de fechamento.
- `dueDay`: dia cadastrado de vencimento.
- `openInvoiceCents`: valor da fatura aberta.
- `closedInvoiceCents`: valor de faturas fechadas.
- `payableInvoiceCents`: valor pagavel/pendente.
- `openInvoiceClosingDate`: proximo fechamento conhecido.
- `nextDueDate`: vencimento relevante conhecido.
- `isInvoiceDueToday`: indica vencimento no dia.
- `isInvoiceOverdue`: indica atraso.

**Validation Rules**:

- Cartoes inativos nao geram candidatos.
- Valores menores ou iguais a zero nao geram aviso de vencimento/atraso.
- Dias de fechamento/vencimento devem ser normalizados para o ultimo dia valido do mes quando necessario.

## InvoiceNotificationType

Enum de tipos de aviso.

**Values**:

- `closing`: fatura fechou hoje.
- `dueToday`: fatura vence hoje.
- `overdue`: fatura esta vencida e pendente.

## InvoiceNotificationCandidate

Aviso elegivel para envio/agendamento.

**Fields**:

- `id`: identificador deterministico do candidato.
- `cardId`: cartao relacionado.
- `cardName`: nome para texto da notificacao.
- `type`: tipo de aviso.
- `invoiceCycleKey`: chave do ciclo de fatura.
- `eventDate`: data de fechamento, vencimento ou atraso.
- `scheduledAt`: data/hora local planejada, sempre 10h.
- `amountCents`: valor pendente/relevante quando confiavel.
- `title`: titulo da notificacao.
- `body`: conteudo da notificacao.
- `payload`: dados para abrir o app no contexto correto.

**Relationships**:

- Derivado de um `CreditCardNotificationSource`.
- Consultado contra `InvoiceNotificationDispatchRecord` antes de enviar.

**State Transitions**:

- `candidate` -> `scheduled`: quando a notificacao e programada.
- `candidate` -> `skipped`: quando ja existe registro para a mesma chave.
- `scheduled` -> `sent`: quando o app registra que o aviso foi exibido ou processado como enviado.
- `scheduled` -> `cancelled`: quando a fatura e paga/zerada ou o cartao fica inativo antes do envio.

## InvoiceNotificationDispatchRecord

Registro local de controle de avisos enviados/agendados.

**Fields**:

- `dedupeKey`: `cardId + invoiceCycleKey + type + eventDate`.
- `notificationId`: id usado pelo plugin de notificacao.
- `cardId`: cartao relacionado.
- `type`: tipo de aviso.
- `invoiceCycleKey`: ciclo de fatura.
- `eventDate`: dia do evento.
- `scheduledAt`: horario planejado.
- `sentAt`: horario em que foi registrado como enviado, se aplicavel.
- `status`: `scheduled`, `sent`, `cancelled` ou `skipped`.
- `createdAt`: criacao do registro.
- `updatedAt`: ultima atualizacao.

**Validation Rules**:

- `dedupeKey` deve ser unico localmente.
- Registros antigos podem ser limpos apos janela segura definida na implementacao.

## InvoiceNotificationPermissionStatus

Estado consultado para feedback e decisao de agendamento.

**Fields**:

- `canPostNotifications`: permissao Android de notificacao concedida.
- `canScheduleExactAlarms`: permissao de alarme exato quando a implementacao exigir.
- `requiresUserAction`: indica se o usuario precisa abrir configuracoes/permissao.

**Validation Rules**:

- Ausencia de permissao nao deve quebrar uso do app.
- O sistema deve permitir revalidacao quando o usuario voltar das configuracoes.
