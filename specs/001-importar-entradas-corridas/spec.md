# Feature Specification: Importacao de entradas por corridas

**Feature Branch**: `001-importar-entradas-corridas`  
**Created**: 2026-03-26  
**Status**: Implementado  
**Input**: User description: "precisamos criar uma opcao de na tela de nova transacao/entrada tenha uma opcao de puxar todas corridas, e seus valores e formas de pagaemnto, e com isso dar opcao do usuario adicionar em cada conta oque entrou e assim regristrar uma entrada nova, bora discutir sobre"

## User Scenarios & Testing

### User Story 1 - Importar corridas para montar a entrada (Priority: P1)

Como motorista, quero abrir a tela de nova entrada e consultar minhas corridas feitas hoje em um dialog com valor e forma de pagamento para nao precisar somar tudo manualmente antes de registrar o que recebi.

**Why this priority**: Esse e o fluxo central da feature e reduz o trabalho manual que hoje existe para transformar corridas finalizadas em entradas financeiras.

**Independent Test**: Abrir a tela de nova entrada, tocar em `Corridas feitas hoje` e verificar que o dialog apresenta corridas elegiveis do dia com informacoes suficientes para conferencia.

**Acceptance Scenarios**:

1. **Given** que o usuario esta na tela de nova transacao do tipo entrada e possui corridas elegiveis hoje, **When** ele escolhe `Corridas feitas hoje`, **Then** o sistema apresenta em dialog as corridas com seus valores e formas de pagamento para conferencia.
2. **Given** que nao ha corridas elegiveis no dia atual, **When** o usuario tenta abrir `Corridas feitas hoje`, **Then** o sistema informa claramente que nao ha corridas disponiveis para gerar entradas.

---

### User Story 2 - Distribuir o recebido entre contas antes de salvar (Priority: P2)

Como motorista, quero escolher em qual conta entrou cada grupo de recebimento para registrar minhas entradas de acordo com a conta que realmente recebeu cada valor.

**Why this priority**: O valor da feature nao esta apenas em puxar corridas, mas em transformar esse total em entradas coerentes com as contas que receberam o dinheiro.

**Independent Test**: Abrir o dialog, escolher a conta de destino para cada grupo de recebimento e confirmar que o sistema aceita salvar somente quando todos os grupos tiverem conta definida.

**Acceptance Scenarios**:

1. **Given** que o usuario abriu as corridas do dia e possui contas ativas, **When** ele escolhe a conta de destino para cada grupo de recebimento, **Then** o sistema libera a confirmacao do registro.
2. **Given** que existe algum grupo sem conta definida, **When** o usuario tenta confirmar, **Then** o sistema bloqueia o registro e orienta o preenchimento pendente.

---

### User Story 3 - Registrar entradas com rastreabilidade da importacao (Priority: P3)

Como usuario, quero concluir o lancamento diretamente pelo dialog com clareza sobre o que foi importado e o que sera salvo para confiar que as entradas geradas refletem as corridas consideradas.

**Why this priority**: Depois da importacao e da distribuicao, o usuario precisa de seguranca para confirmar sem duvida sobre o total, as contas envolvidas e o resultado do registro.

**Independent Test**: Finalizar uma importacao valida pelo dialog e verificar que o sistema salva as entradas previstas, fecha o dialog, fecha a tela de entrada e volta para a tela de transacoes com feedback de sucesso.

**Acceptance Scenarios**:

1. **Given** que o usuario revisou as corridas importadas, escolheu a categoria e definiu as contas de destino, **When** ele confirma o registro, **Then** o sistema salva as novas entradas, fecha o dialog, fecha a tela de nova entrada e apresenta uma confirmacao clara do resultado.
2. **Given** que alguma corrida importada ficou inconsistente antes da confirmacao, **When** o usuario tenta concluir o fluxo, **Then** o sistema impede o registro e orienta o ajuste necessario.

---

### Edge Cases

- Corridas sem forma de pagamento identificada nao devem entrar silenciosamente no calculo final.
- Corridas sem valor valido nao devem ser consideradas para gerar entradas.
- O fluxo deve deixar evidente quando nao existe nenhuma conta ativa disponivel para receber a distribuicao.
- O usuario deve entender claramente o que acontece quando tenta importar corridas que ja participaram de um registro anterior.
- O dialog deve deixar claro quando nao houver categoria selecionada ou quando algum grupo ainda estiver sem conta de destino.

## Requirements

### Functional Requirements

