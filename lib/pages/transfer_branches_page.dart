import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

class TranbranchesPage extends StatefulWidget {
  final String branchNo;
  final String idNumber;
  final String branchApi;
  final String TRANS_PATH;   
  const TranbranchesPage({
    Key? key,
    required this.branchNo,
    required this.idNumber,
    required this.branchApi,
    required this.TRANS_PATH,

  }) : super(key: key);

  @override
  _TranbranchesPageState createState() => _TranbranchesPageState();
}

class _TranbranchesPageState extends State<TranbranchesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _conversionQuantityController = TextEditingController();
  final TextEditingController _currentQuantityController = TextEditingController();
  final TextEditingController _currentprivController = TextEditingController();

  String? selectedBranch;
  Map<String, String> branches = {};
  String? errorMessage;
  String? successMessage;
String? _itemNo; 
String? _itemName;
String? _barcodeValue; 
String? _itemEVQTY;
bool _isSaving = false; // إضافة هذا المتغير
bool _isResetting = false; // إضافة هذا المتغير

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.rawContent.isNotEmpty) {
      _barcodeController.text = result.rawContent;
      _fetchItemDetails(result.rawContent); // Fetch item details based on the barcode
    }
  }

  Future<void> _fetchBranches() async {
  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_branch.php',
    'https://188.247.88.117/api_pda/fetch_branch.php', // رابط احتياطي
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
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');  

      if (response.statusCode == 200) {
        try {
          if (response.body.isNotEmpty) {
            final Map<String, dynamic> result = json.decode(response.body);

            if (result.containsKey('status')) {
              if (result['status'] == 'success') {
                setState(() {
                  branches = {
                    for (var branch in result['data'])
                      branch['BRANCH_NO']: branch['BRANCH_NAME']
                  };
                  errorMessage = ''; 
                });
              } else if (result['status'] == 'error') {
                setState(() {
                  errorMessage = result['message'] ?? 'فشل في استرجاع البيانات';
                });
              }
            } else {
              setState(() {
                errorMessage = 'الاستجابة من الخادم غير صالحة';
              });
            }
          } else {
            setState(() {
              errorMessage = 'الاستجابة فارغة من الخادم';
            });
          }
        } catch (e) {
          print('Error parsing JSON: $e');
          setState(() {
            errorMessage = 'حدث خطأ أثناء تحليل البيانات: $e';
          });
        }
      } else {
        setState(() {
          errorMessage = 'فشل الاتصال بالخادم: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        errorMessage = 'حدث خطأ أثناء إرسال البيانات: $e';
      });
    }
  }}
  Future<void> _fetchItemDetails(String barcode) async {  
  
  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_item_details.php?cache=${DateTime.now().millisecondsSinceEpoch}',
    'https://188.247.88.117/api_pda/fetch_item_details.php?cache=${DateTime.now().millisecondsSinceEpoch}', // رابط احتياطي
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
          'barcode': barcode.trim(),
      },  
    );  
  
    debugPrint('Response Status Code: ${response.statusCode}');  
    debugPrint('Response Body: ${response.body}');  
  
    if (response.statusCode == 200) {  
      final Map<String, dynamic> result = json.decode(response.body);  
  
      if (result['status'] == 'success') {  
        setState(() {  
          _barcodeValue = barcode; // حفظ قيمة الباركود  
          _itemNo = result['data']['ITEM_NO']; // تخزين ITEM_NO  
          _itemName = result['data']['ITEM_NAME']; // تخزين ITEM_NAME  
                    _itemEVQTY = result['data']['ITEM_EV_QTY']; 

        });  
        _fetchStockBalance(_itemNo!); // جلب المخزون بناءً على ITEM_NO  
        _fetchStockpriv(_itemNo!);
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
}}

 Future<void> _fetchStockBalance(String itemNo) async {


  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/fetch_stock_balance.php',
    'https://188.247.88.117/api_pda/fetch_stock_balance.php', // رابط احتياطي
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
        'store_no': '0001',
                'typ': '4',

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
        'store_no': '4',
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
}}
 
