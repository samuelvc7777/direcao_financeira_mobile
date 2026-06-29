package com.example.direcao_financeira_mobile.parsers

import java.text.Normalizer
import kotlin.math.abs

class MoveSjParser {

    // Padroes principais que identificam as partes da tela da oferta.
    // O parser depende desses textos porque a MoveSJ e lida por OCR, nao por API.
    private val priceRegex = Regex("(?:R\\$|RS|R\\s*\\$)\\s*\\d+(?:[.,]\\d+)?", RegexOption.IGNORE_CASE)
    private val ratingRegex =
        Regex("\\d+(?:[.,]\\d+)?\\s*[\\u2605\\u2B50]", RegexOption.IGNORE_CASE)
    private val ratingValueRegex =
        Regex("^\\d(?:[.,]\\d{1,2})\\s*(?:[\\u2605\\u2B50])?$", RegexOption.IGNORE_CASE)
    private val ratingNumberRegex =
        Regex("\\d(?:[.,]\\d{1,2})", RegexOption.IGNORE_CASE)
    // Trecho da rota exibido na lista de origem/destino: "1,5 km (4 min)" ou "300 m (2 min)".
    private val routeStepRegex =
        Regex(
            "\\d+(?:[.,]\\d+)?\\s*(?:km|m)\\s*\\((?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min\\)",
            RegexOption.IGNORE_CASE,
        )
    private val routeStepAnchorRegex =
        Regex(
            "^\\s*\\d+(?:[.,]\\d+)?\\s*(?:km|m)(?:\\s*\\(?(?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min\\)?)?\\s*$",
            RegexOption.IGNORE_CASE,
        )
    private val routeStepPrefixRegex =
        Regex(
            "^\\s*\\d+(?:[.,]\\d+)?\\s*(?:km|m)(?:\\s*\\((?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min\\)|\\s+(?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min)?",
            RegexOption.IGNORE_CASE,
        )
    private val routeDurationOnlyRegex =
        Regex(
            "^\\s*\\(?(?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min\\)?\\s*$",
            RegexOption.IGNORE_CASE,
        )
    // Metricas principais da oferta: distancia total e valor por km.
    private val offerDistanceRegex =
        Regex(
            "([\\dIlL]+(?:[.,]\\d+)?)\\s*km\\s*\\(\\s*R\\$\\s*\\d+(?:[.,]\\d+)?\\s*/\\s*km\\s*\\)",
            RegexOption.IGNORE_CASE,
        )
    // Metricas principais da oferta: tempo total e valor por minuto.
    private val offerMinutesRegex =
        Regex(
            "((?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min)\\s*\\(\\s*R\\$\\s*\\d+(?:[.,]\\d+)?\\s*/\\s*min\\s*\\)",
            RegexOption.IGNORE_CASE,
        )
    // Marcadores que confirmam que a tela e uma chamada acionavel, nao historico ou resumo.
    private val actionMarkers =
        listOf(
            "deslize para recusar",
            "deslize para aceitar",
            "recusar",
            "aceitar",
        )

    // Linha reconhecida pelo OCR com sua caixa na tela. A posicao e essencial para separar
    // passageiro, valor, mapa, origem e destino quando o OCR mistura tudo em uma lista.
    data class OcrLine(
        val text: String,
        val left: Int,
        val top: Int,
        val right: Int,
        val bottom: Int,
    ) {
        val centerX: Int get() = (left + right) / 2
        val centerY: Int get() = (top + bottom) / 2
    }

    fun parseOcrOffer(
        rawText: String,
        lines: List<String>,
    ): Map<String, Any>? {
        // Entrada mais simples: so texto, sem coordenadas. Serve como fallback e para testes.
        if (rawText.isBlank()) {
            return null
        }

        // Antes de extrair campos, confirma se o texto tem cara de oferta real.
        if (!isOfferScreenFromLines(lines)) {
            return null
        }

        return parseOfferFromLines(
            lines = lines,
            priceText = resolveBestPriceText(lines, rawText) ?: "R$ 0,00",
            ratingText = ratingRegex.find(rawText)?.value,
        )
    }

    fun parsePositionedOcrOffer(
        rawText: String,
        ocrLines: List<OcrLine>,
    ): Map<String, Any>? {
        // Caminho principal da leitura de tela: texto + coordenadas vindos do ML Kit.
        if (rawText.isBlank() || ocrLines.isEmpty()) {
            return null
        }

        val orderedLines =
            ocrLines
                .filter { it.text.trim().isNotEmpty() }
                .sortedWith(compareBy<OcrLine> { it.top }.thenBy { it.left })

        val textLines = orderedLines.map { it.text.trim() }
        // Uma tela so vira corrida se tiver preco, metricas e aceitar/recusar.
        if (!isOfferScreenFromLines(textLines)) {
            return null
        }

        val offerData = parseOfferFromOcrLines(
            rawText = rawText,
            ocrLines = orderedLines,
        )

        val originAddress = offerData["origin_address"]?.toString().orEmpty()
        val destinationAddress = offerData["destination_address"]?.toString().orEmpty()
        val kmTotal = (offerData["km_total"] as? Number)?.toDouble() ?: 0.0
        val totalMinutes = (offerData["minutos_total"] as? Number)?.toInt() ?: 0

        // A deteccao de MoveSJ em tempo real e conservadora: sem rota completa e sem metrica,
        // o servico nao salva corrida para evitar falso positivo.
        if (originAddress.isBlank() || destinationAddress.isBlank() || kmTotal <= 0.0 || totalMinutes <= 0) {
            return null
        }

        return offerData
    }

