# direcao_financeira_mobile

Aplicativo Flutter do projeto Direcao Financeira.

## Fluxo de especificacao

Este repositorio passou a usar o **Spec Kit** como fluxo principal de trabalho.

Comandos principais no Codex:

- `$speckit-constitution`
- `$speckit-specify`
- `$speckit-plan`
- `$speckit-tasks`
- `$speckit-implement`

Artefatos principais:

- `.specify/memory/constitution.md`: principios e regras do projeto
- `.specify/specs/`: especificacoes, planos e tarefas por feature
- `.agents/skills/`: skills do Codex para executar o fluxo do Spec Kit

## Contexto atual

- App mobile em Flutter
- Arquitetura com separacao por camadas e uso extensivo de GetX
- Foco atual de refatoracao: `lib/app/presentation/modules/journey/`

## Desenvolvimento Flutter

- Separe a page/view da composicao visual
- Mantenha a view responsavel pela estrutura macro da tela
- Extraia secoes, cards, itens e blocos visuais para widgets menores quando isso melhorar legibilidade, reuso ou manutencao

## Referencias

- [Flutter docs](https://docs.flutter.dev/)
- [GitHub Spec Kit](https://github.com/github/spec-kit)
