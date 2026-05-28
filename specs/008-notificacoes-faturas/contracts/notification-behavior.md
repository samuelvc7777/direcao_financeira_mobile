# Contract: Comportamento das Notificacoes de Fatura

## Escopo

Este contrato descreve o comportamento observavel da feature Android de notificacoes locais de faturas.

## Canais

- Canal: `faturas_cartao`
- Nome exibivel: `Faturas de cartao`
- Finalidade: avisos de fechamento, vencimento e atraso de faturas.

## Horario

- Todos os avisos devem ser avaliados para 10h no horario local do aparelho.
- Se o aparelho estiver desligado, sem permissao ou impedido pelo sistema no horario planejado, o app deve reavaliar pendencias na proxima oportunidade segura.

## Tipos de Aviso

### Fechamento

**Quando**: dia de fechamento do cartao, as 10h.

**Condição**: cartao ativo e fatura relevante para revisao.

**Texto esperado**:

- Titulo deve indicar que a fatura fechou.
- Corpo deve identificar o cartao e, quando confiavel, o valor.

### Vencimento

**Quando**: dia de vencimento do cartao, as 10h.

**Condição**: cartao ativo e fatura com valor pendente.

**Texto esperado**:

- Titulo deve indicar que a fatura vence hoje.
- Corpo deve identificar o cartao e valor pendente quando confiavel.

### Atraso

**Quando**: diariamente as 10h apos o vencimento.

**Condição**: cartao ativo, vencimento passado e fatura ainda com valor pendente.

**Texto esperado**:

- Titulo deve indicar fatura vencida.
- Corpo deve identificar cartao e valor pendente quando confiavel.

## Dedupe

O mesmo `cardId`, `invoiceCycleKey`, `type` e `eventDate` nao pode gerar mais de uma notificacao.

## Acao ao tocar

Ao tocar na notificacao, o app deve abrir em uma rota ou estado que permita revisar a fatura/cartao relacionado com clareza.

## Permissoes

- Sem `POST_NOTIFICATIONS`, a feature deve falhar de forma silenciosa no envio e manter feedback disponivel no app.
- Se alarme exato for adotado na implementacao, ausencia da permissao correspondente deve ser tratada com fallback ou orientacao clara.

## Fora de escopo

- Push remoto.
- Firebase.
- Campanhas ou mensagens promocionais.
- Suporte iOS nesta feature.
