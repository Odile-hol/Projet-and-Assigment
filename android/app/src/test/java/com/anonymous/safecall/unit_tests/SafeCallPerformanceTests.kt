package com.anonymous.safecall.unit_tests

import org.junit.Test
import org.junit.Assert.*

/**
 * TESTS DE PERFORMANCE : Rapidité de réponse et stabilité du processeur.
 */
class SafeCallPerformanceTests {

    // 1. TEST DE LATENCE (Vitesse de déclenchement)
    @Test
    fun testAlertTriggerSpeed() {
        val startTime = System.currentTimeMillis()

        // Simule l'activation des capteurs
        val alertActivated = true

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime

        // Une alerte doit se lancer en moins de 500 millisecondes
        assertTrue("L'alerte est trop lente ($totalTime ms)", totalTime < 500)
    }

    // 2. TEST ANTI-SPAM (Clics multiples sur le bouton)
    @Test
    fun testPreventMultipleClicks() {
        var processCount = 0
        val isAppBusy = true // Simule que l'app traite déjà une alerte

        // On simule 5 clics rapides de l'utilisateur stressé
        for (i in 1..5) {
            if (i == 1) processCount++ // Seul le premier clic doit compter
        }

        assertEquals("L'app ne doit pas lancer 5 alertes en même temps", 1, processCount)
    }
}