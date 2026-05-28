package com.example.direcao_financeira_mobile.parsers

import java.text.Normalizer
import kotlin.math.abs

class MoveSjParser {

    private val priceRegex = Regex("R\\$\\s*\\d+(?:[.,]\\d+)?")
    private val ratingRegex =
        Regex("\\d+(?:[.,]\\d+)?\\s*[\\u2605\\u2B50]", RegexOption.IGNORE_CASE)
    private val ratingValueRegex =
        Regex("^\\d(?:[.,]\\d{1,2})\\s*(?:[\\u2605\\u2B50])?$", RegexOption.IGNORE_CASE)
    private val routeStepRegex =
        Regex(
            "\\d+(?:[.,]\\d+)?\\s*(?:km|m)\\s*\\((?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min\\)",
            RegexOption.IGNORE_CASE,
        )
    private val offerDistanceRegex =
        Regex(
            "(\\d+(?:[.,]\\d+)?)\\s*km\\s*\\(\\s*R\\$\\s*\\d+(?:[.,]\\d+)?\\s*/\\s*km\\s*\\)",
            RegexOption.IGNORE_CASE,
        )
    private val offerMinutesRegex =
        Regex(
            "((?:(?:\\d+)\\s*hora(?:s)?\\s*)?(?:\\d+)\\s*min)\\s*\\(\\s*R\\$\\s*\\d+(?:[.,]\\d+)?\\s*/\\s*min\\s*\\)",
            RegexOption.IGNORE_CASE,
        )
    private val actionMarkers =
        listOf(
            "deslize para recusar",
            "deslize para aceitar",
            "recusar",
            "aceitar",
        )
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
        if (rawText.isBlank()) {
            return null
        }

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
        if (rawText.isBlank() || ocrLines.isEmpty()) {
            return null
        }

        val orderedLines =
            ocrLines
                .filter { it.text.trim().isNotEmpty() }
                .sortedWith(compareBy<OcrLine> { it.top }.thenBy { it.left })

        val textLines = orderedLines.map { it.text.trim() }
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
        val textLines = ocrLines.map { it.text.trim() }
        val parsedOffer = extractOfferDetailsFromOcrLines(ocrLines)

