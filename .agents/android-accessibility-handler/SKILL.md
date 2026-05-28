---
name: android-accessibility-handler
description: Configura e implementa serviços de acessibilidade no Android (Kotlin) para leitura de tela em tempo real, especificamente para capturar dados de aplicativos de terceiros (corridas). Use esta skill quando precisar ler notificações ou janelas do Android que o Flutter não alcança nativamente.
---

# Android Accessibility Handler

## Visão Geral
Esta skill fornece o fluxo de trabalho e os padrões de código necessários para implementar um `AccessibilityService` robusto no Android usando Kotlin, integrado a um projeto Flutter. Ela é ideal para automação de leitura de dados de corridas em apps de entrega/transporte.

## Fluxo de Implementação (Workflow)

### 1. Configuração de Recursos
Todo serviço de acessibilidade precisa de um arquivo XML de configuração que define quais eventos ele escuta.
- **Arquivo:** `android/app/src/main/res/xml/accessibility_service_config.xml`
- **Importante:** Definir `accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged"` e `canRetrieveWindowContent="true"`.

### 2. Registro no Manifest
O serviço deve ser declarado no `AndroidManifest.xml` com a permissão `android.permission.BIND_ACCESSIBILITY_SERVICE`.
- **Filtro de Intent:** `android.accessibilityservice.AccessibilityService`.

### 3. Implementação do Service (Kotlin)
Criar uma classe que estende `AccessibilityService`.
- **onAccessibilityEvent:** Onde a mágica acontece. Filtre pelo pacote do app alvo (ex: Uber, iFood).
- **Leitura de Tela:** Use `rootInActiveWindow` para obter o nó raiz e faça uma busca recursiva por textos ou IDs.
- **Comunicação:** Use um `MethodChannel` estático ou um EventBus para enviar os dados capturados para o lado Flutter.

## Padrões de Captura

### Buscar por Texto
```kotlin
val nodes = rootInActiveWindow?.findAccessibilityNodeInfosByText("Valor")
```

### Percorrer Nós Recursivamente
Consulte `references/screen_crawler.md` para um algoritmo eficiente de varredura de tela.

## Recursos desta Skill

- `references/service_template.md`: Template base da classe Kotlin.
- `assets/config_template.xml`: Template do XML de configuração.
- `references/method_channel_bridge.md`: Como conectar o Kotlin ao Flutter/GetX.
