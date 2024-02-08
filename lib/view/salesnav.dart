import 'package:UltimateSolutions/view/activity/addactivity.dart';
import 'package:UltimateSolutions/view/print.dart';
import 'package:UltimateSolutions/view/products/purchase.dart';
import 'package:UltimateSolutions/view/quotation/rfq.dart';
import 'package:UltimateSolutions/view/activity/viewallactivities.dart';
import 'package:flutter/material.dart';


import 'customer/addcustomer.dart';
import 'checkout.dart';
import 'credits.dart';
import 'delivery/delivery.dart';
import 'followup.dart';
import 'invoice/invoice.dart';

class SalesNav extends StatefulWidget {
  SalesNav({Key? key, this.userEmail=''}) : super(key: key);


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
                    horizontal: constraints.maxWidth > 600 ? 100 : 20,
                    vertical: 20,
                  ),
          child: GridView.count(
            crossAxisCount: constraints.maxWidth > 600 ? 6 : 2,
            mainAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: [
              if (isAdmin)
                buildMenuItem('Purchase', Purchase(userEmail: widget.userEmail), Icons.shopping_cart, Colors.blue),
              if (isAdmin)
                buildMenuItem('Add Customer', AddCustomer(userEmail: widget.userEmail,), Icons.person_add, Colors.green),
              if (isAdmin)
                buildMenuItem('RFQ', Rfq(userEmail: widget.userEmail), Icons.task, Colors.orange),
              if (isAdmin)
                buildMenuItem('Delivery', Delivery(userEmail: widget.userEmail), Icons.fire_truck, Colors.purple),
              if (isAdmin)
                buildMenuItem('Invoice', Invoice(userEmail: widget.userEmail,), Icons.receipt_long, Colors.red),
              if (isAdmin)
                buildMenuItem('View Activity', ViewActivity(), Icons.list, Colors.teal),
              if (isAdmin)
                buildMenuItem('View Credits', Credits(), Icons.credit_card_rounded, Colors.indigo),
              if (isAdmin)
                buildMenuItem('Follow Up', FollowUp(), Icons.timelapse, Colors.deepOrange),
              if (isAdmin)
                buildMenuItem('Print', Print(), Icons.print, Colors.blue),
              if (isUser)
                buildMenuItem('Add Activity', AddActivity(userEmail: widget.userEmail,), Icons.done_all_rounded, Colors.amber),
              buildCheckoutButton(),
            ],

          ),
                );
              },
          ),
      ),
    );
  }
  Widget buildMenuItem(String title, Widget page, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
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
              style: TextStyle(color: Colors.white,
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

