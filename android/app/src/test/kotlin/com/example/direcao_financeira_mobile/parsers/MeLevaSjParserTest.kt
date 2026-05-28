package com.example.direcao_financeira_mobile.parsers

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class MeLevaSjParserTest {

    private val parser = MeLevaSjParser()

    @Test
    fun `usa ultimo endereco como destino quando Me Leva SJ tem parada`() {
        val lines =
            listOf(
                "R$ 28,00",
                "Embarque - (660m) 1 min",
                "Av. Origem, 10 - Centro",
                "Destino - 8 min",
                "Rua Parada, 20 - Centro",
                "12 min",
                "Rua Destino Final, 300 - Bairro Final",
                "Moto Taxi",
                "Dinheiro",
            )

        val offerData = parser.parseOffer(lines.joinToString("\n"), lines)

        assertNotNull(offerData)
        assertEquals("Av. Origem, 10 - Centro", offerData?.get("origin_address"))
        assertEquals(
            "Rua Destino Final, 300 - Bairro Final",
            offerData?.get("destination_address"),
        )
    }

    @Test
    fun `captura avaliacao do cliente ao lado da estrela no Me Leva SJ`() {
        val lines =
            listOf(
                "R$ 12,00",
                "5,0",
                "Embarque - (660m) 1 min",
                "Av. Leite de Castro (lado impar) -",
                "Fabricas de Castro",
                "Destino - 12 min",
                "R. Vilma Aparecida Araujo, 195 - Vila Jardim Sao Jose",
                "Moto Taxi",
                "Dinheiro",
            )

        val offerData = parser.parseOffer(lines.joinToString("\n"), lines)

        assertNotNull(offerData)
        assertEquals("5,0", offerData?.get("avaliacao"))
    }
}
