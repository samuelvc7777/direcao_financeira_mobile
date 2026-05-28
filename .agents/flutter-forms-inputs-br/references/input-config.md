# Configuracao de inputs

## Escolha de teclado

- numero: `TextInputType.number`
- telefone: `TextInputType.phone`
- email: `TextInputType.emailAddress`
- url: `TextInputType.url`
- texto longo: `TextInputType.multiline`

## Capitalizacao

- nomes: `TextCapitalization.words`
- frases: `TextCapitalization.sentences`
- codigos: `TextCapitalization.characters`
- email e senha: `TextCapitalization.none`

## Acao do teclado

- campo intermediario: `TextInputAction.next`
- ultimo campo: `TextInputAction.done` ou `send`
- busca: `TextInputAction.search`

## Feedback de erro

- escrever mensagens especificas.
- evitar "campo invalido" sem contexto.
- preferir erro abaixo do campo.
