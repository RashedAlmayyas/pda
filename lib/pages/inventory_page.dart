import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/io_client.dart';
import 'dart:io';

class InventoryPage extends StatefulWidget {
   final String branchNo;
  final String branchApi;

  const InventoryPage({
    Key? key,
    required this.branchNo,
    required this.branchApi,
  }) : super(key: key);

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _inventoryQuantityController =
      TextEditingController();

  String? inventoryNumber;
  String? currentQuantity;
  String? itemName;
  String? errorMessage;
  String? successMessage;




 

Future<void> _fetchQuantities(String barcode) async {
  setState(() {
    currentQuantity = null;
    itemName = null;
  });

  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_inventory.php',
    'https://188.247.88.117/api_pda/fetch_inventory.php',
  ];

  http.Client client = http.Client(); // الاتصال العادي الافتراضي

  for (String url in urls) {
    final uri = Uri.parse(url);

    // تجاوز فحص SSL إذا كان الرابط يحتوي على IP
    if (uri.host == '188.247.88.117') {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      client = IOClient(httpClient);
    }

    try {
      final response = await client.post(
        uri,
        body: {
          'branchNo': widget.branchNo,
          'barcode': barcode,
          'branch_api': widget.branchApi,
        },
      );

      debugPrint('Response from $url: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['status'] == 'success') {
          setState(() {
            itemName = responseBody['itemName'];
            currentQuantity = responseBody['currentQuantity'];
          });
          return; // توقف عند أول استجابة ناجحة
        } else if (responseBody['status'] == 'error') {
          setState(() {
            errorMessage = responseBody['message'];
          });
        }
      } else {
        setState(() {
          errorMessage = 'حدث خطأ في الاتصال بالخادم';
        });
      }
    } catch (e) {
      debugPrint('فشل الاتصال بـ $url: $e');
    }
  }

  // إذا فشلت جميع المحاولات
  setState(() {
    errorMessage = 'فشل الاتصال بالخادم أو استرجاع البيانات.';
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تعذر جلب الكميات')),
  );
}Future<void> _resetQuantities() async {
  if (_formKey.currentState?.validate() ?? false) {
    setState(() {
      errorMessage = null;
      successMessage = null;
    });

    List<String> urls = [
      'https://swipup.samehgroup.com/api_pda/update_inventory2.php',
      'https://188.247.88.117/api_pda/update_inventory2.php', // رابط احتياطي
    ];

    http.Client client = http.Client(); // الاتصال العادي الافتراضي

    for (String url in urls) {
      final uri = Uri.parse(url);

      // تجاوز فحص SSL إذا كان الرابط يحتوي على IP
  if (uri.host == '188.247.88.117') {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      client = IOClient(httpClient);
    }
 
      try {
        final response = await client.post(
          uri,
          body: {
            'branchNo': widget.branchNo.toString(),
            'itemBarcode': _barcodeController.text,
            'pdaInvQnty': _inventoryQuantityController.text,
            'branch_api': widget.branchApi,
          },
        );

        debugPrint('Response from $url: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');

        final responseBody = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (responseBody['success'] != null) {
            setState(() {
              successMessage = responseBody['success'];
              _barcodeController.clear();
              _inventoryQuantityController.clear();
              currentQuantity = null;
              itemName = null;
            });
            return; // توقف عند أول استجابة ناجحة
          } else if (responseBody['error'] != null) {
            setState(() {
              errorMessage = responseBody['error'];
            });
          }
        } else {
          setState(() {
            errorMessage = 'حدث خطأ في الاتصال بالخادم';
          });
        }
      } catch (e) {
        debugPrint('فشل الاتصال بـ $url: $e');
      }
    }

    // إذا فشلت جميع المحاولات
    setState(() {
      errorMessage = 'فشل الاتصال بالخادم أو تحديث الكميات.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر تحديث الكميات')),
    );
  }
}Future<void> _saveQuantities() async {
  if (_formKey.currentState?.validate() ?? false) {
    setState(() {
      errorMessage = null;
      successMessage = null;
    });

    List<String> urls = [
      'https://swipup.samehgroup.com/api_pda/update_inventory.php',
      'https://188.247.88.117/api_pda/update_inventory.php', // رابط احتياطي
    ];

    http.Client client = http.Client(); // الاتصال العادي الافتراضي

    for (String url in urls) {
      final uri = Uri.parse(url);

      // تجاوز فحص SSL إذا كان الرابط يحتوي على IP
  if (uri.host == '188.247.88.117') {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      client = IOClient(httpClient);
    }

      try {
        final response = await client.post(
          uri,
          body: {
            'branchNo': widget.branchNo.toString(),
            'itemBarcode': _barcodeController.text,
            'pdaInvQnty': _inventoryQuantityController.text,
            'qntyType': '1',  // مثال: تحديد نوع الكمية (الزيادة أو النقص)
            'branch_api': widget.branchApi,
          },
        );

        debugPrint('Response from $url: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');

        final responseBody = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (responseBody['success'] != null) {
            setState(() {
              successMessage = responseBody['success'];
              _barcodeController.clear();
              _inventoryQuantityController.clear();
              currentQuantity = null;
              itemName = null;
            });
            return; // توقف عند أول استجابة ناجحة
          } else if (responseBody['error'] != null) {
            setState(() {
              errorMessage = responseBody['error'];
            });
          }
        } else {
          setState(() {
            errorMessage = 'حدث خطأ في الاتصال بالخادم';
          });
        }
      } catch (e) {
        debugPrint('فشل الاتصال بـ $url: $e');
      }
    }

    // إذا فشلت جميع المحاولات
    setState(() {
      errorMessage = 'فشل الاتصال بالخادم أو تحديث الكميات.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر تحديث الكميات')),
    );
  }
}



  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.rawContent.isNotEmpty) {
      _barcodeController.text = result.rawContent;
      _fetchQuantities(result.rawContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الجرد',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        backgroundColor:const Color.fromARGB(255, 223, 14, 14),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inventoryNumber != null)
                  const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'أدخل الباركود',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال الباركود';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _fetchQuantities(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _scanBarcode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 209, 2, 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (currentQuantity != null)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '  $itemName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),

                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'الكمية الحالية: $currentQuantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(height: 10),
                       TextFormField(
  controller: _inventoryQuantityController,
  keyboardType: TextInputType.numberWithOptions(decimal: false), 
  decoration: InputDecoration(
    labelText: 'كمية الجرد',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كمية الجرد';
    }

    final quantity = double.tryParse(value);
    if (quantity == null) {
      return 'يرجى إدخال قيمة رقمية صحيحة';
    }

    if (quantity < 0) {
      return 'لا يمكن إدخال قيمة أقل من 0';
    }

    return null;
  },
),

                        ],
                      ),
                    ),
                  ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                if (successMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      successMessage!,
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveQuantities,
                        style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 209, 2, 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          elevation: 6,
                        ),
                        child: const Text(
                          'حفظ',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetQuantities,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 0, 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          elevation: 6,
                        ),
                        child: const Text(
                          ' تصفير',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
