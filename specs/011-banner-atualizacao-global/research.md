# Research: Banner global de atualizacao

## Decisao 1: Reaproveitar `AppUpdateService`

**Decision**: Manter `AppUpdateService` e `PlayStoreUpdateService` como fonte de verificacao e abertura da loja.

**Rationale**: O projeto ja possui contrato mockavel com `hasUpdateAvailable()` e `openStorePage()`, usando `in_app_update` e `url_launcher`. Reaproveitar esse contrato evita dependencia nova e reduz risco.

**Alternatives considered**:

- Criar novo servico de versao: rejeitado porque duplicaria infraestrutura ja existente.
- Criar versao minima remota: rejeitado porque esta fora do MVP e exigiria regra/backend novo.

## Decisao 2: Controller global em GetX

**Decision**: Criar `AppUpdateController` global e permanente para estado de apresentacao do aviso.

**Rationale**: A verificacao precisa ocorrer ao abrir o app e o aviso precisa aparecer em qualquer rota, logo o estado nao pode depender da Home. GetX e o padrao constitucional para estado e bindings.

**Alternatives considered**:

- Manter logica no `HomeController`: rejeitado porque nao cobre Login, Settings, Subscription e outras rotas.
- Colocar estado diretamente em `main.dart`: rejeitado porque misturaria composicao macro com comportamento de presentation.

## Decisao 3: Registro em binding global

**Decision**: Registrar `AppUpdateService` e `AppUpdateController` em `CoreBinding` ou `AppBinding`, antes das rotas dependerem da Home.

**Rationale**: O controller precisa existir cedo no app e nao pode depender de `HomeBinding`. O registro global reduz duplicidade e permite reutilizacao em qualquer rota.

**Alternatives considered**:

- Registrar no `HomeBinding`: rejeitado por escopo incorreto.
- Instanciar no widget: rejeitado por violar o padrao de binding e ciclo de vida previsivel.

## Decisao 4: Overlay defensivo no `GetMaterialApp.builder`

**Decision**: Integrar o overlay no `GetMaterialApp.builder`, com tolerancia caso o controller ainda nao esteja registrado.

**Rationale**: O builder e o ponto comum de todas as rotas. Como root overlay pode rodar cedo, a implementacao deve checar registro antes de `Get.find()` para nao deixar o app cinza ou quebrar startup.

**Alternatives considered**:

- Renderizar o overlay dentro da Home: rejeitado porque nao e global.
- Usar dialog/modal por rota: rejeitado porque duplica controle e pode competir com navegacao.

## Decisao 5: Card central com fundo blur

**Decision**: Implementar o design aprovado como overlay central com fundo escurecido/desfocado, card escuro premium, selo, icone, bloco de mensagem e botoes.

**Rationale**: Esse design aumenta percepcao do aviso e atende o pedido do usuario. A adaptacao deve priorizar compactacao, `SafeArea`, rolagem e largura maxima.

**Alternatives considered**:

- Banner superior simples: rejeitado porque o usuario aprovou um overlay central mais forte.
- Bloqueio obrigatorio: rejeitado no MVP porque a regra de produto exige permitir cancelar.

## Decisao 6: Remover aviso duplicado da Home

**Decision**: Remover a renderizacao e a responsabilidade de update da Home.

**Rationale**: A spec exige no maximo uma experiencia ativa de update. Manter card e overlay geraria duplicidade.

**Alternatives considered**:

- Deixar `UpdateAvailableCard` sem uso: aceitavel temporariamente se remover referencias, mas a implementacao deve preferir apagar arquivo/testes mortos quando nao houver outro consumidor.
