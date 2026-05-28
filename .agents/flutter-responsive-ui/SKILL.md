---
name: flutter-responsive-ui
description: Criar, revisar ou refatorar telas Flutter com responsividade real, escalas proporcionais, adaptacao por largura, uso correto de Theme e composicao de layouts para mobile e tablet. Use quando a tarefa envolver tamanhos, espacos, tipografia, grids, empty states ou ajustes de UI para diferentes telas.
---

# Flutter Responsive UI

Use esta skill para evitar UI quebrada, rigida ou cheia de valores fixos.

## Executar fluxo

1. Identificar em quais larguras a tela precisa funcionar.
2. Remover tamanhos fixos quando eles forem sensiveis ao device.
3. Centralizar escalas em helper responsivo ou design tokens existentes.
4. Adaptar layout com base em largura disponivel, nao em suposicoes visuais.
5. Validar empty state, scrolling e overflow.

## Regras obrigatorias

- Evitar `fontSize`, `padding`, `height` e `width` fixos sem justificativa.
- Preferir `Expanded`, `Flexible`, `FractionallySizedBox` e constraints.
- Usar cores vindas do tema.
- Testar a composicao em pelo menos mobile compacto e tablet.
- Tratar listas vazias com empty state claro.

## Ler referencias quando necessario

- Ler [references/responsive-helper.md](references/responsive-helper.md) para helper base.
- Ler [references/layout-rules.md](references/layout-rules.md) para decisoes de layout.
- Ler [references/ui-checklist.md](references/ui-checklist.md) antes de finalizar uma tela.
