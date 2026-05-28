# Goals UI Contract

## Entradas de navegacao

- Settings: item "Configurar Metas" abre `AppRoutes.goals`.
- Home: botao/acao "Gerenciar" da secao "Minhas Metas" abre `AppRoutes.goals`.

## Estados da tela Goals

| Estado | Requisito visual |
|--------|------------------|
| Loading | Indicador com texto curto, sem lista piscando |
| Empty | Mensagem clara e CTA para criar primeira meta |
| Success | Header/resumo, lista de metas ativas e area para concluidas/arquivadas quando aplicavel |
| Error | Mensagem e acao de tentar novamente |
| Submitting | Formulario bloqueia duplo envio e preserva dados digitados |

## Composicao esperada

- `GoalsView`: scaffold, observador de estado e abertura do formulario.
- `GoalsContent`: conteudo principal responsivo.
- `GoalsSummaryHeader`: totais e progresso geral.
- `GoalCard`: nome, status, valores e barra de progresso.
- `GoalFormSheet`: criar/editar meta.
- `GoalsEmptyState` e `GoalsErrorState`: estados independentes.

## Formulario

Campos:

- Nome da meta
- Descricao opcional
- Valor objetivo
- Valor atual
- Data alvo opcional

Validacoes visiveis:

- Nome obrigatorio.
- Valor objetivo maior que zero.
- Valor atual nao negativo.

## Home

- `GoalsSection` usa lista/resumo real de Goal.
- Se nao houver Goals reais, nao exibe "Pagar contas" ou qualquer mock.
- O progresso geral considera metas nao arquivadas.

## Responsividade

- Em telas estreitas, cards ficam em coluna unica.
- Em larguras maiores, cards podem usar grid/wrap.
- Valores monetarios longos devem usar truncamento, quebra controlada ou escala visual sem sair do card.