Future<void> _resetFields(String itemNo) async {
    if (_isSaving) return; // إذا كان الزر محجوزًا، لا تفعل شيئًا
  _isSaving = true; // قفل الزر
  if (_formKey.currentState?.validate() ?? false) {

 
    List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/transfer_item_0.php',
    'https://188.247.88.117/api_pda/transfer_item_0.php', // رابط احتياطي
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
          'P_FROM_BRANCH_NO': widget.branchNo,
          'P_TO_BRANCH_NO': selectedBranch,
          'P_ITEM_NO': itemNo,
          'P_ITEM_BARCODE': _barcodeValue,
          'P_ITM_EQUIVELENT_QTY': _itemEVQTY,
          'P_TRANS_QTY': _conversionQuantityController.text,
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

            // إفراغ الحقول ما عدا الفرع
            _barcodeController.clear();
            _conversionQuantityController.clear();
            _currentQuantityController.clear();
            _currentprivController.clear();
            _itemNo = null;
            _itemName = null;
            _barcodeValue = null;
            _itemEVQTY = null;
                _isSaving = false; // إعادة تعيين
    _isResetting = false; 
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

}}

Future<void> _sendTransferData(String itemNo) async {
    if (_isSaving) return; // إذا كان الزر محجوزًا، لا تفعل شيئًا
  _isSaving = true; // قفل الزر
  if (_formKey.currentState?.validate() ?? false) {
 
     List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/transfer_item.php',
    'https://188.247.88.117/api_pda/transfer_item.php', // رابط احتياطي
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
          'P_FROM_BRANCH_NO': widget.branchNo,
          'P_TO_BRANCH_NO': selectedBranch,
          'P_ITEM_NO': itemNo,
          'P_ITEM_BARCODE': _barcodeValue,
          'P_ITM_EQUIVELENT_QTY': _itemEVQTY,
          'P_TRANS_QTY': _conversionQuantityController.text,
        },
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
    

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        if (result['status'] == 'success') {
          setState(() {
            successMessage = result['message'] ?? 'تم التحويل بنجاح';
            errorMessage = null;

            // إفراغ الحقول ما عدا الفرع
            _barcodeController.clear();
            _conversionQuantityController.clear();
            _currentQuantityController.clear();
            _currentprivController.clear();
            _itemNo = null;
            _itemName = null;
            _barcodeValue = null;
            _itemEVQTY = null;
                        _isSaving = false; // إعادة تعيين
    _isResetting = false; 
          });
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'فشل في عملية التحويل';
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
    _isSaving = false; // فتح الزر بعد الانتهاء

}}


 @override
  void initState() {
    super.initState();
    _fetchBranches(); 
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التحويل بين الفروع',
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
                DropdownButtonFormField<String>(
                  value: selectedBranch,
                  items: branches.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBranch = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'اختر الفرع',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null ? 'يرجى اختيار الفرع' : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                  Expanded(
  child: TextFormField(
    controller: _barcodeController,
      style: const TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold, 
  ),  
    decoration: InputDecoration(
      labelText: _itemName ?? 'أدخل الباركود', 
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'يرجى إدخال الباركود';
      }
      return null;
    },

    onChanged: (value) {
      if (value.isNotEmpty ) {
        _fetchItemDetails(value);
      }
    },
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
readOnly: false,   ),
),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _scanBarcode,
                      child: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _conversionQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'كمية التحويل',
                    border: OutlineInputBorder(),
                  ),
               validator: (value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال القيمة';
    }
    final double? conversionQuantity = double.tryParse(value);
    final double? currentQuantity = double.tryParse(_currentQuantityController.text);

    if (conversionQuantity == null) {
      return 'الرجاء إدخال قيمة صحيحة';
    }

    if (currentQuantity == null) {
      return 'الكمية الحالية غير متوفرة';
    }
    if (conversionQuantity < 0) {
      return 'كمية التحويل لا يمكن أن تكون أقل من 0';
    }
    if (conversionQuantity > currentQuantity) {
      return 'كمية التحويل لا يمكن أن تتجاوز الكمية الحالية';
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
),   ],
            ),
          ),
        ),
      ),
    );
  }
}
