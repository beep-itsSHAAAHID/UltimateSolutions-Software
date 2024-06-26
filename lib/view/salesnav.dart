import 'package:UltimateSolutions/view/activity/activitiy.dart';
import 'package:UltimateSolutions/view/activity/addactivity.dart';
import 'package:UltimateSolutions/view/delivery/deliverynote.dart';
import 'package:UltimateSolutions/view/inventory.dart';
import 'package:UltimateSolutions/view/invoice/invoicereceipt.dart';
import 'package:UltimateSolutions/view/print.dart';
import 'package:UltimateSolutions/view/purchase/add_purchase.dart';
import 'package:UltimateSolutions/view/purchase/view_purchase.dart';
import 'package:UltimateSolutions/view/quotation/rfq.dart';
import 'package:UltimateSolutions/view/activity/viewallactivities.dart';
import 'package:UltimateSolutions/view/quotation/rfqreceipt.dart';
import 'package:UltimateSolutions/view/vat_report/vat_report.dart';
import 'package:flutter/material.dart';
import 'checkout.dart';
import 'credits.dart';
import 'customer/addcustomer.dart';
import 'customer/customers.dart';
import 'delivery/delivery.dart';
import 'followup.dart';
import 'invoice/invoice.dart';

class SalesNav extends StatefulWidget {
  SalesNav({Key? key, this.userEmail = ''}) : super(key: key);

  final String userEmail;

  @override
  State<SalesNav> createState() => _SalesNavState();
}

class _SalesNavState extends State<SalesNav> {
  @override
  Widget build(BuildContext context) {
    bool isAdmin = isRoleMatching('admin', widget.userEmail);
    bool isUser = isRoleMatching('user', widget.userEmail);

    print('isAdmin: $isAdmin');
    print('isUser: $isUser');

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: AppBar(
            title: Text("Welcome!",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30)),
            centerTitle: true,
            backgroundColor: Color(0xff0C88BD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth > 600 ? 50 : 10,
                vertical: 20,
              ),
              child: GridView.count(
                crossAxisCount: 6,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.8,
                children: [
                  buildMenuItem(
                    'Purchase',
                    Icons.shopping_cart,
                    Colors.blue,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'Add Purchase', 'page': Purchase(userEmail: widget.userEmail)},
                      {'title': 'View Purchase', 'page': ViewPurchase()}, // Replace with your view purchase page
                    ],
                  ),
                  buildMenuItem(
                    'Add Activity',
                    Icons.done_all_rounded,
                    Colors.amber,
                    isVisible: isAdmin || isUser,
                    options: [
                      {'title': 'Add Activity', 'page': AddActivity(userEmail: widget.userEmail)},
                    ],
                  ),
                  buildMenuItem(
                    'Add Customer',
                    Icons.person_add,
                    Colors.green,
                    isVisible: isAdmin || isUser,
                    options: [
                      {'title': 'Add Customer', 'page': AddCustomer(userEmail: widget.userEmail)},
                      {'title': 'View Customers', 'page': ViewCustomers(userEmail: widget.userEmail,isAdmin: isAdmin,)}, // Replace with your view customers page
                    ],
                  ),
                  buildMenuItem(
                    'RFQ',
                    Icons.task,
                    Colors.orange,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'Add RFQ', 'page': Rfq(userEmail: widget.userEmail)},
                      {'title': 'View RFQs', 'page': RfqReceipt()}, // Replace with your view RFQs page
                    ],
                  ),
                  buildMenuItem(
                    'Delivery',
                    Icons.fire_truck,
                    Colors.purple,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'Add Delivery', 'page': Delivery(userEmail: widget.userEmail)},
                      {'title': 'View Delivery Notes', 'page': DeliveryNotes()}, // Replace with your view deliveries page
                    ],
                  ),
                  buildMenuItem(
                    'Invoice',
                    Icons.receipt_long,
                    Colors.red,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'Add Invoice', 'page': Invoice(userEmail: widget.userEmail)},
                      {'title': 'View Invoices', 'page': InvoiceReceipt(userEmail: widget.userEmail)}, // Replace with your view invoices page
                    ],
                  ),
                  buildMenuItem(
                    'View Activity',
                    Icons.list,
                    Colors.teal,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'View Activities', 'page': Activities()},
                    ],
                  ),
                  buildCheckoutButton(),
                  buildMenuItem(
                    'View Credits',
                    Icons.credit_card_rounded,
                    Colors.indigo,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'View Credits', 'page': Credits()},
                    ],
                  ),
                  buildMenuItem(
                    'Inventory',
                    Icons.store,
                    Colors.purpleAccent,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'Check Inventory', 'page': Inventory()},
                    ],
                  ),

                  buildMenuItem(
                    'Vat Report',
                    Icons.print,
                    Colors.blue,
                    isVisible: isAdmin,
                    options: [
                      {'title': 'Cming Soon', 'page': VatReport()},
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildMenuItem(String title, IconData icon, Color color,
      {bool isVisible = true, required List<Map<String, dynamic>> options}) {
    return Visibility(
      visible: isVisible,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              ...options.map((option) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => option['page']),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          option['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCheckoutButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => CheckoutPage()));
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.red,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, color: Colors.white, size: 40),
            SizedBox(height: 10),
            Text(
              'Checkout',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool isRoleMatching(String selectedRole, String? userEmail) {
    if (selectedRole == 'admin') {
      return isAdmin(userEmail);
    } else if (selectedRole == 'user') {
      return isUser(userEmail);
    }
    return false;
  }

  bool isAdmin(String? userEmail) {
    return userEmail?.contains('@admin.ultimategcc.com') == true;
  }

  bool isUser(String? userEmail) {
    return userEmail?.contains('@salesman.ultimategcc.com') == true;
  }
}
