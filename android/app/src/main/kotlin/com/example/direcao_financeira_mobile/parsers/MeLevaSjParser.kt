package com.example.direcao_financeira_mobile.parsers

import java.text.Normalizer

class MeLevaSjParser {

    private val ratingValueRegex = Regex("(?<!\\d)([1-5])[\\.,]([0-9]{1,2})(?!\\d)")

    fun parsePositionedOcrOffer(
        rawText: String,
        ocrLines: List<MoveSjParser.OcrLine>,
    ): Map<String, Any>? {
        if (rawText.isBlank() || ocrLines.isEmpty()) {
            return null
        }

        val orderedLines =
            ocrLines
                .filter { it.text.trim().isNotEmpty() }
                .sortedWith(compareBy<MoveSjParser.OcrLine> { it.top }.thenBy { it.left })

        return parseOffer(rawText, orderedLines.map { it.text.trim() })
    }

    fun parseOffer(
        rawText: String,
        lines: List<String>,
    ): Map<String, Any>? {
        if (rawText.isBlank() || lines.isEmpty()) {
            return null
        }

        val normalizedLines = lines.map(::normalizeText)
        val joined = normalizedLines.joinToString(" ")
        if (!looksLikeMeLeva(joined)) {
            return null
        }

        val originAddress =
            extractSection(lines, normalizedLines, listOf("embarque"), listOf("destino"))
        val destinationAddress =
            extractSection(
                lines,
                normalizedLines,
                listOf("destino"),
                listOf("recusar", "aceitar", "moto taxi", "dinheiro", "pix"),
                keepLastAddressBlock = true,
            )

        return mutableMapOf<String, Any>(
            "app" to "MeLevaSJ",
            "platform_name" to "MeLevaSJ",
            "valor_bruto" to (extractCurrency(rawText, lines) ?: "R$ 0,00"),
            "km_total" to 0.0,
            "minutos_total" to 0,
            "avaliacao" to (extractRating(rawText, lines) ?: ""),
            "passenger_name" to (extractPassenger(lines, normalizedLines) ?: ""),
            "origin_address" to (originAddress ?: ""),
            "destination_address" to (destinationAddress ?: ""),
            "forma_pagamento" to (extractPaymentMethod(lines) ?: ""),
        )
    }

    private fun looksLikeMeLeva(normalizedText: String): Boolean {
        val moveSjMarkers =
            listOf(
                "endereco de origem",
                "endereco de destino",
                "numero viagem",
                "numero da viagem",
                "status",
                "forma de pagamento",
                "cliente",
                "passageiro",
            )

        val hasMoveSjMarkers = moveSjMarkers.any { normalizedText.contains(it) }
        val hasMeLevaSignature = normalizedText.contains("embarque") && normalizedText.contains("destino")

        return normalizedText.contains("me leva sj") || (hasMeLevaSignature && !hasMoveSjMarkers)
    }

    private fun extractSection(
        lines: List<String>,
        normalizedLines: List<String>,
        startLabels: List<String>,
        endLabels: List<String>,
        keepLastAddressBlock: Boolean = false,
    ): String? {
        val startIndex = normalizedLines.indexOfFirst { containsAny(it, startLabels) }
        if (startIndex < 0) {
            return null
        }

        val values = mutableListOf<String>()
        cleanAddressValue(inlineValue(lines[startIndex], normalizedLines[startIndex], startLabels))
            ?.let(values::add)

        for (index in startIndex + 1 until lines.size) {
            val normalized = normalizedLines[index]
            if ((!keepLastAddressBlock && containsAny(normalized, startLabels)) ||
                containsAny(normalized, endLabels)
            ) {
                break
            }
            val startsNewAddressBlock =
                keepLastAddressBlock &&
                    values.isNotEmpty() &&
                    isRouteSeparatorLine(lines[index])
            if (startsNewAddressBlock) {
                values.clear()
                continue
            }
            cleanAddressValue(lines[index])?.let(values::add)
        }

        return values.joinToString(" ").replace(Regex("\\s+"), " ").trim().ifBlank { null }
    }

    private fun isRouteSeparatorLine(value: String): Boolean {
        val normalized = normalizeText(value)
        return Regex("^\\d+\\s*min\\b").containsMatchIn(normalized) ||
            Regex("^\\(?\\s*\\d+(?:[.,]\\d+)?\\s*(?:m|km)\\)?\\b").containsMatchIn(normalized)
    }

