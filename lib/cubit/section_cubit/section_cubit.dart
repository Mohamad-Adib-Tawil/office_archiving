import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/models/section.dart';
import 'package:office_archiving/service/sqlite_service.dart';

part 'section_state.dart';
class SectionCubit extends Cubit<SectionState> {
  final DatabaseService _databaseService;

  SectionCubit(this._databaseService) : super(SectionLoading());


  
  void loadSections() async {
  try {
    List<Map<String, dynamic>> sectionMaps = await _databaseService.getAllSections();
    List<Section> sections = sectionMaps.map((sectionMap) {
      return Section(id: sectionMap['id'], name: sectionMap['name']);
    }).toList();
    emit(SectionLoaded(sections));
  } catch (e) {
    emit(SectionError('Failed to load sections: $e'));
  }
}

Future<String?> addSection(String name) async {
  if (name.isEmpty) {
    return 'Please enter section name';
  } else {
    bool isNameUnique = await _checkSectionNameUnique(name);
    if (!isNameUnique) {
      return 'Section name already exists';
    } else {
      try {
        int sectionId = await _databaseService.insertSection(name);
        Section newSection = Section(id: sectionId, name: name);
        emit(SectionLoaded([...((state as SectionLoaded).sections), newSection]));
        return null; // No error
      } catch (e) {
        return 'Failed to add section: $e';
      }
    }
  }
}
Future<bool> _checkSectionNameUnique(String name) async {
  List<Map<String, dynamic>> existingSections = await _databaseService.getAllSections();
  for (var section in existingSections) {
    if (section['name'] == name) {
      return false; // Name already exists
    }
  }
  return true; // Name is unique
}

void updateSectionName(int id, String newName) async {
  try {
    await _databaseService.updateSectionName(id, newName);

    if (state is SectionLoaded) {
      List<Section> updatedSections = List.from((state as SectionLoaded).sections);
      int index = updatedSections.indexWhere((section) => section.id == id);

      if (index != -1) {
        updatedSections[index] = Section(id: id, name: newName);
        emit(SectionLoaded(updatedSections));
      }
    }
  } catch (e) {
    emit(SectionError('Failed to update section name: $e'));
  }
}

  void deleteSection(int id) async {
    try {
      await _databaseService.deleteSection(id);
      log('deleteSection');
      loadSections();
    } catch (e) {
      emit(SectionError('Failed to delete section: $e'));
    }
  }

}
