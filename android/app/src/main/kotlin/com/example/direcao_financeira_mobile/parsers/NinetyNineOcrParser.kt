package com.example.direcao_financeira_mobile.parsers

import java.text.Normalizer

class NinetyNineOcrParser {

    data class OcrLine(
        val text: String,
        val left: Int,
        val top: Int,
        val right: Int,
        val bottom: Int,
    ) {
        val area: Int
            get() = (right - left).coerceAtLeast(0) * (bottom - top).coerceAtLeast(0)
    }
    private val priceRegex = Regex("R\\$\\s*\\d+(?:[.,]\\d+)?")
    private val gainPerKmRegex = Regex("R\\$\\s*\\d+(?:[.,]\\d+)?\\s*/\\s*km", RegexOption.IGNORE_CASE)
    private val statsRegex =
        Regex("(\\d+)\\s*min(?:utos?)?\\s*\\(([0-9Il]+(?:[.,]\\d+)?)\\s*(km|m)\\)", RegexOption.IGNORE_CASE)
    private val corridasLineRegex =
        Regex("(?:^|[^\\d])([1-5](?:[.,]\\d{1,2})?)\\s*(?:[\\u2022·•]|\\.)?\\s+(\\d+)\\s*corridas\\b", RegexOption.IGNORE_CASE)
    private val ratingProfileLineRegex =
        Regex("(?:^|[^\\d])([1-5](?:[.,]\\d{1,2})?)\\s*(?:[\\u2022·•]|\\.)\\s*perfil\\b", RegexOption.IGNORE_CASE)
    private val fallbackRatingRegex = Regex("\\b\\d(?:[.,]\\d{1,2})\\b")
    private val profileRegex =
        Regex("Perfil\\s+([A-Za-zÀ-ÿ]+(?:\\s+[A-Za-zÀ-ÿ]+)*)", RegexOption.IGNORE_CASE)

    fun buildDebugSnapshot(
        rawText: String,
        lines: List<String>,
    ): Map<String, Any> {
        val passengerName = extractPassengerName(lines)
        val addresses = extractAddresses(lines, passengerName)

        return mapOf(
            "priceText" to (priceRegex.find(rawText)?.value.orEmpty()),
            "statsCount" to statsRegex.findAll(rawText).count(),
            "hasPrecoX" to normalize(rawText).contains("preco x"),
            "hasNaoAfetaTA" to normalize(rawText).contains("nao afeta a ta"),
            "passengerName" to (passengerName ?: ""),
            "offerType" to (extractOfferType(lines) ?: ""),
            "paymentMethod" to (extractPaymentMethod(lines) ?: ""),
            "rating" to (extractRating(rawText, lines) ?: ""),
            "ridesCount" to (extractRidesCount(rawText, lines) ?: 0),
            "originAddress" to (addresses.first ?: ""),
            "destinationAddress" to (addresses.second ?: ""),
            "sampleLines" to lines.take(12),
        )
    }

    fun parseOffer(
        rawText: String,
        lines: List<String>,
    ): Map<String, Any>? {
        if (rawText.isBlank()) {
            return null
        }

        val normalizedText = normalize(rawText)
        val price = priceRegex.find(rawText)?.value ?: return null
        val stats = statsRegex.findAll(rawText).toList()
        val hasMarkers =
            normalizedText.contains("preco x") ||
                normalizedText.contains("perfil") ||
                normalizedText.contains("nao afeta a ta") ||
                normalizedText.contains("aceitar por") ||
                normalizedText.contains("corridas") ||
                normalizedText.contains("tarifa base dinamica") ||
                normalizedText.contains("prioritario") ||
                normalizedText.contains("pgto") ||
                normalizedText.contains("cpf verif") ||
                normalizedText.contains("parada")

        if (stats.size < 2 && !hasMarkers) {
            return null
        }

        var totalMinutes = 0
        var totalKm = 0.0

        stats.forEach { match ->
            totalMinutes += match.groupValues[1].toIntOrNull() ?: 0
            totalKm += routeDistanceKm(match)
        }

        val passengerName = extractPassengerName(lines)
        val addresses = extractAddresses(lines, passengerName)

        return mutableMapOf<String, Any>().apply {
            put("app", "99")
            put("platform_name", "99")
            put("valor_bruto", price)
            extractGainPerKm(rawText, lines)?.let { put("ganho_km", it) }
            put("km_total", totalKm)
            put("minutos_total", totalMinutes)
            put("avaliacao", extractRating(rawText, lines) ?: "5,00")
            put("corridas_total", extractRidesCount(rawText, lines) ?: 0)
            put("passenger_name", passengerName ?: "")
            put("perfil_passageiro", passengerName ?: "")
            put("origin_address", addresses.first ?: "")
            put("destination_address", addresses.second ?: "")
            put("tipo_corrida", extractOfferType(lines) ?: "")
            put("forma_pagamento", extractPaymentMethod(lines) ?: "")
        }
    }

