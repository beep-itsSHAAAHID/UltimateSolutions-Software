import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' as printing;

class DeliveryNotes extends StatefulWidget {
  const DeliveryNotes({Key? key}) : super(key: key);

  @override
  State<DeliveryNotes> createState() => _DeliveryNotesState();
}

class _DeliveryNotesState extends State<DeliveryNotes> {
  Stream<QuerySnapshot>? _deliveryStream;

  @override
  void initState() {
    super.initState();
    _initDeliveryStream();
  }

  void _initDeliveryStream() {
    _deliveryStream = FirebaseFirestore.instance.collection('delivery').snapshots();
  }



  Future<void> _generatePDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load("lib/assets/fonts/Poppins-Regular.ttf");
    final ttfFont = pw.Font.ttf(fontData);

    final fontDataBold = await rootBundle.load("lib/assets/fonts/Poppins-Bold.ttf");
    final ttfFontBold = pw.Font.ttf(fontDataBold);

    pw.TableRow _buildDetailsTableRow(List<String> rowData, {bool isHeader = false}) {
      return pw.TableRow(
        children: rowData.map((cellData) {
          return pw.Container(
            padding: pw.EdgeInsets.all(8.0),
            decoration: isHeader ? pw.BoxDecoration(color: pw.PdfColors.blue50) : null,
            child: pw.Text(
              cellData,
              style: isHeader ? pw.TextStyle(font: ttfFontBold) : null,
            ),
          );
        }).toList(),
      );
    }

    pw.Widget _buildDetailText(String label, dynamic value, {bool isBold = false}) {
      return pw.Container(
        margin: pw.EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label ',
                style: pw.TextStyle(font: ttfFont),
              ),
              pw.TextSpan(
                text: '${value ?? ''}',
                style: pw.TextStyle(font: isBold ? ttfFontBold : ttfFont),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _buildDetailsColumn(Map<String, dynamic> data) {
      return pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDetailText('Customer Code:', data['customerCode'], isBold: true),
                _buildDetailText('Customer Name:', data['customerName'], isBold: true),
                _buildDetailText('Address:', data['address'], isBold: true),
                _buildDetailText('VAT Number:', data['vatNo'], isBold: true),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Container(
            height: 100,
            width: 5,
            color: pw.PdfColors.blue50,
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDetailText('Delivery Note No:', data['deliveryNoteNo'], isBold: true),
                _buildDetailText('Date:', data['date'], isBold: true),
                _buildDetailText('Po No.:', data['poNo'], isBold: true),
                _buildDetailText('Ref No.:', data['refNo'], isBold: true),
              ],
            ),
          ),
        ],
      );
    }

    // Retrieve the product details from the Firestore data
    List<Map<String, dynamic>> productList = (data['products'] as List<dynamic>).cast<Map<String, dynamic>>();

    // Build the table rows dynamically using Firestore data
    List<pw.TableRow> tableRows = [];
    tableRows.add(_buildDetailsTableRow(['Sl No', 'Product Code', 'Product Name', 'Qty', 'Unit'], isHeader: true));

    for (int i = 0; i < productList.length; i++) {
      Map<String, dynamic> product = productList[i];
      tableRows.add(_buildDetailsTableRow([
        (i + 1).toString(),
        product['code'] ?? '',
        product['name'] ?? '',
        product['quantity']?.toString() ?? '',
        product['unit'] ?? '',
      ]));
    }

    pw.Image headerImage = pw.Image(
      pw.MemoryImage(
        (await rootBundle.load('lib/assets/header.png')).buffer.asUint8List(),
      ),
    );

    pw.Image footerImage = pw.Image(
      pw.MemoryImage(
        (await rootBundle.load('lib/assets/footer.png')).buffer.asUint8List(),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pw.PdfPageFormat.a4.copyWith(
          marginTop: 0,
          marginBottom: 0,
          marginLeft: 0,
          marginRight: 0,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 100,
                decoration: pw.BoxDecoration(
                  color: pw.PdfColors.red,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.FittedBox(
                  fit: pw.BoxFit.fill,
                  alignment: pw.Alignment.topCenter,
                  child: headerImage,
                ),
              ),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      margin: pw.EdgeInsets.symmetric(horizontal: 20),
                      child: pw.Container(
                        margin: pw.EdgeInsets.symmetric(vertical: 5),
                        color: pw.PdfColors.blue50,
                        height: 5,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Center(
                  child: pw.Text(
                    'Delivery Note',
                    style: pw.TextStyle(font: ttfFontBold, fontSize: 18, letterSpacing: 2),
                  ),
                ),
              ),
               pw.Container(
                margin: pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: 5),
                  color: pw.PdfColors.blue50,
                  height: 5,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildDetailsColumn(data)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Expanded(
                flex: 0,
                child: pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 20.0),
                  height: 200,
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(inside: pw.BorderSide.none),
                    children: tableRows,
                  ),
                ),
              ),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(horizontal: 20.0),
                height: 1.0,
                color: pw.PdfColors.blueAccent,
              ),
              pw.Expanded(
                flex: 1,
                child: pw.SizedBox(),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(left: 20, top: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Received By:',
                      style: pw.TextStyle(
                        font: ttfFontBold,
                        fontSize: 16,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(width: 200),
                    pw.Text(
                      'Sales Dept:',
                      style: pw.TextStyle(
                        font: ttfFontBold,
                        fontSize: 16,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                margin: pw.EdgeInsets.only(top: 0, bottom: 10),
                child: footerImage,
              ),
            ],
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    await printing.Printing.layoutPdf(onLayout: (format) => pdfBytes);

    print('PDF generated successfully!');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Delivery Notes')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _deliveryStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          var documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var data = documents[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 2.0,
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(data['deliveryNoteNo']),
                  subtitle: Text(data['customerName']),
                  trailing: ElevatedButton(
                    onPressed: () async => await _generatePDF(data),
                    child: Text('Generate PDF'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
