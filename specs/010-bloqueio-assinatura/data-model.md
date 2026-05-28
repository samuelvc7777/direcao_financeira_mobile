# Data Model: Bloqueio por assinatura vigente

## Usuario

**Descricao**: Pessoa autenticada no app mobile, associada a uma assinatura ativa armazenada ou consultada.

**Campos relevantes existentes**:

- `id`: identificador do usuario.
- `email`: contato do usuario.
- `name`: nome exibido.
- `isActive`: indica se a conta do usuario esta ativa.
- `activeSubscription`: assinatura atual, quando existe.
- `subscriptions`: historico/lista de assinaturas conhecidas.

**Validacoes/Regras**:

- Usuario sem `activeSubscription` deve ser tratado como sem acesso vigente para acoes protegidas.
- Usuario ativo no painel admin nao deve ser afetado por bloqueios visuais do app mobile.

## Assinatura

**Descricao**: Registro que representa plano, status e periodo de acesso do usuario.

**Campos relevantes existentes**:

- `id`: identificador da assinatura.
- `status`: estado de negocio da assinatura.
- `startDate`: inicio do periodo.
- `endDate`: fim do periodo vigente.
- `canceledAt`: data de cancelamento, quando houver.
- `autoRenew`: indica renovacao automatica.
- `plan`: plano associado.
- `googlePlayProductId` e `googlePlayPurchaseToken`: vinculo com Play Store quando aplicavel.

**Validacoes/Regras**:

- `ACTIVE`, `TRIAL` e `CANCELED` podem liberar acesso quando o periodo vigente ainda nao terminou.
- Qualquer status fora dos estados elegiveis bloqueia acoes protegidas.
- `endDate` vencida bloqueia mesmo que exista assinatura.
- `endDate` ausente segue a regra atual de dominio: estados elegiveis liberam acesso.

## Decisao de acesso premium

**Descricao**: Resultado usado pela presentation para decidir se uma acao protegida pode executar.

**Campos sugeridos**:

- `isAllowed`: indica se a acao protegida pode continuar.
- `reason`: motivo de bloqueio ou estado incerto, quando aplicavel.
- `source`: origem da decisao, como usuario armazenado ou assinatura sincronizada.

**Estados**:

- `allowed`: assinatura vigente confirmada.
- `blocked`: sem assinatura, assinatura vencida ou status sem acesso.
- `loading`: estado ainda sendo carregado.
- `error`: nao foi possivel confirmar acesso.

**Transicoes**:

- `loading` -> `allowed` quando assinatura vigente e confirmada.
- `loading` -> `blocked` quando ausencia/vencimento e confirmado.
- `loading` -> `error` quando a confirmacao falha sem decisao confiavel.
- `error` -> `allowed` ou `blocked` apos nova tentativa bem-sucedida.

## Acao protegida

**Descricao**: Botao ou comando do app mobile que executa recurso premium.

**Exemplos atuais a avaliar na implementacao**:

- Criar ou editar transacoes.
- Configurar contas, cartoes, categorias, custos/ganhos, semaforo, gravacao e metas.
- Iniciar/importar/acessar comandos operacionais de jornada.
- Pagar fatura ou executar comandos financeiros internos.

**Regras**:

- Quando acesso e permitido, executa callback original.
- Quando acesso e bloqueado, nao executa callback original e aciona banner premium.
- Navegacao principal, logout e ver plano/ver assinatura nao sao acoes protegidas.

## Banner premium

**Descricao**: Comunicacao visual exibida quando uma acao protegida e bloqueada.

**Conteudo minimo**:

- Selo premium.
- Titulo de assinatura premium.
- Texto explicando ausencia de plano ativo vigente.
- Beneficios do plano.
- CTA para ver assinatura/plano.

**Regras visuais**:

- Alto contraste.
- Direcao visual escura com destaque amarelo/dourado.
- Responsivo em telas compactas.
- Sem empilhar multiplas instancias ao toque repetido.