- **FR-001**: O sistema MUST oferecer, na tela de nova transacao do tipo entrada, uma opcao explicita `Corridas feitas hoje`.
- **FR-002**: O sistema MUST apresentar para conferencia o valor e a forma de pagamento de cada corrida considerada na importacao.
- **FR-003**: O sistema MUST abrir a consulta em um dialog dedicado, sem tirar o usuario imediatamente da tela de nova entrada.
- **FR-004**: O sistema MUST permitir que o usuario escolha a conta de destino para cada grupo consolidado de recebimento antes de concluir o registro.
- **FR-005**: O sistema MUST bloquear a confirmacao enquanto existir grupo consolidado sem conta de destino definida.
- **FR-006**: O sistema MUST registrar novas entradas de acordo com a distribuicao confirmada pelo usuario, preservando a conta escolhida para cada parcela registrada.
- **FR-007**: O sistema MUST permitir ao usuario revisar quais corridas participaram do registro antes de concluir a operacao.
- **FR-008**: O sistema MUST informar com clareza quando nao houver corridas elegiveis, quando faltarem contas ativas ou quando existir inconsistencia nos dados importados.
- **FR-009**: O sistema MUST considerar apenas corridas finalizadas e com dados minimos suficientes para compor uma entrada.
- **FR-010**: O sistema MUST bloquear automaticamente corridas que ja participaram de um registro anterior, impedindo que elas sejam consideradas novamente em uma nova importacao.
- **FR-011**: O sistema MUST apresentar a importacao inicialmente por um consolidado de totais, incluindo ao menos agrupamento por forma de pagamento, com opcao de expandir os detalhes das corridas individuais para conferencia.
- **FR-012**: O sistema MUST permitir escolher a categoria diretamente no dialog antes de salvar as entradas importadas.
- **FR-013**: O sistema MUST fechar automaticamente o dialog e a tela de nova entrada quando o registro importado for concluido com sucesso.
- **FR-014**: O sistema MUST considerar automaticamente apenas corridas elegiveis do dia atual ao abrir `Corridas feitas hoje`, sem exigir que o usuario informe a data manualmente nesse fluxo.

### Key Entities

- **Corrida importavel**: Corrida finalizada que possui dados suficientes para ser considerada na geracao de entrada, incluindo ao menos valor e forma de pagamento.
- **Destino por grupo de recebimento**: Definicao da conta ativa que recebera cada grupo consolidado de valor importado.
- **Entrada importada**: Registro financeiro de entrada gerado a partir da confirmacao da distribuicao de valores das corridas.

### Business Rules

- **BR-001**: Apenas corridas finalizadas e com valor valido podem compor a importacao.
- **BR-002**: Corridas sem forma de pagamento valida ou sem valor confiavel devem ser destacadas como inconsistentes e nao podem entrar no total confirmado sem acao explicita do usuario.
- **BR-003**: A confirmacao do fluxo exige que cada grupo consolidado tenha uma conta de destino definida.
- **BR-004**: Cada conta so deve receber valor maior que zero no momento da confirmacao do registro.
- **BR-005**: A mesma sessao de importacao deve deixar claro para o usuario quais corridas foram consideradas, quais ficaram de fora e por qual motivo.
- **BR-006**: Corridas ja utilizadas em importacoes anteriores nao podem retornar como elegiveis para nova importacao.
- **BR-007**: O consolidado inicial da importacao nao substitui a rastreabilidade; o usuario deve conseguir expandir e conferir as corridas que compoem cada total apresentado.
- **BR-008**: No fluxo `Corridas feitas hoje`, a data do registro importado segue automaticamente o dia atual considerado na consulta.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Um usuario consegue sair da tela de nova entrada com o total das corridas carregado para conferencia em ate 1 minuto, sem precisar recalcular manualmente os valores.
- **SC-002**: O usuario consegue concluir a definicao das contas de destino e confirmar o registro diretamente no dialog sem precisar voltar ao formulario para finalizar.
- **SC-003**: Em cenarios sem corridas elegiveis, sem contas disponiveis ou com dados inconsistentes, o sistema informa o impedimento sem deixar o usuario em estado ambigguo.
- **SC-004**: O fluxo permite ao usuario identificar com clareza quais corridas participaram do registro antes da confirmacao final.

## Assumptions

- A feature sera iniciada a partir da tela de nova transacao do tipo entrada.
- A distribuicao sera feita apenas entre contas ativas, nao entre cartoes.
- A categoria pode ser escolhida diretamente no dialog antes de salvar.
- No fluxo `Corridas feitas hoje`, a data do registro segue o dia atual e nao exige ajuste manual previo no formulario.
- Quando a distribuicao envolver mais de uma conta, o resultado esperado e o registro de entradas coerentes com cada conta informada pelo usuario.
