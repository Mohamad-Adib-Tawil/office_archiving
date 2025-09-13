import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class MyPdfViewer extends StatefulWidget {
  final String filePath;

  const MyPdfViewer({super.key, required this.filePath});

  @override
  State<MyPdfViewer>  createState() => _MyPdfViewerState();
}

class _MyPdfViewerState extends State<MyPdfViewer> {
  late PDFViewController pdfViewController;
  int currentPage = 0;
  int totalPages = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            fitEachPage: true,
            fitPolicy: FitPolicy.BOTH,
            onRender: (pages) {
              setState(() {
                totalPages = pages!;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$error in page : $page';
              });
            },
            onViewCreated: (PDFViewController vc) {
              setState(() {
                pdfViewController = vc;
              });
              _setInitialPage();
            },
          ),
          if (errorMessage.isEmpty && !isReady)
            Center(
              child: CircularProgressIndicator(),
            )
          else if (errorMessage.isNotEmpty)
            Center(
              child: Text(errorMessage),
            ),
        ],
      ),
    );
  }

  _setInitialPage() async {
    try {
      int? pageCount = await pdfViewController.getPageCount();
      setState(() {
        totalPages = pageCount!;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }
}
