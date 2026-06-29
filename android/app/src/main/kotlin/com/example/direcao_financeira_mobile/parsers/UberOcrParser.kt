package com.example.direcao_financeira_mobile.parsers

import java.text.Normalizer

class UberOcrParser {
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

    private val priceRegex = Regex("R\\$\\s*\\d+(?:[.,]\\d{1,2})?", RegexOption.IGNORE_CASE)
    private val routeStatsRegex =
        Regex("(\\d+)\\s*min(?:utos?)?\\s*\\((\\d+(?:[.,]\\d+)?)\\s*km\\)", RegexOption.IGNORE_CASE)
    private val ratingRegex = Regex("\\b([1-5][.,]\\d{1,2})\\s*\\((\\d+)\\)")

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
        val routeLines = regions.routeLines.map { it.text }
        val addresses = extractAddresses(routeLines)

        return parsed.toMutableMap().apply {
            put("origin_address", addresses.first ?: parsed["origin_address"]?.toString().orEmpty())
            put("destination_address", addresses.second ?: parsed["destination_address"]?.toString().orEmpty())
        }
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
        val stats = routeStatsRegex.findAll(rawText).toList()
        val hasUberMarker =
            normalizedText.contains("uberx") ||
                normalizedText.contains("comfort") ||
                normalizedText.contains("uber")

        if (stats.size < 2 || !hasUberMarker) {
            return null
        }

        var totalMinutes = 0
        var totalKm = 0.0
        stats.forEach { match ->
            totalMinutes += match.groupValues[1].toIntOrNull() ?: 0
            totalKm += match.groupValues[2].replace(",", ".").toDoubleOrNull() ?: 0.0
        }

        val addresses = extractAddresses(lines)

        return mutableMapOf<String, Any>().apply {
            put("app", "Uber")
            put("platform_name", "Uber")
            put("valor_bruto", price)
            put("km_total", totalKm)
            put("minutos_total", totalMinutes)
            put("avaliacao", extractRating(rawText, lines) ?: "5,00")
            put("corridas_total", extractRidesCount(rawText, lines) ?: 0)
            put("passenger_name", "")
            put("perfil_passageiro", "")
            put("origin_address", addresses.first ?: "")
            put("destination_address", addresses.second ?: "")
            put("tipo_corrida", extractRideType(lines) ?: "Uber")
            put("forma_pagamento", "")
        }
    }

    private fun buildDynamicRegions(ocrLines: List<OcrLine>): UberOcrRegions {
        val lines =
            ocrLines
                .map { it.copy(text = it.text.trim()) }
                .filter { it.text.isNotEmpty() }
                .sortedWith(compareBy<OcrLine> { it.top }.thenBy { it.left })
        val firstRouteTop =
            lines
                .filter { routeStatsRegex.containsMatchIn(it.text) }
                .minOfOrNull { it.top }
                ?: Int.MAX_VALUE
        val mainPriceLine =
            lines
                .filter { line ->
                    priceRegex.containsMatchIn(line.text) &&
                        line.top < firstRouteTop
                }
                .sortedWith(compareByDescending<OcrLine> { it.area }.thenBy { it.top })
                .firstOrNull()
                ?: return UberOcrRegions(lines, lines)
        val priceHeight = (mainPriceLine.bottom - mainPriceLine.top).coerceAtLeast(1)
        val cardTop = (mainPriceLine.top - priceHeight * 2).coerceAtLeast(0)
        val cardLines = lines.filter { it.top >= cardTop }
        val routeLines =
            if (firstRouteTop == Int.MAX_VALUE) {
                cardLines
            } else {
                cardLines.filter { it.top >= firstRouteTop }
            }

        return UberOcrRegions(cardLines = cardLines, routeLines = routeLines)
    }

    private fun extractRideType(lines: List<String>): String? {
        return lines.firstOrNull { line ->
            val normalized = normalize(line)
            normalized.contains("uberx") ||
                normalized.contains("comfort") ||
                normalized.contains("black")
        }?.trim()
    }

    private fun extractRating(
        rawText: String,
        lines: List<String>,
    ): String? {
        val ratingLine =
            lines.firstOrNull { ratingRegex.containsMatchIn(it) }
                ?: rawText.lineSequence().firstOrNull { ratingRegex.containsMatchIn(it) }

        return ratingLine?.let { ratingRegex.find(it)?.groupValues?.get(1) }
    }

    private fun extractRidesCount(
        rawText: String,
        lines: List<String>,
    ): Int? {
        val ratingLine =
            lines.firstOrNull { ratingRegex.containsMatchIn(it) }
                ?: rawText.lineSequence().firstOrNull { ratingRegex.containsMatchIn(it) }

        return ratingLine?.let { ratingRegex.find(it)?.groupValues?.get(2)?.toIntOrNull() }
    }

    private fun extractAddresses(lines: List<String>): Pair<String?, String?> {
        val addresses = mutableListOf<String>()

        lines.forEachIndexed { index, line ->
            if (!routeStatsRegex.containsMatchIn(line)) {
                return@forEachIndexed
            }

            extractAddressFromStatLine(line)?.let { address ->
                addresses.add(address)
                return@forEachIndexed
            }

            collectNextAddress(lines, index + 1)?.let(addresses::add)
        }

        return firstAndLastAddress(addresses.distinct())
    }

    private fun firstAndLastAddress(addresses: List<String>): Pair<String?, String?> {
        val originAddress = addresses.firstOrNull()
        val destinationAddress = addresses.drop(1).lastOrNull()
        return originAddress to destinationAddress
    }

    private fun extractAddressFromStatLine(line: String): String? {
        val match = routeStatsRegex.find(line) ?: return null
        val candidate = line.substring(match.range.last + 1).trim()
        return if (isAddressCandidate(candidate)) candidate else null
    }

    private fun collectNextAddress(
        lines: List<String>,
        startIndex: Int,
    ): String? {
        val parts = mutableListOf<String>()
        for (index in startIndex until lines.size) {
            val currentLine = lines[index].trim()
            if (currentLine.isEmpty()) {
                continue
            }

            if (routeStatsRegex.containsMatchIn(currentLine)) {
                break
            }

            if (isAddressCandidate(currentLine)) {
                parts.add(currentLine)
                continue
            }

            if (parts.isNotEmpty()) {
                break
            }
        }

        val address = parts.joinToString(" ").replace(Regex("\\s+"), " ").trim()
        return address.takeIf { it.isNotBlank() }
    }

    private fun isAddressCandidate(line: String): Boolean {
        val trimmed = line.trim()
        val normalized = normalize(trimmed)

        if (trimmed.length < 6 || !trimmed.any { it.isLetter() }) {
            return false
        }

        if (priceRegex.containsMatchIn(trimmed) || routeStatsRegex.containsMatchIn(trimmed)) {
            return false
        }

        val blockedTerms =
            listOf(
                "aceitar",
                "uberx",
                "uber",
                "comfort",
                "black",
                "r$",
            )

        return blockedTerms.none { normalized.contains(it) }
    }

    private fun normalize(value: String): String {
        val normalized =
            Normalizer.normalize(value, Normalizer.Form.NFD)
                .replace("\\p{InCombiningDiacriticalMarks}+".toRegex(), "")

        return normalized.lowercase().replace(Regex("\\s+"), " ").trim()
    }

    private data class UberOcrRegions(
        val cardLines: List<OcrLine>,
        val routeLines: List<OcrLine>,
    )
}
