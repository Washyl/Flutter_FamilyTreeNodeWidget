class Person {
  final int id;
  final String firstName;
  final String lastName;
  final String? label;
  final int type;
  final String? born;
  final bool disinherited;
  final int? parentBranch;
  List<Family> children;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.label,
    required this.type,
    this.born,
    required this.disinherited,
    this.parentBranch,
    this.children = const [],
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    var children = json['children'] as List<dynamic>? ?? [];
    return Person(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      label: json['label'],
      type: json['type'],
      born: json['born'],
      disinherited: json['disinherited'] ?? false,
      parentBranch: json['parent_branch'],
      children: children.map((child) => Family.fromJson(child)).toList(),
    );
  }
}

class Family {
  final Person? firstPerson;
  final Person? secondPerson;
  List<Family> children;

  Family({
    this.firstPerson,
    this.secondPerson,
    this.children = const [],
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    var children = json['children'] as List<dynamic>? ?? [];
    return Family(
      firstPerson: json['firstPerson'] != null ? Person.fromJson(json['firstPerson']) : null,
      secondPerson: json['secondPerson'] != null ? Person.fromJson(json['secondPerson']) : null,
      children: children.map((child) => Family.fromJson(child)).toList(),
    );
  }
}
