import 'package:flutter/material.dart';

class Etudiant {
  final String nom;
  final List<double> notes;

  Etudiant(this.nom, this.notes);

  // Lambda pour la moyenne
  double get moyenne =>
      notes.isEmpty ? 0 : notes.reduce((a, b) => a + b) / notes.length;

  // Logique métier condensée
  String get mention => moyenne >= 16
      ? "Très Bien"
      : moyenne >= 14
      ? "Bien"
      : moyenne >= 12
      ? "Assez Bien"
      : moyenne >= 10
      ? "Passable"
      : "Insuffisant";

  String get grade => moyenne >= 16
      ? "A"
      : moyenne >= 14
      ? "B"
      : moyenne >= 12
      ? "C"
      : moyenne >= 10
      ? "D"
      : "F";

  Color get color =>
      moyenne >= 10 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
}