    fun parsePositionedOffer(
        rawText: String,
        ocrLines: List<OcrLine>,
    ): Map<String, Any>? {
        if (rawText.isBlank() || ocrLines.isEmpty()) {
            return null
        }

        val regions = buildDynamicRegions(ocrLines)
        val cardLines = regions.cardLines.map { it.text }
        val parsed = parseOffer(cardLines.joinToString("\n"), cardLines) ?: return null
        val headerLines = regions.headerLines.map { it.text }
        val profileLines = regions.profileLines.map { it.text }
        val routeLines = regions.routeLines.map { it.text }
        val passengerName = extractPassengerName(profileLines)
        val addresses = extractAddresses(routeLines, passengerName)

        return parsed.toMutableMap().apply {
            put("passenger_name", passengerName ?: parsed["passenger_name"]?.toString().orEmpty())
            put("perfil_passageiro", passengerName ?: parsed["perfil_passageiro"]?.toString().orEmpty())
            put("origin_address", addresses.first ?: parsed["origin_address"]?.toString().orEmpty())
            put("destination_address", addresses.second ?: parsed["destination_address"]?.toString().orEmpty())
            put("tipo_corrida", extractOfferType(headerLines) ?: parsed["tipo_corrida"]?.toString().orEmpty())
            put("forma_pagamento", extractPaymentMethod(headerLines) ?: parsed["forma_pagamento"]?.toString().orEmpty())
            put(
                "avaliacao",
                extractRating(profileLines.joinToString("\n"), profileLines)
                    ?: parsed["avaliacao"]?.toString().orEmpty(),
            )
            put(
                "corridas_total",
                extractRidesCount(profileLines.joinToString("\n"), profileLines)
                    ?: parsed["corridas_total"]
                    ?: 0,
            )
        }
    }

    private fun buildDynamicRegions(ocrLines: List<OcrLine>): NinetyNineOcrRegions {
        val lines =
            ocrLines
                .map { it.copy(text = it.text.trim()) }
                .filter { it.text.isNotEmpty() }
                .sortedWith(compareBy<OcrLine> { it.top }.thenBy { it.left })
        val firstRouteTop =
            lines
                .filter { statsRegex.containsMatchIn(it.text) }
                .minOfOrNull { it.top }
                ?: Int.MAX_VALUE
        val mainPriceLine =
            lines
                .filter { line ->
                    priceRegex.containsMatchIn(line.text) &&
                        !normalize(line.text).contains("/km") &&
                        line.top < firstRouteTop
                }
                .sortedWith(compareByDescending<OcrLine> { it.area }.thenBy { it.top })
                .firstOrNull()
                ?: return NinetyNineOcrRegions(lines, lines, lines, lines)
        val priceHeight = (mainPriceLine.bottom - mainPriceLine.top).coerceAtLeast(1)
        val cardTop = (mainPriceLine.top - priceHeight * 2).coerceAtLeast(0)
        val cardLines = lines.filter { it.top >= cardTop }
        val headerLines = cardLines.filter { it.top < firstRouteTop }
        val profileLines =
            headerLines.filter { line ->
                val normalized = normalize(line.text)
                line.top >= mainPriceLine.bottom &&
                    (
                        normalized.contains("perfil") ||
                            normalized.contains("corridas") ||
                            normalized.contains("passageiro") ||
                            fallbackRatingRegex.containsMatchIn(line.text)
                    )
            }
        val routeLines =
            if (firstRouteTop == Int.MAX_VALUE) {
                cardLines
            } else {
                cardLines.filter { it.top >= firstRouteTop }
            }

        return NinetyNineOcrRegions(
            cardLines = cardLines,
            headerLines = headerLines,
            profileLines = profileLines,
            routeLines = routeLines,
        )
    }

