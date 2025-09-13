// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';



class Section {
  final  int id;

  final String name;

  Section({
    required this.id,
    required this.name,
  });

  Section copyWith({
    int? id,
    String? name,
  }) {
    return Section(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Section.fromJson(String source) => Section.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Section(id: $id, name: $name)';

  @override
  bool operator ==(covariant Section other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}














