import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:UltimateSolutions/view/invoice/invoice.dart';

class AdminDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String collection;

  const AdminDetailScreen({
    super.key,
    required this.data,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    final String titleText = _capitalize(collection);

    final entries = data.entries.toList();
    entries.sort((a, b) {
      if (a.key == 'invoiceNo') return -1;
      if (b.key == 'invoiceNo') return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("Details - $titleText", style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {

              print('--------');
              print(data['invoiceNo']);
              print(data);


              print('--------');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Invoice(

                    userEmail: 'admin@zappq.com', // Use a valid email if needed
                    documentId: data['invoiceNo'] ?? 0, // if your doc ID is invoiceNo
                    invoiceData: data ?? {},
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: data.isEmpty
            ? const Center(
          child: Text(
            "No data available",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        )
            : ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final key = entries[index].key;
            final value = entries[index].value;

            if (key == 'products' && value is List) {
              return _buildProductsCard(value);
            }

            return Card(
              color: const Color(0xFF1E1E1E),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.document_text, color: Colors.white70),
                title: Text(
                  _beautifyKey(key),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  value != null ? value.toString() : 'N/A',
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductsCard(List products) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        collapsedIconColor: Colors.white70,
        iconColor: Colors.greenAccent,
        title: const Text(
          "Products",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        children: products.map<Widget>((product) {
          if (product is Map<String, dynamic>) {
            final name = product['name'];
            final otherFields = Map.of(product)..remove('name');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name != null)
                    Text(
                      "Name: $name",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 4),
                  ...otherFields.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      "${_beautifyKey(entry.key)}: ${entry.value}",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  )),
                  const Divider(color: Colors.white24),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(product.toString(), style: const TextStyle(color: Colors.white70)),
            );
          }
        }).toList(),
      ),
    );
  }

  String _capitalize(String str) {
    if (str.isEmpty) return "Unknown";
    return str[0].toUpperCase() + str.substring(1);
  }

  String _beautifyKey(String key) {
    final parts = key.replaceAll('_', ' ').split(RegExp(r'(?=[A-Z])'));
    return parts.map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
