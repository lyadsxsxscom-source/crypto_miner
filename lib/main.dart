import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const AdvancedCryptoMinerApp());
}

class AdvancedCryptoMinerApp extends StatelessWidget {
  const AdvancedCryptoMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Miner Rig Farm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        primaryColor: const Color(0xFFF7931A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7931A),
          secondary: Color(0xFF00E676),
          tertiary: Color(0xFF00B0FF),
          surface: Color(0xFF141721),
        ),
      ),
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;

  // اقتصاد اللعبة
  double _btcBalance = 0.00000000;
  int _userPoints = 500; // نقاط بداية
  int _activeWorkers = 1;
  double get _totalHashRate => _activeWorkers * 50.0; // كل عامل يعطي 50 GH/s

  Timer? _miningTimer;
  late AnimationController _fanController;

  @override
  void initState() {
    super.initState();
    _fanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _btcBalance += (_totalHashRate * 0.00000000005);
      });
    });
  }

  @override
  void dispose() {
    _miningTimer?.cancel();
    _fanController.dispose();
    super.dispose();
  }

  void _buyWorker(int cost) {
    if (_userPoints >= cost) {
      setState(() {
        _userPoints -= cost;
        _activeWorkers += 1;
      });
      _showSnackBar('🎉 تم شراء وتفعيل صندوق تعدين جديد (+50 GH/s)!', Colors.green);
    } else {
      _showSnackBar('❌ نقاطك غير كافية! أكمل المهام للحصول على النقاط.', Colors.redAccent);
    }
  }

  void _completeOffer(int reward, String title) {
    setState(() {
      _userPoints += reward;
    });
    _showSnackBar('✅ تم إكمال $title وحصلت على +$reward نقطة!', const Color(0xFF00B0FF));
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildMiningTab(),
      _buildShopTab(),
      _buildOfferwallTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141721),
        elevation: 2,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_bitcoin, color: Color(0xFFF7931A)),
                const SizedBox(width: 4),
                Text(_btcBalance.toStringAsFixed(8), style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Color(0xFFF7931A))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00B0FF).withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00B0FF))),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFF00B0FF), size: 16),
                  const SizedBox(width: 4),
                  Text('$_userPoints PTS', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
                ],
              ),
            ),
          ],
        ),
      ),
      body: pages[_selectedNavIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        backgroundColor: const Color(0xFF141721),
        selectedItemColor: const Color(0xFFF7931A),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.developer_board), label: 'المستودع'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'متجر العمال'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'جدار المهام'),
        ],
      ),
    );
  }

  // 1. واجهة المستودع والتعدين
  Widget _buildMiningTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF141721), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إجمالي قوة التعدين', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('${_totalHashRate.toStringAsFixed(0)} GH/s', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('العمال النشطون', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('$_activeWorkers Rigs', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerRight, child: Text('صناديق التعدين في منجمك:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
              itemCount: _activeWorkers,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(color: const Color(0xFF141721), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotationTransition(
                        turns: _fanController,
                        child: const Icon(Icons.settings_input_component, size: 45, color: Color(0xFF00E676)),
                      ),
                      const SizedBox(height: 8),
                      Text('عامل رقم #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('السرعة: 50 GH/s', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 2. واجهة المتجر لشراء العمال
  Widget _buildShopTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('استئجار عمال وصناديق تعدين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('استخدم النقاط التي جمعتها من المهام لشراء عمال جدد', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 15),
          _buildShopCard('صندوق تعدين أساسي', 'يعطي قوة +50 GH/s مستمرة', 300, Icons.memory),
          _buildShopCard('وقت تعدين مضاعف', 'يعطي قوة +100 GH/s مستمرة', 550, Icons.developer_board),
        ],
      ),
    );
  }

  Widget _buildShopCard(String title, String desc, int price, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141721), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFF7931A)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 5),
                Text('$price PTS', style: const TextStyle(color: Color(0xFF00B0FF), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _buyWorker(price),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7931A), foregroundColor: Colors.black),
            child: const Text('شراء'),
          ),
        ],
      ),
    );
  }

  // 3. واجهة جدار المهام والاستبيانات
  Widget _buildOfferwallTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جدار المهام والاستبيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('أكمل المهام للحصول على النقاط وتطوير منجمك', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 15),
          _buildOfferCard('استبيان الرأي السريع', 'أجب عن 5 أسئلة قصيرة', 150, Icons.poll),
          _buildOfferCard('زيارة رابط رعاية', 'قم بزيارة الموقع لمدة 30 ثانية', 100, Icons.link),
          _buildOfferCard('تثبيت تطبيق تجريبي', 'قم بتنزيل وفتح التطبيق', 300, Icons.get_app),
        ],
      ),
    );
  }

  Widget _buildOfferCard(String title, String desc, int reward, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141721), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF00B0FF)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _completeOffer(reward, title),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00B0FF), side: const BorderSide(color: Color(0xFF00B0FF))),
            child: Text('+$reward PTS'),
          ),
        ],
      ),
    );
  }
}
