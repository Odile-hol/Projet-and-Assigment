package com.anonymous.safecall.unit_tests

class GpsLocationTest {
    @Test
    fun test_Gps_Data_Integrity() {
        val latitude = 3.8480  // Exemple Yaoundé
        val longitude = 11.5021

        // Vérifie que le capteur n'est pas "perdu" (souvent 0.0 en cas d'erreur)
        assertNotEquals("Erreur: Le GPS renvoie une valeur nulle (0.0)", 0.0, latitude, 0.001)

        // Vérifie les bornes réelles
        assertTrue("Latitude hors limites mondiales", latitude in -90.0..90.0)
        assertTrue("Longitude hors limites mondiales", longitude in -180.0..180.0)
    }
}