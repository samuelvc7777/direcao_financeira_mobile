package com.example.direcao_financeira_mobile.parsers

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UberOcrParserTest {
    private val parser = UberOcrParser()

    @Test
    fun `ocr posicional le oferta uberx pelo card`() {
        val lines =
            listOf(
                UberOcrParser.OcrLine("14:33", 42, 30, 125, 70),
                UberOcrParser.OcrLine("240 m", 170, 22, 295, 70),
                UberOcrParser.OcrLine("BR-265", 380, 240, 500, 290),
                UberOcrParser.OcrLine("UberX", 170, 1020, 310, 1078),
                UberOcrParser.OcrLine("R$ 12,30", 84, 1135, 560, 1240),
                UberOcrParser.OcrLine("4,93 (42)", 165, 1280, 360, 1335),
                UberOcrParser.OcrLine("10 min (4.0 km)", 165, 1420, 460, 1480),
                UberOcrParser.OcrLine("Rua Marco Aurelio Stefani,", 165, 1490, 620, 1545),
                UberOcrParser.OcrLine("Barbacena, Barbacena", 165, 1550, 590, 1605),
                UberOcrParser.OcrLine("11 minutos (4.4 km)", 165, 1608, 510, 1665),
                UberOcrParser.OcrLine("condominio adib kyrillos, 39,", 165, 1690, 680, 1745),
                UberOcrParser.OcrLine("Pontilhao, Barbacena", 165, 1750, 600, 1805),
                UberOcrParser.OcrLine("Aceitar", 390, 1860, 560, 1920),
            )

        val offerData = parser.parsePositionedOffer(lines.joinToString("\n") { it.text }, lines)

        assertNotNull(offerData)
        assertEquals("Uber", offerData!!["app"])
        assertEquals("Uber", offerData["platform_name"])
        assertEquals("R$ 12,30", offerData["valor_bruto"])
        assertEquals(8.4, offerData["km_total"] as Double, 0.01)
        assertEquals(21, offerData["minutos_total"])
        assertEquals("4,93", offerData["avaliacao"])
        assertEquals(42, offerData["corridas_total"])
        assertEquals("UberX", offerData["tipo_corrida"])
        assertTrue(offerData["origin_address"].toString().contains("Marco Aurelio"))
        assertTrue(offerData["destination_address"].toString().contains("adib kyrillos"))
    }
}
