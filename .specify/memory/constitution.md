<!--
Sync Impact Report
- Version change: 1.1.0 -> 1.2.0
- Modified principles:
  - II. Clean Architecture Como Base -> II. Clean Architecture Como Contrato Estrutural
  - III. GetX Como Padrao de Presentation -> III. GetX Como Padrao de Presentation e Binding
  - V. Regras de Negocio Fora da View -> V. Regras de Negocio no Domain
  - VI. Testes Como Regra de Entrega -> VI. Testes Como Regra por Camada
- Added sections:
  - Contratos por Camada
  - Padrao de Testes por Camada
- Removed sections: nenhuma
- Templates requiring updates:
  - ✅ .specify/templates/plan-template.md
  - ✅ .specify/templates/spec-template.md
  - ✅ .specify/templates/tasks-template.md
- Follow-up TODOs: nenhum
-->

# Direcao Financeira Mobile Constitution

## Core Principles

### I. Verdade e Contexto Real
Toda decisao tecnica MUST partir do estado real do repositorio, do comportamento observado e
dos requisitos explicitados. Nao e permitido inventar regras, fluxos, dependencias ou
comportamentos nao verificados. Quando houver lacuna de contexto, ela MUST ser registrada com
clareza antes de qualquer mudanca estrutural.

### II. Clean Architecture Como Contrato Estrutural
O projeto MUST seguir Clean Architecture como padrao estrutural obrigatorio. A organizacao do
codigo deve preservar separacao clara entre `presentation`, `domain` e `data`, com dependencias
apontando para dentro e contratos estaveis entre camadas. Nenhuma feature nova deve colapsar essas
fronteiras para ganhar velocidade local. Quando uma nova necessidade surgir, ela SHOULD ser
encaixada na camada correta, mesmo que com implementacao minima e incremental.

### III. GetX Como Padrao de Presentation e Binding
GetX MUST ser a base de gerenciamento de estado, injecao, bindings e fluxo de presentation do
projeto. Controllers MUST controlar estado e comportamento de tela, navegacao local e reacoes da
UI. Bindings MUST concentrar registro e composicao das dependencias da feature, evitando
instanciacao espalhada na view. Controllers MUST NOT concentrar regra de negocio complexa, acesso
direto a datasources, transformacoes centrais de dominio ou orquestracao que pertence a use cases,
servicos, entidades ou repositorios. Widgets puramente visuais podem permanecer simples, mas a
verdade de estado da tela deve ficar ancorada em GetX quando houver estado de presentation.

### IV. Views Responsivas e Composicao Modular
Toda view MUST ser responsiva e pensada para diferentes tamanhos de tela. A implementacao de
responsividade SHOULD usar o melhor conjunto de praticas e utilitarios adotado pelo projeto em
Flutter, sempre priorizando previsibilidade visual, legibilidade e manutencao. Page/view MUST
ficar responsavel pela estrutura macro da tela; secoes, cards, listas, itens e blocos visuais
devem ser extraidos para widgets menores quando isso melhorar clareza, reuso e manutencao.

### V. Regras de Negocio no Domain
Toda regra de negocio MUST viver fora de views, widgets, bindings e controllers. O `domain` e o
centro semantico do projeto: entidades, use cases, servicos de dominio e contratos de repositorio
devem refletir as regras reais do negocio com clareza. O `presentation` apenas consome e exibe
essas decisoes; o `data` apenas materializa acesso e persistencia. Qualquer calculo financeiro,
agregacao relevante, criterio operacional, validacao de negocio ou decisao de fluxo de dominio
MUST permanecer fora da UI.

### VI. Testes Como Regra por Camada
Toda implementacao nova MUST considerar testes como parte da entrega. O projeto e orientado a
testes, e a estrategia de verificacao deve respeitar a camada alterada: logica de negocio no
`domain`, adaptacao e mapeamento no `data`, e comportamento/estado de tela no `presentation`.
Mudanca estrutural ou funcional sem avaliar impacto em testes e inaceitavel. Quando uma regra de
negocio for introduzida ou alterada, os testes correspondentes SHOULD acompanhar a mudanca.

## Restricoes de Arquitetura

O projeto usa Flutter, GetX e organizacao por camadas. Mudancas em `presentation`, `domain` e
`data` devem respeitar fronteiras claras. A camada `presentation` nao deve conhecer detalhes de
infraestrutura alem do necessario para consumir contratos estaveis. A camada `data` nao deve
vazar detalhes de provider, banco, serializacao ou transporte para a UI. A camada `domain` deve
permanecer isolada de frameworks, widgets e detalhes de persistencia. Decisoes que afetem multiplos
modulos devem explicitar impacto em bindings, estado, navegacao e fluxo de dependencias.

