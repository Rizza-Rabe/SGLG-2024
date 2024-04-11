
import 'dart:convert';
import 'dart:typed_data';
import 'package:audit_tracker/Dialogs/classic_dialog.dart';
import 'package:audit_tracker/Dialogs/loading_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mime_type/mime_type.dart';
import '../Utility/default_values.dart';
import '../Utility/utility.dart';

class MovFiles {
  List<dynamic> _movFileList = [];
  String? _zoneId;
  String _uploadButton = "Upload File";
  StateSetter? _setState;
  bool _isUploading = false;
  late BuildContext _context;
  late Function(String newData) _callback;
  final _classicDialog = ClassicDialog();
  final _loadingDialog = LoadingDialog();

  void showMovFilesDialogs(String movTitle, BuildContext mainContext, String? movFileInJson, String zoneId, void Function(String? newData) callback) async {
    _zoneId = zoneId;
    _movFileList = movFileInJson == null || movFileInJson.toString() == "null" ? [] : jsonDecode(movFileInJson);
    _callback = callback;
    _context = mainContext;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        "MOV Files",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        movTitle,
                        style: const TextStyle(
                            fontSize: 12
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

                            child: IgnorePointer(
                              ignoring: _isUploading,
                              child: InkWell(
                                onTap: (){
                                  _pickFile();
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    _uploadButton,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue
                                    ),
                                  ),
                                ),
                              ),
                            )
                        )
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _movFileList.isEmpty ?
                            const Text(
                              "No MOV files yet.",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey
                              ),
                            )
                                :
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: _movFileList.length,
                              itemBuilder: (context, index){
                                return Card(
                                  color: Colors.blue[100],
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Text(
                                              _movFileList[index]["fileName"].toString(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16
                                              ),
                                            ),
                                          ),
                                        ),

                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Text(
                                              "${_movFileList[index]["fileSize"].toString()}Kb",
                                              style: const TextStyle(
                                                  fontSize: 12
                                              ),
                                            ),
                                          ),
                                        ),

                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Text(
                                              _movFileList[index]["fileDate"].toString(),
                                              style: const TextStyle(
                                                  fontSize: 12
                                              ),
                                            ),
                                          ),
                                        ),

                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Ink(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: Colors.white
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  _classicDialog.setTitle("Confirm");
                                                  _classicDialog.setMessage("Are you sure you want to delete MOV \"${_movFileList[index]["fileName"].toString()}\"");
                                                  _classicDialog.setPositiveButtonTitle("Delete");
                                                  _classicDialog.setNegativeButtonTitle("Cancel");
                                                  _classicDialog.setCancelable(true);
                                                  _classicDialog.showTwoButtonDialogWithFunc(context, (positiveClicked) async {
                                                    _loadingDialog.showLoadingDialog(context);
                                                    await _removeFile(_movFileList[index]["fileDownloadLink"].toString());
                                                    _movFileList.removeAt(index);
                                                    setState((){});
                                                    if(_movFileList.isEmpty){
                                                      callback(null);
                                                    }else{
                                                      String listData = jsonEncode(_movFileList);
                                                      _callback(listData);
                                                    }
                                                    if(context.mounted) _loadingDialog.dismissDialog(context);
                                                  }, (negativeClicked) {

                                                  });
                                                },

                                                borderRadius: BorderRadius.circular(10),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text(
                                                    "Remove File",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

                    TextButton(
                        onPressed: (){
                          Navigator.of(modalContext).pop();
                        },
                        style: ButtonStyle(
                          textStyle: const MaterialStatePropertyAll(
                              TextStyle(
                                  fontSize: 16
                              )
                          ),
                          minimumSize: MaterialStateProperty.all(
                              const Size(100, 45)
                          ),
                          overlayColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              return Colors.white24;
                            },
                          ),
                          backgroundColor: MaterialStateProperty.all(Colors.blue),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          "Done",
                          style: TextStyle(
                              color: Colors.white
                          ),
                        )
                    ),
                  ],
                )
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
            final progress = (event.bytesTransferred / event.totalBytes * 100).toInt();
            _uploadButton = "Uploading $progress%";
            _isUploading = true;
            _setState!((){});
          });

          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();
          Utility().printLog('File uploaded successfully! Download URL: $downloadUrl');

          Map<dynamic, dynamic> movFileData = {};
          movFileData["fileLink"] = downloadUrl;
          movFileData["fileName"] = file.name;
          movFileData["fileDate"] = DateFormat("MMM dd, yyyy hh:mm a").format(DateTime.now());
          movFileData["fileSize"] = (file.size / 1000);
          movFileData["fileDownloadLink"] = downloadUrl;
          _movFileList.insert(0, movFileData);
          _isUploading = false;
          _uploadButton = "Upload File";
          _setState!((){});
          String listData = jsonEncode(_movFileList);
          _callback(listData);
        } catch (error) {
          Utility().printLog('Error uploading file: $error');
        }
      }
    } else {
      // User canceled the picker
      Utility().printLog('User canceled file selection');
    }
  }

  Future<void> _removeFile(String downloadURL) async {
    final storage = FirebaseStorage.instance;
    final reference = storage.refFromURL(downloadURL);
    try{
      await reference.delete();
    }catch(a){
      _classicDialog.setTitle("An error occurred!");
      _classicDialog.setMessage(a.toString());
      _classicDialog.setPositiveButtonTitle("Close");
      _classicDialog.setCancelable(false);
      if(_context.mounted) _classicDialog.showOneButtonDialog(_context, () { });
    }
  }
}