import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TermsPage extends StatelessWidget {
  const TermsPage() : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SfPdfViewer.asset('assets/pdfs/pandevita_terms.pdf'),
    );
  }
}
