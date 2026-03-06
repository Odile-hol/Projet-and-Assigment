List<int> processList(List<int> numbers, bool Function(int) predicate) {
  List<int> result = [];
  for (int number in numbers) {
    if (predicate(number)) {
      result.add(number);
    }
  }
  return result;
}

void main() {
  List<int> nums = [1, 2, 3, 4, 5, 6];
  List<int> even = processList(nums, (number) => number % 2 == 0);
  print(even);
}
