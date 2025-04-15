import 'package:flutter/material.dart';
import 'package:pda_v1/pages/balance_page.dart';
import 'package:pda_v1/pages/login_page.dart';
import 'inventory_page.dart'; 
import 'receipts_page.dart'; 
import 'transfer_branches_page.dart'; 
import 'expiry_page.dart'; 
import 'return_page.dart'; 
import 'transfer_store_page.dart'; 
import 'pricing_page.dart'; 
import 'package:shared_preferences/shared_preferences.dart';


class MainPage extends StatefulWidget {
  final String idNumber;
  final String branchNo;
  final String branchNa;
  final String branchApi;
  final String appid;
  final String INV_PATH;
  final String TRANS_PATH;

  const MainPage({
    Key? key,
    required this.idNumber,
    required this.branchNo,
    required this.branchNa,
    required this.branchApi, 
    required this.appid, 
    required this.INV_PATH,
    required this.TRANS_PATH,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  void _navigateToFeature(String featureName) {
    if (featureName == 'الجرد') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryPage(branchNo: widget.branchNo,branchApi: widget.branchApi),
        ),
      );
    }
    else if  (featureName == 'التسعير') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PricingPage(branchNo: widget.branchNo,idNumber: widget.idNumber,branchApi: widget.branchApi),
        ),
      );
    }
     else if  (featureName == 'الأستلام') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptsPage(branchNo: widget.branchNo,idNumber: widget.idNumber,branchApi: widget.branchApi,INV_PATH: widget.INV_PATH),
        ),
      );
    }    else if  (featureName == 'تحويل فروع') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TranbranchesPage(branchNo: widget.branchNo,idNumber: widget.idNumber,branchApi: widget.branchApi,TRANS_PATH: widget.TRANS_PATH),
        ),
      );
      
    }    else if  (featureName == 'تحويل مستودعات') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TranstorePage(branchNo: widget.branchNo,idNumber: widget.idNumber,branchApi: widget.branchApi,TRANS_PATH: widget.TRANS_PATH),
        ),
      );
    }
      else if  (featureName == 'التوالف') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => expiryPage(branchNo: widget.branchNo,idNumber: widget.idNumber,branchApi: widget.branchApi),
        ),
      );
    } else if  (featureName == 'المرتجع') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => returnPage(branchNo: widget.branchNo,idNumber: widget.idNumber,branchApi: widget.branchApi),
        ),
      );
    }
    else if  (featureName == 'رصيد المخزون') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BalancePage(branchNo: widget.branchNo,idNumber: widget.idNumber,branchApi: widget.branchApi),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$featureName قيد التطوير'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ' ${widget.branchNa}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: const Color.fromARGB(255, 223, 14, 14),
        actions: [
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  },
),

        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0, 
            mainAxisSpacing: 16.0, 
          ),
          itemCount: _buildFeatureTiles().length,
          itemBuilder: (context, index) {
            return _buildFeatureTiles()[index];
          },
        ),
      ),
    );
  }
  List<Widget> _buildFeatureTiles() {
  List<Widget> tiles = [];

  if (widget.appid == '1') {
    bool shouldHideFeatures = widget.branchApi == '192.168.0.35:1521/Orcl2';

    if (!shouldHideFeatures) {
      tiles.add(_buildFeatureTile(
        icon: Icons.inventory,
        title: 'الأستلام',
        subtitle: '  ',
        onTap: () => _navigateToFeature('الأستلام'),
      ));
      tiles.add(_buildFeatureTile(
        icon: Icons.settings,
        title: 'توالف',
        subtitle: ' ',
        onTap: () => _navigateToFeature('التوالف'),
      ));
     
      tiles.add(_buildFeatureTile(
        icon: Icons.storage,
        title: 'تحويل المستودعات',
        subtitle: '',
        onTap: () => _navigateToFeature('تحويل مستودعات'),
      ));
      tiles.add(_buildFeatureTile(
        icon: Icons.assignment_return,
        title: 'مرتجع',
        subtitle: '   ',
        onTap: () => _navigateToFeature('المرتجع'),
      ));
    }

     tiles.add(_buildFeatureTile(
        icon: Icons.transfer_within_a_station,
        title: 'تحويل بين الفروع',
        subtitle: '',
        onTap: () => _navigateToFeature('تحويل فروع'),
      ));
    tiles.add(_buildFeatureTile(
      icon: Icons.inventory,
      title: 'الجرد',
      subtitle: '  ',
      onTap: () => _navigateToFeature('الجرد'),
    ));

    if (shouldHideFeatures) {
      tiles.add(_buildFeatureTile(
        icon: Icons.account_balance_wallet,
        title: 'رصيد المخزون',
        subtitle: '',
        onTap: () => _navigateToFeature('رصيد المخزون'),
      ));
    }
  }

  if (widget.appid == '2') {
    tiles.add(_buildFeatureTile(
      icon: Icons.price_change,
      title: 'التسعير',
      subtitle: '  ',
      onTap: () => _navigateToFeature('التسعير'),
    ));
  }

  return tiles;
}


  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10.0,
              spreadRadius: 3.0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 251, 187, 187),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
