# 📊 Grade Calculator & Application de Bilan Scolaire

Ce projet est une application mobile développée avec le framework **Flutter**. Elle est conçue pour automatiser le calcul des moyennes académiques, la gestion des grades et la visualisation des performances des étudiants.

> **Note de développement :** L'intégralité de la logique métier, des algorithmes de calcul et des structures de données a été programmée en **Dart**.

---

## 🚀 Fonctionnalités Clés

* **Calcul de Moyenne Intelligent :** Algorithme Dart permettant de calculer la moyenne pondérée en temps réel.
* **Génération de Grades :** Attribution automatique des mentions (A, B, C...) basée sur les seuils de réussite définis.
* **Importation de Données (Excel) :** Capacité d'importer des fichiers `.xlsx` pour charger des listes de notes massives sans saisie manuelle.
* **Visualisation Graphique :** Intégration de la bibliothèque `fl_chart` pour afficher l'évolution des résultats sous forme de graphiques intuitifs.
* **Interface Material 3 :** Design moderne et adaptatif pour une expérience utilisateur fluide sur Android et iOS.

---

## 🛠️ Détails Techniques (Programmation Dart)

En tant que développeur principal sur la partie logique, j'ai mis en place :
* **Modélisation POO :** Création de classes `Student` et `Grade` pour structurer les données.
* **Parsing de données :** Gestion des flux asynchrones pour la lecture des fichiers Excel.
* **Logique de validation :** Systèmes de contrôle pour éviter les erreurs de saisie (notes négatives, hors limites).

---

## 📁 Structure du Projet

* `lib/` : Contient tout le code source **Dart**.
* `assets/` : Contient les icônes et les polices de caractères.
* `ressources/` : Inclut un modèle `tableau.xlsx` pour tester l'importation.

---

## ⚙️ Installation et Lancement

1.  **Prérequis :** Avoir Flutter installé sur votre machine.
2.  **Récupérer les dépendances :**
    ```bash
    flutter pub get
    ```
3.  **Lancer l'application :**
    ```bash
    flutter run
    ```

---

## 👥 Peer Review
Ce projet a été soumis à une révision de code (Code Review) via une **Pull Request** pour valider la qualité de l'implémentation Dart et l'architecture Flutter, conformément aux standards du cours.

---
**Développeur :** Odile  
**Langage :** Dart 🎯  
**Framework :** Flutter 💙
