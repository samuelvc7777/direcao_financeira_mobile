---
name: research-codebase
description: Documenta o codebase existente com foco em descrever o que ja existe, onde existe e como os componentes se conectam. Use quando o pedido for para pesquisar, mapear ou explicar o codigo atual, ler arquivos citados por completo, usar subagentes para explorar areas do repositorio e gerar um documento de pesquisa sem sugerir melhorias, correcao de bugs ou refatoracao.
---

# Research Codebase

## Objetivo

Documentar o sistema como ele esta hoje, com base no codigo-fonte e nos artefatos de apoio.

## Fluxo

1. Ler primeiro qualquer arquivo citado diretamente pelo usuario.
2. Decompor a pergunta em areas de pesquisa.
3. Usar subagentes para localizar e explicar os componentes relevantes.
4. Ler por completo os arquivos identificados como importantes.
5. Sintetizar o que existe com caminhos de arquivo e linhas de referencia.
6. Registrar o resultado em um documento de pesquisa em `thoughts/shared/research/`.

## Regras

- Descrever apenas o estado atual.
- Nao sugerir melhorias, correcao de problema ou refatoracao.
- Nao fazer analise de causa raiz sem pedido explicito.
- Priorizar o codigo vivo como fonte principal.
- Incluir contexto historico de `thoughts/` quando existir.
- Sempre citar caminhos de arquivo e, quando possivel, linhas.

## Estrutura esperada do resultado

- Resumo do que foi encontrado
- Findings por componente ou area
- Referencias de codigo
- Arquitetura observada
- Contexto historico relevante
- Questoes em aberto, se houver