## Contratos por Camada

### Presentation
`presentation` MUST conter pages/views, widgets, controllers, bindings e objetos auxiliares de
interface. Views e widgets focam em composicao e renderizacao. Controllers focam em estado de tela,
intencoes do usuario e coordenacao de chamadas para o dominio. Bindings focam em registrar as
dependencias corretas da feature. `presentation` MUST NOT implementar regra de negocio central.

### Domain
`domain` MUST conter entidades, value objects quando fizer sentido, contratos de repositorio, use
cases e servicos de dominio. Toda regra de negocio importante SHOULD ser representada aqui. Use
cases MUST expor operacoes orientadas ao negocio e nao detalhes de UI. Entidades MUST preservar
coerencia sem depender de Flutter, GetX ou detalhes de infraestrutura.

### Data
`data` MUST conter modelos, mapeadores, datasources, providers e implementacoes concretas de
repositorios. Datasources SHOULD apenas buscar, persistir ou transportar dados. Repositorios
concretos MUST adaptar o mundo externo para os contratos definidos no `domain`. Modelos de `data`
MUST NOT vazar diretamente como verdade do negocio para camadas superiores quando existir entidade
de dominio apropriada.

### Bindings
Bindings MUST ser o ponto oficial de composicao de dependencias por modulo ou feature. Toda
injecao de controller, use case, repositorio e datasource SHOULD partir dali, salvo excecoes muito
locais e justificadas. Bindings MUST manter previsibilidade de ciclo de vida e evitar registro
duplicado ou disperso.

### Controllers
Controllers MUST traduzir eventos da UI em chamadas a use cases/servicos e refletir o estado de
presentation para a tela. Controllers MUST NOT virar fachada de infraestrutura ou deposito de
regras de negocio. Se um controller estiver crescendo por causa de calculos, validacoes complexas
ou transformacoes centrais, essa logica deve ser extraida para o `domain` ou para componentes
apropriados de apoio.

## Padrao de Testes por Camada

### Domain
O `domain` SHOULD ter prioridade maxima de testes automatizados. Entidades, use cases, servicos de
dominio e regras de calculo MUST ser testados com foco em comportamento, cenarios limite e
consistencia sem depender de UI ou infraestrutura real.

### Data
O `data` SHOULD ter testes para mapeamentos, contratos de repositorio, adaptacao entre modelos e
entidades, tratamento de erro e comportamento de datasources quando isso tiver risco funcional.
Testes nessa camada devem garantir que a implementacao concreta respeita o contrato esperado pelo
`domain`.

### Presentation
O `presentation` SHOULD ter testes voltados a estado de controller, fluxo principal de tela,
formatacao visivel relevante e regressao de comportamento. Testes de widget e controller devem
validar estados importantes sem empurrar regra de negocio para a UI.

## Documentacao e Acesso ao Codigo

Toda implementacao relevante SHOULD deixar o codigo mais facil de navegar e entender. Views,
widgets, controllers, servicos, use cases, repositorios e datasources devem ter nomes coerentes e
organizacao previsivel. Quando houver logica menos obvia, a documentacao local e os comentarios
sucintos devem facilitar o acesso futuro sem poluir o codigo. A estrutura do projeto deve
favorecer manutencao, onboarding e localizacao rapida de responsabilidades.

## Fluxo de Trabalho

O fluxo padrao do projeto e:

1. Atualizar ou validar a constituicao com `$speckit-constitution`, quando necessario.
2. Criar a especificacao da feature com `$speckit-specify`.
3. Gerar o plano tecnico com `$speckit-plan`.
4. Gerar tarefas executaveis com `$speckit-tasks`.
5. Implementar seguindo as tarefas com `$speckit-implement`.

Para tarefas pequenas e de baixo risco, pode haver execucao direta, mas o agente ainda MUST
preservar os principios desta constituicao e registrar claramente as suposicoes feitas.

## Governance

Esta constituicao prevalece sobre instrucoes informais de fluxo dentro do repositorio. Toda
mudanca relevante em principios, arquitetura ou forma de execucao deve atualizar este documento.
O versionamento segue semver:

- MAJOR para mudancas incompativeis de principios ou governanca
- MINOR para novos principios, novas restricoes ou ampliacao material de regras
- PATCH para clarificacoes editoriais sem mudanca substantiva

Toda revisao tecnica relevante SHOULD validar aderencia a esta constituicao, aos artefatos em
`.specify/` e ao estado real do codigo alterado.

**Version**: 1.2.0 | **Ratified**: 2026-03-26 | **Last Amended**: 2026-03-26
