import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

class returnPage extends StatefulWidget {
  final String branchNo;
  final String idNumber;
  final String branchApi;

  const returnPage({
    Key? key,
    required this.branchNo,
    required this.idNumber,
    required this.branchApi,
  }) : super(key: key);

  @override
  _returnPageState createState() => _returnPageState();
}

class _returnPageState extends State<returnPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _conversionQuantityController = TextEditingController();
  final TextEditingController _currentQuantityController = TextEditingController();
  final TextEditingController _currentprivController = TextEditingController();
final TextEditingController _suppController = TextEditingController();
final TextEditingController _itemController = TextEditingController();


  String? selectedBranch;
  Map<String, String> branches = {};
  String? errorMessage;
  String? successMessage;
  String rashed = '';
  String mayyas= '';
bool _isSaving = false; 
bool _isResetting = false; 
String? _itemNo; 
String? _suppNo; 
String? _itemName;
String? _suppName;
String? _barcodeValue; 
       String? selectedBranchFrom; 
String? selectedBranchTo;  
String? _itemEVQTY;

Future<void> _scanSuppBarcode() async {
  var result = await BarcodeScanner.scan();
  if (result.rawContent.isNotEmpty) {
    _suppController.text = result.rawContent;
    _fetchSuppDetails(result.rawContent);
  }
}

Future<void> _scanItemBarcode() async {
  var result = await BarcodeScanner.scan();
  if (result.rawContent.isNotEmpty) {
    _itemController.text = result.rawContent;
    _fetchItemDetails(result.rawContent);
  }
}

Future<void> _fetchItemDetails(String barcode) async {
  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_item_details.php?cache=${DateTime.now().millisecondsSinceEpoch}',
    'https://188.247.88.117/api_pda/fetch_item_details.php?cache=${DateTime.now().millisecondsSinceEpoch}', // رابط احتياطي
  ];

  http.Client client = http.Client(); // الاتصال العادي الافتراضي

  for (String url in urls) {
    final uri = Uri.parse(url);

    // تجاوز فحص SSL عند استخدام IP مباشر
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
          'branch_api': widget.branchApi,
          'barcode': barcode.trim(),
          'branch_no': widget.branchNo,
        },
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        if (result['status'] == 'success') {
          setState(() {
            _barcodeValue = barcode;
            _itemNo = result['data']['ITEM_NO'];
            _itemName = result['data']['ITEM_NAME'];
            _itemEVQTY = result['data']['ITEM_EV_QTY'];
          });

          // استدعاء الوظائف الإضافية
          _fetchStockBalance(_itemNo!);
          _returncheck(_itemNo!);
          _fetchStockpriv(_itemNo!);

          return; // توقف عند نجاح الطلب
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'فشل في استرجاع تفاصيل العنصر';
          });
        }
      } else {
        setState(() {
          errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() {
        errorMessage = 'حدث خطأ أثناء إرسال البيانات: $e';
      });
    }
  }

  // إذا فشلت جميع المحاولات
  setState(() {
    errorMessage = 'فشل الاتصال بالخادم أو استرجاع البيانات.';
  });
}

Future<void> _fetchSuppDetails(String suppNo) async {  
   List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_supp_details.php',
    'https://188.247.88.117/api_pda/fetch_supp_details.php', // رابط احتياطي
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
        'branch_api': widget.branchApi,  
        'supp_no': suppNo,  
      },  
    );  
  
    debugPrint('Response Status Code: ${response.statusCode}');  
    debugPrint('Response Body: ${response.body}');  
  
    if (response.statusCode == 200) {  
      final Map<String, dynamic> result = json.decode(response.body);  
  
      if (result['status'] == 'success') {  
        setState(() {  
          _barcodeValue = suppNo; 
          _suppNo = result['data']['SUPP_NO']; 
          _suppName = result['data']['SUPP_NAME']; 
          _barcodeController.text = _suppName!; 
        });  
      _fetchStockBalance(_suppNo!);
      _fetchStockpriv(_suppNo!);
        
      } else {  
        setState(() {  
          errorMessage = result['message'] ?? 'فشل في استرجاع تفاصيل المورد';  
        });  
      }  
    } else {  
      setState(() {  
        errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode}';  
      });  
    }  
  } catch (e) {  
    debugPrint('Exception: $e');  
    setState(() {  
      errorMessage = 'حدث خطأ أثناء إرسال البيانات: $e';  
    });  
  }  
}
    
}