    internal fun parseOfferFromLines(
        lines: List<String>,
        priceText: String = "R$ 0,00",
        ratingText: String? = null,
    ): Map<String, Any> {
        // Monta o payload no contrato consumido pelo ScreenReaderService/Flutter.
        val parsedOffer = extractOfferDetails(lines)

        return mutableMapOf<String, Any>(
            "app" to "MoveSj",
            "platform_name" to "MoveSj",
            "valor_bruto" to priceText,
            "km_total" to parsedOffer.metrics.totalKm,
            "minutos_total" to parsedOffer.metrics.totalMinutes,
            "avaliacao" to sanitizeRating(ratingText),
            "passenger_name" to (parsedOffer.passengerName ?: ""),
            "origin_address" to (parsedOffer.originAddress ?: ""),
            "destination_address" to (parsedOffer.destinationAddress ?: ""),
        )
    }

    internal fun parseOfferFromOcrLines(
        rawText: String,
        ocrLines: List<OcrLine>,
    ): Map<String, Any> {
        // A tela e dividida uma unica vez em regioes dinamicas ancoradas no proprio card.
        // Isso evita que textos do mapa concorram com nome, valor e enderecos.
        val normalizedLines = normalizeOcrLines(ocrLines)
        val regions = buildDynamicOcrRegions(normalizedLines)
        val textLines = normalizedLines.map { it.text }
        val parsedOffer = extractOfferDetailsFromOcrRegions(regions)
        val price =
            extractBestPrice(rawText, regions.priceLines)
                ?: extractBestPrice(rawText, normalizedLines)
                ?: "R$ 0,00"
        val rating =
            extractBestRating(regions.passengerLines, regions.pageWidth)
                ?: extractBestRating(normalizedLines)

        return mutableMapOf<String, Any>(
            "app" to "MoveSj",
            "platform_name" to "MoveSj",
            "valor_bruto" to price,
            "km_total" to parsedOffer.metrics.totalKm,
            "minutos_total" to parsedOffer.metrics.totalMinutes,
            "avaliacao" to sanitizeRating(rating),
            "passenger_name" to (parsedOffer.passengerName ?: ""),
            "origin_address" to (parsedOffer.originAddress ?: ""),
            "destination_address" to (parsedOffer.destinationAddress ?: ""),
        ).also {
            // Fallback textual para metricas quando a analise posicional nao encontrou km/min.
            if (it["km_total"] == 0.0 || it["minutos_total"] == 0) {
                val fallback = extractOfferDetails(textLines)
                it["km_total"] = fallback.metrics.totalKm
                it["minutos_total"] = fallback.metrics.totalMinutes
            }
        }
    }
    internal fun isOfferScreenFromLines(lines: List<String>): Boolean {
        // Regra de entrada do parser: a tela precisa ter valor, metricas de oferta e acao.
        // Isso impede que telas como historico/ganhos sejam interpretadas como corrida.
        val normalizedLines = normalizeVisibleTexts(lines)
        val hasMainPrice = normalizedLines.any { priceRegex.containsMatchIn(it) }
        val hasMetrics =
            normalizedLines.any { offerDistanceRegex.containsMatchIn(it) } &&
                normalizedLines.any { offerMinutesRegex.containsMatchIn(it) }
        val hasActionMarker =
            normalizedLines.any { line ->
                val normalized = normalizedText(line)
                actionMarkers.any { marker -> normalized.contains(marker) }
            }

        return hasMainPrice && hasMetrics && hasActionMarker
    }

    private fun extractOfferDetails(lines: List<String>): MoveSjParsedOffer {
        // Extracao textual pura, usada quando nao ha coordenadas ou como fallback.
        val normalizedLines = normalizeVisibleTexts(lines)
        val passengerName = extractPassengerName(normalizedLines)
        val addresses = extractAddresses(normalizedLines, passengerName)
        val offerMetrics = extractOfferMetrics(normalizedLines)

        return MoveSjParsedOffer(
            passengerName = passengerName,
            originAddress = addresses.originAddress,
            destinationAddress = addresses.destinationAddress,
            stopAddresses = addresses.stopAddresses,
            metrics = offerMetrics,
        )
    }

    private fun extractOfferMetrics(lines: List<String>): MoveSjOfferMetrics {
        // Primeiro tenta ler as metricas principais da oferta:
        // "8,0 km (R$ .../km)" e "22 min (R$ .../min)".
        var totalKm = 0.0
        var totalMinutes = 0

        lines.forEach { line ->
            if (totalKm <= 0) {
                val kmValue =
                    offerDistanceRegex.find(line)
                        ?.groupValues
                        ?.getOrNull(1)
                        ?.let(::parseOcrDecimalNumber)
                if (kmValue != null && kmValue > 0) {
                    totalKm = kmValue
                }
            }

            if (totalMinutes <= 0) {
                val minuteValue =
                    offerMinutesRegex.find(line)
                        ?.groupValues
                        ?.getOrNull(1)
                        ?.let(::parseDurationMinutes)
                if (minuteValue != null && minuteValue > 0) {
                    totalMinutes = minuteValue
                }
            }
        }

        // Se as metricas principais falharem, soma os trechos da rota:
        // origem -> parada -> destino. Isso salva casos onde a MoveSJ exibe so os passos.
        if (totalKm <= 0 || totalMinutes <= 0) {
            var fallbackKm = 0.0
            var fallbackMinutes = 0

            lines.forEach { line ->
                val routeMatch = routeStepRegex.find(line) ?: return@forEach
                val routeText = routeMatch.value

                if (totalKm <= 0) {
                    val routeKm = parseRouteDistanceKm(routeText)
                    if (routeKm != null) {
                        fallbackKm += routeKm
                    }
                }

                if (totalMinutes <= 0) {
                    val routeMinutes =
                        Regex("\\(((?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min)\\)", RegexOption.IGNORE_CASE)
                            .find(routeText)
                            ?.groupValues
                            ?.getOrNull(1)
                            ?.let(::parseDurationMinutes)
                    if (routeMinutes != null) {
                        fallbackMinutes += routeMinutes
                    }
                }
            }

            if (totalKm <= 0 && fallbackKm > 0) {
                totalKm = fallbackKm
            }
            if (totalMinutes <= 0 && fallbackMinutes > 0) {
                totalMinutes = fallbackMinutes
            }
        }

        return MoveSjOfferMetrics(
            totalKm = roundKm(totalKm),
            totalMinutes = totalMinutes,
        )
    }

