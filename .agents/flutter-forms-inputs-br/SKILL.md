---
name: flutter-forms-inputs-br
description: Criar, revisar ou refatorar inputs e formularios Flutter com teclado correto, fluxo de foco, validacao clara, mascaras brasileiras, estados de loading e tratamento seguro de valores monetarios em centavos. Use quando a tarefa envolver TextField, TextFormField, CPF, CNPJ, telefone, CEP, dinheiro, validacoes, UX de formulario ou prevencao de duplo envio.
---

# Flutter Forms Inputs BR

Use esta skill para formularios claros, robustos e adequados ao contexto brasileiro.

## Executar fluxo

1. Identificar os tipos de campo e o fluxo do formulario.
2. Configurar teclado, capitalizacao e acao do teclado por campo.
3. Aplicar mascara apenas onde ela reduz erro do usuario.
4. Definir validacao por foco, digitacao ou submit conforme o caso.
5. Tratar loading e bloqueio de duplo envio.
6. Garantir persistencia monetaria em centavos.

## Regras obrigatorias

- Escolher `keyboardType` coerente com o dado.
- Guiar o usuario com `textInputAction`.
- Exibir erro humanizado e especifico.
- Nao usar `double` como fonte de verdade para dinheiro persistido.
- Desabilitar acao durante submit.
- Preservar navegacao por foco em ordem logica.

## Ler referencias quando necessario

- Ler [references/input-config.md](references/input-config.md) para configuracoes basicas.
- Ler [references/br-masks-money.md](references/br-masks-money.md) para mascaras e dinheiro.
- Ler [references/form-checklist.md](references/form-checklist.md) antes de concluir um formulario.
