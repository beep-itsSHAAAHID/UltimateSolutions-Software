import 'package:UltimateSolutions/view/activitiy.dart';
import 'package:UltimateSolutions/view/customers.dart';
import 'package:UltimateSolutions/view/customerselection.dart';
import 'package:UltimateSolutions/view/productselectionpage.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:flutter/material.dart';

import 'deliverynote.dart';


class ViewActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Activities',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context)=>Activities()));

          },
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activities',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  // Add your content for Delivery Note here
                  // Example:

                ],
              ),
            ),
          ),
          InkWell(onTap: (){
            Navigator.push(context,
                MaterialPageRoute(builder: (context)=>ViewCustomers()));
          },
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Customers',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  // Add your content for Invoice here
                  // Example:

                ],
              ),
            ),
          ),
          InkWell(onTap: (){
            Navigator.push(context,
                MaterialPageRoute(builder: (context)=>ProductSelectionPage()));
          },
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Products',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  // Add your content for Invoice here
                  // Example:

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