    private fun extractOfferDetailsFromOcrRegions(regions: MoveSjOcrRegions): MoveSjParsedOffer {
        val passengerName =
            extractPassengerNameFromOcrLines(
                lines = regions.passengerLines,
                pageWidth = regions.pageWidth,
                cardTop = regions.cardTop,
                firstRouteTop = regions.firstRouteTop,
            )
        val addresses = extractAddressesFromOcrLines(regions.routeLines, passengerName)
        val offerMetrics =
            extractOfferMetrics(regions.metricLines.map { it.text }).let { regionalMetrics ->
                if (regionalMetrics.totalKm > 0 && regionalMetrics.totalMinutes > 0) {
                    regionalMetrics
                } else {
                    extractOfferMetrics(regions.allLines.map { it.text })
                }
            }

        return MoveSjParsedOffer(
            passengerName = passengerName,
            originAddress = addresses.originAddress,
            destinationAddress = addresses.destinationAddress,
            stopAddresses = addresses.stopAddresses,
            metrics = offerMetrics,
        )
    }

    private fun buildDynamicOcrRegions(lines: List<OcrLine>): MoveSjOcrRegions {
        val pageWidth = inferPageWidth(lines)
        val firstRouteTop = firstRouteTop(lines)
        val mainPriceLine = resolveBestPriceLine(lines)
        val refuseBottom =
            lines
                .filter { normalizedText(it.text).contains("recusar") }
                .maxOfOrNull { it.bottom }
        val cardTop =
            listOfNotNull(refuseBottom, mainPriceLine?.top?.minus(120))
                .minOrNull()
                ?.coerceAtLeast(0)
                ?: 0
        val cardBottom =
            listOf(firstRouteTop, mainPriceLine?.bottom?.plus(320) ?: Int.MAX_VALUE)
                .minOrNull()
                ?: firstRouteTop
        val broadPassengerLines =
            lines.filter { line ->
                line.left < pageWidth * 0.40f &&
                    line.top >= cardTop &&
                    line.top < cardBottom
            }
        val ratingLine =
            resolvePassengerCardRatingLine(
                lines = broadPassengerLines,
                pageWidth = pageWidth,
                cardTop = cardTop,
                cardBottom = cardBottom,
            )
        val passengerTop =
            ratingLine
                ?.top
                ?.minus(180)
                ?.coerceAtLeast(cardTop)
                ?: cardTop
        val passengerLines =
            broadPassengerLines.filter { line ->
                line.bottom >= passengerTop &&
                    line.top <= (ratingLine?.bottom?.plus(24) ?: cardBottom)
            }
        val priceLines =
            lines.filter { line ->
                line.top >= cardTop &&
                    line.top < cardBottom &&
                    line.centerX > pageWidth * 0.20f
            }
        val metricLines =
            priceLines.filter { line ->
                isOfferMetricContextLine(line.text) ||
                    passengerCandidateNameFromNoisyMetricLine(line.text) != null
            }
        val routeLines =
            if (firstRouteTop == Int.MAX_VALUE) {
                lines
            } else {
                lines.filter { it.top >= firstRouteTop }
            }

        return MoveSjOcrRegions(
            allLines = lines,
            passengerLines = passengerLines,
            priceLines = priceLines,
            metricLines = metricLines,
            routeLines = routeLines,
            pageWidth = pageWidth,
            cardTop = cardTop,
            firstRouteTop = firstRouteTop,
        )
    }
    private fun normalizeOcrLines(ocrLines: List<OcrLine>): List<OcrLine> {
        // Limpa linhas vazias, ordena de cima para baixo/esquerda para direita e remove
        // repeticoes consecutivas que o OCR pode gerar no mesmo elemento visual.
        val normalizedLines = mutableListOf<OcrLine>()

        ocrLines
            .map { it.copy(text = it.text.trim()) }
            .filter { it.text.isNotEmpty() }
            .sortedWith(compareBy<OcrLine> { it.top }.thenBy { it.left })
            .forEach { line ->
                if (normalizedLines.lastOrNull()?.text == line.text) {
                    return@forEach
                }
                normalizedLines.add(line)
            }

        return normalizedLines
    }

    internal fun resolveBestPriceText(
        lines: List<String>,
        rawText: String? = null,
    ): String? {
        // Escolhe o valor principal da chamada. O maior risco aqui e confundir
        // "R$ X/km" ou "R$ X/min" com o valor bruto da corrida.
        val firstMetricIndex = lines.indexOfFirst(::isOfferMetricContextLine)
        val linesBeforeMetrics =
            if (firstMetricIndex > 0) {
                lines.subList(0, firstMetricIndex)
            } else {
                lines
            }

        linesBeforeMetrics
            .firstNotNullOfOrNull(::extractPriceFromCandidateLine)
            ?.let { return it }

        lines
            .firstNotNullOfOrNull(::extractPriceFromCandidateLine)
            ?.let { return it }

        val fallbackLine =
            linesBeforeMetrics.firstOrNull { line ->
                priceRegex.containsMatchIn(line) && !isDerivedMetricPriceLine(line)
            }
                ?: lines.firstOrNull { line ->
                priceRegex.containsMatchIn(line) && !isDerivedMetricPriceLine(line)
            }
        if (fallbackLine != null) {
            return priceRegex.find(fallbackLine)?.value?.let(::normalizePriceText)
        }

        return rawText?.let { priceRegex.find(it)?.value?.let(::normalizePriceText) }
    }

