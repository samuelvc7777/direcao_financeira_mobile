# Mascaras brasileiras e dinheiro

## Mascaras comuns

- CPF: `###.###.###-##`
- CNPJ: `##.###.###/####-##`
- Telefone: `(##) #####-####`
- CEP: `#####-###`
- Data: `##/##/####`

## Dinheiro

- Exibir com `intl` em `pt_BR`.
- Alinhar campo monetario a direita quando fizer sentido.
- Armazenar e trafegar valores em centavos.
- Converter UI para centavos antes de enviar.
- Converter centavos para exibicao ao carregar.

```dart
final format = NumberFormat.simpleCurrency(locale: 'pt_BR');
final texto = format.format(valorEmReais);
```

## Alertas

- Evitar `double` para persistencia.
- Evitar parse frouxo que aceite lixo silenciosamente.
