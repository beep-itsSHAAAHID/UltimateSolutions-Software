import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' as printing;
import 'package:number_to_words/number_to_words.dart' as words;
import 'package:http/http.dart' as http;
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:number_to_word_arabic/number_to_word_arabic.dart';

import 'invoice.dart';

class InvoiceReceipt extends StatefulWidget {

  final String userEmail;
  const  InvoiceReceipt({ required this.userEmail});

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
    _invoiceStream =
        FirebaseFirestore.instance.collection('invoices').snapshots();
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

    final fontData =
        await rootBundle.load("lib/assets/fonts/Poppins-Regular.ttf");
    final ttfFont = pw.Font.ttf(fontData);

    final fontDataBold =
        await rootBundle.load("lib/assets/fonts/Poppins-Bold.ttf");
    final ttfFontBold = pw.Font.ttf(fontDataBold);

    final ttfArabicFont =
        pw.Font.ttf(await rootBundle.load("lib/assets/fonts/HacenTunisia.ttf"));

    List<pw.Widget> _wrapText(String text) {
      const int maxCharactersPerLine =
          40; // Set your desired maximum characters per line
      List<pw.Widget> lines = [];

      for (int i = 0; i < text.length; i += maxCharactersPerLine) {
        int end = i + maxCharactersPerLine;
        if (end > text.length) {
          end = text.length;
        }
        lines.add(
          pw.Text(
            text.substring(i, end),
            style: pw.TextStyle(font: ttfArabicFont),
            textDirection: pw.TextDirection.rtl,
            // Right-to-left text direction for Arabic
            textAlign: pw.TextAlign.center, // Apply the font style here
          ),
        );
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

    // pw.Widget _buildDetailText(String label, dynamic value, {bool isBold = false, bool isCustomerName = false, bool isArabicName = false}) {
    //   return pw.Container(
    //     margin: pw.EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
    //     child: pw.Row(
    //       crossAxisAlignment: pw.CrossAxisAlignment.start,
    //       children: [
    //         pw.Expanded(
    //           flex: 1,
    //           child: pw.Text(
    //             label,
    //             style: pw.TextStyle(
    //               font: isArabicName ? ttfArabicFont : ttfFontBold,
    //               fontWeight: isBold ? pw.FontWeight.bold : null,
    //             ),
    //             textDirection: isArabicName ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    //           ),
    //         ),
    //         pw.SizedBox(width: 10),
    //         pw.Expanded(
    //           flex: 2,
    //           child: pw.Container(
    //             constraints: pw.BoxConstraints(maxWidth: 300), // Increase maxWidth for better text wrapping
    //             child: pw.Text(
    //               '${value ?? ''}',
    //               style: pw.TextStyle(
    //                 font: ttfArabicFont, // Use Arabic font for the value
    //                 fontWeight: pw.FontWeight.bold,
    //                 letterSpacing: 0, // No letter spacing
    //               ),
    //               textDirection: isCustomerName ? pw.TextDirection.ltr : pw.TextDirection.rtl,
    //               textAlign: pw.TextAlign.left, // Align Arabic text to the right
    //               maxLines: isCustomerName ? 3 : 2, // Allow for more lines
    //               overflow: pw.TextOverflow.visible, // Clip overflow text
    //               softWrap: true, // Ensure text wraps properly
    //             ),
    //           ),
    //         ),
    //       ],
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
                      _buildDetailText('Payment Term:', data['modeOfPayment'], isBold: true),
                      _buildDetailText('Date:', data['invoiceDate'], isBold: true),
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









    //start
    // Retrieve the product details from the Firestore data
    List<Map<String, dynamic>> productList =
        (data['products'] as List<dynamic>).cast<Map<String, dynamic>>();

    // Build the table rows dynamically using Firestore data
    List<pw.TableRow> tableRows = [];
    tableRows.add(_buildDetailsTableRow([
      ' Sl No\nعدد ',
      ' Item Code\n رمز الصنف',
      'Product Description\n وصف',
      'Qty\nالكمية',
      'Unit\nوحدة',
      'Price\nالسعر',
      'Vat(15%)\nضريبة',
      'Line Total\nمجموع'
    ], isHeader: true));

    for (int i = 0; i < productList.length; i++) {
      Map<String, dynamic> product = productList[i];
      tableRows.add(_buildDetailsTableRow([
        (i + 1).toString(),
        product['code'] ?? '',
        product['name'] ?? '',
        product['quantity']?.toString() ?? '',
        product['unit'] ?? '',
        product['price']?.toString() ?? '',
        (product['taxAmount'] ?? 0.0).toStringAsFixed(2),
        // Formatting VAT to one decimal place
        (product['lineTotal'] ?? 0.0).toStringAsFixed(2),
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
      int netAmountInt = netAmountDouble.truncate();
      int halalas = ((netAmountDouble - netAmountInt) * 100).toInt(); // Extract halalas
      String netAmountInWords = words.NumberToWord().convert('en-in', netAmountInt);
      String halalasInWords = words.NumberToWord().convert('en-in', halalas); // Convert halalas to words

      String netAmountText = '${capitalizeWords(netAmountInWords)} Saudi Riyals and $halalasInWords Halalas';
      return netAmountText;
    }



    // Fetch the QR code image URL from Firestore data
    String qrCodeImageUrl = data['qrCodeImageUrl'] ?? '';

    // Build the QR code image section in the PDF
    pw.Widget qrCodeImage = await _buildQRCodeImage(qrCodeImageUrl);

    pw.Widget _buildTableCell(String label, String value, String arabicValue) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: ttfArabicFont, // Applying Arabic font
                fontSize: 10, // Adjust font size

              ),
              textDirection: pw.TextDirection.rtl, // Left-to-right for English text
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    value,
                    style: pw.TextStyle(
                      color: pw.PdfColors.red900,
                      font: ttfArabicFont, // Applying Arabic font
                      fontSize: 10, // Adjust font size
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textDirection: pw.TextDirection.ltr, // Left-to-right for English text
                    textAlign: pw.TextAlign.left,
                  ),
                  pw.Text(
                    arabicValue,
                    style: pw.TextStyle(
                      color: pw.PdfColors.red900,
                      font: ttfArabicFont, // Applying Arabic font
                      fontSize: 10, // Adjust font size
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textDirection: pw.TextDirection.rtl, // Right-to-left for Arabic text
                    textAlign: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
            pw.Divider(
              color: pw.PdfColors.grey, // Divider color
              height: 1, // Divider height
              thickness: 0.5, // Divider thickness
            ),
          ],
        ),
      );
    }



    String _convertToArabic(String value) {
      final arabicNumbers = ArabicNumbers();

      String result = '';
      for (int i = 0; i < value.length; i++) {
        if (value[i] == '.') {
          result += '.';
        } else {
          result += arabicNumbers.convert(int.parse(value[i]));
        }
      }

      return result;
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
                        color: pw.PdfColors.blue200,
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
                    'TAX INVOICE   فاتورة الضريبة',
                    style: pw.TextStyle(
                        font: ttfArabicFont, fontSize: 18, letterSpacing: 2),
                    textDirection: pw.TextDirection
                        .rtl, // Set text direction to right-to-left
                  ),
                ),
              ),

