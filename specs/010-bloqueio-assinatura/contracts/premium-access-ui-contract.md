# UI Contract: Premium Access Guard

## Objetivo

Padronizar o comportamento visivel quando um usuario sem assinatura vigente toca em uma acao protegida no app mobile.

## Acoes liberadas sempre

- Troca de abas pela navegacao principal.
- Acesso a telas por navegacao basica.
- Botao de sair da conta.
- Botao "Ver plano", "Ver assinatura" ou equivalente.

## Acoes protegidas

Toda acao marcada como protegida deve seguir este contrato:

1. Receber a intencao do usuario por toque.
2. Consultar a decisao de acesso vigente.
3. Se acesso estiver liberado, executar exatamente a acao original.
4. Se acesso estiver bloqueado, impedir a acao original.
5. Exibir o banner premium.
6. Se o banner ja estiver visivel, nao abrir outro banner por cima.

## Banner premium

### Conteudo obrigatorio

- Selo: `PREMIUM`.
- Titulo: deve comunicar assinatura premium.
- Mensagem: deve informar que a conta esta sem plano ativo vigente ou que precisa assinar para liberar funcionalidades.
- Beneficios:
  - liberar recursos premium do aplicativo;
  - manter a experiencia ativa/protegida;
  - escolher um plano na tela de assinatura.
- CTA principal: `VER ASSINATURA` ou texto equivalente que navegue para a tela de assinatura.

### Comportamento

- CTA principal navega para `AppRoutes.subscription`.
- Fechamento do banner nao executa a acao bloqueada.
- Toques repetidos em botoes protegidos nao criam banners duplicados.
- O banner deve funcionar em tema escuro e respeitar contraste.

### Responsividade

- Em telas pequenas, o banner deve caber na largura disponivel com margens seguras.
- Textos podem quebrar linha, mas nao devem sofrer overflow horizontal.
- CTA deve manter area de toque suficiente.

## Estados esperados

| Estado de acesso | Resultado do toque protegido |
|------------------|------------------------------|
| Liberado | Executa acao original |
| Bloqueado | Nao executa acao original; mostra banner |
| Carregando | Nao executa acao original; mostra feedback seguro |
| Erro/incerto | Nao executa acao original; mostra feedback seguro |

## Fora do escopo

- Permissoes ou telas do painel admin.
- Alteracao de planos, precos ou contratos de compra.
- Bloqueio global de rotas por middleware.