    private fun extractPassengerName(lines: List<String>): String? {
        return lines.firstNotNullOfOrNull { line ->
            profileRegex.find(line)?.groupValues?.getOrNull(1)?.trim()
        }?.takeIf { it.isNotBlank() }
    }

    private fun extractAddresses(
        lines: List<String>,
        passengerName: String?,
    ): Pair<String?, String?> {
        val routeAnchoredAddresses = extractAddressesFromRouteStats(lines, passengerName)
        if (routeAnchoredAddresses.first != null || routeAnchoredAddresses.second != null) {
            return routeAnchoredAddresses
        }

        val candidates =
            lines.filter { isAddressCandidate(it, passengerName) }
                .distinct()

        return firstAndLastAddress(candidates)
    }

    private fun extractAddressesFromRouteStats(
        lines: List<String>,
        passengerName: String?,
    ): Pair<String?, String?> {
        val addresses = mutableListOf<String>()

        lines.forEachIndexed { index, line ->
            if (!statsRegex.containsMatchIn(line)) {
                return@forEachIndexed
            }

            val addressParts = mutableListOf<String>()
            extractAddressFromStatLine(line, passengerName)?.let(addressParts::add)
            addressParts.addAll(
                collectAddressContinuationParts(lines, startIndex = index + 1, passengerName = passengerName),
            )

            val address = joinAddressParts(addressParts)
            if (address != null) {
                addresses.add(address)
            }
        }

        return firstAndLastAddress(addresses.distinct())
    }

    private fun firstAndLastAddress(addresses: List<String>): Pair<String?, String?> {
        val originAddress = addresses.firstOrNull()
        val destinationAddress = addresses.drop(1).lastOrNull()
        return originAddress to destinationAddress
    }

    private fun routeDistanceKm(match: MatchResult): Double {
        val value =
            match.groupValues[2]
                .replace("I", "1")
                .replace("l", "1")
                .replace(",", ".")
                .toDoubleOrNull() ?: return 0.0
        val unit = match.groupValues.getOrNull(3)?.lowercase().orEmpty()
        return if (unit == "m") value / 1000.0 else value
    }

    private fun extractGainPerKm(
        rawText: String,
        lines: List<String>,
    ): Double? {
        val match =
            lines.asSequence()
                .filter { normalize(it).contains("/km") }
                .mapNotNull { gainPerKmRegex.find(it) }
                .firstOrNull()
                ?: gainPerKmRegex.find(rawText)
                ?: return null

        return match.value
            .replace(Regex("[^0-9,]"), "")
            .replace(",", ".")
            .toDoubleOrNull()
    }

    private fun extractAddressFromStatLine(
        line: String,
        passengerName: String?,
    ): String? {
        val match = statsRegex.find(line) ?: return null
        val candidate = line.substring(match.range.last + 1).trim()
        if (isAddressCandidate(candidate, passengerName)) {
            return candidate
        }

        return null
    }

    private fun collectAddressContinuationParts(
        lines: List<String>,
        startIndex: Int,
        passengerName: String?,
    ): List<String> {
        val parts = mutableListOf<String>()

        for (index in startIndex until lines.size) {
            val currentLine = lines[index].trim()
            if (currentLine.isEmpty()) {
                continue
            }

            if (statsRegex.containsMatchIn(currentLine)) {
                break
            }

            if (isAddressCandidate(currentLine, passengerName)) {
                parts.add(currentLine)
                continue
            }

            if (parts.isNotEmpty()) {
                break
            }
        }

        return parts
    }

    private fun joinAddressParts(parts: List<String>): String? {
        return parts
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .distinct()
            .joinToString(" ")
            .takeIf { it.isNotBlank() }
    }

