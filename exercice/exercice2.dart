void main() {
 
  List<String> words = ["apple", "cat", "banana", "dog", "elephant"];

  Map<String, int> wordLengthMap = {};

  for (String word in words) {
    wordLengthMap[word] = word.length;
  }

  wordLengthMap.forEach((word, length) {
    if (length > 4) {
      print("$word a une longueur de $length");
    }
  });

  print("\n--- Avec filter et forEach ---");
  Map<String, int> map = {for (var word in words) word: word.length};

  map.entries.where((entry) => entry.value > 4).forEach((entry) {
    print("${entry.key} a une longueur de ${entry.value}");
  });
}

Map<String, int> createLengthMap(List<String> words) {
  return {for (var word in words) word: word.length};
}

void printLongWords(Map<String, int> map, {int minLength = 4}) {
  map.entries.where((entry) => entry.value > minLength).forEach((entry) {
    print("${entry.key} a une longueur de ${entry.value}");
  });
}