              pw.Container(
                margin: pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: 5),
                  color: pw.PdfColors.orange200,
                  height: 5,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildDetailsColumn(data)),
                ],
              ),
               pw.SizedBox(height: 5),
              pw.Expanded(
                flex: 0,
                child: pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 20.0),
                  height: 200,
                  child: pw.Table(
                    border: pw.TableBorder.all(
                        style: pw.BorderStyle.dashed,
                        color: pw.PdfColors.blueAccent),
                    // Add dashed outside border
                    children: tableRows,
                  ),
                ),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.only(left: 0), // Set left padding to 0
                    child: pw.Container(
                      height: 200,
                      width: 200,
                      child: qrCodeImage,
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.only(left: 223), // Add space between QR code and table
                    child: pw.Container(
                      height: 200,
                      width: 150,
                      child: pw.Table(
                        border: pw.TableBorder.all(
                            style: pw.BorderStyle.dashed,
                            color: pw.PdfColors.blueAccent),
                        children: [
                          // Gross Amount Row
                          pw.TableRow(
                            children: [
                              _buildTableCell(
                                  'Gross Amount (المبلغ الإجمالي):',
                                  (double.parse(data['totalWithoutVat']?.toString() ?? '0')).toStringAsFixed(2),
                                  _convertToArabic((double.parse(data['totalWithoutVat']?.toString() ?? '0')).toStringAsFixed(2))
                              ),
                            ],
                          ),
                          // Total VAT(15%) Row
                          pw.TableRow(
                            children: [
                              _buildTableCell(
                                  'Total VAT (ضريبة):',
                                  (double.parse(data['totalWithoutVat']?.toString() ?? '0') * 0.15).toStringAsFixed(2),
                                  _convertToArabic((double.parse(data['totalWithoutVat']?.toString() ?? '0') * 0.15).toStringAsFixed(2))
                              ),
                            ],
                          ),
                          // Net Amount Row
                          pw.TableRow(
                            children: [
                              _buildTableCell(
                                  'Net Amount (المجموع الصافي):',
                                  (double.parse(data['netAmount']?.toString() ?? '0')).toStringAsFixed(2),
                                  _convertToArabic(data['netAmount']?.toString() ?? '')
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),





              pw.Expanded(
                flex: 1,
                child: pw.SizedBox(),
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 20), // Add horizontal padding
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Total Amount In Words: ',
                        style: pw.TextStyle(
                          font: ttfFontBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                          decorationColor: pw.PdfColors.orange900,// Underline the heading text
                        ),
                      ),
                      pw.TextSpan(
                        text: _getNetAmountInWords(data),
                        style: pw.TextStyle(
                          font: ttfArabicFont,
                          fontSize: 13,
                          fontStyle: pw.FontStyle.italic, // Italicize the value text
                        ),
                      ),
                    ],
                  ),
                ),
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
        title: Center(
          child: Text(
            'Invoice Receipts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 50,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _invoiceStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
              ],
            );
          }

          var documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var sortedDocuments = documents.toList()
                ..sort((a, b) => (b['invoiceNo'] as String)
                    .compareTo(a['invoiceNo'] as String));
              var data = sortedDocuments[index].data() as Map<String, dynamic>;
              var documentId = sortedDocuments[index].id;
              return Card(
                elevation: 4.0,
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () async => await _generatePDF(data),
                  child: Row(
                    children: [
                      Expanded(
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
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Invoice(
                                userEmail: widget.userEmail,
                                documentId: documentId,
                                invoiceData: data,
                              ),
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirm Delete"),
                                content: Text(
                                    "Are you sure you want to delete this invoice?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text("Yes"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            await FirebaseFirestore.instance
                                .collection('invoices')
                                .doc(documentId)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invoice deleted'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
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
