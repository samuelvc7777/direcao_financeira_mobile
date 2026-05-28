# Service Template (Kotlin)

```kotlin
package com.example.direcao_financeira_mobile

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

class ScreenReaderService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Filtrar apps específicos se necessário
        // val packageName = event.packageName?.toString()
        
        val rootNode = rootInActiveWindow ?: return
        
        // Exemplo: Buscar dados de uma corrida
        processNode(rootNode)
    }

    private fun processNode(node: AccessibilityNodeInfo) {
        val text = node.text?.toString()
        if (text != null && text.contains("R$")) {
            Log.d("ScreenReader", "Valor encontrado: $text")
            // Notificar Flutter
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                processNode(child)
            }
        }
    }

    override fun onInterrupt() {}
}
```
