import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DocListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> docList;
  final Function() getDoc;
  const DocListWidget({super.key, required this.docList, required this.getDoc});

  @override
  State<DocListWidget> createState() => _DocListWidgetState();
}

class _DocListWidgetState extends State<DocListWidget> {
  List<File> _docFileList = [];

  @override
  void initState() {
    super.initState();
    widget.getDoc();
  }

  @override
  Widget build(BuildContext context) {
    return widget.docList.isEmpty
        ? Center(
            child: TextButton(
                onPressed: () => widget.getDoc(),
                child: const Text('تلاش مجدد')),
          )
        : ListView(
            shrinkWrap: true,
            children: widget.docList.map((doc) {
              return DocItemWidget(
                doc: doc,
                onFilePicked: (file) {
                  _docFileList.add(file);
                  setState(() {});
                },
              );
            }).toList());
  }
}

class DocItemWidget extends StatefulWidget {
  final Map<String, dynamic> doc;
  final Function(File file) onFilePicked;
  const DocItemWidget(
      {super.key, required this.doc, required this.onFilePicked});

  @override
  State<DocItemWidget> createState() => _DocItemWidgetState();
}

class _DocItemWidgetState extends State<DocItemWidget> {
  File? _image;
  void _picFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        widget.onFilePicked(File(result.files.single.path!));
        setState(() {
          _image = File(result.files.single.path!);
        });
      } else {
        debugPrint('User canceled or picker failed');
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            _image == null
                ? Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.grey[600],
                  )
                : SizedBox(
                    height: 48,
                    width: 48,
                    child: Image.file(_image!, fit: BoxFit.fill)),
            const SizedBox(height: 8),
            Text(
              widget.doc['documentTitle'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _picFile();
              },
              child: const Text(
                'انتخاب فایل',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
