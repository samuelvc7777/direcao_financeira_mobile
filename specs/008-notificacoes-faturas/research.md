# Research: Notificacoes de Faturas

## Decision: notificacoes locais Android, sem Firebase

**Rationale**: A regra depende de dados que o app ja conhece: cartoes, fechamento, vencimento, fatura vencida e pagamento. Firebase/FCM adicionaria cadastro de token, backend de disparo e sincronizacao remota sem necessidade para o MVP solicitado.

**Alternatives considered**:

- Firebase Cloud Messaging: rejeitado por adicionar infraestrutura remota para uma rotina local.
- Foreground service diario: rejeitado por custo de bateria e por nao ser necessario para avisos pontuais.

## Decision: agendamento com flutter_local_notifications

**Rationale**: O app ja possui `flutter_local_notifications` e usa o plugin para permissao/canais. A versao instalada fornece `zonedSchedule`, `AndroidScheduleMode`, suporte a `POST_NOTIFICATIONS` e integracao com boot quando as permissoes/receivers necessarios existem.

**Alternatives considered**:

- Implementacao nativa propria com AlarmManager: rejeitada no plano inicial porque duplica responsabilidade que o plugin ja cobre.
- WorkManager: rejeitado para horario fixo de notificacao, pois e melhor para trabalho diferido e nao para experiencia de aviso as 10h.

## Decision: usar timezone como dependencia direta

**Rationale**: O plugin recomenda uso de datas com fuso via `zonedSchedule` e o pacote `timezone` ja aparece como transitive no lock. Como o codigo vai referenciar tipos do pacote diretamente, ele deve virar dependencia direta para evitar depender de transitive dependency.

**Alternatives considered**:

- Usar DateTime simples: rejeitado porque o metodo moderno de agendamento do plugin trabalha com `TZDateTime`.
- Criar conversao manual de fuso: rejeitado por aumentar risco de erro em mudanca de fuso/horario.

## Decision: horario local do aparelho as 10h

**Rationale**: A especificacao pede 10h da manha e o app e mobile/individual. O horario local do aparelho e a interpretacao mais previsivel para o usuario.

**Alternatives considered**:

- Horario fixo de Brasilia: rejeitado por poder surpreender usuarios em outro fuso.
- Horario configuravel: rejeitado para MVP porque o usuario pediu horario fixo.

## Decision: dedupe local por cartao, ciclo, tipo e data

**Rationale**: O Android pode reagendar apos boot, o app pode abrir varias vezes e faturas podem ser recalculadas. Um registro local evita duplicidade para o mesmo evento diario.

**Alternatives considered**:

- Confiar apenas em IDs de notificacao pendente: rejeitado porque nao cobre todos os caminhos de reprocessamento.
- Persistir dedupe remoto: rejeitado para MVP Android local.

## Decision: reagendar em inicializacao, boot/update e mudancas relevantes

**Rationale**: Notificacao local precisa sobreviver a reinicio e refletir alteracoes de cartao/fatura/pagamento. O manifest ja possui `RECEIVE_BOOT_COMPLETED`, e o app tambem pode revalidar quando abre.

**Alternatives considered**:

- Agendar apenas quando o usuario cadastra cartao: rejeitado porque pagamentos, alteracoes e boot podem invalidar o estado anterior.
- Calcular somente as 10h sem agenda previa: rejeitado porque o app pode estar fechado.

## Decision: exatidao pragmatica para 10h

**Rationale**: Para chegar exatamente as 10h em Android recente, alarmes exatos podem exigir permissao especifica e possivel avaliacao de loja. O plano deve priorizar funcionamento robusto e registrar que, se a validacao exigir precisao estrita, `SCHEDULE_EXACT_ALARM` e permissao correspondente devem entrar na implementacao.

**Alternatives considered**:

- `USE_EXACT_ALARM`: rejeitado como default por ser mais restrito e sujeito a politica de loja.
- Agendamento inexato sem qualquer nota: rejeitado porque o usuario perguntou sobre app fechado e espera clareza sobre confiabilidade.
