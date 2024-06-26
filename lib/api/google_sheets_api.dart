import 'package:gsheets/gsheets.dart';


final _credentials = {
  "type": "service_account",
  "project_id": "ultimate-ba724",
  "private_key_id": "4bb7f7d640d344f25ce95cadfe53cd87e536d320",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDrURUC3PNtisGd\n3i89SRr19FSyaJE3PqJv4DURiecdxB15LmcU4o5dtszmpQbC7lnEQA1uyFSRMBbo\nYqjK4XyPf/fjwWoS/r9MGy3WXF06lcajO+BpsvNIpkXoLPFBM7jlwGvN99I6+X6t\nmL93Isa6tWjEVVOyiQBQvhxL9IMMozDhPTDe9dExU31crBzHSPyxluGujfI4trH8\nh/yb7cO7wFMCkNUUqLGf7yrZDi5sLCp+BWTCPd0cbChfuFKnIJ5fMMVKtPMTWqmU\naQ9EGZBw+g+DoWoAto58mvDPr0kKAkmWhDWjnbuH771HAXgA7w+irXBfKf7ngVv2\nFbwFTzmTAgMBAAECggEAFwzn5aeRF3+KZxVsQ9uVDtddMztiUNVg11v7YXlvBeUV\nDK7KnYAdI/mTvrAW+8yZ8csNxcv32gpU5B9DRi7/ouridGaY0RLagvD9SiHdZq9k\njXmAX7o4xzq1CauFV7a3pkHKuEVN9vBDmWunWFs0DkwA3uKLgqdAPFMzCw8A20wy\nQUGUFXvWbJOdTv3p3iv6G2BUVMYwKE4Xckfa1N1R0mTEUMzg+uLYnaNv+ckPy+4K\nKTG8I67hVUkH41gDBqRSfHSET/dkiHncdWsQ1KvI5uLoFTTVwmb0bY+D5vfmgtFW\nh2wTXBOpMMJtpwhNkIK+dxkec405n0GWxEFGoyXUuQKBgQD5YI36rvgZi6nYpx7/\n45x7UJ4jbsV8m0lJ10lZMnho8NJEaUEZygyyiEjXrtFAHiErZmBTxQ2IsW1uysaf\n2DLK3HXn2HoOjLfD4nnqHX6pv/sZY5WbmJo4iQytKSyscXg+xqcIp/+m1J8584Qy\n8W8uHtat9iFernPqw70XqK/OxwKBgQDxkO86X0Mlz+DJA2xMnohTTmXfcxx4fjhQ\nMN0UjjTEA6AfGUwLiMWfLlnlKSjqb+RkNldfLAtFCC1thUNTgG+wTshki4mT2+sh\nl9jAKjxomUNhC6HTnwUiQ1AaekRzQRFAvGExLV7WfPajrMo/1KsAsTI3ZbXOhyn+\nV67jUyBi1QKBgQDJsuXDH2e9ya+7cxhooaE8QC1XvU1wBm1VkxJZWa/4OOfouzUT\ndc+lSwOXp2bJtFThtHEu8A+NQuyfEtVqDcSvPXcD6Zx3TiuH/RLcX7TF+WhP1bL4\n4YnDNl4RZF8krrYyGBybrL3jItASYDrJtWtWY00B8TR2TyWkeWLk0uQ3mwKBgCC7\nMq8GGWMWN68E97eqA27GQKd2QXVSJO84r7wJSL0GgLu2AcfOUHixHx0d5p1da+To\nOA59OUmxQfaFCApYbMnG4wA8p/eQ5Ns4Z/Yhwu2pVqffm53A/kEWPdRYnM3BE0Vi\nQQkYzLDjXcfvsbfUaRc+6z72WRwS1G3SE7BZoxnBAoGBAONJvjZOkcmU0585uaFc\n9Vlod9WVHkwvmBPprjDLmlqI0frihvo0RxSo7vQqLhh6mFog6y5yImsY0VrDLWJu\npuoPdcinXFANxRLO2DBAj3SrDPMHFwYBldFqZOQm4qgDO7hODIop/H1NqE50XOPS\n40szid7VjYmNmSqo8BMYD9Lc\n-----END PRIVATE KEY-----\n",
  "client_email": "shahidsservices-913@ultimate-ba724.iam.gserviceaccount.com",
  "client_id": "101185272529500843022",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/shahidsservices-913%40ultimate-ba724.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

// Initialize the GSheets library with your service account credentials
final gsheets = GSheets(_credentials);
Spreadsheet? _spreadsheet;

// Initialize the Spreadsheet object only
Future<void> init() async {
  const spreadsheetId = '1jdkTt_u6ECcEGs_yydRWnCNEKP6NY-UKVJTO2Mn7cNE';
  _spreadsheet = await gsheets.spreadsheet(spreadsheetId);
  print('Spreadsheet initialized successfully');
}

// Dynamically handle worksheet selection or creation based on employee name
Future<Worksheet> getOrCreateWorksheetForEmployee(String employeeName) async {
  if (_spreadsheet == null) {
    // If _spreadsheet is not initialized, call init()
    await init();
  }

  var worksheet = _spreadsheet!.worksheetByTitle(employeeName);
  if (worksheet == null) {
    // Create a new worksheet for the employee if it doesn't exist
    worksheet = await _spreadsheet!.addWorksheet(employeeName);
    // Optionally, initialize the worksheet with a header row
    await worksheet.values.insertRow(1, ["USERNAME", "CUSTOMER NAME", "ACTIVITY", "CUSTOMER REMARK", "SALESMAN REMARK","TIME STAMP"]);
  }
  return worksheet;
}

// Function to append a row to the correct worksheet for a specific employee
Future<void> appendActivityToEmployeeSheet(String employeeName, List<dynamic> rowValues) async {
  final worksheet = await getOrCreateWorksheetForEmployee(employeeName);
  await worksheet.values.appendRow(rowValues);
}

Future<void> appendCustomerToSheet(String worksheetName, List<dynamic> rowValues) async {
  final worksheet = await getOrCreateWorksheetForCustomer(worksheetName);
  await worksheet.values.appendRow(rowValues);
}


Future<Worksheet> getOrCreateWorksheetForCustomer(String worksheetName) async {
  if (_spreadsheet == null) {
    // If _spreadsheet is not initialized, call init()
    await init();
  }
  var worksheet = _spreadsheet!.worksheetByTitle(worksheetName);
  if (worksheet == null) {
    // Create a new worksheet for the customer if it doesn't exist
    worksheet = await _spreadsheet!.addWorksheet(worksheetName);
    // Optionally, initialize the worksheet with a header row
    await worksheet.values.insertRow(1, ["Customer Name", "Customer Code", "Address", "Customer Type", "Delivery Location", "Mobile Number", "Telephone Number", "VT Number", "Created At", "Email"]);
  }
  return worksheet;
}

