package com.example.direcao_financeira_mobile

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class RideOfferNotificationContent(
    val notificationId: Int,
    val title: String,
    val contentText: String,
    val expandedTitle: String,
    val summaryText: String,
    val inboxLines: List<String>,
    val originAddress: String?,
    val destinationAddress: String?,
) {
    val hasOriginAction: Boolean
        get() = !originAddress.isNullOrBlank()

    val hasDestinationAction: Boolean
        get() = !destinationAddress.isNullOrBlank()
}

object RideOfferNotificationFormatter {
    private val brazilianLocale = Locale.forLanguageTag("pt-BR")

    fun format(
        data: Map<String, Any>,
        detectedTimeText: String = currentTimeText(),
    ): RideOfferNotificationContent {
        val appName = resolveText(data["platform_name"])
            ?: resolveText(data["app"])
            ?: "App"
        val grossValue = parseCurrencyToDouble(data["valor_bruto"])
        val totalKm = parseDistanceKm(data["km_total"])
        val totalMinutes = parseTotalMinutes(data["minutos_total"])
        val passengerName = resolveText(data["passenger_name"]) ?: "Cliente nao informado"
        val originAddress = resolveMapAddress(data["origin_address"])
        val destinationAddress = resolveMapAddress(data["destination_address"])
        val valueText = formatCurrency(grossValue)
        val gainPerKmText = formatCurrency(if (totalKm > 0.0) grossValue / totalKm else 0.0) + "/km"
        val distanceText = if (totalKm > 0.0) formatDistance(totalKm) else "Distancia nao informada"
        val durationText = if (totalMinutes > 0) "${totalMinutes} min" else "Tempo nao informado"

        val displayOrigin = originAddress ?: "Origem nao informada"
        val displayDestination = destinationAddress ?: "Destino nao informado"
        val title = "Nova corrida - $appName"
        val expandedTitle = "$valueText em $appName"
        val summaryText = "Detectada as $detectedTimeText"
        val routeText = "$distanceText em $durationText"
        val contentText = "$valueText | $routeText | $gainPerKmText"
        val inboxLines =
            listOf(
                "Cliente: $passengerName",
                "Rota: $routeText",
                "Ganho/km: $gainPerKmText",
                "Origem: $displayOrigin",
                "Destino: $displayDestination",
            )

        return RideOfferNotificationContent(
            notificationId = buildNotificationId(data),
            title = title,
            contentText = contentText,
            expandedTitle = expandedTitle,
            summaryText = summaryText,
            inboxLines = inboxLines,
            originAddress = originAddress,
            destinationAddress = destinationAddress,
        )
    }

    private fun currentTimeText(): String {
        return SimpleDateFormat("HH:mm", brazilianLocale).format(Date())
    }

    private fun buildNotificationId(data: Map<String, Any>): Int {
        val signature =
            listOf(
                data["app"]?.toString().orEmpty(),
                data["platform_name"]?.toString().orEmpty(),
                data["valor_bruto"]?.toString().orEmpty(),
                data["km_total"]?.toString().orEmpty(),
                data["minutos_total"]?.toString().orEmpty(),
                data["passenger_name"]?.toString().orEmpty(),
                data["origin_address"]?.toString().orEmpty(),
                data["destination_address"]?.toString().orEmpty(),
            ).joinToString("|")

        return 10_000 + (signature.hashCode() and 0x0fffffff)
    }

    private fun resolveText(rawValue: Any?): String? {
        val text = rawValue?.toString()?.trim()
        if (text.isNullOrEmpty()) {
            return null
        }
        return text
    }

    private fun resolveMapAddress(rawValue: Any?): String? {
        val text = resolveText(rawValue) ?: return null
        val normalized = text.lowercase(brazilianLocale)
        if (normalized == "origem nao informada" || normalized == "destino nao informado") {
            return null
        }
        return text
    }

    private fun parseDistanceKm(rawValue: Any?): Double {
        if (rawValue is Number) {
            return rawValue.toDouble()
        }

        val text = rawValue?.toString()?.trim()?.replace(",", ".") ?: return 0.0
        return text.toDoubleOrNull() ?: 0.0
    }

    private fun parseTotalMinutes(rawValue: Any?): Int {
        if (rawValue is Number) {
            return rawValue.toInt()
        }

        val text = rawValue?.toString()?.trim() ?: return 0
        return text.toIntOrNull() ?: 0
    }

    private fun parseCurrencyToDouble(rawValue: Any?): Double {
        val text = rawValue?.toString()?.trim() ?: return 0.0
        if (text.isEmpty()) {
            return 0.0
        }

        val numericText = text.replace(Regex("[^0-9,.-]"), "")
        if (numericText.isBlank()) {
            return 0.0
        }

        val normalized =
            if (numericText.contains(",")) {
                numericText.replace(".", "").replace(",", ".")
            } else {
                numericText
            }

        return normalized.toDoubleOrNull() ?: 0.0
    }

    private fun formatCurrency(value: Double): String {
        return "R$ " + String.format(brazilianLocale, "%.2f", value)
    }

    private fun formatDistance(value: Double): String {
        return String.format(brazilianLocale, "%.1f km", value)
    }
}
