# Padroes de motion

## Duracoes recomendadas

- toque e press: 100ms a 150ms
- mudanca de estado simples: 200ms a 300ms
- troca de tela: 250ms a 350ms
- lista escalonada: 300ms base com pequeno atraso por item

## Widgets preferidos

- `AnimatedContainer`
- `AnimatedOpacity`
- `AnimatedScale`
- `AnimatedSwitcher`
- `TweenAnimationBuilder`
- `AnimatedList`
- `Hero`

## Exemplo de feedback de press

```dart
AnimatedScale(
  scale: isPressed ? 0.96 : 1,
  duration: const Duration(milliseconds: 100),
  curve: Curves.easeInOut,
  child: child,
)
```

## Exemplo de troca de estado

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 250),
  child: isLoading
      ? const CircularProgressIndicator(key: ValueKey('loading'))
      : const Icon(Icons.check, key: ValueKey('done')),
)
```
