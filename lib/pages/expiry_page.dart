import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;

class expiryPage extends StatefulWidget {
  final String branchNo;
  final String idNumber;
  final String branchApi;

  const expiryPage({
    Key? key,
    required this.branchNo,
    required this.idNumber,
    required this.branchApi,
  }) : super(key: key);

  @override
  _expiryPageState createState() => _expiryPageState();
}

class _expiryPageState extends State<expiryPage> {
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
bool _isSaving = false; 
bool _isResetting = false;
       String? selectedBranchFrom; 
String? selectedBranchTo;  
  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.rawContent.isNotEmpty) {
      _barcodeController.text = result.rawContent;
      _fetchItemDetails(result.rawContent); 
    }
  }Future<void> _fetchItemDetails(String barcode) async {  
  final url = Uri.parse('https://swipup.samehgroup.com/api_pda/fetch_item_details_exp.php?cache=${DateTime.now().millisecondsSinceEpoch}');  
  
  try {  
    final response = await http.post(  
      url,  
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
        _fetchStockBalance(_itemNo!); 
        _fetchStockpriv(_itemNo!); 
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
}

 Future<void> _fetchStockBalance(String itemNo) async {
  final url = Uri.parse('https://swipup.samehgroup.com/api_pda/fetch_stock_balance_exp.php');

  try {
    final response = await http.post(
      url,
      body: {
        'branch_api': widget.branchApi,
        'branch_no': widget.branchNo,
        'item_no': itemNo,
        'store_no': '2',
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
}
   Future<void> _fetchStockpriv(String itemNo) async {
  final url = Uri.parse('https://swipup.samehgroup.com/api_pda/fetch_stock_priv.php');

  try {
    final response = await http.post(
      url,
      body: {
        'branch_api': widget.branchApi,
        'branch_no': widget.branchNo,
        'item_no': itemNo,
        'store_no': '2',
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
Future<void> _resetFields(String itemNo) async {
  if (_isResetting) return; // إذا كان الزر محجوزًا، لا تفعل شيئًا
  _isResetting = true; // قفل الزر

  if (_formKey.currentState?.validate() ?? false) {
    final url = Uri.parse('https://swipup.samehgroup.com/api_pda/exp_item_0.php');

    try {
      final response = await http.post(
        url,
        body: {
          'branch_api': widget.branchApi,
          'branch_no': widget.branchNo,
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
          });

          // بعد تصفير البيانات، تفريغ الحقول
          _clearFields();
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

  _isResetting = false; 
}

void _clearFields() {
  _barcodeController.clear();
  _conversionQuantityController.clear();
  _currentQuantityController.clear();
  _currentprivController.clear();
  setState(() {
    _itemNo = null;
    _itemName = null;
    _barcodeValue = null;
    _itemEVQTY = null;
      _isSaving = false; 
    _isResetting = false;
    
  });
}


 Future<void> _sendTransferData(String itemNo) async {
  if (_isSaving) return; 
  _isSaving = true; 

  if (_formKey.currentState?.validate() ?? false) {
    final url = Uri.parse('https://swipup.samehgroup.com/api_pda/exp_item.php');

    try {
      final response = await http.post(
        url,
        body: {
          'branch_api': widget.branchApi,
          'branch_no': widget.branchNo,
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
          });

          // بعد حفظ البيانات، تفريغ الحقول
          _clearFields();
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
            '  التوالف',
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
    onFieldSubmitted: (value) {
      if (value.isNotEmpty) {
        _fetchItemDetails(value);
      }
    },
    onChanged: (value) {
      if (value.isNotEmpty ) {
        _fetchItemDetails(value);
      }
    },
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    readOnly: false, 
  ),
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
                              keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: 'الكمية التالفة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال القيمة';
    }
    final enteredQuantity = double.tryParse(value);
    final currentQuantity = double.tryParse(_currentQuantityController.text);
    


    if (enteredQuantity == null) {
      return 'يرجى إدخال قيمة رقمية صحيحة';
    }
  

    if (currentQuantity != null && enteredQuantity > currentQuantity) {
      return 'الكمية التالفة لا يمكن أن تتجاوز الكمية الحالية';
    }
    if (currentQuantity != null && currentQuantity < 0) {
      return 'كمية التحويل لا يمكن أن تكون أقل من 0';
    }
    return null;
  },
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
                    labelText: ' الكمية الحالية',
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
), ],
            ),
          ),
        ),
      ),
    );
  }
}