Future<void> _returncheck(String itemNo) async {
 List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/check_return.php',
    'https://188.247.88.117/api_pda/check_return.php', // رابط احتياطي
  ];

  void showTopSnackBar(BuildContext context, String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50, // المسافة من أعلى الشاشة
        right: 16,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }

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
        'branch_api': widget.branchApi,
        'branch_no': widget.branchNo,
        'item_no': itemNo,
        'supp_no': _suppNo,
      },
    );

    debugPrint('Response Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = json.decode(response.body);

      if (result['status'] == 'success') {
        if (result['message'] == 'لا توجد مشكلة.') {
          if (mounted) {
            setState(() {
              successMessage = 'تمت العملية بنجاح: لا توجد مشكلة.';
            rashed = 'rr';
            });
            showTopSnackBar(context, 'تمت العملية بنجاح: لا توجد مشكلة.', Colors.green);
          }
        }
      } else if (result['status'] == 'error') {
        if (mounted) {
          setState(() {
            errorMessage = result['message'] ?? 'حدث خطأ';
                        rashed = 'mm';

          });

          if (result['message'] == 'مشكلة غير معرّفة على المورد.') {
            showTopSnackBar(context, 'مشكلة غير معرّفة على المورد.', Colors.red);
                                    rashed = 'mm';

          } else if (result['message'] == 'مشكلة غير معرّفة على الفرع.') {
            showTopSnackBar(context, 'مشكلة غير معرّفة على الفرع.', Colors.orange);
                                    rashed = 'mm';

          } else {
            showTopSnackBar(context, result['message'] ?? 'حدث خطأ', Colors.red);
                                    rashed = 'mm';

          }
        }
      }
    } else {
      if (mounted) {
        setState(() {
          errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode} - ${response.reasonPhrase}';
        });
        showTopSnackBar(context, 'فشل الاتصال بالخادم: ${response.statusCode}', Colors.red);
      }
    }
  } on FormatException catch (e) {
    if (mounted) {
      setState(() {
        errorMessage = 'خطأ في تنسيق البيانات المستلمة: ${e.message}';
      });
      showTopSnackBar(context, 'خطأ في تنسيق البيانات: ${e.message}', Colors.orange);
    }
  } on http.ClientException catch (e) {
    if (mounted) {
      setState(() {
        errorMessage = 'خطأ في الاتصال بالخادم: ${e.message}';
      });
      showTopSnackBar(context, 'خطأ في الاتصال بالخادم: ${e.message}', Colors.red);
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        errorMessage = 'حدث خطأ غير متوقع: $e';
      });
      showTopSnackBar(context, 'حدث خطأ غير متوقع: $e', Colors.red);
    }
  }
}
}


 Future<void> _fetchStockBalance(String itemNo) async {

     List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_stock_balance_return.php',
    'https://188.247.88.117/api_pda/fetch_stock_balance_return.php', // رابط احتياطي
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
        'branch_api': widget.branchApi,
        'branch_no': widget.branchNo,
        'item_no': itemNo,
        'store_no': '1',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = json.decode(response.body);

      if (result['status'] == 'success') {
        setState(() {
          _currentQuantityController.text = result['data']['quantity'].toString();

         
          errorMessage = ''; 
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'فشل في استرجاع الكمية الحالية';
        });
      }
    } else {
      setState(() {
        errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode} - ${response.reasonPhrase}';
      });
    }
  } on FormatException catch (e) {
    setState(() {
      errorMessage = 'خطأ في تنسيق البيانات المستلمة: ${e.message}';
    });
  } on http.ClientException catch (e) {
    setState(() {
      errorMessage = 'خطأ في الاتصال بالخادم: ${e.message}';
    });
  } catch (e) {
    setState(() {
      errorMessage = 'حدث خطأ غير متوقع: $e';
    });
  }
}}
  Future<void> _fetchStockpriv(String itemNo) async {

    List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_stock_priv.php',
    'https://188.247.88.117/api_pda/fetch_stock_priv.php', // رابط احتياطي
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
        'branch_api': widget.branchApi,
        'branch_no': widget.branchNo,
        'item_no': itemNo,
        'store_no': '1',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = json.decode(response.body);

      if (result['status'] == 'success') {
        setState(() {
            _currentprivController.text = result['data']['quantity'].toString();
          errorMessage = ''; 
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'فشل في استرجاع الكمية الحالية';
        });
      }
    } else {
      setState(() {
        errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode} - ${response.reasonPhrase}';
      });
    }
  } on FormatException catch (e) {
    setState(() {
      errorMessage = 'خطأ في تنسيق البيانات المستلمة: ${e.message}';
    });
  } on http.ClientException catch (e) {
    setState(() {
      errorMessage = 'خطأ في الاتصال بالخادم: ${e.message}';
    });
  } catch (e) {
    setState(() {
      errorMessage = 'حدث خطأ غير متوقع: $e';
    });
  }
}
}
 