        return mutableMapOf<String, Any>(
            "app" to "MoveSj",
            "platform_name" to "MoveSj",
            "valor_bruto" to (extractBestPrice(rawText, ocrLines) ?: "R$ 0,00"),
            "km_total" to parsedOffer.metrics.totalKm,
            "minutos_total" to parsedOffer.metrics.totalMinutes,
            "avaliacao" to sanitizeRating(extractBestRating(ocrLines)),
            "passenger_name" to (parsedOffer.passengerName ?: ""),
            "origin_address" to (parsedOffer.originAddress ?: ""),
            "destination_address" to (parsedOffer.destinationAddress ?: ""),
        ).also {
            if (it["km_total"] == 0.0 || it["minutos_total"] == 0) {
                val fallback = extractOfferDetails(textLines)
                it["km_total"] = fallback.metrics.totalKm
                it["minutos_total"] = fallback.metrics.totalMinutes
            }
        }
    }

    internal fun isOfferScreenFromLines(lines: List<String>): Boolean {
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
        var totalKm = 0.0
        var totalMinutes = 0

        lines.forEach { line ->
            if (totalKm <= 0) {
                val kmValue =
                    offerDistanceRegex.find(line)
                        ?.groupValues
                        ?.getOrNull(1)
                        ?.replace(",", ".")
                        ?.toDoubleOrNull()
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

    private fun extractOfferDetailsFromOcrLines(ocrLines: List<OcrLine>): MoveSjParsedOffer {
        val normalizedLines = normalizeOcrLines(ocrLines)
        val textLines = normalizedLines.map { it.text }
        val passengerName = extractPassengerNameFromOcrLines(normalizedLines)
        val addresses = extractAddressesFromOcrLines(normalizedLines, passengerName)
        val offerMetrics = extractOfferMetrics(textLines)

        return MoveSjParsedOffer(
            passengerName = passengerName,
            originAddress = addresses.originAddress,
            destinationAddress = addresses.destinationAddress,
            stopAddresses = addresses.stopAddresses,
            metrics = offerMetrics,
        )
    }

    private fun normalizeOcrLines(ocrLines: List<OcrLine>): List<OcrLine> {
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
            return priceRegex.find(fallbackLine)?.value
        }

        return rawText?.let { priceRegex.find(it)?.value }
    }

    private fun extractBestPrice(
        rawText: String,
        ocrLines: List<OcrLine>,
    ): String? {
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
                    val price = priceRegex.find(line.text)?.value ?: return@mapNotNull null
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

    private fun extractPriceFromCandidateLine(line: String): String? {
        if (isDerivedMetricPriceLine(line)) {
            return null
        }

        return when {
            priceRegex.matches(line.trim()) -> line.trim()
            else -> null
        }
    }

    private fun isDerivedMetricPriceLine(line: String): Boolean {
        val normalized = normalizedText(line)
        return normalized.contains("/km") || normalized.contains("/min")
    }

    private fun isOfferMetricContextLine(line: String): Boolean {
        return offerDistanceRegex.containsMatchIn(line) ||
            offerMinutesRegex.containsMatchIn(line) ||
            isDerivedMetricPriceLine(line)
    }

    private fun extractBestRating(ocrLines: List<OcrLine>): String? {
        val pageWidth = inferPageWidth(ocrLines)
        return ocrLines.firstOrNull { line ->
            line.centerX < pageWidth * 0.45f &&
                (ratingRegex.containsMatchIn(line.text) || ratingValueRegex.matches(line.text.trim()))
        }?.text
    }

    private fun normalizeVisibleTexts(lines: List<String>): List<String> {
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

    private fun extractPassengerNameFromOcrLines(lines: List<OcrLine>): String? {
        val pageWidth = inferPageWidth(lines)
        val firstMetricTop =
            lines.firstOrNull { offerDistanceRegex.containsMatchIn(it.text) || offerMinutesRegex.containsMatchIn(it.text) }
                ?.top
                ?: Int.MAX_VALUE

        val ratingLine =
            lines.firstOrNull { line ->
                line.centerX < pageWidth * 0.45f &&
                    (ratingRegex.containsMatchIn(line.text) || ratingValueRegex.matches(line.text.trim()))
            }

        if (ratingLine != null) {
            lines
                .filter { it.bottom <= ratingLine.top && it.centerX < pageWidth * 0.45f }
                .sortedByDescending { it.top }
                .firstOrNull { isPassengerCandidate(it.text) }
                ?.let { return it.text }
        }

        return lines
            .filter { it.centerX < pageWidth * 0.45f && it.top < firstRouteTop(lines) }
            .sortedByDescending { it.top }
            .firstOrNull { isPassengerCandidate(it.text) }
            ?.text
    }

    private fun isPassengerCandidate(line: String): Boolean {
        val normalized = normalizedText(line)
        return line.length in 3..30 &&
            line.any { it.isLetter() } &&
            !line.contains(",") &&
            !line.any { it.isDigit() } &&
            !normalized.contains("deslize") &&
            !isRouteMetricLine(line) &&
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
            !normalized.contains("centro") &&
            !ratingRegex.containsMatchIn(line) &&
            !ratingValueRegex.matches(line.trim())
    }

    private fun extractAddresses(
        lines: List<String>,
        passengerName: String?,
    ): MoveSjRouteAddresses {
        val routeAddresses = mutableListOf<String>()

        lines.forEachIndexed { index, line ->
            if (!routeStepRegex.containsMatchIn(line)) {
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
        val distinctAddresses = distinctAddressBlocks(routeAddresses + fallbackAddresses)

        return toRouteAddresses(distinctAddresses)
    }

    private fun extractAddressesFromOcrLines(
        lines: List<OcrLine>,
        passengerName: String?,
    ): MoveSjRouteAddresses {
        val routeLines =
            lines
                .filter { line ->
                    routeStepRegex.containsMatchIn(line.text) &&
                        !line.text.contains("R$", ignoreCase = true)
                }
                .sortedBy { it.top }

        if (routeLines.isEmpty()) {
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
            return toRouteAddresses(distinctAddresses)
        }

        return extractAddresses(lines.map { it.text }, passengerName)
    }

    private fun toRouteAddresses(addresses: List<String>): MoveSjRouteAddresses {
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
        val collected = mutableListOf<String>()
        extractInlineAddressFromRouteLine(routeLine.text, passengerName)?.let(collected::add)

        lines
            .filter { line ->
                line.top > routeLine.top &&
                    line.top < nextRouteTop &&
                    isAddressCandidate(line.text, passengerName)
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
        val collected = mutableListOf<String>()
        val routeLine = lines.getOrNull(startIndex - 1)
        extractInlineAddressFromRouteLine(routeLine, passengerName)?.let(collected::add)

        for (index in startIndex until lines.size) {
            val candidate = lines[index]
            if (routeStepRegex.containsMatchIn(candidate)) {
                break
            }

            if (!isAddressCandidate(candidate, passengerName)) {
                if (collected.isNotEmpty()) {
                    break
                }
                continue
            }

            collected.add(candidate)

            // Endereco da MoveSj costuma vir quebrado em 1 a 3 linhas.
            if (collected.size >= 3) {
                break
            }
        }

        return joinAddressLines(collected)
    }

    private fun extractInlineAddressFromRouteLine(
        routeLine: String?,
        passengerName: String?,
    ): String? {
        if (routeLine.isNullOrBlank()) {
            return null
        }

        val routeMatch = routeStepRegex.find(routeLine) ?: return null
        val inlineAddress = routeLine.substring(routeMatch.range.last + 1).trim()
        if (!isAddressCandidate(inlineAddress, passengerName)) {
            return null
        }

        return inlineAddress
    }

    private fun buildFallbackAddressBlocks(
        lines: List<String>,
        passengerName: String?,
    ): List<String> {
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
            if (routeStepRegex.containsMatchIn(line)) {
                flushCurrentBlock()
                continue
            }

            if (!isAddressCandidate(line, passengerName)) {
                flushCurrentBlock()
                continue
            }

            currentBlock.add(line)
            if (currentBlock.size >= 3) {
                flushCurrentBlock()
            }
        }

        flushCurrentBlock()
        return blocks
    }

    private fun distinctAddressBlocks(blocks: List<String>): List<String> {
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

    private fun isRouteMetricLine(line: String): Boolean {
        return routeStepRegex.containsMatchIn(line) ||
            offerDistanceRegex.containsMatchIn(line) ||
            offerMinutesRegex.containsMatchIn(line)
    }

    private fun inferPageWidth(lines: List<OcrLine>): Int {
        return lines.maxOfOrNull { it.right }?.coerceAtLeast(1) ?: 1
    }

    private fun firstRouteTop(lines: List<OcrLine>): Int {
        return lines
            .filter { line ->
                routeStepRegex.containsMatchIn(line.text) &&
                    !line.text.contains("R$", ignoreCase = true)
            }
            .minOfOrNull { it.top }
            ?: Int.MAX_VALUE
    }

    private fun normalizedText(value: String?): String {
        if (value.isNullOrBlank()) {
            return ""
        }

        val normalized =
            Normalizer.normalize(value, Normalizer.Form.NFD)
                .replace("\\p{InCombiningDiacriticalMarks}+".toRegex(), "")

        return normalized.lowercase()
    }

    private fun parseRouteDistanceKm(routeText: String): Double? {
        val match =
            Regex("(\\d+(?:[.,]\\d+)?)\\s*(km|m)", RegexOption.IGNORE_CASE)
                .find(routeText)
                ?: return null

        val rawValue =
            match.groupValues
                .getOrNull(1)
                ?.replace(",", ".")
                ?.toDoubleOrNull()
                ?: return null
        val unit = match.groupValues.getOrNull(2)?.lowercase()

        return when (unit) {
            "km" -> rawValue
            "m" -> rawValue / 1000.0
            else -> null
        }
    }

    private fun parseDurationMinutes(durationText: String): Int? {
        val normalized = normalizedText(durationText)
        val hourMatch = Regex("(\\d+)\\s*hora").find(normalized)
        val minuteMatch = Regex("(\\d+)\\s*min").find(normalized)

        val hours = hourMatch?.groupValues?.getOrNull(1)?.toIntOrNull() ?: 0
        val minutes = minuteMatch?.groupValues?.getOrNull(1)?.toIntOrNull() ?: 0
        val total = (hours * 60) + minutes

        return total.takeIf { it > 0 }
    }

    private fun roundKm(value: Double): Double {
        return (value * 1000).toInt() / 1000.0
    }

    private fun sanitizeRating(ratingText: String?): String {
        return ratingText
            ?.replace("\u2605", "")
            ?.replace("\u2B50", "")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "5,00"
    }

    private data class MoveSjOfferMetrics(
        val totalKm: Double,
        val totalMinutes: Int,
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
