# UI Contract: Importacao de entradas por corridas

## Escopo

Contrato funcional da interface de importacao de corridas dentro da tela de nova transacao do tipo entrada.

## Entrada do fluxo

- A acao `Corridas feitas hoje` so aparece quando a transacao atual e do tipo `Entrada`.
- Ao iniciar o fluxo, a UI abre um dialog dedicado sem sair imediatamente da tela de nova entrada.
- O dialog deve permitir selecionar a categoria antes da confirmacao final.
- O dialog deve usar apenas corridas elegiveis do dia atual, sem filtro manual adicional de data nesse fluxo.

## Estados obrigatorios

### 1. Loading

- Exibir indicador de carregamento enquanto corridas elegiveis estao sendo buscadas.
- Bloquear confirmacao final enquanto a sessao nao estiver pronta.

### 2. Empty

- Quando nao houver corridas elegiveis no dia atual, exibir estado vazio com mensagem objetiva.
- Nao exibir total importado diferente de zero.

### 3. Error

- Exibir erro amigavel quando a busca falhar.
- Permitir nova tentativa sem perder o contexto da tela de entrada.

### 4. Loaded

- Exibir consolidado inicial por forma de pagamento dentro do dialog.
- Exibir cabecalho curto com contexto do dia e CTA principal de salvamento no proprio dialog.
- Cada grupo deve informar ao menos:
  - forma de pagamento;
  - quantidade de corridas;
  - valor total do grupo.
- Cada grupo deve permitir escolher a conta de destino.
- Cada grupo deve permitir expandir as corridas individuais.

### 5. Inconsistencias

- Corridas invalidas ou excluidas devem aparecer separadas do total elegivel.
- O motivo da exclusao deve estar visivel.

### 6. Conta por grupo

- Exibir as contas ativas disponiveis para cada grupo de recebimento.
- Exibir sempre o total importado do dia no dialog.
- Impedir confirmacao quando algum grupo estiver sem conta definida.
- A selecao da conta acontece no proprio card ou bloco do grupo consolidado, sem etapa separada de distribuicao manual por valor.

### 7. Confirmacao

- Antes de salvar, a UI deve permitir revisao do total, categoria, contas envolvidas e corridas consideradas.
- Em sucesso, exibir feedback claro de registro concluido, fechar o dialog, fechar a tela de entrada e voltar para a lista de transacoes.
- Em erro de persistencia, preservar estado suficiente para nova tentativa ou ajuste.

## Acoes de usuario

- Abrir `Corridas feitas hoje`.
- Selecionar categoria no dialog.
- Expandir ou recolher grupo por forma de pagamento.
- Escolher conta de destino por grupo.
- Confirmar registro.
- Cancelar fluxo e voltar ao formulario manual.

## Regras visiveis

- Corridas ja importadas nao podem aparecer como selecionaveis novamente.
- Corridas sem dados minimos nao entram no total importado.
- Cada grupo precisa ter conta de destino definida antes do salvamento.
- Contas com valor zero nao devem aparecer como entradas persistidas no resultado final.
- O sucesso do salvamento nao deve deixar o usuario parado na tela de entrada; o fluxo retorna automaticamente para transacoes.
