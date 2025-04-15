import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'package:http/io_client.dart';

class ReceiptsPage extends StatefulWidget {
  final String branchNo;
  final String idNumber;
  final String branchApi;
  final String INV_PATH;

  const ReceiptsPage({
    Key? key,
    required this.branchNo,
    required this.idNumber,
    required this.branchApi,
    required this.INV_PATH,
  }) : super(key: key);

  @override
  _ReceiptsPageState createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  final TextEditingController purchaseNumberController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController invoiceQuantityController = TextEditingController();
  final TextEditingController invoiceCostController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  XFile? attachedImage;
  bool showAdditionalFields = false;
  bool isFirstSave = true;

  String suppName = '';
  String itemName = '';

  @override
  void initState() {
    super.initState();
    barcodeController.addListener(() {
      onBarcodeChanged(barcodeController.text);
    });
    purchaseNumberController.addListener(() {
      onSupplierNumberChanged(purchaseNumberController.text);
    });
  }

  @override
  void dispose() {
    barcodeController.removeListener(() {});
    purchaseNumberController.removeListener(() {});
    super.dispose();
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

Future<void> fetchSuppName(String supplierNumber) async {
  if (!await checkInternetConnection()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('لا يوجد اتصال بالإنترنت!')),
    );
    return;
  }

  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/get_supplier.php',
    'https://188.247.88.117/api_pda/get_supplier.php', // رابط احتياطي
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
          'SUPP_NO': supplierNumber,
          'branch_api': widget.branchApi,
          'BRANCH_NO': widget.branchNo,
          'ORDER_NO': purchaseNumberController.text,
        },
      );

      debugPrint('Data sent to fetch supplier name:');
      debugPrint('SUPP_NO: $supplierNumber');
      debugPrint('branch_api: ${widget.branchApi}');
      debugPrint('BRANCH_NO: ${widget.branchNo}');
      debugPrint('ORDER_NO: ${purchaseNumberController.text}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Response from API:');
        debugPrint(data.toString());

        setState(() {
          suppName = data['SUPP_NAME'] ?? 'غير متوفر';
        });
        return; // توقف عند أول استجابة ناجحة
      } else {
        debugPrint('Error: Failed to fetch supplier name, status code: ${response.statusCode}');
        setState(() {
          suppName = 'حدث خطأ في جلب البيانات';
        });
      }
    } catch (e) {
      debugPrint('Error fetching supplier name: $e');
    }
  }

  // إذا فشلت جميع المحاولات
  setState(() {
    suppName = 'فشل الاتصال بالخادم أو جلب اسم المورد.';
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('تعذر جلب اسم المورد')),
  );
}
Future<void> fetchItemName(String barcode) async {
  if (!await checkInternetConnection()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('لا يوجد اتصال بالإنترنت!')),
    );
    return;
  }

  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/get_item.php?cache=${DateTime.now().millisecondsSinceEpoch}',
    'https://188.247.88.117/api_pda/get_item.php?cache=${DateTime.now().millisecondsSinceEpoch}', // رابط احتياطي
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
      print('Barcode sent to API: ${barcode.trim()}');
      final response = await client.post(
        uri,
        body: {
          'ITEM_BARCODE': barcode.trim(),
          'branch_api': widget.branchApi,
          'BRANCH_NO': widget.branchNo,
          'ORDER_NO': purchaseNumberController.text,
        },
      );

      print('Response from API: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          itemName = data['ITEM_NAME'] ?? 'غير متوفر';
        });
        return; // توقف عند أول استجابة ناجحة
      } else {
        print('Error: Failed to fetch item name, status code: ${response.statusCode}');
        setState(() {
          itemName = 'حدث خطأ في جلب البيانات';
        });
      }
    } catch (e) {
      print('Error fetching item name: $e');
    }
  }

  // إذا فشلت جميع المحاولات
  setState(() {
    itemName = 'فشل الاتصال بالخادم أو جلب اسم العنصر.';
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('تعذر جلب اسم العنصر')),
  );
}

  void onBarcodeChanged(String value) async {
    if (value.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 500)); // تأخير بسيط
      fetchItemName(value.trim());
    } else {
  
    }
  }

  void onSupplierNumberChanged(String value) async {
    if (value.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 500)); // تأخير بسيط
      fetchSuppName(value);
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        attachedImage = image;
      });
    }
  }

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        setState(() {
          barcodeController.text = result.rawContent.trim();
          onBarcodeChanged(result.rawContent.trim());
        });
      }
    } catch (e) {
      print("Error while scanning barcode: $e");
    }
  }

  Future<void> scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        setState(() {
          purchaseNumberController.text = result.rawContent.trim();
        });
      }
    } catch (e) {
      print("Error while scanning QR code: $e");
    }
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.now();

    DatePicker.showDatePicker(context,
        showTitleActions: true,
        minTime: DateTime(2024, 4, 1),
        maxTime: DateTime(2101, 12, 31),
        onConfirm: (date) {
          setState(() {
            dateController.text = intl.DateFormat('yyyy-MM-dd').format(date);
          });
        },
        currentTime: selectedDate,
        locale: LocaleType.ar);
  }

  Future<void> saveReceiptData() async {


    await saveImage();
    await sendData();

    if (isFirstSave) {
      setState(() {
        isFirstSave = false;
        barcodeController.clear();
        quantityController.clear();
        invoiceQuantityController.clear();
        invoiceCostController.clear();
        dateController.clear();
        attachedImage = null;
        itemName = '';
      });
    }
  }
