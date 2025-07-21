import 'package:UltimateSolutions/view/expenses/view_expenses.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:UltimateSolutions/approvereqs.dart';
import 'package:UltimateSolutions/view/activity/checkins.dart';
import 'package:UltimateSolutions/view/products/add_products.dart';
import 'package:UltimateSolutions/view/products/productselectionpage.dart';
import '../payments/collection_home.dart';
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
  Widget _currentPage = DashboardPage();

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isDesktop
          ? null
          : AppBar(
        backgroundColor: Color(0xff172028),
        iconTheme: IconThemeData(color: Colors.white), // Force white menu icon

        title: Text(
          'Aman And Judeh Foundation',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      drawer: isDesktop
          ? null
          : Drawer(
        child: Container(
          color: Color(0xff172028), // Match sidebar color
          child: ListView(
            padding: EdgeInsets.zero,
            children: _buildMenuOptions(),
          ),
        ),
      ),

      body: isDesktop
          ? Row(
        children: [
          // Sidebar for Desktop
          Container(
            width: 250,
            color: Color(0xff172028),
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuOptions(),
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _currentPage,
            ),
          ),
        ],
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: _currentPage,
      ),
    );
  }

  List<Widget> _buildMenuOptions() {
    return [
      Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 10),
            Center(
              child: Text(
                'Aman And Judeh Foundation',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            Divider(color: Colors.white),
            SizedBox(height: 15),
            Text('Welcome Admin!',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            Text('Date : ${DateTime.now().toLocal()}',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      _menuTile('Dashboard', ['View Dashboard'], Iconsax.setting, Colors.grey),
      _menuTile('Invoice', ['Add Invoice', 'View Invoices'], Iconsax.receipt, Colors.red),
      _menuTile('RFQ', ['Add RFQ', 'View RFQs'], Iconsax.task, Colors.orange),
      _menuTile('Delivery', ['Add Delivery', 'View Delivery Notes'], Iconsax.truck, Colors.purple),
      _menuTile('Products', ['Add Products', 'View Products'], Iconsax.shopping_cart, Colors.blue),
      _menuTile('Purchase', ['Add Purchase', 'View Purchase'], Iconsax.shopping_cart, Colors.teal),
      _menuTile('Suppliers', ['Add Supplier'], Iconsax.people, Colors.red),
      _menuTile('Expenses', ['View Expenses'], Iconsax.wallet, Colors.green),
      _menuTile('View Activity', ['View Activity', 'View Check-ins'], Iconsax.activity, Colors.amber),
      _menuTile('Add Customer', ['Add Customer', 'View Customers'], Iconsax.profile, Colors.green),
      _menuTile('Approvals', ['Approval Pending'], Iconsax.verify, Colors.deepOrange),
      _menuTile('Collections', ['Collections'], Iconsax.money, Colors.deepOrange),

      SizedBox(height: 30,),
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            'v1.1.1',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
        ),
      ),
    ];
  }

  Widget _menuTile(String menuName, List<String> subOptions, IconData icon, Color color) {
    return ExpansionTile(
      iconColor: Colors.white,
      collapsedIconColor: color,
      title: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 10),
          Text(menuName, style: GoogleFonts.poppins(color: Colors.white)),
        ],
      ),
      children: subOptions.map((subOption) {
        return ListTile(
          title: Text(subOption, style: GoogleFonts.poppins(color: Colors.white70)),
          onTap: () {
            Navigator.of(context).maybePop(); // Close drawer on mobile
            _updatePage(subOption);
          },
        );
      }).toList(),
    );
  }

  void _updatePage(String subOption) {
    switch (subOption) {
      case 'View Dashboard':
        _currentPage = DashboardPage();
        break;
      case 'Add Invoice':
        _currentPage = Invoice(userEmail: "admin@ultimategcc.com");
        break;
      case 'View Invoices':
        _currentPage = InvoiceReceipt(userEmail: "admin@ultimategcc.com");
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
      case 'View Expenses':
        _currentPage = ViewExpensesPage();
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
      case 'Approval Pending':
        _currentPage = AdminPendingScreen();
        break;
      case 'Collections':
        _currentPage = PaymentCollections();
        break;
      default:
        _currentPage = DashboardPage();
        print("Unknown menu selected: $subOption");
    }
    setState(() {});
  }
}
