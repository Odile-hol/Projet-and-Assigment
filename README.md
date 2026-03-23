# 🛡️ Module SafeCall - Tests de Fiabilité et Robustesse

Ce module regroupe l'ensemble des tests automatisés pour garantir le fonctionnement critique de l'application **SafeCall** (Microphone, GPS, Batterie, Performance).

## 🚀 Objectifs du Projet
L'objectif est de valider l'accès aux capteurs et le comportement de l'application dans des conditions dégradées, en suivant les principes de la **Clean Architecture** (découplage total du code partenaire).

---

## 🧪 Stratégie de Test (4 Niveaux)

### 1. Tests Unitaires (`SafeCallUnitTests.kt`)
* Vérification de l'initialisation du flux **Audio**.
* Validation de la détection des capteurs **GPS** et **Caméra**.

### 2. Tests de Robustesse (`SafeCallRobustnessTest.kt`)
* **Gestion du Réseau :** Comportement en "Zone Blanche" (absence de signal GPS).
* **Gestion de l'Énergie :** Passage automatique en mode économie si la batterie est < 5%.
* **Protection Stockage :** Prévention des crashs si la mémoire du téléphone est saturée.

### 3. Tests de Performance (`SafeCallPerformanceTests.kt`)
* **Latence :** Déclenchement de l'alerte en moins de **500ms**.
* **Anti-Spam :** Protection contre les clics multiples accidentels sur le bouton d'urgence.

### 4. Tests d'Intégration (`SafeCallIntegrationTests.kt`)
* Validation du format d'échange de données entre mon module et le module principal (Binôme).

---

## 🛠️ Installation et Exécution
1. Ouvrir le projet sous **Android Studio**.
2. Naviguer vers : `android/app/src/test/java/com/anonymous/safecall/unit_tests/`.
3. Clic droit sur le dossier et sélectionner **"Run All Tests"**.

## 📈 Indépendance Logicielle
Ce dossier a été conçu pour être **100% testable indépendamment** du reste du projet, permettant une maintenance simplifiée même si le code global évolue.
