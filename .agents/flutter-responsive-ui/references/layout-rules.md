# Regras de layout

## Preferencias

- Preferir `Expanded()` no lugar de largura fixa.
- Preferir `LayoutBuilder` para trocar entre lista e grid.
- Preferir `Wrap` ou `GridView` quando a linha pode quebrar.
- Preferir `SafeArea` em telas principais.

## Evitar

- `SizedBox(width: 300)` como base da interface.
- `const EdgeInsets.all(16)` repetido em toda a app sem token central.
- cores hardcoded em componentes de negocio.

## Exemplo adaptativo

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 700) {
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        children: cards,
      );
    }

    return ListView(children: cards);
  },
)
```