    private fun extractBestPrice(
        rawText: String,
        ocrLines: List<OcrLine>,
    ): String? {
        // Na tela real existem precos repetidos e precos derivados. A escolha usa:
        // 1) estar antes das metricas, 2) nao ser /km ou /min, 3) area visual,
        // 4) proximidade do centro, 5) posicao vertical.
        val normalizedLines = normalizeOcrLines(ocrLines)
        val firstMetricTop =
            normalizedLines
                .filter { isOfferMetricContextLine(it.text) }
                .minOfOrNull { it.top }
                ?: Int.MAX_VALUE
        val pageWidth = inferPageWidth(normalizedLines)

        val priceCandidates =
            normalizedLines
                .mapNotNull { line ->
                    val price = priceRegex.find(line.text)?.value?.let(::normalizePriceText) ?: return@mapNotNull null
                    PriceCandidate(
                        price = price,
                        line = line,
                        area = (line.right - line.left) * (line.bottom - line.top),
                        isDerived = isDerivedMetricPriceLine(line.text),
                        isPriceOnly = priceRegex.matches(line.text.trim()),
                        isBeforeMetrics = line.bottom <= firstMetricTop,
                        distanceToCenter = abs(line.centerX - (pageWidth / 2)),
                    )
                }.sortedWith(
                    compareByDescending<PriceCandidate> { if (it.isBeforeMetrics && !it.isDerived) 1 else 0 }
                        .thenByDescending { if (it.isPriceOnly) 1 else 0 }
                        .thenByDescending { it.area }
                        .thenBy { it.distanceToCenter }
                        .thenBy { it.line.top },
                )

        priceCandidates.firstOrNull { it.isBeforeMetrics && !it.isDerived }?.let { candidate ->
            return candidate.price
        }

        priceCandidates.firstOrNull { !it.isDerived }?.let { candidate ->
            return candidate.price
        }

        return resolveBestPriceText(ocrLines.map { it.text }, rawText)
    }

    private fun resolveBestPriceLine(ocrLines: List<OcrLine>): OcrLine? {
        // Retorna a linha do valor principal para ajudar outros calculos posicionais,
        // principalmente a area provavel do cartao do passageiro.
        val normalizedLines = normalizeOcrLines(ocrLines)
        val firstMetricTop =
            normalizedLines
                .filter { isOfferMetricContextLine(it.text) }
                .minOfOrNull { it.top }
                ?: Int.MAX_VALUE
        val pageWidth = inferPageWidth(normalizedLines)

        return normalizedLines
            .mapNotNull { line ->
                val price = priceRegex.find(line.text)?.value?.let(::normalizePriceText) ?: return@mapNotNull null
                PriceCandidate(
                    price = price,
                    line = line,
                    area = (line.right - line.left) * (line.bottom - line.top),
                    isDerived = isDerivedMetricPriceLine(line.text),
                    isPriceOnly = priceRegex.matches(line.text.trim()),
                    isBeforeMetrics = line.bottom <= firstMetricTop,
                    distanceToCenter = abs(line.centerX - (pageWidth / 2)),
                )
            }.sortedWith(
                compareByDescending<PriceCandidate> { if (it.isBeforeMetrics && !it.isDerived) 1 else 0 }
                    .thenByDescending { if (it.isPriceOnly) 1 else 0 }
                    .thenByDescending { it.area }
                    .thenBy { it.distanceToCenter }
                    .thenBy { it.line.top },
            )
            .firstOrNull { !it.isDerived }
            ?.line
    }

    private fun extractPriceFromCandidateLine(line: String): String? {
        // So aceita linha que seja praticamente o preco puro. Linhas de metrica sao descartadas.
        if (isDerivedMetricPriceLine(line)) {
            return null
        }

        return when {
            priceRegex.matches(line.trim()) -> normalizePriceText(line.trim())
            else -> null
        }
    }

    private fun normalizePriceText(value: String): String {
        val amount =
            Regex("\\d+(?:[.,]\\d+)?")
                .find(value)
                ?.value
                ?.replace(".", ",")
                ?: return value.trim()

        return "R$ $amount"
    }

    private fun isDerivedMetricPriceLine(line: String): Boolean {
        // Preco derivado e o valor por km/min, nao o valor bruto da corrida.
        val normalized = normalizedText(line)
        return normalized.contains("/km") || normalized.contains("/min")
    }

    private fun isOfferMetricContextLine(line: String): Boolean {
        // Qualquer linha de metrica define a regiao depois do valor principal.
        return offerDistanceRegex.containsMatchIn(line) ||
            offerMinutesRegex.containsMatchIn(line) ||
            isDerivedMetricPriceLine(line)
    }

    private fun extractBestRating(
        ocrLines: List<OcrLine>,
        pageWidth: Int = inferPageWidth(ocrLines),
    ): String? {
        // A avaliacao costuma ficar no card do passageiro, no lado esquerdo da tela.
        return ocrLines.firstOrNull { line ->
            line.centerX < pageWidth * 0.45f &&
                (ratingRegex.containsMatchIn(line.text) || ratingValueRegex.matches(line.text.trim()))
        }?.text?.let(::extractRatingTextFromLine)
    }

    private fun normalizeVisibleTexts(lines: List<String>): List<String> {
        // Normalizacao simples para fluxo textual: remove vazios e duplicados consecutivos.
        val normalizedLines = mutableListOf<String>()

        lines.forEach { rawLine ->
            val trimmed = rawLine.trim()
            if (trimmed.isEmpty()) {
                return@forEach
            }

            if (normalizedLines.lastOrNull() == trimmed) {
                return@forEach
            }

            normalizedLines.add(trimmed)
        }

        return normalizedLines
    }