Future<void> _resetFields(String itemNo) async {
    if (_isResetting) return; // إذا كان الزر محجوزًا، لا تفعل شيئًا
  _isResetting = true; // قفل الزر
  if (_formKey.currentState?.validate() ?? false) {

   List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/return_item_0.php',
    'https://188.247.88.117/api_pda/return_item_0.php', // رابط احتياطي
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
          'branch_api': widget.branchApi,
          'branch_no': widget.branchNo,
          'P_ITEM_NO': itemNo,
          'P_ITEM_BARCODE': _barcodeValue,
          'P_ITM_EQUIVELENT_QTY': _itemEVQTY,
          'P_TRANS_QTY': _conversionQuantityController.text,
          'supp_no': _suppNo,
        },
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        if (result['status'] == 'success') {
          setState(() {
            successMessage = result['message'] ?? 'تم التصفير بنجاح';
            errorMessage = null;
            // إفراغ جميع الحقول ما عدا رقم المورد
            _barcodeController.clear(); 
            _conversionQuantityController.clear(); 
            _currentQuantityController.clear();
            _currentprivController.clear();
            _itemController.clear();
            _itemNo = null;
            _itemName = null;
            _itemEVQTY = null;
            _barcodeValue = null;
               _isSaving = false; // إعادة تعيين
    _isResetting = false; // إعادة تعيين
          });
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'فشل في عملية التصفير';
          });
        }
      } else {
        setState(() {
          errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode} - ${response.reasonPhrase}';
        });
      }
    } on FormatException catch (e) {
      setState(() {
        errorMessage = 'خطأ في تنسيق البيانات المستلمة: ${e.message}';
      });
    } on http.ClientException catch (e) {
      setState(() {
        errorMessage = 'خطأ في الاتصال بالخادم: ${e.message}';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ غير متوقع: $e';
      });
    }
  }
    _isResetting = false; // فتح الزر بعد الانتهاء

}
}


Future<void> _sendTransferData(String itemNo) async {
    if (_isSaving) return; 
  _isSaving = true; 
  if (_formKey.currentState?.validate() ?? false) {

   List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/return_item.php',
    'https://188.247.88.117/api_pda/return_item.php', // رابط احتياطي
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
          'branch_api': widget.branchApi,
          'branch_no': widget.branchNo,
          'P_ITEM_NO': itemNo,
          'P_ITEM_BARCODE': _barcodeValue,
          'P_ITM_EQUIVELENT_QTY': _itemEVQTY,
          'P_TRANS_QTY': _conversionQuantityController.text,
          'supp_no': _suppNo,
        },
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        if (result['status'] == 'success') {
          setState(() {
            successMessage = result['message'] ?? 'تم  بنجاح';
            // إفراغ جميع الحقول ما عدا رقم المورد
            _barcodeController.clear(); 
            _conversionQuantityController.clear(); 
            _currentQuantityController.clear();
            _currentprivController.clear();
            _itemController.clear();
            _itemNo = null;
            _itemName = null;
            _itemEVQTY = null;
            _barcodeValue = null;
               _isSaving = false; // إعادة تعيين
    _isResetting = false; // إعادة تعيين
          });
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'فشل في عملية الارجاع';
          });
        }
      } else {
        setState(() {
          errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode} - ${response.reasonPhrase}';
        });
      }
    } on FormatException catch (e) {
      setState(() {
        errorMessage = 'خطأ في تنسيق البيانات المستلمة: ${e.message}';
      });
    } on http.ClientException catch (e) {
      setState(() {
        errorMessage = 'خطأ في الاتصال بالخادم: ${e.message}';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ غير متوقع: $e';
      });
    }
  }
    _isSaving = false;

}
}
  @override
  void initState() {
    super.initState();
  
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '  ارجاع',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 223, 14, 14),
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
 Row(
  children: [
    Expanded(
      child: TextFormField(
        controller: _suppController,
  style: const TextStyle(
       fontSize: 18, 
 
    fontWeight: FontWeight.bold, // جعل الخط بولد غامق
  ),        decoration: InputDecoration(
          labelText: _suppName ?? 'رقم المورد',
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى إدخال رقم المورد';
          }
          return null;
        },
        onFieldSubmitted: (value) {
          if (value.isNotEmpty) {
            _fetchSuppDetails(value);
          }
        },
        onChanged: (value) {
          if (value.isNotEmpty) {
            _fetchSuppDetails(value);
          }
        },
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        readOnly: _suppName != null,
      ),
    ),
    const SizedBox(width: 10),
    ElevatedButton(
      onPressed: _scanSuppBarcode,
      child: const Icon(Icons.qr_code_scanner),
    ),
  ],
),
const SizedBox(height: 20),