Future<void> saveImage() async {
   if (attachedImage != null) {
    try {
      final fileName = '${purchaseNumberController.text}.jpg';
      final imageFile = File(attachedImage!.path);


      List<String> urls = [
        'https://swipup.samehgroup.com/api_pda/upload.php',
        'https://188.247.88.117/api_pda/upload.php', // رابط احتياطي
      ];

      http.Client client = http.Client();

      for (String url in urls) {
        final uri = Uri.parse(url);

        // تجاوز SSL لعناوين IP فقط
        if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(uri.host)) {
          HttpClient httpClient = HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
          client = IOClient(httpClient);
        }

        try {
          var request = http.MultipartRequest('POST', uri);

          request.files.add(await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            filename: fileName,
              contentType: MediaType('image', 'jpg'),
           ));

          request.fields['inv_path'] = widget.INV_PATH;

          var response = await client.send(request);

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم رفع الصورة بنجاح إلى الخادم!')),
            );
            return; // توقف عند أول استجابة ناجحة
          } else {
            print('Error: Failed to upload image, status code: ${response.statusCode}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل رفع الصورة إلى الخادم: ${response.statusCode}')),
            );
          }
        } catch (e) {
          print('Error uploading image: $e');
        }
      }

      // إذا فشلت جميع المحاولات
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفع الصورة إلى الخادم')),
      );
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء رفع الصورة: $e')),
      );
    }
  }
}
Future<void> sendData() async {
  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/receipts.php',
    'https://188.247.88.117/api_pda/receipts.php', // رابط احتياطي
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
          'ORDER_NO': purchaseNumberController.text,
          'branch_api': widget.branchApi,
          'BARCODE': barcodeController.text.trim(),
          'BRANCH_NO': widget.branchNo,
          'P_RECEIVED_ITEM_QNTY': quantityController.text,
          'P_RECEIVED_ITEM_PRICE': invoiceCostController.text,
          'P_EXPIRY_DATE': dateController.text,
          'P_SUPP_INV_QTY': invoiceQuantityController.text,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ البيانات بنجاح!')),
          );
          setState(() {
            barcodeController.clear();
            quantityController.clear();
            invoiceQuantityController.clear();
            invoiceCostController.clear();
            dateController.clear();
            attachedImage = null;
            itemName = '';
          });
          return; // توقف عند أول استجابة ناجحة
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${result['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاتصال بالخادم: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال البيانات: $e')),
      );
    }
  }

  // إذا فشلت جميع المحاولات
  
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الاستلامات',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 223, 14, 14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: purchaseNumberController,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: suppName.isNotEmpty ? suppName : 'رقم الشراء',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال رقم الشراء';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: scanQRCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 209, 2, 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: barcodeController,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: itemName.isNotEmpty ? itemName : 'أدخل الباركود',
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
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: scanBarcode,
                      child: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (itemName != 'غير متوفر') ...[
                  Row(
                    children: [
                   Expanded(
  child: TextFormField(
    controller: quantityController,
    keyboardType: const TextInputType.numberWithOptions(decimal: true), 
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), 
    ],
    decoration: InputDecoration(
      labelText: 'الكمية',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'يرجى إدخال كمية';
      }
      if (double.tryParse(value) == null || double.parse(value) < 0) {
        return 'يرجى إدخال كمية صحيحة (>=0)';
      }
      return null;
    },
  ),
),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: invoiceQuantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'كمية الفاتورة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) {
                            if (value != null && (double.tryParse(value) == null || double.parse(value) < 0)) {
                              return 'يرجى إدخال كمية فاتورة صحيحة (>=0)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: invoiceCostController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: InputDecoration(
                            labelText: 'تكلفة الفاتورة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) {
                            if (value != null && (double.tryParse(value) == null || double.parse(value) < 0)) {
                              return 'يرجى إدخال تكلفة صحيحة (>=0)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'التاريخ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () {
                            selectDate(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                if (attachedImage != null)
                  Column(
                    children: [
                      Image.file(
                        File(attachedImage!.path),
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 5),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            attachedImage = null;
                          });
                        },
                        child: const Text(
                          'إزالة الصورة',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 223, 14, 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('التقاط صورة'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (purchaseNumberController.text.isNotEmpty &&
                            (!showAdditionalFields ||
                                (quantityController.text.isNotEmpty &&
                                    dateController.text.isNotEmpty))) {
                          saveReceiptData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("يرجى تعبئة كافة الحقول المطلوبة!")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 209, 2, 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                        elevation: 6,
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(fontSize: 16),
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