    private fun extractPassengerName(lines: List<String>): String? {
        // Sem coordenadas, tenta encontrar o passageiro perto da avaliacao ou antes das metricas.
        val ratingIndex =
            lines.indexOfFirst { line ->
                ratingRegex.containsMatchIn(line) || ratingValueRegex.matches(line.trim())
            }
        if (ratingIndex >= 0) {
            for (index in (ratingIndex - 1).coerceAtLeast(0) downTo (ratingIndex - 3).coerceAtLeast(0)) {
                val candidate = lines[index]
                if (isPassengerCandidate(candidate)) {
                    return candidate
                }
            }
        }

        val metricsIndex =
            lines.indexOfFirst { line ->
                offerDistanceRegex.containsMatchIn(line) || offerMinutesRegex.containsMatchIn(line)
            }
        val headerCandidates =
            if (metricsIndex > 0) lines.take(metricsIndex) else lines

        headerCandidates.lastOrNull(::isPassengerCandidate)?.let { return it }
        lines.firstOrNull(::isPassengerCandidate)?.let { return it }
        return null
    }

    private fun extractPassengerNameFromOcrLines(
        lines: List<OcrLine>,
        pageWidth: Int,
        cardTop: Int,
        firstRouteTop: Int,
    ): String? {
        // O nome so concorre com textos da regiao esquerda do card e continua ancorado na nota.
        val cardBottom =
            lines.maxOfOrNull { it.bottom }
                ?.coerceAtMost(firstRouteTop)
                ?: firstRouteTop
        val ratingLine = resolvePassengerCardRatingLine(lines, pageWidth, cardTop, cardBottom)
            ?: return extractPassengerNameFromPassengerCardArea(
                lines = lines,
                pageWidth = pageWidth,
                cardTop = cardTop,
                firstRouteTop = firstRouteTop,
            )

        // Alguns OCRs juntam "Nome 5,00" na mesma linha; outros separam nome e nota.
        passengerCandidateName(ratingLine.text)?.let { return it }

        return lines
            .filter { line ->
                isPassengerNameLineAboveRating(line, ratingLine, pageWidth, cardTop, firstRouteTop)
            }
            .sortedByDescending { it.top }
            .firstNotNullOfOrNull { passengerCandidateName(it.text) }
            ?: extractPassengerNameFromPassengerCardArea(
                lines = lines,
                pageWidth = pageWidth,
                cardTop = cardTop,
                firstRouteTop = firstRouteTop,
            )
    }

    private fun extractPassengerNameFromPassengerCardArea(
        lines: List<OcrLine>,
        pageWidth: Int,
        cardTop: Int,
        firstRouteTop: Int,
    ): String? {
        return lines
            .filter { line ->
                line.left < pageWidth * 0.35f &&
                    line.top >= cardTop &&
                    line.top < firstRouteTop &&
                    line.text.any { it.isLetter() }
            }
            .sortedByDescending { it.top }
            .firstNotNullOfOrNull { line ->
                passengerCandidateNameFromNoisyMetricLine(line.text)
                    ?: passengerCandidateName(line.text)
            }
    }

    private fun resolvePassengerCardRatingLine(
        lines: List<OcrLine>,
        pageWidth: Int,
        cardTop: Int,
        cardBottom: Int,
    ): OcrLine? {
        return lines
            .filter { line ->
                isInsidePassengerCardArea(line, pageWidth, cardTop, cardBottom) &&
                    isPassengerRatingLine(line.text)
            }
            .sortedBy { it.top }
            .firstOrNull()
    }

    private fun isPassengerNameLineAboveRating(
        line: OcrLine,
        ratingLine: OcrLine,
        pageWidth: Int,
        cardTop: Int,
        firstRouteTop: Int,
    ): Boolean {
        val verticalGap = ratingLine.top - line.bottom
        return line.centerX < pageWidth * 0.45f &&
            line.top >= cardTop &&
            line.bottom <= ratingLine.top &&
            line.top < firstRouteTop &&
            verticalGap in -8..90
    }

    private fun isPassengerCandidate(line: String): Boolean {
        return passengerCandidateName(line) != null
    }

    private fun passengerCandidateName(line: String): String? {
        // Filtro agressivo para evitar usar bairro, mapa, botao, valor ou texto fixo como passageiro.
        val candidate = stripRatingFromPassengerCandidate(line)
        val normalized = normalizedText(line)
        val candidateNormalized = normalizedText(candidate)
        return candidate.takeIf {
            candidate.length in 3..30 &&
            candidate.any { it.isLetter() } &&
            (!line.contains(",") || isPassengerRatingLine(line)) &&
            !candidate.contains(",") &&
            (!line.any { it.isDigit() } || isPassengerRatingLine(line)) &&
            !candidate.any { it.isDigit() } &&
            !normalized.contains("deslize") &&
            !isRouteMetricLine(candidate) &&
            !normalized.contains("r$") &&
            !normalized.contains("aceitar") &&
            !normalized.contains("recusar") &&
            !normalized.contains("pix") &&
            !normalized.contains("cartao") &&
            !normalized.contains("dinheiro") &&
            !normalized.contains("move") &&
            !normalized.contains("movesj") &&
            !normalized.contains("app") &&
            !normalized.contains("corrida") &&
            !normalized.contains("motorista") &&
            !normalized.contains("sao joao") &&
            !candidateNormalized.contains("matozinhos") &&
            !candidateNormalized.contains("fabricas") &&
            !normalized.contains("centro") &&
            !ratingValueRegex.matches(candidate.trim())
        }
    }

