import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:UltimateSolutions/approvereqs.dart';
import 'package:UltimateSolutions/view/activity/checkins.dart';
import 'package:UltimateSolutions/view/products/add_products.dart';
import 'package:UltimateSolutions/view/products/productselectionpage.dart';
import '../view/activity/addactivity.dart';
import '../view/customer/addcustomer.dart';
import '../view/customer/customers.dart';
import '../view/delivery/delivery.dart';
import '../view/delivery/deliverynote.dart';
import '../view/invoice/invoice.dart';
import '../view/invoice/invoicereceipt.dart';
import '../view/purchase/add_purchase.dart';
import '../view/purchase/view_purchase.dart';
import '../view/quotation/rfq.dart';
import '../view/quotation/rfqreceipt.dart';
import '../view/supplier/add_supplier.dart';
import 'dashboard.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Define the current page (the content displayed on the right side)
  Widget _currentPage = DashboardPage(); // Default to Dashboard


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar Menu
          Container(
            width: 250,
            color: Color(0xff172028),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Welcome Section
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Center(child: Text('Aman And Judeh Foundation', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24), textAlign: TextAlign.center)),
                      Divider(color: Colors.white),
                      SizedBox(height: 15),
                      Text('Welcome Admin!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                      Text('Date : ${DateTime.now()}', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),



                MenuOption('Dashboard', [
                  'View Dashboard'

                ], Iconsax.setting, Color(0xff172028), context, _updatePage),


                // Menu Section
                MenuOption('Invoice', [
                  'Add Invoice',
                  'View Invoices',
                ], Iconsax.receipt, Colors.red, context, _updatePage),

                MenuOption('RFQ', [
                  'Add RFQ',
                  'View RFQs',
                ], Iconsax.task, Colors.orange, context, _updatePage),

                MenuOption('Delivery', [
                  'Add Delivery',
                  'View Delivery Notes',
                ], Iconsax.truck, Colors.purple, context, _updatePage),

                MenuOption('Products', [
                  'Add Products',
                  'View Products',
                ], Iconsax.shopping_cart, Colors.blue, context, _updatePage),

                MenuOption('Purchase', [
                  'Add Purchase',
                  'View Purchase',
                ], Iconsax.shopping_cart, Colors.blue, context, _updatePage),

                MenuOption('Suppliers', [
                  'Add Supplier',
                ], Iconsax.shopping_cart, Colors.red, context, _updatePage),

                MenuOption('View Activity', [
                  'View Activity',
                  'View Check-ins',
                ], Iconsax.activity, Colors.amber, context, _updatePage),

                MenuOption('Add Customer', [
                  'Add Customer',
                  'View Customers',
                ], Iconsax.profile, Colors.green, context, _updatePage),

                MenuOption('Approvals', [
                  'Approval Pending',
                ], Iconsax.shopping_cart, Colors.red, context, _updatePage),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'v1.0.1',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area (Body)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _currentPage, // Display the updated content
            ),
          ),
        ],
      ),
    );
  }

  // This method will update the content displayed on the right side based on the menu item clicked
  void _updatePage(String subOption) {
    switch (subOption) {
      case 'Go to Approve':
        _currentPage = AdminPendingScreen();
        break;
      case 'Add Products':
        _currentPage = AddProductPage();
        break;
      case 'View Products':
        _currentPage = ProductSelectionPage();
        break;
      case 'Add Purchase':
        _currentPage = Purchase(userEmail: "");
        break;
      case 'View Purchase':
        _currentPage = ViewPurchase();
        break;
      case 'Add Supplier':
        _currentPage = AddSupplier(userEmail: "");
        break;
      case 'View Activity':
        _currentPage = UserListPage();
        break;
      case 'View Check-ins':
        _currentPage = CheckInViewer();
        break;
      case 'Add Customer':
        _currentPage = AddCustomer(userEmail: '');
        break;
      case 'View Customers':
        _currentPage = ViewCustomers(userEmail: "", isAdmin: true);
        break;
      case 'Add RFQ':
        _currentPage = Rfq(userEmail: "");
        break;
      case 'View RFQs':
        _currentPage = RfqReceipt();
        break;
      case 'Add Delivery':
        _currentPage = Delivery(userEmail: "");
        break;
      case 'View Delivery Notes':
        _currentPage = DeliveryNotes();
        break;
      case 'Add Invoice':
        _currentPage = Invoice(userEmail: "admin@ultimategcc.com");
        break;
      case 'View Invoices':
        _currentPage = InvoiceReceipt(userEmail: "admin@ultimategcc.com");
        break;
      case 'Approval Pending':
        _currentPage = AdminPendingScreen();
        break;
      case 'View Dashboard' :
        _currentPage = DashboardPage();

        break;


      default:
        _currentPage = Container(); // Default to an empty container if no match
        print('Unknown sub-option');
    }
    setState(() {}); // Update the UI after the page has been updated
  }


}

class MenuOption extends StatelessWidget {
  final String menuName;
  final List<String> subOptions;
  final IconData menuIcon;
  final Color collapsedIconColor;
  final BuildContext context;
  final Function(String) onMenuSelected;

  MenuOption(this.menuName, this.subOptions, this.menuIcon, this.collapsedIconColor, this.context, this.onMenuSelected);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      iconColor: Colors.white,
      collapsedIconColor: collapsedIconColor,
      title: Row(
        children: [
          Icon(menuIcon, color: Colors.white),
          SizedBox(width: 10),
          Text(menuName, style: GoogleFonts.poppins(color: Colors.white)),
        ],
      ),
      children: subOptions
          .map((subOption) => ListTile(
        title: Text(subOption, style: GoogleFonts.poppins(color: Colors.white70)),
        onTap: () {
          onMenuSelected(subOption); // Notify parent about the selected sub-option
        },
      ))
          .toList(),
    );
  }
}
