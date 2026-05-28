---
name: flutter-view-widget-separation
description: Criar, revisar ou refatorar telas Flutter com separacao clara entre a page/view e widgets menores, extraindo secoes, cards, itens de lista, cabecalhos, estados vazios e blocos visuais para widgets privados ou arquivos dedicados. Use quando a tela estiver grande, quando o `build` estiver poluido, quando houver repeticao de UI, quando for preciso padronizar composicao Flutter senior ou reduzir acoplamento entre layout e apresentacao.
---

# Flutter View Widget Separation

Use esta skill para evitar telas gigantes, `build` confuso e widgets fazendo responsabilidades demais.

## Executar fluxo

1. Identificar a responsabilidade da `Page` ou `View`.
2. Separar o que e estrutura de tela do que e bloco visual.
3. Extrair widgets locais ou compartilhados conforme o nivel de reuso.
4. Passar dados e callbacks por construtor, sem empurrar regra de negocio para widget visual.
5. Validar legibilidade, reuso e coesao final.

## Regras obrigatorias

- Deixar a `Page` ou `View` responsavel por `Scaffold`, scroll principal, composicao macro, estado de rota e ligacao com controller.
- Extrair para widgets separados blocos visualmente distintos como header, hero, section, card, item de lista, chip group, empty state e bottom bar.
- Preferir widget privado no mesmo arquivo quando o bloco for local da tela e nao tiver reuso imediato.
- Mover para arquivo proprio quando o widget tiver reuso real, crescer demais ou competir com a leitura da tela principal.
- Passar apenas dados prontos, callbacks e dependencias de apresentacao no construtor.
- Nao acessar datasource, repository ou regra de negocio dentro de widget visual.
- Evitar widget com `build` gigante, muitos `if`s ou muitos niveis de aninhamento sem extracao.
- Preferir `StatelessWidget` para blocos puros de apresentacao.

## Heuristicas de decisao

- Se a tela tiver 3 ou mais secoes importantes, considerar uma extracao por secao.
- Se um trecho exigir nome para ser entendido, extrair.
- Se um widget repetir estilo e estrutura, extrair.
- Se a page ficar dificil de escanear rapidamente, extrair.
- Se o widget depender de estado global de navegacao ou layout macro, manter na page.

## Estrutura recomendada

```text
app/ui/pages/
  home_page.dart
app/ui/widgets/
  home/
    home_header.dart
    home_focus_card.dart
    home_agenda_section.dart
```

## Padrao pratico

1. Manter a tela principal legivel de cima para baixo.
2. Nomear widgets pelo papel visual e nao por detalhe tecnico.
3. Centralizar constantes e pequenos modelos visuais perto do widget que usa.
4. Evitar arquivo separado para widget trivial sem ganho real.

## Ler referencias quando necessario

- Ler [references/extraction-rules.md](references/extraction-rules.md) para decidir entre widget privado, widget compartilhado ou permanencia na view.
