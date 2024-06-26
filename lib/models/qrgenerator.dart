import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ZatcaFatooraDataModel {
  late String sellerName;
  late String vatRegistrationNumber;
  late String invoiceStamp;
  late String totalInvoice;
  late String totalVat;

  ZatcaFatooraDataModel({
    required this.sellerName,
    required this.vatRegistrationNumber,
    required this.invoiceStamp,
    required this.totalInvoice,
    required this.totalVat,
  });

  List<int> toBytes() {
    BytesBuilder bytesBuilder = BytesBuilder();

    // 1. Seller Name
    _addTLV(bytesBuilder, 1, utf8.encode(sellerName));

    // 2. VAT Registration Number
    _addTLV(bytesBuilder, 2, utf8.encode(vatRegistrationNumber));

    // 3. Invoice Stamp
    _addTLV(bytesBuilder, 3, utf8.encode(invoiceStamp));

    // 4. Total Invoice
    _addTLV(bytesBuilder, 4, utf8.encode(totalInvoice));

    // 5. Total VAT
    _addTLV(bytesBuilder, 5, utf8.encode(totalVat));

    return bytesBuilder.toBytes();
  }

  List<int> _encodeAmountField(num amount) {
    int amountInCents = (amount * 100).round();
    return [amountInCents >> 8, amountInCents & 0xFF];
  }

  void _addTLV(BytesBuilder bytesBuilder, int tag, List<int> value) {
    bytesBuilder.addByte(tag);
    bytesBuilder.addByte(value.length);
    bytesBuilder.add(value);
  }

  String generateZatcaFatooraBase64Code() {
    Uint8List bytes = Uint8List.fromList(toBytes());
    String qrCodeBase64 = base64.encode(bytes);
    return qrCodeBase64;
  }

  Widget generateQrCodeWidget() {
    String qrCode = generateZatcaFatooraBase64Code();
    return QrImageView(data: qrCode, version: QrVersions.auto, size: 100.0);
  }

  Uint8List hexStringToBytes(String hexString) {
    List<int> bytes = [];
    for (int i = 0; i < hexString.length; i += 2) {
      String hex = hexString.substring(i, i + 2);
      bytes.add(int.parse(hex, radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

class ZatcaFatooraController {
  ZatcaFatooraController._();

  static String generateZatcaFatooraBase64Code(ZatcaFatooraDataModel fatooraData) {
    Uint8List bytes = Uint8List.fromList(fatooraData.toBytes());
    String qrCodeBase64 = base64.encode(bytes);
    return qrCodeBase64;
  }
}


