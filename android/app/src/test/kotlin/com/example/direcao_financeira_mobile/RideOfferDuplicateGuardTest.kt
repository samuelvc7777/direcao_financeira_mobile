package com.example.direcao_financeira_mobile

import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RideOfferDuplicateGuardTest {
    private val guard = RideOfferDuplicateGuard(duplicateWindowMs = 20_000L)

    @Test
    fun `bloqueia mesma corrida movesj mesmo com destino truncado pelo ocr`() {
        val original =
            moveSjOffer(
                passenger = "Samuel",
                price = "R$ 12,66",
                km = 1.5,
                minutes = 4,
                origin = "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG",
                destination = "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG",
            )
        val reread =
            moveSjOffer(
                passenger = "Samuel",
                price = "R$ 12,66",
                km = 1.6,
                minutes = 5,
                origin = "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao",
                destination = "Av. Leite de Castro, 617 - Fabricas, Sao Joao",
            )

        guard.rememberAcceptedOffer(original, acceptedAtElapsed = 1_000L)

        assertNotNull(guard.recentDuplicateReason(reread, nowElapsed = 1_800L))
    }

    @Test
    fun `nao bloqueia corrida diferente da movesj com mesmo valor`() {
        val original =
            moveSjOffer(
                passenger = "Samuel",
                price = "R$ 12,66",
                km = 1.5,
                minutes = 4,
                origin = "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG",
                destination = "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG",
            )
        val differentRide =
            moveSjOffer(
                passenger = "Larissa",
                price = "R$ 12,66",
                km = 3.4,
                minutes = 9,
                origin = "Av. Presidente Tancredo Neves, 120 - Centro",
                destination = "Rua Antonio Rocha, 88 - Senhor dos Montes",
            )

        guard.rememberAcceptedOffer(original, acceptedAtElapsed = 1_000L)

        assertNull(guard.recentDuplicateReason(differentRide, nowElapsed = 2_000L))
    }

    @Test
    fun `rejeita dados movesj sem rota confiavel`() {
        val invalid =
            moveSjOffer(
                passenger = "Samuel",
                price = "R$ 12,66",
                km = 1.5,
                minutes = 4,
                origin = "R. Joaquim Portugal",
                destination = "R. Joaquim Portugal",
            )

        assertFalse(guard.hasReliableMoveSjOfferData(invalid))
        assertTrue(
            guard.hasReliableMoveSjOfferData(
                invalid + mapOf("destination_address" to "Av. Leite de Castro, 617 - Fabricas"),
            ),
        )
    }

    @Test
    fun `aceita destino movesj com nome de lugar curto`() {
        val offer =
            moveSjOffer(
                passenger = "Juliana",
                price = "R$ 14,61",
                km = 5.3,
                minutes = 13,
                origin = "Rua Delegado Jose Lima, 201 - Guarda-Mor - Sao Joao del Rei - MG",
                destination = "Independente",
            )

        assertTrue(guard.hasReliableMoveSjOfferData(offer))
    }

    private fun moveSjOffer(
        passenger: String,
        price: String,
        km: Double,
        minutes: Int,
        origin: String,
        destination: String,
    ): Map<String, Any> {
        return mapOf(
            "app" to "MoveSj",
            "platform_name" to "MoveSj",
            "valor_bruto" to price,
            "km_total" to km,
            "minutos_total" to minutes,
            "passenger_name" to passenger,
            "origin_address" to origin,
            "destination_address" to destination,
        )
    }
}
