
import 'dart:convert';
import 'dart:js';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mime_type/mime_type.dart';

import '../Utility/default_values.dart';
import '../Utility/utility.dart';

class MovFiles {

  String? _zoneId;
  StateSetter? _setState;

  void showMovFilesDialogs(BuildContext mainContext, String? movFileInJson, String zoneId, void Function(List<dynamic> newData) callback) async {
    List<dynamic> _movFileList = movFileInJson == null ? [] : jsonDecode(movFileInJson);
    _zoneId = zoneId;

    showModalBottomSheet(
      context: mainContext,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext){
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (statefulContext, setState){
              _setState = setState;

              return Container(
                padding: const EdgeInsets.all(20),
                width: DefaultValues().getDefaultWidth(),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Means of Verification Files",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(10)
                          ),

                          child: InkWell(
                            onTap: (){
                              _pickFile();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                "Upload File",
                                style: TextStyle(
                                    fontSize: 14,
                                  color: Colors.blue
                                ),
                              ),
                            ),
                          ),
                        )
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _movFileList.length,
                        itemBuilder: (context, index){
                          return Card(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                ],
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true,);
    if (result != null) {
      for (PlatformFile file in result.files) {
        try {
          // Get file bytes (web) or path (mobile/desktop)
          Uint8List? fileBytes;
          fileBytes = file.bytes;
          if (fileBytes == null) {
            throw Exception('Failed to read file bytes');
          }

          final storage = FirebaseStorage.instance;
          final filename = '${DateTime.now().millisecondsSinceEpoch}-${file.name}';
          final reference = storage.ref().child("Files").child(_zoneId!).child(filename);
          final mimeType = mime(filename) ?? 'application/octet-stream';
          final uploadTask = reference.putData(fileBytes, SettableMetadata(contentType: mimeType));
          uploadTask.snapshotEvents.listen((event) {
            final progress = event.bytesTransferred / event.totalBytes;
            Utility().printLog('Upload progress: $progress');
          });

          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();
          Utility().printLog('File uploaded successfully! Download URL: $downloadUrl');
        } catch (error) {
          Utility().printLog('Error uploading file: $error');
        }
      }
    } else {
      // User canceled the picker
      Utility().printLog('User canceled file selection');
    }
  }

}