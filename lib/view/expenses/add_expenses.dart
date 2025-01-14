import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpensePage extends StatefulWidget {
  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _enteredByController = TextEditingController();
  final TextEditingController _docNoController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  final TextEditingController _expenseDetailsController = TextEditingController();

  String _paymentMethod = 'Cash in Hand';

  @override
  void initState() {
    super.initState();
    _fetchLastDocNo();
  }

  @override
  void dispose() {
    _enteredByController.dispose();
    _docNoController.dispose();
    _expenseAmountController.dispose();
    _expenseDetailsController.dispose();
    super.dispose();
  }

  Future<void> _fetchLastDocNo() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('expenses')
        .orderBy('docNo', descending: true)
        .limit(1)
        .get();

    int lastDocNo = 1000;
    if (snapshot.docs.isNotEmpty) {
      lastDocNo = snapshot.docs.first['docNo'];
    }
    setState(() {
      _docNoController.text = (lastDocNo + 1).toString();
    });
  }

  void _addExpenseToFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('expenses').add({
        'enteredBy': _enteredByController.text,
        'docNo': int.parse(_docNoController.text),
        'paymentMethod': _paymentMethod,
        'expenseAmount': double.parse(_expenseAmountController.text),
        'expenseDetails': _expenseDetailsController.text,
        'createdDate': FieldValue.serverTimestamp(),
      });
      print('Expense added to Firestore successfully!');
      Navigator.pop(context);
    } catch (error) {
      print('Error adding expense to Firestore: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Expense",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Color(0xff0C88BD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTextField('Entered By', _enteredByController),
            buildTextField('Document Number', _docNoController, editable: false),
            buildPaymentMethodSelector(),
            buildTextField('Expense Amount', _expenseAmountController),
            buildTextField('Expense Details', _expenseDetailsController),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addExpenseToFirestore,
              child: Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller, {bool editable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: editable,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  Widget buildPaymentMethodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: Text('Cash in Hand'),
              value: 'Cash in Hand',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: Text('Bank Account'),
              value: 'Bank Account',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
