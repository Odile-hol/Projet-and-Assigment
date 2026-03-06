import 'dart:io';
import 'dart:math';

class Etudiant {
  final String nom;
  final List<double?> notes;

  Etudiant(this.nom, this.notes);
}

void main() {
  print('=== CALCULATEUR DE NOTES D\'ÉTUDIANT ===');
  print('Ce programme calcule la moyenne et les statistiques\n');

  while (true) {
    print('\n--- MENU ---');
    print('1. Saisir un étudiant');
    print('2. Voir démo');
    print('3. Quitter');
    stdout.write('Choix: ');

    final choix = stdin.readLineSync()?.trim();

    if (choix == null || choix.isEmpty) {
      print("Entrée invalide !");
      continue;
    }

    switch (choix) {
      case '1':
        saisirEtudiant();
        break;
      case '2':
        demoTraitementGroupe();
        break;
      case '3':
        print('Au revoir 👋');
        return;
      default:
        print('Choix invalide');
    }
  }
}

void saisirEtudiant() {
  stdout.write('\nNom de l\'étudiant: ');
  final nom = stdin.readLineSync()?.trim() ?? '';

  if (nom.isEmpty) {
    print('Nom invalide');
    return;
  }

  final notes = <double?>[];

  print('\nEntrez les notes (0-20). Entrée vide pour arrêter.');

  while (true) {
    stdout.write('Note ${notes.length + 1}: ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) break;

    final note = double.tryParse(input);

    if (note == null) {
      print('Format invalide');
      continue;
    }

    if (note < 0 || note > 20) {
      print('La note doit être entre 0 et 20');
      continue;
    }

    notes.add(note);
  }

  final etudiant = Etudiant(nom, notes);
  afficherResultats(etudiant);
}

void afficherResultats(Etudiant etudiant) {
  print('\n' + '=' * 40);
  print('RÉSULTATS POUR ${etudiant.nom.toUpperCase()}');
  print('=' * 40);

  final notesValides = etudiant.notes.whereType<double>().toList();

  if (notesValides.isEmpty) {
    print('Aucune note valide.');
    return;
  }

  // Moyenne
  final somme = notesValides.fold(0.0, (a, b) => a + b);
  final moyenne = somme / notesValides.length;

  print('\nMoyenne: ${moyenne.toStringAsFixed(2)}/20');

  // Grade
  String grade;
  if (moyenne >= 16) {
    grade = 'A (Excellent)';
  } else if (moyenne >= 14) {
    grade = 'B (Très Bien)';
  } else if (moyenne >= 12) {
    grade = 'C (Bien)';
  } else if (moyenne >= 10) {
    grade = 'D (Passable)';
  } else {
    grade = 'F (Insuffisant)';
  }

  print('Grade: $grade');

  // Statistiques
  final noteMax = notesValides.reduce(max);
  final noteMin = notesValides.reduce(min);

  print('\nStatistiques:');
  print('Meilleure note: $noteMax');
  print('Moins bonne note: $noteMin');

  // Médiane
  final notesTriees = List<double>.from(notesValides)..sort();
  double mediane;

  if (notesTriees.length % 2 == 0) {
    mediane = (notesTriees[notesTriees.length ~/ 2 - 1] +
            notesTriees[notesTriees.length ~/ 2]) /
        2;
  } else {
    mediane = notesTriees[notesTriees.length ~/ 2];
  }

  print('Médiane: ${mediane.toStringAsFixed(2)}');

  print('=' * 40);
}

void demoTraitementGroupe() {
  final etudiants = [
    Etudiant('Alice', [18.5, 16.0, 19.0]),
    Etudiant('Bob', [12.0, 8.5, 10.0]),
    Etudiant('Charlie', [5.0, 7.0, 6.0]),
  ];

  for (var etudiant in etudiants) {
    afficherResultats(etudiant);
  }
}