    private fun passengerCandidateNameFromNoisyMetricLine(line: String): String? {
        val beforeMetric =
            line
                .replace(
                    Regex(
                        "(?i)(?:[\\dIlL]+(?:[.,]\\d+)?\\s*(?:km|m)|\\d+\\s*min|R\\$|RS).*$",
                    ),
                    "",
                ).replace(Regex("[^\\p{L}\\s'.-]+"), " ")
                .trim()

        val firstToken = beforeMetric.split(Regex("\\s+")).firstOrNull().orEmpty()
        val repairedToken = repairNoisyPassengerToken(firstToken)

        return passengerCandidateName(repairedToken)
    }

    private fun repairNoisyPassengerToken(token: String): String {
        val trimmed = token.trim('.', '\'', '-', ' ')
        val normalized = normalizedText(trimmed)
        val noisySuffixes = listOf("stb", "std", "sta")
        val suffix = noisySuffixes.firstOrNull { normalized.endsWith(it) }

        return if (suffix != null && trimmed.length > suffix.length + 2) {
            trimmed.dropLast(suffix.length)
        } else {
            trimmed
        }
    }

    private fun stripRatingFromPassengerCandidate(line: String): String {
        // Remove nota quando OCR junta nome e avaliacao na mesma linha.
        val withoutKnownRating = line
            .replace(ratingRegex, "")
            .replace(ratingValueRegex, "")
            .replace(Regex("[^\\p{L}\\s'.-]+"), "")
            .trim()

        if (line.contains(",")) {
            return withoutKnownRating
        }

        return withoutKnownRating
            .replace(Regex("\\s+\\d(?:[.,]\\d{1,2}).*$"), "")
            .trim()
    }

    private fun isPassengerRatingLine(line: String): Boolean {
        val normalized = normalizedText(line)
        return !isRouteMetricLine(line) &&
            !normalized.contains("r$") &&
            !normalized.contains("/km") &&
            !normalized.contains("/min") &&
            (
                ratingRegex.containsMatchIn(line) ||
                    ratingValueRegex.matches(line.trim()) ||
                    ratingNumberRegex.containsMatchIn(line)
            )
    }

    private fun isInsidePassengerCardArea(
        line: OcrLine,
        pageWidth: Int,
        cardTop: Int,
        cardBottom: Int,
    ): Boolean {
        // O card do passageiro fica no lado esquerdo da chamada da MoveSJ.
        return line.centerX < pageWidth * 0.45f &&
            line.top >= cardTop &&
            line.top < cardBottom
    }

    private fun extractAddresses(
        lines: List<String>,
        passengerName: String?,
    ): MoveSjRouteAddresses {
        // Fluxo textual: cada trecho de rota indica que as proximas linhas formam um endereco.
        val routeAddresses = mutableListOf<String>()

        lines.forEachIndexed { index, line ->
            if (!isRouteStepAnchorLine(line)) {
                return@forEachIndexed
            }

            val addressBlock =
                buildAddressBlock(
                    lines = lines,
                    startIndex = index + 1,
                    passengerName = passengerName,
                )
            if (addressBlock != null) {
                routeAddresses.add(addressBlock)
            }
        }

        val fallbackAddresses = buildFallbackAddressBlocks(lines, passengerName)
        // Junta candidatos do caminho principal e fallback, removendo duplicatas.
        val distinctAddresses = distinctAddressBlocks(routeAddresses + fallbackAddresses)

        return toRouteAddresses(distinctAddresses)
    }

    private fun extractAddressesFromOcrLines(
        lines: List<OcrLine>,
        passengerName: String?,
    ): MoveSjRouteAddresses {
        // Fluxo posicional: usa a coordenada vertical de cada trecho para pegar o endereco abaixo
        // dele e parar antes do proximo trecho.
        val routeLines =
            lines
                .filter { line ->
                    isPositionedRouteStepAnchorLine(line, lines)
                }
                .sortedBy { it.top }

        if (routeLines.isEmpty()) {
            // Se o OCR nao achou trechos posicionais, volta para a estrategia textual.
            return extractAddresses(lines.map { it.text }, passengerName)
        }

        val addressBlocks =
            routeLines.mapIndexedNotNull { index, routeLine ->
                val nextRouteTop = routeLines.getOrNull(index + 1)?.top ?: Int.MAX_VALUE
                extractAddressBlockBelowRouteLine(
                    lines = lines,
                    routeLine = routeLine,
                    nextRouteTop = nextRouteTop,
                    passengerName = passengerName,
                )
            }

        val distinctAddresses = distinctAddressBlocks(addressBlocks)
        if (distinctAddresses.size >= 2) {
            // Com duas ou mais rotas, primeira e origem; ultima e destino.
            return toRouteAddresses(distinctAddresses)
        }

        return extractAddresses(lines.map { it.text }, passengerName)
    }

    private fun toRouteAddresses(addresses: List<String>): MoveSjRouteAddresses {
        // Se houver parada, o destino deve ser o ultimo endereco, nao o segundo.
        val originAddress = addresses.firstOrNull()
        val destinationAddress =
            when {
                addresses.size >= 3 -> addresses.lastOrNull()
                else -> addresses.getOrNull(1)
            }
        return MoveSjRouteAddresses(
            originAddress = originAddress,
            destinationAddress = destinationAddress,
            stopAddresses = emptyList(),
        )
    }

    private fun extractAddressBlockBelowRouteLine(
        lines: List<OcrLine>,
        routeLine: OcrLine,
        nextRouteTop: Int,
        passengerName: String?,
    ): String? {
        // Captura linhas de endereco entre o trecho atual e o proximo trecho de rota.
        val collected = mutableListOf<String>()
        extractInlineAddressFromRouteLine(routeLine.text, passengerName)?.let(collected::add)

        lines
            .filter { line ->
                line.top > routeLine.top &&
                    line.top < nextRouteTop &&
                    isRouteAddressCandidate(line.text, passengerName)
            }
            .sortedWith(compareBy<OcrLine> { it.top }.thenBy { it.left })
            .forEach { line ->
                collected.add(line.text)
            }

        return joinAddressLines(collected)
    }

