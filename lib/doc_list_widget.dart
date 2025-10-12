import 'dart:io';
import 'package:dynamic_form_builder/enums.dart';
import 'package:cross_file/cross_file.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DocUploaderWidget extends StatefulWidget {
  final List<dynamic> docList;
  final bool isLoading;
  final int uploadedDocCount;
  final Function(dynamic) onUploadDone;
  final List<Map<dynamic, dynamic>>? additionalParameters;
  final ValueNotifier<double> uploadedProgress;

  final Function(Map<String, dynamic> doc) upload;
  const DocUploaderWidget({
    super.key,
    required this.docList,
    required this.upload,
    required this.uploadedProgress,
    this.additionalParameters,
    required this.isLoading,
    required this.uploadedDocCount,
    required this.onUploadDone,
  });

  @override
  State<DocUploaderWidget> createState() => _DocUploaderWidgetState();
}

class _DocUploaderWidgetState extends State<DocUploaderWidget> {
  // List<File> _docFileList = [];

  @override
  void initState() {
    super.initState();
  }

  bool allDocUploaded() {
    if (widget.uploadedDocCount ==
        widget.docList
            .where((d) => d['status'] != DocumentStatusEnum.approved.value)
            .length) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 120,
      child: widget.docList.isEmpty
          ? Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('تلاش مجدد'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.docList.length,
                    itemBuilder: (context, index) {
                      var item = widget.docList[index];

                      return DocItemWidget(
                        doc: item,
                        isLoading: widget.isLoading,
                        uploadedProgress: widget.uploadedProgress,
                        onUploadDone: (val) {
                          widget.onUploadDone(val);
                        },
                        additionalParameters: widget.additionalParameters,
                        upload: (doc) {
                          return widget.isLoading ? null : widget.upload(doc);
                        },
                        onFilePicked: (file) {
                          // _docFileList.add(file);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
                ElevatedButton(
                    style: ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(Colors.white)),
                    onPressed: allDocUploaded()
                        ? () {
                            widget.onUploadDone(null);
                          }
                        : null,
                    child: Text('تایید'))
              ],
            ),
    );
  }
}

class DocItemWidget extends StatefulWidget {
  final Map<dynamic, dynamic> doc;
  final bool isLoading;
  final List<Map<dynamic, dynamic>>? additionalParameters;
  final ValueNotifier<double> uploadedProgress;
  final Function(Map<String, dynamic> doc) upload;
  final Function(XFile file) onFilePicked;
  final Function(dynamic) onUploadDone;

  const DocItemWidget({
    super.key,
    required this.doc,
    required this.onFilePicked,
    required this.upload,
    required this.uploadedProgress,
    this.additionalParameters,
    required this.isLoading,
    required this.onUploadDone,
  });

  @override
  State<DocItemWidget> createState() => _DocItemWidgetState();
}

class _DocItemWidgetState extends State<DocItemWidget> {
  XFile? _image;

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = result.files.single.xFile;
        widget.onFilePicked(file);
        setState(() {
          _image = file;
        });
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  void _confirmAndSend() async {
    try {
      Map<dynamic, dynamic> requestJson = {};
      widget.additionalParameters
          ?.forEach((element) => requestJson.addAll(element));
      Map<String, dynamic> mergedJson = {
        ...requestJson,
        ...{
          "DocumentId": widget.doc['documentId'],
          "DocumentTitle": widget.doc['documentTitle'],
          "ActorType": widget.doc['actorType'],
          "File": _image!.path,
        }.map((key, value) => MapEntry(key.toString(), value)),
      };
      widget.upload(mergedJson);
    } catch (e) {
      debugPrint('$e');
    }
  }

  void _openFullImage(BuildContext context) {
    if (_image == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullImageView(
          imageFile: _image!,
          heroTag: widget.doc['documentTitle'],
        ),
      ),
    );
  }

  void _openFullImageWithPath(BuildContext context, filePath) {
    if (filePath == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullImageView(
          // imageFile: File(filePath),
          imagePath: filePath,
          heroTag: widget.doc['documentTitle'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docTitle = widget.doc['documentTitle'];
    final rejectionReason = widget.doc['rejectionReason'];
    final filePath = widget.doc['filePath'];
    final statusInt = widget.doc['status'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: statusInt == DocumentStatusEnum.approved.value
                  ? Colors.green
                  : statusInt == DocumentStatusEnum.rejicted.value
                      ? Colors.red
                      : Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            _image == null && (filePath == null || filePath == "")
                ? Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.grey[600],
                  )
                : _image != null
                    ? GestureDetector(
                        onTap: () => _openFullImage(context),
                        child: Hero(
                          tag: docTitle,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_image!.path),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _openFullImageWithPath(context, filePath),
                        child: Hero(
                          tag: docTitle,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              filePath,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
            const SizedBox(height: 8),
            Text(
              docTitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            if (rejectionReason != null && rejectionReason != "")
              Row(
                children: [
                  Text('علت رد :'),
                  Text(
                    rejectionReason,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                      statusInt == DocumentStatusEnum.approved.value
                          ? Colors.blueGrey.shade100
                          : Color(0xff223369))),
              onPressed: statusInt == DocumentStatusEnum.approved.value
                  ? null
                  : _pickFile,
              child: const Text(
                'انتخاب فایل',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Colors.white)),
              onPressed: _image == null ? null : _confirmAndSend,
              child: ValueListenableBuilder(
                valueListenable: widget.uploadedProgress,
                builder: (context, value, child) {
                  return widget.isLoading
                      ? CupertinoActivityIndicator()
                      : Text((value > 0.0 && value < 100.0)
                          ? '${value.toInt()}'
                          : 'تایید و ارسال');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullImageView extends StatelessWidget {
  final XFile? imageFile;
  final String? imagePath;
  final String heroTag;

  const FullImageView({
    super.key,
    this.imageFile,
    this.imagePath,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: heroTag,
            child: (imagePath != null && imagePath!.isNotEmpty)
                ? Image.network(imagePath!, fit: BoxFit.contain)
                : Image.file(File(imageFile!.path), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