Row(
  children: [
    Expanded(
      child: TextFormField(
        controller: _itemController,
  style: const TextStyle(
       fontSize: 18, 
 
    fontWeight: FontWeight.bold, 
  ),        decoration: InputDecoration(
          labelText: _itemName ?? 'أدخل الباركود',
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى إدخال الباركود';
          }
          return null;
        },
        onFieldSubmitted: (value) {
          if (value.isNotEmpty) {
            _fetchItemDetails(value);
          }
        },
        onChanged: (value) {
          if (value.isNotEmpty) {
            _fetchItemDetails(value);
          }
        },
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        readOnly:  false,
      ),
    ),
    const SizedBox(width: 10),
    ElevatedButton(
      onPressed: _scanItemBarcode,
      child: const Icon(Icons.qr_code_scanner),
    ),
  ],
),
const SizedBox(height: 20),

               if (rashed == 'rr') ...[
      TextFormField(
        controller: _conversionQuantityController,
        decoration: const InputDecoration(
          labelText: 'الكمية المرتجعة',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى إدخال القيمة';
          }

          // Convert input values to numbers and compare
          double returnedQuantity = double.tryParse(value) ?? 0;
          double currentQuantity = double.tryParse(_currentQuantityController.text) ?? 0;

          if (returnedQuantity > currentQuantity) {
            return 'الكمية المرتجعة تتجاوز الكمية الحالية';
          }
          if (currentQuantity < 0) {
            return 'كمية التحويل لا يمكن أن تكون أقل من 0';
          }
          return null;
        },
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 20),
            TextFormField(
        controller: _currentprivController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'الكمية المحجوزة',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 20),
   
      TextFormField(
        controller: _currentQuantityController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'الكمية الحالية',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 20),
    ],
    if (errorMessage != null)
      Text(
        errorMessage!,
        style: const TextStyle(color: Colors.red),
      ),
    if (successMessage != null)
      Text(
        successMessage!,
        style: const TextStyle(color: Colors.green),
      ),

      
    const Spacer(),
Row(
  children: [
    Expanded(
      child: ElevatedButton(
        onPressed: _isSaving ? null : () {
          if (_itemNo != null && _itemNo!.isNotEmpty) {
            _sendTransferData(_itemNo!); 
          } else {
            setState(() {
              errorMessage = 'لم يتم تحميل رقم الصنف بعد. الرجاء مسح الباركود أولاً.';
            });
          }
        },
        child: const Text('حفظ'),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: ElevatedButton(
        onPressed: _isResetting ? null : () {
          if (_itemNo != null && _itemNo!.isNotEmpty) {
            _resetFields(_itemNo!); 
          } else {
            setState(() {
              errorMessage = 'لم يتم تحميل رقم الصنف بعد. الرجاء مسح الباركود أولاً.';
            });
          }
        },
        child: const Text('تصفير'),
      ),
    ),
  ],
),  
 ],
)          ),
        ),
      ),
    );
  }
}
