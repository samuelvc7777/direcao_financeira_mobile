package com.example.direcao_financeira_mobile.parsers

class AutoRideParser {
    private val moveSjParser = MoveSjParser()
    private val meLevaSjParser = MeLevaSjParser()

    fun parsePositionedOcrOffer(
        rawText: String,
        ocrLines: List<MoveSjParser.OcrLine>,
    ): Map<String, Any>? {
        if (looksLikeMeLeva(rawText, ocrLines.map { it.text })) {
            return meLevaSjParser.parsePositionedOcrOffer(rawText, ocrLines)
        }

        return moveSjParser.parsePositionedOcrOffer(rawText, ocrLines)
    }

    fun parseOffer(
        rawText: String,
        lines: List<String>,
    ): Map<String, Any>? {
        if (looksLikeMeLeva(rawText, lines)) {
            return meLevaSjParser.parseOffer(rawText, lines)
        }

        return moveSjParser.parseOcrOffer(rawText, lines)
    }

    private fun looksLikeMeLeva(rawText: String, lines: List<String>): Boolean {
        val normalized = (listOf(rawText) + lines).joinToString(" ").lowercase()
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

        val hasMoveSjMarkers = moveSjMarkers.any { normalized.contains(it) }
        val hasMeLevaSignature = normalized.contains("embarque") && normalized.contains("destino")

        return normalized.contains("me leva sj") || (hasMeLevaSignature && !hasMoveSjMarkers)
    }
}
