# Data Model: Banner global de atualizacao

## Estado do aviso de atualizacao

Representa o estado em memoria da experiencia global de update durante a sessao atual.

### Campos

- `isCheckingUpdate`: booleano; verdadeiro enquanto a verificacao silenciosa esta em andamento.
- `isUpdateAvailable`: booleano; verdadeiro quando a fonte de update indica nova versao disponivel.
- `isDismissedForSession`: booleano; verdadeiro depois que o usuario toca em cancelar na sessao atual.
- `lastCheckError`: texto opcional para diagnostico/teste; nao deve ser exibido diretamente ao usuario.
- `badgeText`: texto opcional de selo visual; padrao esperado no MVP e `PLAY STORE`.
- `forceUpdate`: booleano reservado para suporte visual futuro; deve permanecer falso no MVP.

### Regras de validacao

- `isUpdateAvailable=false` implica overlay oculto.
- `isDismissedForSession=true` implica overlay oculto mesmo se `isUpdateAvailable=true`.
- `forceUpdate=true` nao deve ser ativado no MVP.
- Erro de verificacao deve resultar em `isUpdateAvailable=false` e app navegavel.

### Estados derivados

- `shouldShowBanner = isUpdateAvailable && !isDismissedForSession`.

## Resultado de verificacao de versao

Representa o resultado retornado pela fonte de disponibilidade de update.

### Valores

- `available`: existe nova versao disponivel.
- `unavailable`: nao existe nova versao ou a plataforma nao suporta o fluxo do MVP.
- `failed`: a verificacao falhou e deve ser tratada silenciosamente para o usuario.

### Transicoes

```text
idle -> checking -> available
idle -> checking -> unavailable
idle -> checking -> failed
available -> dismissed
dismissed -> available somente em nova sessao
```

## Persistencia

Nenhuma persistencia nova no MVP. O cancelamento e apenas em memoria e reinicia ao abrir uma nova sessao do app.
