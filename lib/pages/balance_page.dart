import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

class BalancePage extends StatefulWidget {
  final String branchNo;
  final String idNumber;
  final String branchApi;

  const BalancePage({
    Key? key,
    required this.branchNo,
    required this.idNumber,
    required this.branchApi,
  }) : super(key: key);

  @override
  _BalancePageState createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();  
  final TextEditingController _itemnoController = TextEditingController();  
  List<Map<String, String>> _items = [];
  bool _isLoading = false;

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.rawContent.isNotEmpty) {
      _barcodeController.text = result.rawContent;
      _fetchItemDetails(result.rawContent);
    }
  }

  Future<void> _fetchItemDetails(String barcode) async {
    setState(() => _isLoading = true);
    List<String> urls = [
      'https://swipup.samehgroup.com/api_pda/fetch_item_details_bal.php',
      'https://188.247.88.117/api_pda/fetch_item_details_bal.php',
    ];

    http.Client client = http.Client();
    for (String url in urls) {
      try {
        final uri = Uri.parse(url);
        if (uri.host == '188.247.88.117') {
          HttpClient httpClient = HttpClient()
            ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          client = IOClient(httpClient);
        }

        final response = await client.post(uri, body: {
          'branch_api': widget.branchApi,
          'barcode': barcode.trim(),
          'branchNo': widget.branchNo,
        });

        print('Sending Data: branch_api=${widget.branchApi}, barcode=$barcode, branchNo=${widget.branchNo}'); 

        if (response.statusCode == 200) {
          print('API Response: ${response.body}'); 

          final Map<String, dynamic> result = json.decode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              _items.clear(); 
              for (var itemData in result['data']) {
                _items.add({
                  'itemNo': itemData['item_no'],
                  'barcode': itemData['ITEM_BARCODE'],
                  'itemName': itemData['ITEM_NAME'],
                  'itemEVQTY': itemData['ITEM_BALANCE'],
                  'ITEM_SIZE': itemData['ITEM_SIZE'],
                  'BRANCH_NAME': itemData['BRANCH_NAME'],
                });
                _itemNameController.text = itemData['ITEM_NAME'];  
                _itemnoController.text = itemData['item_no'];  
              }
              _isLoading = false;
            });
            break;
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
    client.close();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رصيد المخزون', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color.fromARGB(255, 223, 14, 14),
        ),
        body: SingleChildScrollView(  // تم إضافة هذا السطر لتمكين التمرير
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'أدخل الباركود',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _fetchItemDetails(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _scanBarcode,
                    child: const Icon(Icons.qr_code_scanner),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: 'اسم الصنف',
                  border: const OutlineInputBorder(),
                ),
                enabled: false, 
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _itemnoController,
                decoration: InputDecoration(
                  labelText: 'رقم الصنف',
                  border: const OutlineInputBorder(),
                ),
                enabled: false, 
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : _items.isNotEmpty
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 56,
                            dataRowHeight: 56,
                            border: TableBorder.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'الفرع',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 223, 14, 14)),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'الباركود',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 223, 14, 14)),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'الحجم',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 223, 14, 14)),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'الكمية',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 223, 14, 14)),
                                ),
                              ),
                            ],
                            rows: _items.map((item) {
                              return DataRow(cells: [
                                DataCell(Text(item['BRANCH_NAME']!)),
                                DataCell(Text(item['barcode']!)),
                                DataCell(Text(item['ITEM_SIZE']!)),
                                DataCell(Text(item['itemEVQTY']!)),
                              ]);
                            }).toList(),
                          ),
                        )
                      : Center(child: Text('لا توجد بيانات لعرضها')),
            ],
          ),
        ),
      ),
    );
  }
}
