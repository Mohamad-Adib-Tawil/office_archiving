import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/functions/handle_delete_section.dart';
import 'package:office_archiving/functions/handle_rename_Section.dart';
import 'package:office_archiving/models/section.dart';
import 'package:office_archiving/pages/section_screen.dart';

class SectionListView extends StatelessWidget {
  final List<Section> sections;
  final SectionCubit sectionCubit;

  const SectionListView({
    required this.sections,
    required this.sectionCubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: sections.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      kLogoOffice,
                      width: 200,
                      height: 200,
                      // color: Colors.grey.withOpacity(0.5),
                    ),
                   
                  ],
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SectionScreen(
                            section: Section(
                              id: sections[index].id,
                              name: sections[index].name,
                            ),
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showOptionsDialog(context, index),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kPrimaryColor.withOpacity(0.1),
                                kPrimaryColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: Image.asset(
                                    kLogoOffice,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  sections[index].name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'options of the section',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: kPrimaryColor),
              title: const Text('edit name'),
              onTap: () {
                Navigator.pop(context);
                handleRenameSection(
                  context,
                  sectionCubit,
                  sections[index],
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade700),
              title: const Text('delete the section'),
              onTap: () {
                Navigator.pop(context);
                handleDeleteSection(context, sections[index]);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }
}
