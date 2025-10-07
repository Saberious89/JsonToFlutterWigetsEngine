import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Widget that displays a list of documents and allows picking files.
class DocUploaderWidget extends StatefulWidget {
  final Map<dynamic, dynamic> doc;
  final Function(Map<String, dynamic> doc) upload;
  const DocUploaderWidget({
    super.key,
    required this.doc,
    required this.upload,
  });

  @override
  State<DocUploaderWidget> createState() => _DocUploaderWidgetState();
}

class _DocUploaderWidgetState extends State<DocUploaderWidget> {
  List<File> _docFileList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.doc.isEmpty
        ? Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('تلاش مجدد'),
            ),
          )
        : DocItemWidget(
            doc: widget.doc,
            upload: (doc) => widget.upload(doc),
            onFilePicked: (file) {
              _docFileList.add(file);
              setState(() {});
            },
          );
    // ListView(
    //     shrinkWrap: true,
    //     children: widget.docList.map((doc) {
    //       return DocItemWidget(
    //         doc: doc,
    //         onFilePicked: (file) {
    //           _docFileList.add(file);
    //           setState(() {});
    //         },
    //       );
    //     }).toList(),
    //   );
  }
}

/// Widget representing a single document upload item.
class DocItemWidget extends StatefulWidget {
  final Map<dynamic, dynamic> doc;
  final Function(Map<String, dynamic> doc) upload;
  final Function(File file) onFilePicked;

  const DocItemWidget({
    super.key,
    required this.doc,
    required this.onFilePicked,
    required this.upload,
  });

  @override
  State<DocItemWidget> createState() => _DocItemWidgetState();
}

class _DocItemWidgetState extends State<DocItemWidget> {
  File? _image;

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
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
      var t = {
        "DocumentId": widget.doc['documentId']['value'],
        // "AgreementId": "",
        "uploadLink": widget.doc['uploadLink']['value'],
        "CustomerId": widget.doc['customerId']['value'],
        "ActorType": widget.doc['actorType']['value'],
        "File": "${File(_image!.path)}",
      };
      log(t.toString());
      widget.upload({
        "DocumentId": widget.doc['documentId']['value'],
        // "AgreementId": "",
        "uploadLink": widget.doc['uploadLink']['value'],
        "CustomerId": widget.doc['customerId']['value'],
        "ActorType": widget.doc['actorType']['value'],
        "File": "${File(_image!.path)}",
      });
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
          heroTag: widget.doc['documentTitle']['value'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docTitle = widget.doc['documentTitle']['value'];

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
                : GestureDetector(
                    onTap: () => _openFullImage(context),
                    child: Hero(
                      tag: docTitle,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _image!,
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
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Color(0xff223369))),
              onPressed: _pickFile,
              child: const Text(
                'انتخاب فایل',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: _image == null ? null : _confirmAndSend,
              child: const Text(
                'تایید و ارسال',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullImageView extends StatelessWidget {
  final File imageFile;
  final String heroTag;

  const FullImageView({
    super.key,
    required this.imageFile,
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
            child: Image.file(imageFile, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
