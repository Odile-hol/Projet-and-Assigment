// Définition de la classe Person (équivalent d'une data class en Kotlin)
class Person {
  final String name;
  final int age;

  // Constructeur
  Person(this.name, this.age);

  // Pour un affichage plus lisible (optionnel)
  @override
  String toString() => 'Person(name: $name, age: $age)';
}

void main() {
  // Liste de personnes (similaire à l'exemple)
  List<Person> people = [
    Person("Alice", 25),
    Person("Bob", 30),
    Person("Charlie", 35),
    Person("Anna", 22),
    Person("Ben", 28),
    // Ajout d'un cas de test avec un nom commençant par une minuscule
    Person(
      "arthur",
      40,
    ), // Ne sera pas inclus car 'a' minuscule != 'A' majuscule
  ];

  // Solution en suivant les étapes

  // Étape 1: Filtrer les personnes dont le nom commence par 'A' ou 'B'
  List<Person> filteredPeople = people.where((person) {
    // Prendre la première lettre du nom et la mettre en majuscule pour la comparaison
    String firstLetter = person.name[0].toUpperCase();
    return firstLetter == 'A' || firstLetter == 'B';
  }).toList();

  // Afficher les personnes filtrées (pour vérification)
  print('Personnes avec noms commençant par A ou B:');
  filteredPeople.forEach(print);

  // Étape 2: Extraire les âges
  List<int> ages = filteredPeople.map((person) => person.age).toList();

  // Étape 3: Calculer la moyenne
  double averageAge = 0;
  if (ages.isNotEmpty) {
    // Somme de tous les âges divisée par le nombre de personnes
    averageAge = ages.reduce((sum, age) => sum + age) / ages.length;
  }

  // Étape 4: Formater et afficher avec une décimale
  // Utilisation de toStringAsFixed pour arrondir à 1 décimale
  print('\nÂge moyen des personnes dont le nom commence par A ou B:');
  print('${averageAge.toStringAsFixed(1)} ans');

  // --- Version plus concise avec une approche fonctionnelle ---
  print('\n--- Version concise ---');

  double avgAge =
      people
          .where((p) => 'AB'.contains(p.name[0].toUpperCase()))
          .map((p) => p.age)
          .fold(0, (sum, age) => sum + age) /
      people.where((p) => 'AB'.contains(p.name[0].toUpperCase())).length;

  print('Âge moyen: ${avgAge.toStringAsFixed(1)} ans');
}

// Extension optionnelle pour ajouter une méthode à List<Person>
extension PersonListUtils on List<Person> {
  double averageAgeWithInitials(String initials) {
    var filtered = where((p) => initials.contains(p.name[0].toUpperCase()));
    if (filtered.isEmpty) return 0;
    return filtered.map((p) => p.age).reduce((a, b) => a + b) / filtered.length;
  }
}

// Version alternative avec gestion des cas particuliers et tests
void alternativeSolution() {
  List<Person> people = [
    Person("Alice", 25),
    Person("Bob", 30),
    Person("Charlie", 35),
    Person("Anna", 22),
    Person("Ben", 28),
  ];

  // Fonction pour calculer la moyenne d'âge pour des initiales données
  double calculateAverageAgeForInitials(List<Person> people, String initials) {
    // Mettre les initiales en majuscules pour la comparaison
    String upperInitials = initials.toUpperCase();

    // Filtrer et collecter les âges
    List<int> ages = [];
    for (var person in people) {
      if (upperInitials.contains(person.name[0].toUpperCase())) {
        ages.add(person.age);
      }
    }

    // Calculer la moyenne
    if (ages.isEmpty) {
      return 0;
    }

    int sum = 0;
    for (int age in ages) {
      sum += age;
    }

    return sum / ages.length;
  }

  double result = calculateAverageAgeForInitials(people, 'AB');
  print('Résultat: ${result.toStringAsFixed(1)}');
}
