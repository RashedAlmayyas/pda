import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

class PricingPage extends StatefulWidget {
  final String branchNo;
  final String idNumber;
  final String branchApi;

  const PricingPage({Key? key, required this.branchNo, required this.idNumber, required this.branchApi}) : super(key: key);

  @override
  _PricingPageState createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool isFetchingData = false; // تعريف المتغير هنا
  String? itemPrice;
  String? normalRemark;
  String? mixRemark;
  String? setRemark;
  String? offerFromDate;
  String? offerToDate;
  String? errorMessage;
  String? printerStatusMessage;
  String? itemname;
  bool isPrinting = false;  // متغير لحماية من الطباعة المتكررة
    bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    try {
      final List<BluetoothDevice> pairedDevices = await printer.getBondedDevices();
      setState(() {
        devices = pairedDevices;
      });
    } catch (e) {
      print('Error fetching devices: $e');
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await printer.connect(device);
      setState(() {
        selectedDevice = device;
      });
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }
  void printSample() async {
String formatted = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());

  double? price = double.tryParse(itemPrice ?? '');
  String formattedPrice = price != null ? price.toStringAsFixed(2) : 'N/A';
String zplCommand = '''
^XA
^CWZ,E:TT0003M_.FNT^FS
^MMT
^BY2,1,75
^FO260,160^BC^FD${_barcodeController.text}^FS  // الباركود في الوسط
^CI28
^FO460,30^CI28^AZN,30,30^TBN,250,250^FD${utf8.decode(utf8.encode("$itemname"))}^FS
^FO150,230^CI28^AZN,25,25^FDالتاريخ: $formatted^FS"
^PA1,1,1,1^FS
^FO360,110^CI28^AZN,50,50^FB500,1,0,C^FD$formattedPrice JD^FS  // السعر في المنتصف مع تنسيق رقمي
^PA1,1,1,1^FS
^PQ1
^XZ
''';


  printer.write(zplCommand);
}

  Future<void> _fetchPricingData(String barcode) async {
    setState(() {
      itemPrice = null;
      normalRemark = null;
      mixRemark = null;
      setRemark = null;
      offerFromDate = null;
      offerToDate = null;
      errorMessage = null;
      itemname = null;
    });

    List<String> urls = [
      'https://swipup.samehgroup.com/api_pda/fetch_pricing.php',
      'https://188.247.88.117/api_pda/fetch_pricing.php',
    ];

    http.Client client = http.Client();

    for (String url in urls) {
      final uri = Uri.parse(url);

      if (uri.host == '188.247.88.117') {
        HttpClient httpClient = HttpClient()
          ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        client = IOClient(httpClient);
      }

      try {
        final response = await client.post(
          uri,
          body: {
            'itemBarcode': barcode,
            'branchNo': widget.branchNo,
            'branch_api': widget.branchApi,
          },
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['status'] == 'success') {
            setState(() {
              itemPrice = responseBody['sellPrice'];
              normalRemark = responseBody['normalRemarkA'];
              mixRemark = responseBody['mixRemarkA'];
              setRemark = responseBody['setRemarkA'];
              offerFromDate = responseBody['offerFromDate'];
              offerToDate = responseBody['offerToDate'];
              itemname = responseBody['itemname'];
            });
            return;
          } else {
            setState(() {
              errorMessage = responseBody['message'];
            });
          }
        } else {
          print('فشل في جلب بيانات السعر من $url');
        }
      } catch (e) {
        print('فشل الاتصال بـ $url: $e');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الصنف غير معرف')));

    setState(() {
    });
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.rawContent.isNotEmpty) {
      _barcodeController.text = result.rawContent;
      _fetchPricingData(result.rawContent);
    }
  }
  Future<void> _saveAndPrintPricingData() async {
  // التأكد من أنه لا توجد عمليات جارية بالفعل
  if (isProcessing) {
    return; // إذا كانت هناك عملية جارية بالفعل، لا تقم بالاستمرار
  }

  final barcode = _barcodeController.text;
  final oldPrice = _oldPriceController.text;

  if (barcode.isEmpty || oldPrice.isEmpty) {
    setState(() {
      errorMessage = 'يرجى إدخال جميع البيانات';
    });
    return;
  }

  setState(() {
    errorMessage = null;  // إعادة تعيين الرسالة السابقة
    isPrinting = false;
    isProcessing = true;  // تعيين المتغير isProcessing ليكون true لأن العملية جارية
  });

  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/save_pricing.php',
    'https://188.247.88.117/api_pda/save_pricing.php',
  ];

  http.Client client = http.Client();

  for (String url in urls) {
    final uri = Uri.parse(url);

    if (uri.host == '188.247.88.117') {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      client = IOClient(httpClient);
    }

    try {
      final response = await client.post(
        uri,
        body: {
          'branchNo': widget.branchNo,
          'itemBarcode': barcode,
          'oldItemPrice': oldPrice,
          'creationBy': widget.idNumber,
          'printFlag': 'T',
          'branch_api': widget.branchApi,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          setState(() {
            errorMessage = 'تم حفظ البيانات بنجاح!';
                         _fetchPricingData(barcode);
            

          });

          // التأكد من أنه سيتم جلب البيانات فقط مرة واحدة
          

          // تأكد من أن البيانات متاحة للطباعة
          
        } else {
          setState(() {
            errorMessage = responseBody['message'];
            isPrinting = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم الحفظ')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الاتصال')));
    }
  }

  // تعيين المتغير isProcessing ليكون false بعد إتمام العملية
  setState(() {
    isProcessing = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التسعير'),
          backgroundColor: const Color.fromARGB(255, 230, 18, 18),
          actions: <Widget>[
           DropdownButton<BluetoothDevice>(
  hint: Icon(Icons.print, color: Colors.white),
  value: selectedDevice,
  onChanged: (BluetoothDevice? device) {
    connectToDevice(device!);
  },
  items: devices
      .map((device) => DropdownMenuItem(
            value: device,
            child: Text(device.name ?? ''),
          ))
      .toList(),
  dropdownColor: const Color.fromARGB(255, 255, 255, 255), 
  iconEnabledColor: Colors.white, 
),

          ],
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
                decoration: InputDecoration(
                  labelText: 'رمز الباركود',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, 
                ],
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'يرجى إدخال رمز الباركود';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _scanBarcode, 
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ],

        if (printerStatusMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            printerStatusMessage!,
            style: TextStyle(color: Colors.blue),
          ),
        ],

        if (itemPrice != null) ...[
          const SizedBox(height: 16),
          Text('الصنف : $itemname'),
          Text('السعر الحالي: $itemPrice'),
          Text('ملاحظات عامة: $normalRemark'),
          Text('ملاحظات خليط: $mixRemark'),
          Text('ملاحظات مجموعة: $setRemark'),
          Text('تاريخ العرض: $offerFromDate - $offerToDate'),
        ],
        const SizedBox(height: 16),

        TextFormField(
          controller: _oldPriceController,
          decoration: InputDecoration(
            labelText: 'السعر القديم',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال السعر القديم';
            }
            if (double.tryParse(value) == null) {
              return 'الرجاء إدخال رقم صالح';
            }
            return null;
          },
        ),
  
         const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveAndPrintPricingData,
                        style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 209, 2, 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          elevation: 6,
                        ),
                        child: const Text(
                          'عرض',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: printSample,
                        style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 209, 2, 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          elevation: 6,
                        ),
                        child: const Text(
                          ' طباعة',
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