    private fun buildAddressBlock(
        lines: List<String>,
        startIndex: Int,
        passengerName: String?,
    ): String? {
        // Captura o bloco de endereco em texto corrido, logo apos a linha do trecho.
        val collected = mutableListOf<String>()
        val routeLine = lines.getOrNull(startIndex - 1)
        extractInlineAddressFromRouteLine(routeLine, passengerName)?.let(collected::add)

        for (index in startIndex until lines.size) {
            val candidate = lines[index]
            if (isRouteStepBoundaryLine(candidate)) {
                break
            }

            if (!isRouteAddressCandidate(candidate, passengerName)) {
                if (collected.isNotEmpty()) {
                    break
                }
                continue
            }

            collected.add(candidate)

            // Alguns destinos longos da MoveSj quebram em 4 linhas.
            if (collected.size >= 4) {
                break
            }
        }

        return joinAddressLines(collected)
    }

    private fun extractInlineAddressFromRouteLine(
        routeLine: String?,
        passengerName: String?,
    ): String? {
        // Algumas leituras vem como "1,5 km (4 min) Rua X". Aqui separa so a parte do endereco.
        if (routeLine.isNullOrBlank()) {
            return null
        }

        val routeMatch = routeStepPrefixRegex.find(routeLine) ?: return null
        val inlineAddress = routeLine.substring(routeMatch.range.last + 1).trim()
        if (!isRouteAddressCandidate(inlineAddress, passengerName)) {
            return null
        }

        return inlineAddress
    }

    private fun buildFallbackAddressBlocks(
        lines: List<String>,
        passengerName: String?,
    ): List<String> {
        // Fallback para quando os marcadores de trecho nao organizam bem o texto.
        // Ele acumula blocos que parecem endereco e quebra ao encontrar algo que nao parece.
        val blocks = mutableListOf<String>()
        val currentBlock = mutableListOf<String>()

        fun flushCurrentBlock() {
            val addressBlock = joinAddressLines(currentBlock)
            if (addressBlock != null) {
                blocks.add(addressBlock)
            }
            currentBlock.clear()
        }

        for (line in lines) {
            if (isRouteStepBoundaryLine(line)) {
                flushCurrentBlock()
                continue
            }

            if (!isAddressCandidate(line, passengerName)) {
                flushCurrentBlock()
                continue
            }

            currentBlock.add(line)
            if (currentBlock.size >= 4) {
                flushCurrentBlock()
            }
        }

        flushCurrentBlock()
        return blocks
    }

    private fun distinctAddressBlocks(blocks: List<String>): List<String> {
        // Remove enderecos repetidos comparando texto normalizado sem espacos.
        val distinctBlocks = mutableListOf<String>()
        val seen = mutableSetOf<String>()

        blocks.forEach { block ->
            val normalized = normalizedText(block).replace(" ", "")
            if (normalized.isBlank() || !seen.add(normalized)) {
                return@forEach
            }

            distinctBlocks.add(block)
        }

        return distinctBlocks
    }

    private fun joinAddressLines(lines: List<String>): String? {
        // Enderecos longos geralmente chegam quebrados em varias linhas.
        return lines
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .joinToString(separator = " ")
            .takeIf { it.isNotBlank() }
    }

    private fun isAddressCandidate(
        line: String,
        passengerName: String?,
    ): Boolean {
        // Decide se uma linha pode ser parte de endereco. Rejeita botoes, metricas, preco,
        // passageiro e textos fixos para reduzir falso positivo.
        val normalized = normalizedText(line)
        val hasStreetLikeStructure =
            line.length >= 6 &&
                (line.contains(",") || line.any { it.isDigit() })

        return (line.length >= 10 || hasStreetLikeStructure) &&
            line.any { it.isLetter() } &&
            (passengerName == null || normalized != normalizedText(passengerName)) &&
            !normalized.contains("move") &&
            !normalized.contains("movesj") &&
            !normalized.contains("deslize") &&
            !normalized.contains("aceitar") &&
            !normalized.contains("recusar") &&
            !isRouteMetricLine(line) &&
            !normalized.contains("r$") &&
            !normalized.contains("pix") &&
            !normalized.contains("cartao") &&
            !normalized.contains("dinheiro") &&
            !normalized.contains("motorista") &&
            !ratingRegex.containsMatchIn(line) &&
            !ratingValueRegex.matches(line.trim())
    }

    private fun isRouteAddressCandidate(
        line: String,
        passengerName: String?,
    ): Boolean {
        return isAddressCandidate(line, passengerName) || isPlaceNameCandidate(line, passengerName)
    }

    private fun isPlaceNameCandidate(
        line: String,
        passengerName: String?,
    ): Boolean {
        val trimmed = line.trim()
        val normalized = normalizedText(trimmed)
        val words = normalized.split(Regex("\\s+")).filter { it.isNotBlank() }

        return trimmed.length in 5..80 &&
            trimmed.any { it.isLetter() } &&
            words.size <= 6 &&
            (passengerName == null || normalized != normalizedText(passengerName)) &&
            !normalized.contains("move") &&
            !normalized.contains("movesj") &&
            !normalized.contains("deslize") &&
            !normalized.contains("aceitar") &&
            !normalized.contains("recusar") &&
            !isRouteMetricLine(trimmed) &&
            !normalized.contains("r$") &&
            !normalized.contains("pix") &&
            !normalized.contains("cartao") &&
            !normalized.contains("dinheiro") &&
            !normalized.contains("motorista") &&
            !ratingRegex.containsMatchIn(trimmed) &&
            !ratingValueRegex.matches(trimmed)
    }

