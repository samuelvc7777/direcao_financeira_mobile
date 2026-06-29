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

    @Test
    fun `extrai oferta da 99 com dinheiro passageiro novo e perfil essencial`() {
        val lines =
            listOf(
                "Dinheiro",
                "R$14,40",
                "R$2,63/km",
                "Passageiro novo",
                "Perfil Essencial",
                "6min (2,2km)",
                "Rua Sinesio Felix da Silva, 260 - Vila Sao Vicente (Colonia do Marcal)",
                "5min (3,3km)",
                "R. do Pica Pau, 220 - Sao Francisco (Colonia do Marcal)",
            )

        val rawText = lines.joinToString("\n")
        val offerData = parser.parseOffer(rawText, lines)

        assertNotNull(offerData)
        assertEquals("R$14,40", offerData?.get("valor_bruto"))
        assertEquals(5.5, offerData?.get("km_total") as Double, 0.01)
        assertEquals(11, offerData["minutos_total"])
        assertEquals("Dinheiro", offerData["forma_pagamento"])
        assertEquals(
            "Rua Sinesio Felix da Silva, 260 - Vila Sao Vicente (Colonia do Marcal)",
            offerData["origin_address"],
        )
        assertEquals(
            "R. do Pica Pau, 220 - Sao Francisco (Colonia do Marcal)",
            offerData["destination_address"],
        )
    }
    @Test
    fun `ocr posicional le entrega carro premium pelas regioes do card`() {
        val lines =
            listOf(
                NinetyNineOcrParser.OcrLine("Barbacena", 70, 110, 145, 130),
                NinetyNineOcrParser.OcrLine("Entrega Carro", 120, 150, 225, 172),
                NinetyNineOcrParser.OcrLine("R$13,00", 95, 180, 245, 225),
                NinetyNineOcrParser.OcrLine("R$2,28/km", 125, 230, 215, 250),
                NinetyNineOcrParser.OcrLine("Preco x1,4", 120, 260, 220, 282),
                NinetyNineOcrParser.OcrLine("4,93 · Perfil Premium", 38, 315, 235, 338),
                NinetyNineOcrParser.OcrLine("5min (1,4km)", 38, 370, 165, 394),
                NinetyNineOcrParser.OcrLine("Acougue, Rua Mal. Floriano Peixoto, 135 - Centro, Barbacena - MG", 52, 400, 315, 444),
                NinetyNineOcrParser.OcrLine("10min (4,3km)", 38, 460, 175, 484),
                NinetyNineOcrParser.OcrLine("Rua Luis Claudio dos Santos, 318 - Jardim das Alterosas", 52, 490, 315, 534),
            ).shuffled()

        val offerData = parser.parsePositionedOffer(lines.joinToString("\n") { it.text }, lines)

        assertNotNull(offerData)
        assertEquals("R$13,00", offerData?.get("valor_bruto"))
        assertEquals(5.7, offerData?.get("km_total") as Double, 0.01)
        assertEquals(15, offerData["minutos_total"])
        assertEquals("4,93", offerData["avaliacao"])
        assertEquals("Premium", offerData["passenger_name"])
        assertEquals("Entrega Carro", offerData["tipo_corrida"])
        assertEquals("Acougue, Rua Mal. Floriano Peixoto, 135 - Centro, Barbacena - MG", offerData["origin_address"])
        assertEquals("Rua Luis Claudio dos Santos, 318 - Jardim das Alterosas", offerData["destination_address"])
    }

    @Test
    fun `ocr posicional le negocia dinheiro essencial e ignora valores dos botoes`() {
        val lines =
            listOf(
                NinetyNineOcrParser.OcrLine("Remedios", 270, 80, 335, 100),
                NinetyNineOcrParser.OcrLine("Negocia · Dinheiro", 105, 130, 255, 154),
                NinetyNineOcrParser.OcrLine("R$12,60", 105, 165, 245, 210),
                NinetyNineOcrParser.OcrLine("R$2,17/km", 125, 218, 220, 238),
                NinetyNineOcrParser.OcrLine("Preco x1,7", 125, 250, 220, 272),
                NinetyNineOcrParser.OcrLine("4,88 · 162 corridas", 55, 310, 225, 334),
                NinetyNineOcrParser.OcrLine("Perfil Essencial", 55, 342, 190, 365),
                NinetyNineOcrParser.OcrLine("7min (2,5km)", 55, 405, 180, 429),
                NinetyNineOcrParser.OcrLine("Campos Distribuidora, Rua Sena Madureira - Pontilhao", 72, 435, 318, 476),
                NinetyNineOcrParser.OcrLine("8min (3,3km)", 55, 490, 180, 514),
                NinetyNineOcrParser.OcrLine("Rua Ulisses Magri, 37, Ipanema", 72, 520, 300, 548),
                NinetyNineOcrParser.OcrLine("Aceitar por R$12,60", 95, 565, 270, 595),
                NinetyNineOcrParser.OcrLine("R$13,23", 55, 610, 115, 635),
                NinetyNineOcrParser.OcrLine("R$13,61", 125, 610, 185, 635),
                NinetyNineOcrParser.OcrLine("R$13,86", 195, 610, 255, 635),
            ).shuffled()

        val offerData = parser.parsePositionedOffer(lines.joinToString("\n") { it.text }, lines)

        assertNotNull(offerData)
        assertEquals("R$12,60", offerData?.get("valor_bruto"))
        assertEquals(5.8, offerData?.get("km_total") as Double, 0.01)
        assertEquals(15, offerData["minutos_total"])
        assertEquals("4,88", offerData["avaliacao"])
        assertEquals(162, offerData["corridas_total"])
        assertEquals("Essencial", offerData["passenger_name"])
        assertEquals("Negocia", offerData["tipo_corrida"])
        assertEquals("Dinheiro", offerData["forma_pagamento"])
        assertEquals("Campos Distribuidora, Rua Sena Madureira - Pontilhao", offerData["origin_address"])
        assertEquals("Rua Ulisses Magri, 37, Ipanema", offerData["destination_address"])
    }

    @Test
    fun `le oferta nova da 99 com primeira perna em metros`() {
        val lines =
            listOf(
                "Dinheiro",
                "Prioritario",
                "R$6,00",
                "R$2,02/km",
                "R$1,23 Tarifa base dinamica incl.",
                "4,98 · 183 corridas",
                "Perfil Premium",
                "5min (590m)",
                "Supermercados Bh, R. Lima Duarte, 59 - Centro",
                "8min (2,4km)",
                "Rua Maria Antonia de Castro, 136, Funcionarios",
            )

        val offerData = parser.parseOffer(lines.joinToString("\n"), lines)

        assertNotNull(offerData)
        assertEquals("R$6,00", offerData?.get("valor_bruto"))
        assertEquals(2.02, offerData?.get("ganho_km") as Double, 0.01)
        assertEquals(2.99, offerData?.get("km_total") as Double, 0.01)
        assertEquals(13, offerData["minutos_total"])
        assertEquals("4,98", offerData["avaliacao"])
        assertEquals(183, offerData["corridas_total"])
        assertEquals("Premium", offerData["passenger_name"])
        assertEquals("Dinheiro", offerData["forma_pagamento"])
        assertEquals("Supermercados Bh, R. Lima Duarte, 59 - Centro", offerData["origin_address"])
        assertEquals("Rua Maria Antonia de Castro, 136, Funcionarios", offerData["destination_address"])
    }

    @Test
    fun `le oferta nova da 99 com parada sem usar parada como endereco`() {
        val lines =
            listOf(
                "Pgto. no app",
                "Prioritario",
                "R$12,10",
                "R$2,11/km",
                "R$2,87 Tarifa base dinamica incl.",
                "4,96 · 461 corridas",
                "Perfil Essencial",
                "3min (138m)",
                "Lanchonete, Pca. Pedro Teixeira",
                "1 parada(s)",
                "15min (5,6km)",
                "Rua Maj. Suckow, 1101, Nova Suica",
            )

        val offerData = parser.parseOffer(lines.joinToString("\n"), lines)

        assertNotNull(offerData)
        assertEquals("R$12,10", offerData?.get("valor_bruto"))
        assertEquals(2.11, offerData?.get("ganho_km") as Double, 0.01)
        assertEquals(5.738, offerData?.get("km_total") as Double, 0.001)
        assertEquals(18, offerData["minutos_total"])
        assertEquals("4,96", offerData["avaliacao"])
        assertEquals(461, offerData["corridas_total"])
        assertEquals("Essencial", offerData["passenger_name"])
        assertEquals("Lanchonete, Pca. Pedro Teixeira", offerData["origin_address"])
        assertEquals("Rua Maj. Suckow, 1101, Nova Suica", offerData["destination_address"])
    }

    @Test
    fun `nao usa numero de corridas como nota da 99`() {
        val lines =
            listOf(
                "Dinheiro",
                "R$6,90",
                "R$1,54/km",
                "R$1,23 Tarifa base dinamica incl.",
                "4,85 · 108 corridas",
                "Perfil Premium",
                "7min (1,7km)",
                "Praca Dom Bosco, R. Luis Moreira da Cruz",
                "7min (2,7km)",
                "Rua Mariano Procopio, 174, Sao Jose",
            )

        val offerData = parser.parseOffer(lines.joinToString("\n"), lines)

        assertNotNull(offerData)
        assertEquals("4,85", offerData?.get("avaliacao"))
        assertEquals(108, offerData?.get("corridas_total"))
        assertEquals(1.54, offerData?.get("ganho_km") as Double, 0.01)
        assertEquals(4.4, offerData?.get("km_total") as Double, 0.01)
    }

    @Test
    fun `le um km mesmo quando ocr troca numero um por letra`() {
        val lines =
            listOf(
                "Dinheiro",
                "R$6,00",
                "R$2,74/km",
                "4,87 · 73 corridas",
                "Perfil Essencial",
                "6min (Ikm)",
                "Escola Municipal Padre Sinfronio de Castro, Praca Dr. Joviano Jardim",
                "3min (1,2km)",
                "Magazine Luiza, Rua 15 de Novembro, 32 - Centro",
            )

        val offerData = parser.parseOffer(lines.joinToString("\n"), lines)

        assertNotNull(offerData)
        assertEquals("4,87", offerData?.get("avaliacao"))
        assertEquals(73, offerData?.get("corridas_total"))
        assertEquals(2.74, offerData?.get("ganho_km") as Double, 0.01)
        assertEquals(2.2, offerData?.get("km_total") as Double, 0.01)
        assertEquals(9, offerData["minutos_total"])
    }

    @Test
    fun `junta destino da 99 quando ocr quebra endereco em varias linhas`() {
        val lines =
            listOf(
                "Dinheiro",
                "R$7,10",
                "R$2,21/km",
                "4,99 · 187 corridas",
                "CPF verif.",
                "3min (251m)",
                "Autoescola Social Barbacena, Praca",
                "Conde de Prados, 99 - Centro",
                "1 parada(s)",
                "10min (3km)",
                "Oratorio Diario Madre Madalena",
                "Morano - Rede Salesiana Brasil, Rua Vigario Brito",
            )

        val offerData = parser.parseOffer(lines.joinToString("\n"), lines)

        assertNotNull(offerData)
        assertEquals(
            "Autoescola Social Barbacena, Praca Conde de Prados, 99 - Centro",
            offerData?.get("origin_address"),
        )
        assertEquals(
            "Oratorio Diario Madre Madalena Morano - Rede Salesiana Brasil, Rua Vigario Brito",
            offerData?.get("destination_address"),
        )
    }
}
