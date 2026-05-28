package com.example.direcao_financeira_mobile.parsers

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MoveSjParserTest {

    private val parser = MoveSjParser()

    @Test
    fun `mantem origem e destino na ordem correta quando endereco esta quebrado em linhas`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "R$ 18,50",
                        "5,4 km (R$ 3,42 / km)",
                        "17 min (R$ 1,08 / min)",
                        "1,3 km (3 min)",
                        "Rua Antonio Floriano da Silva, 5 - Sao Joao del Rei - MG",
                        "1,1 km (3 min)",
                        "Igreja de Sao Francisco de Assis -",
                        "Praca Frei Orlando - Centro, Sao Joao del Rei - MG",
                        "Deslize para aceitar",
                    ),
                priceText = "R$ 18,50",
            )

        assertEquals(
            "Rua Antonio Floriano da Silva, 5 - Sao Joao del Rei - MG",
            offerData["origin_address"],
        )
        assertEquals(
            "Igreja de Sao Francisco de Assis - Praca Frei Orlando - Centro, Sao Joao del Rei - MG",
            offerData["destination_address"],
        )
    }

    @Test
    fun `nao perde sufixo repetido da cidade no segundo endereco`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "1,3 km (3 min)",
                        "Rua A, 10",
                        "Centro, Sao Joao del Rei - MG",
                        "1,1 km (3 min)",
                        "Praca B, 25",
                        "Centro, Sao Joao del Rei - MG",
                    ),
            )

        assertEquals(
            "Rua A, 10 Centro, Sao Joao del Rei - MG",
            offerData["origin_address"],
        )
        assertEquals(
            "Praca B, 25 Centro, Sao Joao del Rei - MG",
            offerData["destination_address"],
        )
    }

    @Test
    fun `mantem origem e destino quando a origem vem com distancia em metros`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "R$ 12,66",
                        "1,5 km (R$ 8,61 / km)",
                        "4 min (R$ 2,98 / min)",
                        "0 m (1 min)",
                        "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG, 36305-174, Brasil",
                        "1,5 km (4 min)",
                        "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG, 36301-182, Brasil",
                        "ACEITAR (12)",
                    ),
                priceText = "R$ 12,66",
            )

        assertEquals(
            "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG, 36305-174, Brasil",
            offerData["origin_address"],
        )
        assertEquals(
            "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG, 36301-182, Brasil",
            offerData["destination_address"],
        )
    }

    @Test
    fun `extrai origem e destino quando endereco vem no mesmo no do trecho da rota`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "R$ 12,66",
                        "1,5 km (R$ 8,61 / km)",
                        "4 min (R$ 2,98 / min)",
                        "0 m (1 min) R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG, 36305-174, Brasil",
                        "1,5 km (4 min) Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG, 36301-182, Brasil",
                        "ACEITAR (12)",
                    ),
                priceText = "R$ 12,66",
            )

        assertEquals(
            "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG, 36305-174, Brasil",
            offerData["origin_address"],
        )
        assertEquals(
            "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG, 36301-182, Brasil",
            offerData["destination_address"],
        )
    }

    @Test
    fun `usa os trechos da rota como fallback para km e minutos`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "1,3 km (3 min)",
                        "Rua Antonio Floriano da Silva, 5 - Sao Joao del Rei - MG",
                        "1,1 km (3 min)",
                        "Praca Frei Orlando - Centro, Sao Joao del Rei - MG",
                    ),
                priceText = "R$ 18,50",
            )

        assertEquals(2.4, offerData["km_total"])
        assertEquals(6, offerData["minutos_total"])
    }

    @Test
    fun `soma trechos em metros no fallback de km e minutos`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "300 m (2 min)",
                        "Rua Antonio Floriano da Silva, 5 - Sao Joao del Rei - MG",
                        "900 m (4 min)",
                        "Praca Frei Orlando - Centro, Sao Joao del Rei - MG",
                    ),
                priceText = "R$ 10,00",
            )

        assertEquals(1.2, offerData["km_total"])
        assertEquals(6, offerData["minutos_total"])
    }

    @Test
    fun `extrai origem destino e duracao quando a movesj informa horas e minutos`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "Move",
                        "1,1x",
                        "Deslize para recusar",
                        "Samuel",
                        "5,00",
                        "R$ 254,25",
                        "(Motorista)",
                        "R$ 254,25",
                        "59,6 km (R$ 4,27/km)",
                        "1 hora 6 min (R$ 3,81/min)",
                        "0 m (1 min)",
                        "R. Getulio Vargas, 989 - A Definir, Santa Cruz de Minas - MG, 36302-142, Brasil",
                        "59,6 km (1 hora 6 min)",
                        "R. Anita Garibalde, 210 - Sao Sebastiao, Barbacena - MG, 36202-314, Brasil",
                        "Deslize para aceitar (5)",
                    ),
                priceText = "R$ 254,25",
            )

        assertEquals(
            "R. Getulio Vargas, 989 - A Definir, Santa Cruz de Minas - MG, 36302-142, Brasil",
            offerData["origin_address"],
        )
        assertEquals(
            "R. Anita Garibalde, 210 - Sao Sebastiao, Barbacena - MG, 36202-314, Brasil",
            offerData["destination_address"],
        )
        assertEquals(59.6, offerData["km_total"])
        assertEquals(66, offerData["minutos_total"])
    }

    @Test
    fun `corrida com parada da movesj usa ultimo pino verde como destino sem salvar paradas`() {
        val offerData =
            parser.parseOfferFromLines(
                lines =
                    listOf(
                        "Move",
                        "Deslize para recusar",
                        "Samuel",
                        "5,00★",
                        "R$ 35,19",
                        "(Motorista)",
                        "R$ 35,19",
                        "8,0 km (R$ 4,42/km)",
                        "22 min (R$ 1,54/min)",
                        "1 m (1 min)",
                        "R. Getulio Vargas, 989 - A Definir, Santa Cruz de Minas - MG, 36302-142, Brasil",
                        "4,0 km (12 min)",
                        "Av. Josue de Queiros, 1119 - Matozinhos, Sao Joao del Rei - MG, 36305-144, Brasil",
                        "4,0 km (10 min)",
                        "Av. Min. Gabriel Passos, 1846 - Santa Cruz De Minas, Santa Cruz de Minas - MG, 36328-000, Brasil",
                        "Deslize para aceitar (8)",
                    ),
                priceText = "R$ 35,19",
            )

        assertEquals(
            "R. Getulio Vargas, 989 - A Definir, Santa Cruz de Minas - MG, 36302-142, Brasil",
            offerData["origin_address"],
        )
        assertEquals(
            "Av. Min. Gabriel Passos, 1846 - Santa Cruz De Minas, Santa Cruz de Minas - MG, 36328-000, Brasil",
            offerData["destination_address"],
        )
        assertFalse(offerData.containsKey("tipo_corrida"))
        assertFalse(offerData.containsKey("stop_addresses"))
    }

    @Test
    fun `reconhece tela da movesj com botoes de aceitar e recusar`() {
        val isOfferScreen =
            parser.isOfferScreenFromLines(
                listOf(
                    "Move",
                    "RECUSAR",
                    "R$ 12,66",
                    "Samuel",
                    "5,00\\u2605",
                    "1,5 km (R$ 8,61 / km)",
                    "4 min (R$ 2,98 / min)",
                    "0 m (1 min)",
                    "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG, 36305-174, Brasil",
                    "1,5 km (4 min)",
                    "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG, 36301-182, Brasil",
                    "ACEITAR (12)",
                ),
            )

        assertTrue(isOfferScreen)
    }

    @Test
    fun `ocr da movesj extrai oferta igual a tela de aceitar`() {
        val lines =
            listOf(
                "Move",
                "RECUSAR",
                "Samuel",
                "R$ 12,66",
                "(Motorista)",
                "R$ 12,66",
                "1,5 km (R$ 8,61/km)",
                "4 min (R$ 2,98/min)",
                "5,00★",
                "0 m (1 min)",
                "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG, 36305-174, Brasil",
                "1,5 km (4 min)",
                "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG, 36301-182, Brasil",
                "ACEITAR (12)",
            )

        val offerData = parser.parseOcrOffer(lines.joinToString("\n"), lines)!!

        assertEquals("MoveSj", offerData["platform_name"])
        assertEquals("R$ 12,66", offerData["valor_bruto"])
        assertEquals("Samuel", offerData["passenger_name"])
        assertEquals(1.5, offerData["km_total"])
        assertEquals(4, offerData["minutos_total"])
        assertEquals(
            "R. Joaquim Portugal, 15 - Matozinhos, Sao Joao del Rei - MG, 36305-174, Brasil",
            offerData["origin_address"],
        )
        assertEquals(
            "Av. Leite de Castro, 617 - Fabricas, Sao Joao del Rei - MG, 36301-182, Brasil",
            offerData["destination_address"],
        )
    }

    @Test
    fun `ocr posicional da movesj separa passageiro origem vermelha e destino verde`() {
        val ocrLines =
            listOf(
                MoveSjParser.OcrLine("Move", 49, 62, 174, 122),
                MoveSjParser.OcrLine("RECUSAR", 168, 219, 343, 255),
                MoveSjParser.OcrLine("R$ 12,66", 423, 408, 709, 480),
                MoveSjParser.OcrLine("(Motorista)", 787, 388, 998, 423),
                MoveSjParser.OcrLine("R$ 12,66", 772, 453, 1009, 501),
                MoveSjParser.OcrLine("1,5 km (R$ 8,61/km)", 421, 535, 866, 574),
                MoveSjParser.OcrLine("4 min (R$ 2,98/min)", 421, 603, 867, 641),
                MoveSjParser.OcrLine("Samuel", 146, 566, 291, 600),
                MoveSjParser.OcrLine("5,00★", 178, 631, 295, 664),
                MoveSjParser.OcrLine("0 m (1 min)", 85, 731, 297, 765),
                MoveSjParser.OcrLine("R. Joaquim Portugal, 15 - Matozinhos, São", 37, 794, 1011, 832),
                MoveSjParser.OcrLine("João del Rei - MG, 36305-174, Brasil", 37, 855, 818, 892),
                MoveSjParser.OcrLine("1,5 km (4 min)", 85, 942, 353, 978),
                MoveSjParser.OcrLine("Av. Leite de Castro, 617 - Fábricas, São João", 37, 1004, 1040, 1041),
                MoveSjParser.OcrLine("del Rei - MG, 36301-182, Brasil", 37, 1065, 697, 1102),
                MoveSjParser.OcrLine("ACEITAR (12)", 363, 1256, 594, 1290),
            ).shuffled()

        val offerData =
            parser.parsePositionedOcrOffer(
                rawText = ocrLines.joinToString("\n") { it.text },
                ocrLines = ocrLines,
            )!!

        assertEquals("Samuel", offerData["passenger_name"])
        assertEquals("R$ 12,66", offerData["valor_bruto"])
        assertEquals(1.5, offerData["km_total"])
        assertEquals(4, offerData["minutos_total"])
        assertEquals(
            "R. Joaquim Portugal, 15 - Matozinhos, São João del Rei - MG, 36305-174, Brasil",
            offerData["origin_address"],
        )
        assertEquals(
            "Av. Leite de Castro, 617 - Fábricas, São João del Rei - MG, 36301-182, Brasil",
            offerData["destination_address"],
        )
    }

    @Test
    fun `resolve valor principal ignorando linhas derivadas por km e por min`() {
        val lines =
            listOf(
                "Move",
                "RECUSAR",
                "Samuel",
                "1,7 km (R$ 7,87/km)",
                "5 min (R$ 2,56/min)",
                "R$ 13,51",
                "(Motorista)",
                "R$ 13,51",
                "ACEITAR (8)",
            )

        val priceText = parser.resolveBestPriceText(lines, lines.joinToString("\n"))

        assertEquals("R$ 13,51", priceText)
    }

    @Test
    fun `ocr da movesj nao usa valor por km como valor bruto`() {
        val lines =
            listOf(
                "Move",
                "RECUSAR",
                "Samuel",
                "1,7 km (R$ 7,87/km)",
                "5 min (R$ 2,56/min)",
                "R$ 13,51",
                "(Motorista)",
                "R$ 13,51",
                "5,00★",
                "7 m (1 min)",
                "R. Herculano Veloso, 413 - Jardim America, Santa Cruz de Minas - MG, 36302-833, Brasil",
                "1,7 km (5 min)",
                "Independente Esporte Clube - Avenida Domingos Pinto Camarano - Colonia do Marcal, Sao Joao del Rei - MG, CEP 36302004, Brasil",
                "ACEITAR (8)",
            )

        val offerData = parser.parseOcrOffer(lines.joinToString("\n"), lines)!!

        assertEquals("R$ 13,51", offerData["valor_bruto"])
        assertEquals(1.7, offerData["km_total"])
        assertEquals(5, offerData["minutos_total"])
    }

    @Test
    fun `ocr posicional da movesj black prioriza valor principal acima das metricas`() {
        val ocrLines =
            listOf(
                MoveSjParser.OcrLine("Move Black", 20, 92, 220, 132),
                MoveSjParser.OcrLine("RECUSAR", 24, 215, 294, 286),
                MoveSjParser.OcrLine("Samuel", 58, 441, 181, 477),
                MoveSjParser.OcrLine("5,00â˜…", 65, 520, 191, 554),
                MoveSjParser.OcrLine("R$ 19,80", 315, 428, 598, 526),
                MoveSjParser.OcrLine("(Motorista)", 644, 403, 869, 442),
                MoveSjParser.OcrLine("R$ 19,80", 642, 464, 857, 514),
                MoveSjParser.OcrLine("3,4 km (R$ 5,76/km)", 316, 548, 714, 592),
                MoveSjParser.OcrLine("R$ 5,76", 320, 554, 746, 640),
                MoveSjParser.OcrLine("9 min (R$ 2,00/min)", 316, 612, 700, 656),
                MoveSjParser.OcrLine("1,2 km (3 min)", 34, 740, 242, 780),
                MoveSjParser.OcrLine("Av. Min. Gabriel Passos, 2172 - Santa", 23, 801, 900, 842),
                MoveSjParser.OcrLine("Cruz De Minas, Santa Cruz de Minas - MG,", 23, 857, 938, 896),
                MoveSjParser.OcrLine("36328-000, Brasil", 23, 912, 356, 950),
                MoveSjParser.OcrLine("2,3 km (6 min)", 34, 1046, 254, 1086),
                MoveSjParser.OcrLine("Independente Esporte Clube - Avenida", 21, 1112, 904, 1152),
                MoveSjParser.OcrLine("Domingos Pinto Camarano - Colônia", 20, 1168, 852, 1208),
                MoveSjParser.OcrLine("do Marçal, São João del Rei - MG, CEP", 20, 1224, 870, 1264),
                MoveSjParser.OcrLine("36302004, Brasil", 20, 1280, 330, 1320),
                MoveSjParser.OcrLine("ACEITAR (7)", 274, 1454, 638, 1510),
            ).shuffled()

        val offerData =
            parser.parsePositionedOcrOffer(
                rawText = ocrLines.joinToString("\n") { it.text },
                ocrLines = ocrLines,
            )!!

        assertEquals("R$ 19,80", offerData["valor_bruto"])
        assertEquals(3.4, offerData["km_total"])
        assertEquals(9, offerData["minutos_total"])
    }

    @Test
    fun `nao reconhece tela generica sem marcadores de oferta`() {
        val isOfferScreen =
            parser.isOfferScreenFromLines(
                listOf(
                    "Move",
                    "Ola, Samuel",
                    "Historico",
                    "Ganhos da semana",
                    "R$ 120,00",
                ),
            )

        assertFalse(isOfferScreen)
    }
}
