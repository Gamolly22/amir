import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  final String whatsappNumber = "201554194749";

  
  final bool isAdmin = true;

  final List<Map<String, String>> products = [
    {
      'image':
          'https://ik.imagekit.io/puceam5ji/New%20Folder/1-removebg-preview.png',
      'name': 'Redmi Note 14',
      'description': 'Price: 9200 EGP',
    },
    {
      'image':
          'https://ik.imagekit.io/puceam5ji/New%20Folder/infinix-hot-50i-gold-removebg-preview.png',
      'name': 'Infinix Hot 50i',
      'description': 'Price: 7800 EGP',
    },
    {
      'image':
          'https://ik.imagekit.io/puceam5ji/New%20Folder/Xiaomi-Redmi-14C-Dual-Sim-128GB-6GB-Ram-4G_3654_1-600x600-removebg-preview.png',
      'name': 'Redmi 14C',
      'description': 'Price: 7000 EGP',
    },
  ];

  HomeScreen({super.key});

  Future<void> openWhatsApp(Map<String, String> product) async {
    final String message = '''
*${product['name']}*
${product['description']}
📸 ${product['image']}
''';

    final Uri url = Uri.parse(
        'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('❌ لم يتمكن من فتح واتساب');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product['image']!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 150, 136),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product['description']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => openWhatsApp(product),
                          child: const Text(
                            'طلب',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
