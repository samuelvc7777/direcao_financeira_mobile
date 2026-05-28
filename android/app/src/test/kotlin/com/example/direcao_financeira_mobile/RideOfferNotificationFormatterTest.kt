package com.example.direcao_financeira_mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RideOfferNotificationFormatterTest {
    @Test
    fun `payload completo gera conteudo da notificacao`() {
        val content =
            RideOfferNotificationFormatter.format(
                data =
                    mapOf(
                        "app" to "99",
                        "platform_name" to "99",
                        "valor_bruto" to "R$ 23,50",
                        "km_total" to 5.0,
                        "minutos_total" to 18,
                        "passenger_name" to "Samuel",
                        "origin_address" to "Rua A, 10",
                        "destination_address" to "Rua B, 20",
                    ),
                detectedTimeText = "14:35",
            )

        assertEquals("Nova corrida - 99", content.title)
        assertEquals("R$ 23,50 em 99", content.expandedTitle)
        assertEquals("Detectada as 14:35", content.summaryText)
        assertEquals("R$ 23,50 | 5,0 km em 18 min | R$ 4,70/km", content.contentText)
        assertTrue(content.inboxLines.contains("Cliente: Samuel"))
        assertTrue(content.inboxLines.contains("Rota: 5,0 km em 18 min"))
        assertTrue(content.inboxLines.contains("Ganho/km: R$ 4,70/km"))
        assertTrue(content.inboxLines.contains("Origem: Rua A, 10"))
        assertTrue(content.inboxLines.contains("Destino: Rua B, 20"))
        assertTrue(content.hasOriginAction)
        assertTrue(content.hasDestinationAction)
    }

    @Test
    fun `payload sem origem e destino nao habilita acoes invalidas`() {
        val content =
            RideOfferNotificationFormatter.format(
                data =
                    mapOf(
                        "app" to "MoveSj",
                        "valor_bruto" to "R$ 15,00",
                        "km_total" to 3.0,
                        "passenger_name" to "",
                        "origin_address" to "",
                        "destination_address" to "",
                    ),
                detectedTimeText = "09:10",
            )

        assertTrue(content.inboxLines.contains("Cliente: Cliente nao informado"))
        assertTrue(content.inboxLines.contains("Origem: Origem nao informada"))
        assertTrue(content.inboxLines.contains("Destino: Destino nao informado"))
        assertFalse(content.hasOriginAction)
        assertFalse(content.hasDestinationAction)
    }

    @Test
    fun `km zero nao divide por zero`() {
        val content =
            RideOfferNotificationFormatter.format(
                data =
                    mapOf(
                        "app" to "99",
                        "valor_bruto" to "R$ 18,00",
                        "km_total" to 0.0,
                    ),
                detectedTimeText = "11:20",
            )

        assertTrue(content.inboxLines.contains("Ganho/km: R$ 0,00/km"))
    }

    @Test
    fun `valor brasileiro e convertido para calculo de ganhos por km`() {
        val content =
            RideOfferNotificationFormatter.format(
                data =
                    mapOf(
                        "app" to "99",
                        "valor_bruto" to "R$ 23,50",
                        "km_total" to 2.0,
                    ),
                detectedTimeText = "16:45",
            )

        assertEquals("R$ 23,50 em 99", content.expandedTitle)
        assertTrue(content.inboxLines.contains("Ganho/km: R$ 11,75/km"))
    }
}