    private fun isRouteMetricLine(line: String): Boolean {
        // Qualquer metrica de rota/oferta nao pode virar passageiro nem endereco.
        return isRouteStepBoundaryLine(line) ||
            offerDistanceRegex.containsMatchIn(line) ||
            offerMinutesRegex.containsMatchIn(line)
    }

    private fun isRouteStepBoundaryLine(line: String): Boolean {
        return isRouteStepAnchorLine(line) || routeDurationOnlyRegex.matches(line.trim())
    }

    private fun isRouteStepAnchorLine(line: String): Boolean {
        val trimmed = line.trim()
        return trimmed.isNotEmpty() &&
            !isDerivedMetricPriceLine(trimmed) &&
            !priceRegex.containsMatchIn(trimmed) &&
            (routeStepRegex.containsMatchIn(trimmed) || routeStepAnchorRegex.matches(trimmed))
    }

    private fun isPositionedRouteStepAnchorLine(
        line: OcrLine,
        allLines: List<OcrLine>,
    ): Boolean {
        if (!isRouteStepAnchorLine(line.text)) {
            return false
        }

        val pageWidth = inferPageWidth(allLines)
        return line.centerX < pageWidth * 0.55f
    }

    private fun inferPageWidth(lines: List<OcrLine>): Int {
        // A largura inferida permite raciocinar sobre lado esquerdo/centro da tela.
        return lines.maxOfOrNull { it.right }?.coerceAtLeast(1) ?: 1
    }

    private fun firstRouteTop(lines: List<OcrLine>): Int {
        // Inicio da rota na tela. Ajuda a separar card do passageiro de enderecos.
        return lines
            .filter { line ->
                isPositionedRouteStepAnchorLine(line, lines)
            }
            .minOfOrNull { it.top }
            ?: Int.MAX_VALUE
    }

    private fun normalizedText(value: String?): String {
        // Normalizacao para comparacoes robustas: remove acentos e deixa minusculo.
        if (value.isNullOrBlank()) {
            return ""
        }

        val normalized =
            Normalizer.normalize(value, Normalizer.Form.NFD)
                .replace("\\p{InCombiningDiacriticalMarks}+".toRegex(), "")

        return normalized.lowercase()
    }

    private fun parseRouteDistanceKm(routeText: String): Double? {
        // Converte distancia de trecho para km, aceitando "m" e "km".
        val match =
            Regex("([\\dIlL]+(?:[.,]\\d+)?)\\s*(km|m)", RegexOption.IGNORE_CASE)
                .find(routeText)
                ?: return null

        val rawValue =
            match.groupValues
                .getOrNull(1)
                ?.let(::parseOcrDecimalNumber)
                ?: return null
        val unit = match.groupValues.getOrNull(2)?.lowercase()

        return when (unit) {
            "km" -> rawValue
            "m" -> rawValue / 1000.0
            else -> null
        }
    }

    private fun parseOcrDecimalNumber(value: String): Double? {
        return value
            .replace("I", "1", ignoreCase = true)
            .replace("l", "1", ignoreCase = true)
            .replace(",", ".")
            .toDoubleOrNull()
    }

    private fun parseDurationMinutes(durationText: String): Int? {
        // Converte "1 hora 6 min" ou "22 min" para minutos totais.
        val normalized = normalizedText(durationText)
        val hourMatch = Regex("(\\d+)\\s*hora").find(normalized)
        val minuteMatch = Regex("(\\d+)\\s*min").find(normalized)

        val hours = hourMatch?.groupValues?.getOrNull(1)?.toIntOrNull() ?: 0
        val minutes = minuteMatch?.groupValues?.getOrNull(1)?.toIntOrNull() ?: 0
        val total = (hours * 60) + minutes

        return total.takeIf { it > 0 }
    }

    private fun roundKm(value: Double): Double {
        // Mantem tres casas por truncamento, seguindo o comportamento original do parser.
        return (value * 1000).toInt() / 1000.0
    }

    private fun sanitizeRating(ratingText: String?): String {
        // Remove estrela e usa 5,00 como padrao quando a tela nao trouxe avaliacao confiavel.
        return ratingText
            ?.replace("\u2605", "")
            ?.replace("\u2B50", "")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "5,00"
    }

    private fun extractRatingTextFromLine(line: String): String? {
        // Extrai a nota tanto quando vem com estrela quanto quando vem so "5,00".
        return ratingRegex.find(line)?.value?.let(::sanitizeRating)
            ?: line.trim().takeIf { ratingValueRegex.matches(it) }?.let(::sanitizeRating)
    }

    // Estruturas internas para manter as etapas do parser tipadas antes de virar Map.
    private data class MoveSjOfferMetrics(
        val totalKm: Double,
        val totalMinutes: Int,
    )

    private data class MoveSjOcrRegions(
        val allLines: List<OcrLine>,
        val passengerLines: List<OcrLine>,
        val priceLines: List<OcrLine>,
        val metricLines: List<OcrLine>,
        val routeLines: List<OcrLine>,
        val pageWidth: Int,
        val cardTop: Int,
        val firstRouteTop: Int,
    )

    private data class MoveSjParsedOffer(
        val passengerName: String?,
        val originAddress: String?,
        val destinationAddress: String?,
        val stopAddresses: List<String>,
        val metrics: MoveSjOfferMetrics,
    )

    private data class MoveSjRouteAddresses(
        val originAddress: String?,
        val destinationAddress: String?,
        val stopAddresses: List<String>,
    )

    private data class PriceCandidate(
        val price: String,
        val line: OcrLine,
        val area: Int,
        val isDerived: Boolean,
        val isPriceOnly: Boolean,
        val isBeforeMetrics: Boolean,
        val distanceToCenter: Int,
    )
}