    private fun isAddressCandidate(
        line: String,
        passengerName: String?,
    ): Boolean {
        val trimmed = line.trim()
        val normalized = normalize(trimmed)

        if (trimmed.length < 6 || !trimmed.any { it.isLetter() }) {
            return false
        }

        if (passengerName != null && normalized == normalize(passengerName)) {
            return false
        }

        if (priceRegex.containsMatchIn(trimmed) || statsRegex.containsMatchIn(trimmed)) {
            return false
        }

        val blockedTerms =
            listOf(
                "preco x",
                "nao afeta a ta",
                "perfil",
                "corridas",
                "aceitar",
                "dinheiro",
                "pix",
                "cartao",
                "entrega",
                "negocia",
                "parada",
                "km",
                "min",
                "r$",
                "passageiro",
                "google",
                "maquina",
                "premium",
                "novo",
            )

        if (blockedTerms.any { normalized.contains(it) }) {
            return false
        }

        return true
    }

    private fun extractRating(
        rawText: String,
        lines: List<String>,
    ): String? {
        val corridasLine =
            lines.firstOrNull { normalize(it).contains("corridas") }
                ?: rawText.lineSequence().firstOrNull { normalize(it).contains("corridas") }

        if (!corridasLine.isNullOrBlank()) {
            corridasLineRegex.find(corridasLine)?.groupValues?.get(1)?.let { return it }
            fallbackRatingRegex.find(corridasLine)?.value?.let { return it }
        }

        val perfilLine =
            lines.firstOrNull { normalize(it).contains("perfil") }
                ?: rawText.lineSequence().firstOrNull { normalize(it).contains("perfil") }

        if (!perfilLine.isNullOrBlank()) {
            ratingProfileLineRegex.find(perfilLine)?.groupValues?.get(1)?.let { return it }
            fallbackRatingRegex.find(perfilLine)?.value?.let { return it }
        }

        return null
    }

    private fun extractRidesCount(
        rawText: String,
        lines: List<String>,
    ): Int? {
        val corridasLine =
            lines.firstOrNull { normalize(it).contains("corridas") }
                ?: rawText.lineSequence().firstOrNull { normalize(it).contains("corridas") }

        return corridasLine?.let { corridasLineRegex.find(it)?.groupValues?.get(2)?.toIntOrNull() }
    }

    private fun extractOfferType(lines: List<String>): String? {
        lines.firstOrNull {
            val normalized = normalize(it)
            normalized == "entrega carro" ||
                normalized == "entrega moto" ||
                normalized == "entrega" ||
                normalized == "negocia"
        }?.let { return it.trim() }

        val line =
            lines.firstOrNull {
                val normalized = normalize(it)
                normalized.contains("negocia") ||
                    normalized.contains("entrega")
            } ?: return null

        return splitOfferLabels(line).map { it.trim() }.firstOrNull {
            val normalized = normalize(it)
            normalized.contains("negocia") ||
                normalized.contains("entrega")
        }
    }

    private fun extractPaymentMethod(lines: List<String>): String? {
        val line =
            lines.firstOrNull {
                val normalized = normalize(it)
                normalized.contains("dinheiro") ||
                    normalized.contains("pix") ||
                    normalized.contains("cartao")
            } ?: return null

        return splitOfferLabels(line).map { it.trim() }.firstOrNull {
            val normalized = normalize(it)
            normalized.contains("dinheiro") ||
                normalized.contains("pix") ||
                normalized.contains("cartao")
        }
    }

    private fun splitOfferLabels(line: String): List<String> {
        return line.split(Regex("\\s*[\u2022\u00B7]\\s*"))
    }
    private fun normalize(value: String): String {
        val normalized =
            Normalizer.normalize(value, Normalizer.Form.NFD)
                .replace("\\p{InCombiningDiacriticalMarks}+".toRegex(), "")

        return normalized.lowercase()
    }

    private data class NinetyNineOcrRegions(
        val cardLines: List<OcrLine>,
        val headerLines: List<OcrLine>,
        val profileLines: List<OcrLine>,
        val routeLines: List<OcrLine>,
    )
}
