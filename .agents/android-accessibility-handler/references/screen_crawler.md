# Screen Crawler (Kotlin)

O `AccessibilityNodeInfo` é uma árvore de componentes de UI. Para extrair dados de corridas:

### Varredura Inteligente
```kotlin
fun findRideData(node: AccessibilityNodeInfo, ride: MutableMap<String, String>) {
    val text = node.text?.toString() ?: ""
    val contentDescription = node.contentDescription?.toString() ?: ""
    
    // Regras de detecção (heurística)
    if (text.contains("R$")) {
        ride["valor"] = text
    } else if (text.matches(Regex("\\d+(\\.\\d+)? km"))) {
        ride["distancia"] = text
    } else if (text.contains("Retirada") || text.contains("Entrega")) {
        ride["ponto"] = text
    }

    for (i in 0 until node.childCount) {
        val child = node.getChild(i)
        if (child != null) {
            findRideData(child, ride)
        }
    }
}
```

### Otimização
Evite varrer o nó `root` a cada micro-mudança (`typeWindowContentChanged`) se o conteúdo não mudou significativamente. Use o `typeWindowStateChanged` para detectar quando o app alvo entrou em foco.
