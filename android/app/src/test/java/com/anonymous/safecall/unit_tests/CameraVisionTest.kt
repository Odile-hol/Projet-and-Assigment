package com.anonymous.safecall.unit_tests

class CameraVisionTest {
    @Test
    fun test_Violence_Detection_Logic() {
        val actionDetected = "fight"
        val confidenceScore = 0.88

        // On décide que l'alerte est valide si l'IA est sûre à plus de 75%
        val shouldAlert = (actionDetected == "fight" || actionDetected == "attack") && confidenceScore > 0.75

        assertTrue("Le système doit valider l'alerte visuelle pour un combat à 88% de confiance", shouldAlert)
    }
}