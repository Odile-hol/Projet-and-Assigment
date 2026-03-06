void main() {
  List<int> numbers = [1, 4, 7, 3, 9, 2, 8];

  var result = numbers
      .where((n) => n > 5) // Filtrer les nombres > 5
      .map((n) => n * n); // Mettre au carré

  result.forEach(print); // Afficher chaque résultat
}
