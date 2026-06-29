# UI Contract: GlobalUpdateBannerOverlay

## Objetivo

Exibir um aviso global de nova versao acima de qualquer rota do app, preservando o app renderizado por baixo e oferecendo as acoes `Atualizar agora` e `Agora nao`.

## Entrada esperada

- `show`: quando falso, renderiza apenas o `child`.
- `child`: rota/tela atual do app.
- `onUpdate`: callback obrigatorio da acao principal.
- `onCancel`: callback da acao secundaria no MVP.
- `forceUpdate`: reservado para futuro; quando verdadeiro, esconde a acao secundaria.
- `badgeText`: texto do selo; se vazio, usar `PLAY STORE`.

## Comportamento

- Quando `show=false`, nao deve haver overlay, blur, textos ou botoes de update.
- Quando `show=true`, deve renderizar overlay cobrindo toda a tela.
- O fundo deve escurecer e desfocar o conteudo atual.
- O card deve ficar centralizado, respeitar `SafeArea` e permitir rolagem em tela pequena.
- Tocar em `Atualizar agora` deve chamar `onUpdate`.
- Tocar em `Agora nao` deve chamar `onCancel` quando `forceUpdate=false`.
- Quando `forceUpdate=true`, a acao secundaria nao deve aparecer.

## Conteudo visual minimo

- Icone de atualizacao.
- Selo com `PLAY STORE` por padrao.
- Texto de destaque equivalente a `ATUALIZACAO RECOMENDADA`.
- Titulo equivalente a `Nova versao disponivel`.
- Mensagem informando melhorias, correcoes e estabilidade.
- Botao principal verde com texto `ATUALIZAR AGORA`.
- Botao secundario discreto com texto `Agora nao` no MVP.
- Texto auxiliar explicando que a atualizacao sera aberta pela Play Store e que o usuario pode continuar usando a versao atual.

## Responsividade

- Largura maxima do card: aproximadamente 430px.
- Em larguras pequenas, o card deve reduzir espacamento sem cortar textos.
- Em alturas pequenas, o conteudo deve rolar para manter botoes acessiveis.
- Nao deve haver overflow horizontal.
- Nao deve haver texto sobreposto, botao cortado ou area de toque menor que o esperado para mobile.

## Acessibilidade e temas

- O contraste entre textos, botoes e fundo deve ser suficiente em tema claro e escuro.
- Os botoes devem ter labels textuais claros.
- O overlay nao deve depender de cor como unico indicador de acao.
