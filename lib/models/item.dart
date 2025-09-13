// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ItemSection {
  final int id;
  final String name;
  final String? filePath;
  final String? fileType;// null
  final int idSection;

  ItemSection({
    required this.id,
    required this.name,
    this.filePath,
    this.fileType,
    required this.idSection,
  });

  ItemSection copyWith({
    int? id,
    String? itemName,
    String? filePath,
    String? fileType,
    int? idSection,
  }) {
    return ItemSection(
      id: id ?? this.id,
      name: itemName ?? this.name,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      idSection: idSection ?? this.idSection,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'itemName': name,
      'filePath': filePath,
      'fileType': fileType,
      'idSection': idSection,
    };
  }

  factory ItemSection.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as int;
    final itemName = map['name'] as String;
    final filePath = map['filePath'] as String?;
    final fileType = map['fileType'] as String?;
    final idSection = map['sectionId'] as int;

    return ItemSection(
      id: id,
      name: itemName,
      filePath: filePath,
      fileType: fileType,
      idSection: idSection,
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemSection.fromJson(String source) =>
      ItemSection.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ItemSection(id: $id, itemName: $name, filePath: $filePath, fileType: $fileType, idSection: $idSection)';
  }

  @override
  bool operator ==(covariant ItemSection other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.filePath == filePath &&
        other.fileType == fileType &&
        other.idSection == idSection;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        filePath.hashCode ^
        fileType.hashCode ^
        idSection.hashCode;
  }
}
