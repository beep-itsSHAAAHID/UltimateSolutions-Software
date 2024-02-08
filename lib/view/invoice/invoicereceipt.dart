import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' as printing;
import 'package:number_to_words/number_to_words.dart' as words;
import 'package:http/http.dart' as http;



class InvoiceReceipt extends StatefulWidget {
  const InvoiceReceipt({Key? key}) : super(key: key);

  @override
  State<InvoiceReceipt> createState() => _InvoiceReceiptState();
}

class _InvoiceReceiptState extends State<InvoiceReceipt> {
  Stream<QuerySnapshot>? _invoiceStream;




  @override
  void initState() {
    super.initState();
    _initDeliveryStream();
  }

  void _initDeliveryStream() {
    _invoiceStream = FirebaseFirestore.instance.collection('invoices').snapshots();
  }


  Future<pw.Widget> _buildQRCodeImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;

        final qrCodeImage = pw.Container(
          margin: pw.EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  '                   ',
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ],
          ),
        );

        // Center the qrCodeImage widget
        return pw.Center(
          child: qrCodeImage,
        );
      } else {
        // Handle non-200 status code (e.g., print the status code)
        print('HTTP request failed with status: ${response.statusCode}');
      }
    } catch (error) {
      // Handle other errors (e.g., network error)
      print('Error fetching image: $error');
    }

    // Return a placeholder widget or null if an error occurs
    return pw.Container(
      width: 0,
      height: 0,
    );
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


    List<pw.Widget> _wrapText(String text) {
      const int maxLineWidth = 21; // Set your desired maximum line width
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


    pw.TableRow _buildDetailsTableRow(List<String> rowData, {bool isHeader = false}) {
      return pw.TableRow(
        children: rowData.map((cellData) {
          return pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0), // Increase horizontal padding
            decoration: isHeader ? pw.BoxDecoration(color: pw.PdfColors.blue50) : null,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _wrapText(cellData),
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
                _buildDetailText('Payment Term:', data['modeOfPayment'], isBold: true),
                _buildDetailText('Date:', data['invoiceDate'], isBold: true),
                _buildDetailText('Invoice No.:', data['invoiceNo'], isBold: true),
                _buildDetailText('Po No.:', data['poNo'], isBold: true),
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
    tableRows.add(_buildDetailsTableRow(['Sl No', 'Product Code', 'Product Name', 'Qty', 'Unit','Price','Vat(15%)','Line Total'], isHeader: true));

    for (int i = 0; i < productList.length; i++) {
      Map<String, dynamic> product = productList[i];
      tableRows.add(_buildDetailsTableRow([
        (i + 1).toString(),
        product['code'] ?? '',
        product['name'] ?? '',
        product['quantity']?.toString() ?? '',
        product['unit'] ?? '',
        product['price']?.toString() ?? '',
        (product['taxAmount'] ?? 0.0).toStringAsFixed(2), // Formatting VAT to one decimal place
        (product['lineTotal']?? 0.0).toStringAsFixed(2),
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


    String capitalizeWords(String input) {
      return input.replaceAllMapped(
        RegExp(r'\b\w'),
            (match) => match.group(0)!.toUpperCase(),
      );
    }


// Add a function to get net amount in words
    String _getNetAmountInWords(Map<String, dynamic> data) {
      double netAmountDouble = double.parse(data['netAmount']?.toString() ?? '0');
      int netAmountInt = netAmountDouble.round();
      String netAmountInWords = words.NumberToWord().convert('en-in', netAmountInt);
      return capitalizeWords(netAmountInWords) + ' Saudi Riyals';
    }



    // Fetch the QR code image URL from Firestore data
    String qrCodeImageUrl = data['qrCodeImageUrl'] ?? '';

    // Build the QR code image section in the PDF
    pw.Widget qrCodeImage = await _buildQRCodeImage(qrCodeImageUrl);



    pw.Widget _buildTableCell(String text) {
      return pw.Padding(
        padding: pw.EdgeInsets.all(8.0),
        child: pw.Text(text),
      );
    }


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
                    'TAX INVOICE',
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
             pw.SizedBox(height: 10),


             // _buildGrossAmountSection(data),
            //  _buildtaxAmountSection(data),
            //   _buildNetAmountSection(data),
            //   _buildNetAmountInWordsSection(data),



              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 70.0),
                child: pw.Container(

                  height: 200,
                //  margin: pw.EdgeInsets.only(top: 10.0), // Adjust the top margin as needed
                  child: pw.Table(

                    border: pw.TableBorder.all(style: pw.BorderStyle.dashed,color: pw.PdfColors.blueAccent),
                    children: [
                      // Gross Amount Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('Gross Amount:'),
                          _buildTableCell(
                            (double.parse(data['totalWithoutVat']?.toString() ?? '0')).toStringAsFixed(2),
                          ),

                        ],
                      ),
                      // Total VAT(15%) Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('Total VAT(15%):'),
                          _buildTableCell(
                            (double.parse(data['totalWithoutVat']?.toString() ?? '0') * 0.15).toStringAsFixed(2),
                          ),
                        ],
                      ),
                      // Net Amount Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('Net Amount:'),
                          _buildTableCell(
                            data['netAmount']?.toString() ?? '',
                          ),
                        ],
                      ),
                      // In Words Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('In Words:'),
                          _buildTableCell(
                            _getNetAmountInWords(data),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.Center(
                child: qrCodeImage,
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
        title: Center(child: Text('Invoice Receipts',style: TextStyle(
          color: Colors.white,fontSize: 50,fontWeight: FontWeight.w700
        ),)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _invoiceStream,
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
                ..sort((a, b) => (b['invoiceNo'] as String).compareTo(a['invoiceNo'] as String));
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
                          'Invoice No: ${data['invoiceNo']}',
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
                          'Date: ${data['invoiceDate']}',
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

