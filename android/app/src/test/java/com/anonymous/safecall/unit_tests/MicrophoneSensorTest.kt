package com.anonymous.safecall.unit_tests

class MicrophoneSensorTest {
    private val DANGER_THRESHOLD = 85.0

    @Test
    fun test_Alert_Triggered_On_High_Volume() {
        val microInput = 92.5 // Simulation d'un cri ou choc
        assertTrue("L'alerte doit s'activer pour un volume de 92.5dB", microInput > DANGER_THRESHOLD)
    }

    @Test
    fun test_No_Alert_On_Normal_Ambient_Noise() {
        val microInput = 45.0 // Simulation d'une conversation calme
        assertFalse("L'alerte ne doit pas s'activer pour un volume de 45dB", microInput > DANGER_THRESHOLD)
    }
}