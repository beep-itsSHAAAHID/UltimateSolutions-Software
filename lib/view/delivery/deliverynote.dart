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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 1), // Adjust the duration as needed
      ),
    );
    final pdf = pw.Document();

    final fontData = await rootBundle.load("lib/assets/fonts/Poppins-Regular.ttf");
    final ttfFont = pw.Font.ttf(fontData);

    final fontDataBold = await rootBundle.load("lib/assets/fonts/Poppins-Bold.ttf");
    final ttfFontBold = pw.Font.ttf(fontDataBold);

    final ttfArabicFont = pw.Font.ttf(await rootBundle.load("lib/assets/fonts/HacenTunisia.ttf"));





    List<pw.Widget> _wrapText(String text) {
      const int maxLineWidth = 40; // Set your desired maximum line width
      List<pw.Widget> lines = [];

      for (int i = 0; i < text.length; i += maxLineWidth) {
        int end = i + maxLineWidth;
        if (end > text.length) {
          end = text.length;
        }
        lines.add(pw.Text(
          text.substring(i, end),
        ));
      }

      return lines;
    }


    pw.TableRow _buildDetailsTableRow(List<String> rowData,
        {bool isHeader = false}) {
      return pw.TableRow(
        children: rowData.map((cellData) {
          return pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
            // Increase horizontal padding
            decoration:
            isHeader ? pw.BoxDecoration(color: pw.PdfColors.blue50) : null,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: _wrapText(cellData),
            ),
          );
        }).toList(),
      );
    }

    // pw.Widget _buildDetailText(String label, dynamic value, {bool isBold = false}) {
    //   return pw.Container(
    //     margin: pw.EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
    //     child: pw.RichText(
    //       text: pw.TextSpan(
    //         children: [
    //           pw.TextSpan(
    //             text: '$label ',
    //             style: pw.TextStyle(font: ttfFont),
    //           ),
    //           pw.TextSpan(
    //             text: '${value ?? ''}',
    //             style: pw.TextStyle(font: isBold ? ttfFontBold : ttfFont),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }


    pw.Widget _buildDetailText(String label, dynamic value, {bool isBold = false, bool isCustomerName = false, bool isArabicName = false}) {
      return pw.Table(
        border: pw.TableBorder(
          top: pw.BorderSide(color: pw.PdfColors.blue, width: 0.5, style: pw.BorderStyle.dotted),
          bottom: pw.BorderSide(color: pw.PdfColors.blue, width: 0.5, style: pw.BorderStyle.dotted),
          left: pw.BorderSide(color: pw.PdfColors.blue, width: 0.5, style: pw.BorderStyle.dotted),
          right: pw.BorderSide(color: pw.PdfColors.blue, width: 0.5, style: pw.BorderStyle.dotted),
          horizontalInside: pw.BorderSide(color: pw.PdfColors.blue, width: 0.5, style: pw.BorderStyle.dashed),
          verticalInside: pw.BorderSide(color: pw.PdfColors.blue, width: 0.5, style: pw.BorderStyle.dashed),
        ),
        columnWidths: {
          0: pw.FixedColumnWidth(100), // Adjust the width as needed
          1: pw.FlexColumnWidth(),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3), // Reduce padding
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    font: isArabicName ? ttfArabicFont : ttfFontBold,
                    fontWeight: isBold ? pw.FontWeight.bold : null,
                    fontSize: 10, // Reduce font size
                  ),
                  textDirection: isArabicName ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3), // Reduce padding
                constraints: pw.BoxConstraints(maxWidth: 300), // Adjust maxWidth for better text wrapping
                child: pw.Text(
                  '${value ?? ''}',
                  style: pw.TextStyle(
                    font: ttfArabicFont, // Use Arabic font for the value
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0, // No letter spacing
                    fontSize: 10, // Reduce font size
                  ),
                  textDirection: isCustomerName ? pw.TextDirection.ltr : pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.left, // Align Arabic text to the right
                  maxLines: isCustomerName ? 3 : 2, // Allow for more lines
                  overflow: pw.TextOverflow.visible, // Clip overflow text
                  softWrap: true, // Ensure text wraps properly
                ),
              ),
            ],
          ),
        ],
      );
    }



    pw.Widget _buildDetailsColumn(Map<String, dynamic> data) {
      return pw.Container(
        margin: pw.EdgeInsets.only(left: 17,right: 17), // Add margins to the entire table
        child: pw.Table(

          columnWidths: {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: pw.EdgeInsets.all(5), // Reduce padding
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildDetailText('Customer Name:', data['customerName'], isBold: true, isCustomerName: true),
                      _buildDetailText(' :اسم الزبون', data['arabicName'], isBold: true, isArabicName: true),
                      _buildDetailText('VAT Number:', data['vatNo'], isBold: true),
                      _buildDetailText('Address:', data['address'], isBold: true),
                    ],
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.all(5), // Reduce padding
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildDetailText('Date:', data['date'], isBold: true),
                      _buildDetailText('Delivery Note No:', data['deliveryNoteNo'], isBold: true),
                      _buildDetailText('Invoice No.:', data['invoiceNo'], isBold: true),
                      _buildDetailText('Po No.:', data['poNo'], isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final Uint8List pdfBytes = await pdf.save();

    await printing.Printing.layoutPdf(onLayout: (format) => pdfBytes);

    print('PDF generated successfully!');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Center(child: Text('Delivery Notes',style: TextStyle(
          fontSize: 50,fontWeight: FontWeight.w700,
          color: Colors.white
        ),)),
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
              var sortedDocuments = documents.toList()
                ..sort((a, b) => (b['deliveryNoteNo'] as String).compareTo(a['deliveryNoteNo'] as String));
              var data = sortedDocuments[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 4.0,
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () async => await _generatePDF(data),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Note No: ${data['deliveryNoteNo']}',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Customer: ${data['customerName']}',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Date: ${data['date']}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
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
