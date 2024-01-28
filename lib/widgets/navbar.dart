// import 'package:flutter/material.dart';
// import 'package:ultimatesolutions/view/SalesHome.dart';
// import 'package:ultimatesolutions/view/addcustomer.dart';
// import 'package:ultimatesolutions/view/checkout.dart';
// import 'package:ultimatesolutions/view/delivery.dart';
// import 'package:ultimatesolutions/view/purchase.dart';
// import 'package:ultimatesolutions/view/salesnav.dart';
// import 'package:ultimatesolutions/view/viewallactivities.dart';
//
// class BottomNavBar extends StatefulWidget {
//   @override
//   _BottomNavBarState createState() => _BottomNavBarState();
// }
//
// class _BottomNavBarState extends State<BottomNavBar> {
//   int _currentIndex = 0;
//
//   // Define your page widgets here
//   final List<Widget> _pages = [
//     SalesNav(),
//     Purchase(),
//     AddCustomer(),
//     ViewActivity(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.blue,
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.shopping_cart),
//             label: 'Purchase',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_add),
//             label: 'Add Customer',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.list),
//             label: 'View Sales',
//           ),
//         ],
//       ),
//     );
//   }
// }