    private fun cleanAddressValue(value: String?): String? {
        if (value.isNullOrBlank()) {
            return null
        }

        var output = value.replace(Regex("\\s+"), " ").trim()
        output = output.replaceFirst(Regex("^\\*\\s*\\d+(?:[.,]\\d+)?\\s*"), "")
        output = output.replaceFirst(Regex("^\\d+(?:[.,]\\d+)?\\s*"), "")
        output = output.replaceFirst(
            Regex("^(embarque|destino)\\s*[:\\-]?\\s*", RegexOption.IGNORE_CASE),
            "",
        )
        output = output.replaceFirst(Regex("^[\\-\\s]+"), "")
        output = output.replaceFirst(
            Regex("^\\(?\\s*\\d+(?:[.,]\\d+)?\\s*m\\)?\\s*", RegexOption.IGNORE_CASE),
            "",
        )
        output = output.replaceFirst(
            Regex("^\\d+\\s*min(?:\\s*[-\\s]?\\s*)?", RegexOption.IGNORE_CASE),
            "",
        )
        output = output.replaceFirst(Regex("^[^A-Za-z]*(?:in|rn|ii)\\s+", RegexOption.IGNORE_CASE), "")
        output = output.replaceFirst(Regex("^(?:[-\\s]+)+"), "")
        output = output.replaceFirst(Regex("\\s+[A-Z]$"), "")
        output = output.replace(Regex("[,;]\\s*$"), "")
        output = output.trim()
        output = output.replaceFirst(Regex("^[^A-Za-z]+"), "")
        val streetMatch = Regex("R\\.").find(output)
        if (streetMatch != null && streetMatch.range.first <= 5) {
            output = output.substring(streetMatch.range.first).trim()
        }
        val lower = output.lowercase()
        if (lower.startsWith("in ")) {
            output = output.substring(3).trim()
        } else if (lower.startsWith("rn ")) {
            output = output.substring(3).trim()
        } else if (lower.startsWith("ii ")) {
            output = output.substring(3).trim()
        }

        if (output.isBlank() || normalizeText(output).contains("recalcular km e tempo")) {
            return null
        }

        val normalizedOutput = normalizeText(output)
        if (normalizedOutput == "in" ||
            normalizedOutput == "rn" ||
            normalizedOutput == "ii"
        ) {
            return null
        }

        return output
    }

    private fun extractPassenger(lines: List<String>, normalizedLines: List<String>): String? {
        val index = normalizedLines.indexOfFirst {
            it.contains("cliente") || it.contains("passageiro")
        }
        if (index < 0) {
            return null
        }

        inlineValue(lines[index], normalizedLines[index], listOf("cliente", "passageiro"))
            ?.let { return cleanPassengerName(it) }

        if (index + 1 < lines.size) {
            return cleanPassengerName(lines[index + 1])
        }

        return null
    }

    private fun cleanPassengerName(value: String?): String? {
        if (value.isNullOrBlank()) {
            return null
        }
        val cleaned = value.replace(Regex("\\s+"), " ").trim()
        val normalized = normalizeText(cleaned)
        if (normalized.length <= 1 ||
            normalized.contains("direcao financeira") ||
            normalized.contains("relatar ocorrencia") ||
            Regex("^[0-9.,\\s]+$").matches(normalized)
        ) {
            return null
        }
        return cleaned
    }

    private fun extractPaymentMethod(lines: List<String>): String? {
        val lower = normalizeText(lines.joinToString(" "))
        return when {
            lower.contains("pix") -> "Pix"
            lower.contains("dinheiro") -> "Dinheiro"
            lower.contains("cart") -> "Cartao"
            lower.contains("moto taxi") -> "Moto Taxi"
            else -> null
        }
    }

    private fun extractCurrency(rawText: String, lines: List<String>): String? {
        val currencyRegex = Regex("R\\$\\s*\\d{1,3}(?:\\.\\d{3})*(?:,\\d{2})|R\\$\\s*\\d+(?:,\\d{2})")
        currencyRegex.find(rawText)?.value?.let { return it }
        for (line in lines) {
            currencyRegex.find(line)?.value?.let { return it }
        }
        return null
    }

    private fun extractRating(rawText: String, lines: List<String>): String? {
        for (line in lines) {
            extractRatingFromLine(line)?.let { return it }
        }

        for (line in rawText.lineSequence()) {
            extractRatingFromLine(line)?.let { return it }
        }

        return null
    }

    private fun extractRatingFromLine(line: String): String? {
        val normalized = normalizeText(line)
        if (isUnlikelyRatingLine(normalized)) {
            return null
        }

        for (match in ratingValueRegex.findAll(line)) {
            val afterMatch = line.substring(match.range.last + 1).trimStart().lowercase()
            if (afterMatch.startsWith("km") ||
                afterMatch.startsWith("m") ||
                afterMatch.startsWith("min") ||
                afterMatch.startsWith("/")
            ) {
                continue
            }

            val value = "${match.groupValues[1]}.${match.groupValues[2]}".toDoubleOrNull()
            if (value != null && value in 1.0..5.0) {
                return match.value
            }
        }

        return null
    }

    private fun isUnlikelyRatingLine(normalizedLine: String): Boolean {
        return normalizedLine.contains("r\$") ||
            normalizedLine.contains("/km") ||
            normalizedLine.contains("/min") ||
            normalizedLine.contains("km/h") ||
            normalizedLine.contains("valor") ||
            normalizedLine.contains("dinheiro") ||
            normalizedLine.contains("pix") ||
            normalizedLine.contains("cartao") ||
            normalizedLine.contains("moto taxi") ||
            normalizedLine.contains("embarque") ||
            normalizedLine.contains("destino")
    }

    private fun inlineValue(
        originalLine: String,
        normalizedLine: String,
        labels: List<String>,
    ): String? {
        for (label in labels) {
            val index = normalizedLine.indexOf(label)
            if (index >= 0) {
                val value = originalLine.substring(index + label.length).trim()
                if (value.isNotBlank()) {
                    return value
                }
            }
        }
        return null
    }

    private fun containsAny(normalizedLine: String, labels: List<String>): Boolean {
        return labels.any { label -> normalizedLine.contains(label) }
    }

    private fun normalizeText(value: String): String {
        return Normalizer.normalize(value.lowercase(), Normalizer.Form.NFD)
            .replace(Regex("\\p{M}+"), "")
            .replace(Regex("\\s+"), " ")
            .trim()
    }
}
