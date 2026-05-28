---
name: create-plan
description: Cria planos tecnicos detalhados a partir de contexto, tickets, pesquisa e arquivos do codebase. Use quando o pedido for para montar um plano de implementacao, ler arquivos citados por completo, pesquisar a implementacao atual, levantar duvidas reais, estruturar fases e escrever um plano completo em `thoughts/shared/plans/` sem deixar perguntas abertas no resultado final.
---

# Create Plan

## Objetivo

Transformar contexto disperso em um plano executavel, claro e verificavel.

## Fluxo

1. Ler completamente os arquivos citados.
2. Pesquisar o codebase e os documentos de apoio.
3. Confirmar o estado atual antes de propor estrutura.
4. Apresentar um resumo curto do entendimento e, se necessario, perguntas objetivas.
5. Definir a estrutura das fases antes de escrever o plano completo.
6. Escrever o plano em `thoughts/shared/plans/`.
7. Sincronizar os artefatos de thoughts quando aplicavel.

## Regras

- Ser cetico e verificar no codigo.
- Nao escrever um plano com duvidas nao resolvidas.
- Separar criterios de verificacao automatica e manual.
- Incluir escopo fora do plano para evitar ambiguidade.
- Descrever fases pequenas, testaveis e executaveis.
- Sempre incluir referencias para arquivos e pesquisas relacionadas.

## Estrutura esperada do plano

- Overview
- Current State Analysis
- Desired End State
- What We Are Not Doing
- Implementation Approach
- Phases com criterios de sucesso
- Testing Strategy
- References
