import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' as printing;
import 'package:number_to_words/number_to_words.dart' as words;

class RfqReceipt extends StatefulWidget {
  const RfqReceipt({Key? key}) : super(key: key);

  @override
  State<RfqReceipt> createState() => _RfqReceiptState();
}

class _RfqReceiptState extends State<RfqReceipt> {
  Stream<QuerySnapshot>? _invoiceStream;

  @override
  void initState() {
    super.initState();
    _initDeliveryStream();
  }

  void _initDeliveryStream() {
    _invoiceStream = FirebaseFirestore.instance.collection('rfq').snapshots();
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
            textDirection:
                pw.TextDirection.rtl, // Right-to-left text direction for Arabic
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
                      _buildDetailText('Quotation Date:', data['quotationDate'], isBold: true),
                      _buildDetailText('Quotation No.:', data['quotationNo'], isBold: true),

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
    List<Map<String, dynamic>> productList =
        (data['products'] as List<dynamic>).cast<Map<String, dynamic>>();

    // Build the table rows dynamically using Firestore data
    List<pw.TableRow> tableRows = [];
    tableRows.add(_buildDetailsTableRow([
      ' Sl No\nعدد ',
      ' Item Code\n رمز الصنف',
      'Product Description\n وصف',
      ' Unit \n وحدة',
      ' Qty \n الكمية ',
      ' Unit Price\nالسعر',
      ' Vat(15%) \nضريبة',
      ' Line Total \nمجموع'
    ], isHeader: true));

    for (int i = 0; i < productList.length; i++) {
      Map<String, dynamic> product = productList[i];
      tableRows.add(_buildDetailsTableRow([
        (i + 1).toString(),
        product['code'] ?? '',
        product['name'] ?? '',
        product['unit'] ?? '',
        product['quantity']?.toString() ?? '',
        product['price']?.toString() ?? '',
        (product['taxAmount'] ?? 0.0)
            .toStringAsFixed(2), // Formatting VAT to one decimal place
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
    String _convertChunk(int number) {
      final List<String> units = [
        '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
        'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'
      ];

      final List<String> tens = [
        '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'
      ];

      if (number == 0) return '';

      if (number < 20) {
        return units[number];
      } else if (number < 100) {
        return tens[number ~/ 10] + (number % 10 != 0 ? ' ${units[number % 10]}' : '');
      } else {
        return units[number ~/ 100] + ' hundred' + (number % 100 != 0 ? ' ' + _convertChunk(number % 100) : '');
      }
    }

    String _convertNumberToWords(int number) {
      if (number == 0) return 'zero';

      final List<String> units = [
        '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
        'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'
      ];

      final List<String> tens = [
        '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'
      ];

      final List<String> scales = [
        '', 'thousand', 'million', 'billion', 'trillion'
      ];

      List<String> words = [];
      int scaleIndex = 0;

      while (number > 0) {
        int chunk = number % 1000;
        if (chunk != 0) {
          words.insert(0, _convertChunk(chunk) + ' ' + scales[scaleIndex]);
        }
        number ~/= 1000;
        scaleIndex++;
      }

      return words.join(' ').trim();
    }

    String _getNetAmountInWords(Map<String, dynamic> data) {
      double netAmountDouble = double.parse(data['netAmount']?.toString() ?? '0');
      int netAmountInt = netAmountDouble.truncate();
      int halalas = ((netAmountDouble - netAmountInt) * 100).toInt(); // Extract halalas

      String netAmountInWords = _convertNumberToWords(netAmountInt);
      String halalasInWords = _convertNumberToWords(halalas);

      String netAmountText = '${capitalizeWords(netAmountInWords)} Saudi Riyals and ${capitalizeWords(halalasInWords)} Halalas';
      return netAmountText;
    }


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
                    'QUOTATION',
                    style: pw.TextStyle(
                        font: ttfFontBold, fontSize: 18, letterSpacing: 2),
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
              pw.Container(
                margin: pw.EdgeInsets.symmetric(horizontal: 20.0),
                child: pw.Table(
                  border: pw.TableBorder.all(
                      style: pw.BorderStyle.dashed, color: pw.PdfColors.blueAccent),
                  children: tableRows,
                ),
              ),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(horizontal: 20.0),
                height: 1.0,
                color: pw.PdfColors.blueAccent,
              ),
              pw.SizedBox(height: 10),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 70.0),
                child: pw.Container(
                  height: 200,
                  //  margin: pw.EdgeInsets.only(top: 10.0), // Adjust the top margin as needed
                  child: pw.Table(
                    border: pw.TableBorder.all(
                        style: pw.BorderStyle.dashed,
                        color: pw.PdfColors.blueAccent),
                    children: [
                      // Gross Amount Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('Gross Amount:'),
                          _buildTableCell(
                            (double.parse(
                                    data['totalWithoutVat']?.toString() ?? '0'))
                                .toStringAsFixed(2),
                          ),
                        ],
                      ),
                      // Total VAT(15%) Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('Total VAT(15%):'),
                          _buildTableCell(
                            (double.parse(data['totalWithoutVat']?.toString() ??
                                        '0') *
                                    0.15)
                                .toStringAsFixed(2),
                          ),
                        ],
                      ),
                      // Net Amount Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('Net Amount:'),
                          _buildTableCell(
                            (double.parse(
                                data['netAmount']?.toString() ?? '0'))
                                .toStringAsFixed(2),
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
              pw.Expanded(
                flex: 1,
                child: pw.SizedBox(),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(left: 20, bottom: 5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    // pw.Text(
                    //   'Note:',
                    //   style: pw.TextStyle(
                    //     font: ttfFontBold,
                    //     fontSize: 16,
                    //     decoration: pw.TextDecoration.underline,
                    //   ),
                    // ),
                    // pw.SizedBox(width: 200),
                    pw.Text(
                      '-Materials quoted are subject to the availability at the time of confirmation by Purchase Order. \n -Prices quoted are based on all items and quantities ordered.\n-Validity of the Quotation is 30 days.',
                      style: pw.TextStyle(
                        font: ttfFont,
                        fontSize: 9,
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
          'Quotation Notes',
          style: TextStyle(
              color: Colors.white, fontSize: 50, fontWeight: FontWeight.w700),
        )),
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
                ..sort((a, b) => (b['quotationNo'] as String)
                    .compareTo(a['quotationNo'] as String));
              var data = sortedDocuments[index].data() as Map<String, dynamic>;
              var documentId =
                  sortedDocuments[index].id; // Retrieve document ID
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
                                'Quotation NO: ${data['quotationNo']}',
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
                                'Date: ${data['quotationDate']}',
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
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirm Delete"),
                                content: Text(
                                    "Are you sure you want to delete this quotation?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(
                                          false); // Return false if cancel is pressed
                                    },
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(
                                          true); // Return true if yes is pressed
                                    },
                                    child: Text("Yes"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            await FirebaseFirestore.instance
                                .collection('rfq')
                                .doc(
                                    documentId) // Use the retrieved document ID here
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Quotation deleted'),
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
