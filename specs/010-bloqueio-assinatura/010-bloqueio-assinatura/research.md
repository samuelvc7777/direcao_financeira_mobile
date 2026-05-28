# Research: Bloqueio por assinatura vigente

## Decisao 1: Reusar `SubscriptionEntity.grantsAccess` como verdade inicial de acesso

**Decision**: A decisao de acesso vigente deve partir de `SubscriptionEntity.grantsAccess`.

**Rationale**: O codigo atual ja possui uma regra de dominio que libera `ACTIVE`, `TRIAL` e `CANCELED` quando a assinatura ainda tem `endDate` futura. Essa regra corresponde ao requisito do usuario: cancelamento dentro do periodo nao bloqueia, assinatura ausente ou vencida bloqueia.

**Alternatives considered**:

- Recriar comparacoes de `status`, `canceledAt` e `endDate` em controllers: rejeitado porque espalha regra de negocio pela presentation.
- Bloquear apenas por `status == ACTIVE`: rejeitado porque bloquearia usuario cancelado ainda dentro do periodo.
- Consultar somente o cache de usuario: rejeitado porque ja houve risco observado de informacao de assinatura desatualizada na tela de Ajustes.

## Decisao 2: Criar uma guarda compartilhada de presentation para acoes protegidas

**Decision**: Usar um ponto compartilhado na presentation para envolver comandos protegidos e decidir entre executar a acao original ou exibir o banner premium.

**Rationale**: O app possui botoes protegidos espalhados por Home, Transacoes, Jornada e Ajustes. Uma guarda compartilhada reduz duplicacao, evita divergencia de comportamento e permite preservar explicitamente excecoes como bottom navigation, logout e ver plano.

**Alternatives considered**:

- Bloquear rotas inteiras via middleware: rejeitado porque a especificacao permite navegacao e bloqueia cliques de acoes, nao abertura de telas.
- Inserir verificacao manual em cada controller sem padrao: rejeitado por aumentar risco de esquecer fluxos como bolinha/jornada ou acoes futuras.
- Desabilitar botoes visualmente: rejeitado porque o requisito pede que os botoes abram o banner premium ao toque.

## Decisao 3: Banner premium como widget reutilizavel

**Decision**: Implementar o banner premium como widget dedicado, acionado pela guarda, com estilo escuro/dourado e CTA para assinatura.

**Rationale**: A referencia visual mostra uma comunicacao forte de premium com superficie escura, destaque amarelo/dourado, selo e CTA destacado. Um widget reutilizavel facilita consistencia, responsividade e testes isolados.

**Alternatives considered**:

- Usar snackbar simples: rejeitado porque nao entrega o banner visual solicitado.
- Reusar diretamente a tela de assinatura: rejeitado porque o usuario pediu um banner no toque bloqueado, com CTA para ver assinatura.
- Criar banner dentro de cada view: rejeitado por duplicacao e risco de inconsistencia visual.

## Decisao 4: Nao alterar painel admin

**Decision**: O plano nao altera contratos, rotas ou permissoes do painel admin.

**Rationale**: A especificacao define que administradores podem continuar gerenciando usuarios ativos pelo painel admin. O bloqueio pertence ao app mobile e ao uso do usuario final.

**Alternatives considered**:

- Propagar bloqueio para backend/admin: rejeitado porque mudaria escopo e poderia impedir operacoes administrativas necessarias.

## Decisao 5: Estado de assinatura carregando ou incerto nao executa acao protegida

**Decision**: Enquanto o estado de acesso nao estiver confiavel, a guarda nao deve executar a acao protegida; deve mostrar feedback adequado ou aguardar carregamento conforme a experiencia definida na implementation.

**Rationale**: A especificacao exige evitar liberar recursos protegidos por engano quando dados chegam atrasados, incompletos ou falham.

**Alternatives considered**:

- Liberar por otimismo durante carregamento: rejeitado porque viola a protecao premium.
- Bloquear silenciosamente: rejeitado porque o usuario precisa entender o motivo e o caminho para assinatura.
