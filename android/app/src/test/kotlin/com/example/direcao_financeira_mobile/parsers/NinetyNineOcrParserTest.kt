package com.example.direcao_financeira_mobile.parsers

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class NinetyNineOcrParserTest {

    private val parser = NinetyNineOcrParser()

    @Test
    fun `extrai origem e destino a partir dos blocos de rota da 99`() {
        val lines =
            listOf(
                "Máquina cartão",
                "R$13,90",
                "Passageiro novo",
                "Perfil Premium",
                "11min (3,2km)",
                "Rua do Jacarandá, 120, Matozinhos",
                "9min (2,4km)",
                "Upa São João Del Rei, Rua Mal. Ciro Espírito Santo Cardoso, 173 - CAIEI...",
                "Google",
            )

        val rawText = lines.joinToString("\n")
        val offerData = parser.parseOffer(rawText, lines)

        assertNotNull(offerData)
        assertEquals("Rua do Jacarandá, 120, Matozinhos", offerData?.get("origin_address"))
        assertEquals(
            "Upa São João Del Rei, Rua Mal. Ciro Espírito Santo Cardoso, 173 - CAIEI...",
            offerData?.get("destination_address"),
        )
    }

    @Test
    fun `ignora textos do mapa e do card ao procurar endereco da 99`() {
        val lines =
            listOf(
                "Santa Cruz de Minas",
                "Matozinhos",
                "Máquina cartão",
                "R$13,90",
                "Perfil Premium",
                "11min (3,2km)",
                "Rua do Jacarandá, 120, Matozinhos",
                "9min (2,4km)",
                "Upa São João Del Rei, Rua Mal. Ciro Espírito Santo Cardoso, 173 - CAIEI...",
                "Google",
            )

        val rawText = lines.joinToString("\n")
        val offerData = parser.parseOffer(rawText, lines)

        assertNotNull(offerData)
        assertEquals("Rua do Jacarandá, 120, Matozinhos", offerData?.get("origin_address"))
        assertEquals(
            "Upa São João Del Rei, Rua Mal. Ciro Espírito Santo Cardoso, 173 - CAIEI...",
            offerData?.get("destination_address"),
        )
    }

    @Test
    fun `nao trata endereco com carros como tipo de corrida da 99`() {
        val lines =
            listOf(
                "Pagamento no app",
                "R$16,40",
                "R$2,78/km",
                "5,00 · 4 corridas",
                "Perfil Essencial",
                "6min (2,3km)",
                "R. Imigrante Marcos Davim, 267 - Nascente do Sol (Colônia do Marçal)",
                "8min (3,6km)",
                "Localiza Aluguel de Carros, Avenida Leite de Castro, 737 - Fábricas",
            )

        val rawText = lines.joinToString("\n")
        val offerData = parser.parseOffer(rawText, lines)

        assertNotNull(offerData)
        assertEquals(
            "R. Imigrante Marcos Davim, 267 - Nascente do Sol (Colônia do Marçal)",
            offerData?.get("origin_address"),
        )
        assertEquals(
            "Localiza Aluguel de Carros, Avenida Leite de Castro, 737 - Fábricas",
            offerData?.get("destination_address"),
        )
        assertEquals("", offerData?.get("tipo_corrida"))
    }

    @Test
    fun `usa ultimo endereco como destino quando oferta da 99 tem parada`() {
        val lines =
            listOf(
                "Pagamento no app",
                "R$24,80",
                "5,00 Â· 12 corridas",
                "Perfil Essencial",
                "4min (1,1km)",
                "Rua Origem, 10 - Centro",
                "7min (2,5km)",
                "Rua Parada Intermediaria, 20 - Centro",
                "13min (5,8km)",
                "Avenida Destino Final, 300 - Bairro Final",
            )

        val rawText = lines.joinToString("\n")
        val offerData = parser.parseOffer(rawText, lines)

        assertNotNull(offerData)
        assertEquals("Rua Origem, 10 - Centro", offerData?.get("origin_address"))
        assertEquals(
            "Avenida Destino Final, 300 - Bairro Final",
            offerData?.get("destination_address"),
        )
    }
}
