package com.example.direcao_financeira_mobile

import java.text.Normalizer
import kotlin.math.abs

internal class RideOfferDuplicateGuard(
    private val duplicateWindowMs: Long,
) {
    private val recentAcceptedOffers = mutableListOf<AcceptedOfferFingerprint>()

    fun rememberAcceptedOffer(
        offerData: Map<String, Any>,
        acceptedAtElapsed: Long,
    ) {
        pruneExpired(acceptedAtElapsed)
        recentAcceptedOffers.add(buildFingerprint(offerData, acceptedAtElapsed))

        while (recentAcceptedOffers.size > 12) {
            recentAcceptedOffers.removeAt(0)
        }
    }

    fun recentDuplicateReason(
        offerData: Map<String, Any>,
        nowElapsed: Long,
    ): String? {
        pruneExpired(nowElapsed)

        val current = buildFingerprint(offerData, nowElapsed)
        return recentAcceptedOffers
            .asReversed()
            .firstNotNullOfOrNull { previous -> duplicateReason(previous, current) }
    }

    fun hasReliableMoveSjOfferData(offerData: Map<String, Any>): Boolean {
        val priceCents = parsePriceCents(offerData["valor_bruto"]?.toString())
        val kmTotal = (offerData["km_total"] as? Number)?.toDouble() ?: 0.0
        val minTotal = (offerData["minutos_total"] as? Number)?.toInt() ?: 0
        val originAddress = offerData["origin_address"]?.toString().orEmpty()
        val destinationAddress = offerData["destination_address"]?.toString().orEmpty()
        val normalizedOrigin = normalizedRouteText(originAddress)
        val normalizedDestination = normalizedRouteText(destinationAddress)

        return priceCents > 0 &&
            kmTotal > 0.0 &&
            minTotal > 0 &&
            normalizedOrigin.isNotBlank() &&
            normalizedDestination.isNotBlank() &&
            normalizedOrigin != normalizedDestination &&
            hasReliableRouteEndpoint(originAddress) &&
            hasReliableRouteEndpoint(destinationAddress)
    }

    private fun pruneExpired(nowElapsed: Long) {
        recentAcceptedOffers.removeAll { nowElapsed - it.acceptedAtElapsed > duplicateWindowMs }
    }

    private fun duplicateReason(
        previous: AcceptedOfferFingerprint,
        current: AcceptedOfferFingerprint,
    ): String? {
        if (previous.appKey != current.appKey || current.appKey != "movesj") {
            return null
        }

        val samePrice =
            previous.priceCents > 0 &&
                current.priceCents > 0 &&
                abs(previous.priceCents - current.priceCents) <= 10
        val samePassenger =
            previous.passengerName.isNotBlank() &&
                current.passengerName.isNotBlank() &&
                previous.passengerName == current.passengerName
        val metricsClose =
            previous.kmTotal > 0.0 &&
                current.kmTotal > 0.0 &&
                previous.minutesTotal > 0 &&
                current.minutesTotal > 0 &&
                abs(previous.kmTotal - current.kmTotal) <= 0.25 &&
                abs(previous.minutesTotal - current.minutesTotal) <= 2
        val originOverlap = tokenOverlap(previous.originAddress, current.originAddress)
        val destinationOverlap = tokenOverlap(previous.destinationAddress, current.destinationAddress)
        val routeOverlap = tokenOverlap(previous.routeTokens, current.routeTokens)
        val sameRoute = originOverlap >= 0.62 && destinationOverlap >= 0.62
        val likelySameRoute = routeOverlap >= 0.70

        return when {
            sameRoute && samePrice -> "movesj_same_route_price"
            sameRoute && samePassenger -> "movesj_same_route_passenger"
            likelySameRoute && samePrice -> "movesj_similar_route_price"
            samePrice && samePassenger && metricsClose -> "movesj_same_price_passenger_metrics"
            samePassenger && metricsClose && likelySameRoute -> "movesj_same_passenger_metrics_route"
            else -> null
        }
    }

    private fun buildFingerprint(
        offerData: Map<String, Any>,
        acceptedAtElapsed: Long,
    ): AcceptedOfferFingerprint {
        val originAddress = offerData["origin_address"]?.toString().orEmpty()
        val destinationAddress = offerData["destination_address"]?.toString().orEmpty()

        return AcceptedOfferFingerprint(
            appKey = normalizeFingerprintValue(resolveOfferAppKey(offerData)),
            acceptedAtElapsed = acceptedAtElapsed,
            priceCents = parsePriceCents(offerData["valor_bruto"]?.toString()),
            kmTotal = (offerData["km_total"] as? Number)?.toDouble() ?: 0.0,
            minutesTotal = (offerData["minutos_total"] as? Number)?.toInt() ?: 0,
            passengerName = normalizeFingerprintValue(offerData["passenger_name"]?.toString()),
            originAddress = normalizedRouteText(originAddress),
            destinationAddress = normalizedRouteText(destinationAddress),
            routeTokens = routeTokens(originAddress) + routeTokens(destinationAddress),
        )
    }

    private fun resolveOfferAppKey(offerData: Map<String, Any>): String? {
        val appValue =
            offerData["platform_name"]?.toString()?.takeIf { it.isNotBlank() }
                ?: offerData["app"]?.toString()?.takeIf { it.isNotBlank() }
                ?: return null

        return when {
            appValue.equals("MoveSj", ignoreCase = true) -> "MoveSj"
            appValue.equals("MeLevaSJ", ignoreCase = true) -> "MeLevaSJ"
            appValue.contains("99", ignoreCase = true) -> "99"
            else -> appValue
        }
    }

    private fun parsePriceCents(value: String?): Int {
        if (value.isNullOrBlank()) {
            return 0
        }

        val clean = value.filter { it.isDigit() || it == ',' || it == '.' }
        if (clean.isBlank()) {
            return 0
        }

        val normalized =
            if (clean.contains(",")) {
                clean.replace(".", "").replace(",", ".")
            } else {
                clean
            }

        val parsed = normalized.toDoubleOrNull() ?: return 0
        return (parsed * 100).toInt()
    }

    private fun tokenOverlap(
        left: String,
        right: String,
    ): Double {
        return tokenOverlap(routeTokens(left), routeTokens(right))
    }

    private fun tokenOverlap(
        left: Set<String>,
        right: Set<String>,
    ): Double {
        if (left.isEmpty() || right.isEmpty()) {
            return 0.0
        }

        val common = left.intersect(right).size
        if (common < 2) {
            return 0.0
        }

        return common.toDouble() / minOf(left.size, right.size).toDouble()
    }

    private fun routeTokens(value: String): Set<String> {
        val ignored =
            setOf(
                "avenida",
                "brasil",
                "colonia",
                "definir",
                "minas",
                "para",
                "rua",
                "sao",
                "santa",
            )

        return normalizedRouteText(value)
            .split(Regex("\\s+"))
            .map { it.trim() }
            .filter { it.length >= 3 && it !in ignored }
            .toSet()
    }

    private fun hasReliableRouteEndpoint(value: String): Boolean {
        val tokens = routeTokens(value)
        return tokens.size >= 2 || isLikelyNamedPlaceEndpoint(value)
    }

    private fun isLikelyNamedPlaceEndpoint(value: String): Boolean {
        val normalized = normalizedRouteText(value)
        val tokens = routeTokens(value)

        return normalized.length >= 5 &&
            tokens.size == 1 &&
            tokens.firstOrNull().orEmpty().length >= 5 &&
            normalized.any { it.isLetter() }
    }

    private fun normalizedRouteText(value: String?): String {
        if (value.isNullOrBlank()) {
            return ""
        }

        return normalizedText(value)
            .replace(Regex("[^a-z0-9]+"), " ")
            .trim()
    }

    private fun normalizeFingerprintValue(value: String?): String {
        if (value.isNullOrBlank()) {
            return ""
        }

        val normalized =
            Normalizer.normalize(value.trim(), Normalizer.Form.NFD)
                .replace("\\p{InCombiningDiacriticalMarks}+".toRegex(), "")

        return normalized.lowercase().replace(" ", "")
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

    private data class AcceptedOfferFingerprint(
        val appKey: String,
        val acceptedAtElapsed: Long,
        val priceCents: Int,
        val kmTotal: Double,
        val minutesTotal: Int,
        val passengerName: String,
        val originAddress: String,
        val destinationAddress: String,
        val routeTokens: Set<String>,
    )
}
