import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pda_v1/pages/main_page.dart';
import 'package:pda_v1/themes/text_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/io_client.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LoginPage(),
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txtEmail = TextEditingController();
  final TextEditingController _txtPassword = TextEditingController();
  final FocusNode _fnEmail = FocusNode();
  final FocusNode _fnPassword = FocusNode();

  bool _obsecureText = true;
  bool _isLoading = false;
  String _selectedBranchApi = '';
  List<Map<String, String>> branches = [];

  @override
  void dispose() {
    _txtEmail.dispose();
    _txtPassword.dispose();
    _fnEmail.dispose();
    _fnPassword.dispose();
    super.dispose();
  }


Future<void> fetchBranches() async {
  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/branches.php',
    'https://188.247.88.117/api_pda/branches.php',
  ];

  http.Client client = http.Client(); 

  for (String url in urls) {
    final uri = Uri.parse(url);

    if (uri.host == '188.247.88.117') {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      client = IOClient(httpClient);
    }

    try {
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          branches = responseData.map((branch) {
            return {
              'branch_id': branch['branch_id'].toString(),
              'branch_name': branch['branch_name'].toString(),
              'branch_api': branch['branch_api'].toString(),
            };
          }).toList();
        });

        return; 
      } else {
        print('فشل في تحميل الفروع من $url');
      }
    } catch (e) {
      print('فشل الاتصال بـ $url: $e');
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('فشل الاتصال بالإنترنت')),
  );
}Future<void> loginUser() async {
  if (_selectedBranchApi.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يرجى اختيار الفرع')),
    );
    return;
  }

  List<String> urls = [
    'https://swipup.samehgroup.com/api_pda/login.php',
    'https://188.247.88.117/api_pda/login.php',
  ];

  setState(() => _isLoading = true);

  http.Client client = http.Client(); 

  for (String url in urls) {
    final uri = Uri.parse(url);

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
          'id_number': _txtEmail.text,
          'pin_code': _txtPassword.text,
          'branch_api': _selectedBranchApi,
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        String branchNo = responseData['branch_no'] ?? '';
        String branchNa = responseData['branch_na'] ?? '';
        String appid = responseData['app_id'] ?? '';
        String INV_PATH = responseData['INV_PATH'] ?? ''; 
        String TRANS_PATH = responseData['TRANS_PATH'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('idNumber', _txtEmail.text);
        await prefs.setString('branchNo', branchNo);
        await prefs.setString('branchNa', branchNa);
        await prefs.setString('branchApi', _selectedBranchApi);
        await prefs.setString('appid', appid);
        await prefs.setString('INV_PATH', INV_PATH);
        await prefs.setString('TRANS_PATH', TRANS_PATH);

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => MainPage(
            idNumber: _txtEmail.text,
            branchNo: branchNo,
            branchNa: branchNa,
            branchApi: _selectedBranchApi,
            appid: appid,
            INV_PATH: INV_PATH,
            TRANS_PATH: TRANS_PATH,
          ),
        ));

        return; 
      } else {
        print('فشل تسجيل الدخول عبر $url');
      }
    } catch (e) {
      print('فشل الاتصال بـ $url: $e');
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('فشل الاتصال بالإنترنت')),
  );

  setState(() => _isLoading = false);
}
  @override
  void initState() {
    super.initState();
    fetchBranches();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    String? idNumber = prefs.getString('idNumber');
    if (idNumber != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(
            idNumber: idNumber,
            branchNo: prefs.getString('branchNo') ?? '',
            branchNa: prefs.getString('branchNa') ?? '',
            branchApi: prefs.getString('branchApi') ?? '',
            appid: prefs.getString('appid') ?? '',
            INV_PATH: prefs.getString('INV_PATH') ?? '',
            TRANS_PATH: prefs.getString('TRANS_PATH') ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 38.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', height: 150.0),
                      const SizedBox(width: 10.0),
                    ],
                  ),
                  const SizedBox(height: 98.0),
                  const Text(
                    'مرحبا سجل دخولك',
                    style: MyTextTheme.welcomeStyle,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12.0),

                  TextFormField(
                    decoration: const InputDecoration(labelText: 'رقم المستخدم'),
                    textAlign: TextAlign.right,
                    controller: _txtEmail,
                    focusNode: _fnEmail,
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'يجب إدخال رقم المستخدم';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) => FocusScope.of(context).requestFocus(_fnPassword),
                  ),

                  const SizedBox(height: 8.0),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'الرقم السري',
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            _obsecureText = !_obsecureText;
                          });
                        },
                        icon: _obsecureText
                            ? const Icon(Icons.visibility_off_rounded)
                            : const Icon(Icons.visibility_rounded),
                      ),
                    ),
                    textAlign: TextAlign.right,
                    obscureText: _obsecureText,
                    controller: _txtPassword,
                    focusNode: _fnPassword,
                    textDirection: TextDirection.rtl,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'يجب إدخال الرقم السري';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) => FocusScope.of(context).unfocus(),
                  ),

                  const SizedBox(height: 42),
                  DropdownButtonFormField<String>(
                    value: _selectedBranchApi.isEmpty ? null : _selectedBranchApi,
                    hint: const Text('اختر الفرع'),
                    items: branches.map((branch) {
                      return DropdownMenuItem<String>(
                        value: branch['branch_api'],
                        child: Text(branch['branch_name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBranchApi = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب اختيار فرع';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              loginUser();
                            }
                          },
                          child: const Text('دخول'),
                        ),
                  const SizedBox(height: 46),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
