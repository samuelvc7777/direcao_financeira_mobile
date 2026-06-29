# Quickstart: Banner global de atualizacao

## Pre-condicoes

- Branch ativa: `011-banner-atualizacao-global`.
- Mudancas sujas preexistentes fora da feature devem ser preservadas.
- Nao publicar update real na Play Store para testar; usar fake/mock de `AppUpdateService`.

## Fluxo de implementacao esperado

1. Criar `AppUpdateController` global usando `AppUpdateService`.
2. Registrar `AppUpdateService` e `AppUpdateController` em binding global.
3. Integrar `GlobalUpdateBannerOverlay` no `GetMaterialApp.builder` de forma defensiva.
4. Criar o widget visual responsivo em `lib/app/presentation/widgets/global_update_banner_overlay.dart`.
5. Remover a verificacao de update do `HomeController`.
6. Remover `UpdateAvailableCard` da Home para evitar duplicidade.
7. Atualizar testes da Home impactados.
8. Criar testes do controller e do overlay.

## Validacao automatizada

```powershell
flutter test test/app/core/update/app_update_controller_test.dart
flutter test test/presentation/widgets/global_update_banner_overlay_test.dart
flutter test test/app/presentation/modules/home/home_controller_test.dart
flutter analyze
```

## Validacao manual

1. Simular `hasUpdateAvailable=true` e abrir o app.
2. Confirmar que o overlay aparece acima da rota inicial.
3. Navegar para Home, Settings e Subscription e confirmar que o overlay continua global enquanto nao cancelado.
4. Tocar em `Agora nao` e confirmar que o overlay some na sessao atual.
5. Simular `hasUpdateAvailable=false` e confirmar que nenhum aviso aparece.
6. Simular falha na verificacao e confirmar que o app abre e navega normalmente.
7. Testar tela estreita e baixa altura para verificar ausencia de overflow e acesso aos botoes.

## Riscos de regressao

- `Get.find()` no root antes do binding terminar pode quebrar startup; usar checagem defensiva.
- Manter o card antigo da Home junto do overlay cria aviso duplicado.
- Chamar update no `HomeController` deixaria Login e outras rotas sem cobertura.
- Estado persistido de cancelamento nao deve ser criado no MVP.
