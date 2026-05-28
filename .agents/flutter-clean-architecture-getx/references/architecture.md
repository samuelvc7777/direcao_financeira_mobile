# Arquitetura

## Estrutura base

```text
lib/
|-- main.dart
|-- core/
|   |-- errors/
|   |-- constants/
|   `-- utils/
|-- domain/
|   |-- entities/
|   |-- repositories/
|   `-- usecases/
|-- data/
|   |-- datasources/
|   |-- models/
|   `-- repositories/
`-- app/
    |-- bindings/
    |-- controllers/
    |-- routes/
    `-- ui/
        |-- pages/
        `-- theme/
```

## Responsabilidades

- `domain/entities`: objetos centrais do negocio, sem detalhes de framework.
- `domain/repositories`: contratos de acesso a dados.
- `domain/usecases`: acoes e regras da aplicacao.
- `data/datasources`: comunicacao com API, banco, cache ou SDK.
- `data/models`: parse e serializacao.
- `data/repositories`: implementacao concreta dos contratos.
- `app/controllers`: orquestracao do estado e chamadas de use case.
- `app/bindings`: injecao de dependencias.
- `app/ui`: pages e widgets.

## Alertas

- Nao misturar parse JSON em controller.
- Nao instanciar datasource dentro de widget.
- Nao deixar regras de negocio espalhadas em `onPressed`.
