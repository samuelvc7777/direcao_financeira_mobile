---
name: flutter-motion-feedback
description: Adicionar, revisar ou refatorar animacoes, transicoes, microinteracoes e feedback tatil em Flutter com foco em UX, performance e acessibilidade. Use quando a tarefa envolver AnimatedContainer, AnimatedSwitcher, AnimatedList, Hero, transicoes de pagina, feedback de toque, Lottie, Rive ou respeito a reduce motion.
---

# Flutter Motion Feedback

Use esta skill para dar vida a interface sem prejudicar performance.

## Executar fluxo

1. Identificar o objetivo da animacao: feedback, hierarquia, transicao ou estado.
2. Escolher animacao implicita por padrao.
3. Manter duracao curta e curva coerente.
4. Respeitar acessibilidade e reduzir movimento quando necessario.
5. Validar se a animacao melhora a UX em vez de apenas ornamentar.

## Regras obrigatorias

- Dar preferencia a widgets implicitos.
- Evitar animacao linear.
- Manter a maioria das interacoes entre 100ms e 400ms.
- Adicionar feedback tatil somente onde fizer sentido.
- Nao acoplar animacoes pesadas a reconstrucoes frequentes.

## Ler referencias quando necessario

- Ler [references/motion-patterns.md](references/motion-patterns.md) para exemplos aprovados.
- Ler [references/accessibility.md](references/accessibility.md) para reduce motion.
- Ler [references/checklist.md](references/checklist.md) antes de fechar a tarefa.
