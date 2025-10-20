class Student {
  final String id;
  final String name;
  final bool isPresent;

  Student({required this.id, required this.name, this.isPresent = false});

  Student copyWith({String? id, String? name, bool? isPresent}) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      isPresent: isPresent ?? this.isPresent,
    );
  }
}