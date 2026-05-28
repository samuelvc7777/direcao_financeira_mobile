---
name: implement-plan
description: Implementa um plano tecnico aprovado a partir de `thoughts/shared/plans/`, lendo o plano e os arquivos relacionados por completo, executando as fases com verificacao e atualizando o progresso de forma controlada. Use quando o pedido for para executar um plano existente, seguir fases planejadas, validar criterios automaticos e pausar para verificacao manual quando necessario.
---

# Implement Plan

## Objetivo

Executar um plano aprovado com disciplina de fase, verificacao e rastreabilidade.

## Fluxo

1. Ler o plano completo e identificar checkboxes ja marcados.
2. Ler os arquivos originais e os arquivos mencionados no plano.
3. Montar um acompanhamento de tarefas.
4. Implementar uma fase por vez, respeitando a ordem do plano.
5. Rodar as verificacoes automatizadas previstas.
6. Atualizar o plano com o progresso real.
7. Pausar para verificacao manual quando a fase exigir confirmacao humana.

## Regras

- Nao assumir que o plano esta perfeito; comparar com o estado real do repositorio.
- Se houver mismatch, parar e explicitar a divergencia.
- Nao marcar etapas de teste manual sem confirmacao do usuario.
- Nao avancar para a proxima fase antes de fechar a fase atual.
- Manter o end goal do plano em foco durante a execucao.
- Usar verificacao para evitar regressao e trabalho incompleto.

## Estrutura de execucao

- Revisar contexto
- Implementar fase
- Verificar
- Registrar progresso
- Pausar ou seguir conforme o numero de fases solicitado
