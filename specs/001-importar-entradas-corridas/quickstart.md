# Quickstart: Importacao de entradas por corridas

## Objetivo

Validar manualmente o fluxo de importacao de corridas para nova entrada, cobrindo consolidado inicial, distribuicao por conta, bloqueio de duplicidade e registro final.

## Pre-condicoes

1. Usuario autenticado.
2. Existe ao menos uma categoria de entrada ativa.
3. Existem contas ativas cadastradas.
4. Existem corridas finalizadas com valor e forma de pagamento validos.
5. Existe ao menos uma corrida ja importada anteriormente para validar bloqueio de duplicidade.

## Fluxo principal

1. Abrir a tela de nova transacao.
2. Selecionar o tipo `Entrada`.
3. Acionar a opcao de importar corridas.
4. Confirmar que o app mostra primeiro um consolidado por forma de pagamento.
5. Expandir um grupo e conferir se as corridas individuais aparecem com valor e identificacao suficiente.
6. Validar que corridas anteriormente importadas nao aparecem como elegiveis.
7. Distribuir o valor total entre uma ou mais contas ativas.
8. Conferir que a diferenca chega a zero.
9. Confirmar o registro.
10. Validar mensagem de sucesso e refletir as novas entradas na lista/resumo financeiro.

## Cenarios de verificacao

### Sem corridas elegiveis

1. Abrir a importacao em um periodo sem corridas elegiveis.
2. Confirmar mensagem clara de estado vazio.
3. Verificar que o fluxo nao tenta registrar entrada.

### Sem contas ativas

1. Garantir ambiente sem contas ativas.
2. Abrir a importacao.
3. Confirmar que o app explica o impedimento antes da confirmacao.

### Distribuicao inconsistente

1. Importar corridas elegiveis.
2. Informar distribuicao menor ou maior que o total.
3. Confirmar que a acao final permanece bloqueada e a diferenca e exibida.

### Dados inconsistentes de corrida

1. Garantir corrida finalizada sem forma de pagamento valida ou com valor invalido.
2. Abrir importacao.
3. Confirmar que a corrida nao entra no total confirmado e que o motivo fica visivel.

### Bloqueio de duplicidade

1. Importar e registrar uma sessao com um conjunto conhecido de corridas.
2. Reabrir a importacao no mesmo recorte.
3. Confirmar que as corridas ja usadas nao aparecem novamente como elegiveis.

## Sugestao de testes automatizados

1. Testes de dominio para elegibilidade e conciliacao.
2. Testes de controller para estados de importacao e confirmacao.
3. Testes de datasource/repositorio para contrato de criacao e bloqueio de reimportacao.
