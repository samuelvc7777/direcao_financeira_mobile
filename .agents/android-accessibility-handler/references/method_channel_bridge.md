# Method Channel Bridge

Para enviar dados do `AccessibilityService` (Android) para o Flutter:

### 1. No Kotlin (MainActivity.kt ou Singleton)
```kotlin
object EventBus {
    private var channel: MethodChannel? = null

    fun init(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "com.direcao_financeira/accessibility")
    }

    fun sendEvent(data: Map<String, Any>) {
        Handler(Looper.getMainLooper()).post {
            channel?.invokeMethod("onRaceDetected", data)
        }
    }
}
```

### 2. No Flutter (Controller do GetX)
```dart
static const platform = MethodChannel('com.direcao_financeira/accessibility');

void initAccessibility() {
  platform.setMethodCallHandler((call) async {
    if (call.method == "onRaceDetected") {
      final data = call.arguments;
      // Processar dados no GetX
    }
  });
}
```
