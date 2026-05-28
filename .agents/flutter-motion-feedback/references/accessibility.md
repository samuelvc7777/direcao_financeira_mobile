# Acessibilidade de movimento

## Regra

Se o sistema indicar reducao de movimento, entregar versao sem animacao ou com transicao minima.

```dart
final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context);

if (reduceMotion) {
  return child;
}
```

## Cuidados

- Evitar animacao continua sem valor funcional.
- Evitar depender apenas de motion para comunicar estado.
- Combinar motion com contraste, texto ou icone quando houver feedback importante.
