import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MiningRigApp());
}

class MiningRigApp extends StatelessWidget {
  const MiningRigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Mining Farm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        primaryColor: const Color(0xFFF7931A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7931A),
          secondary: Color(0xFF00E676),
          tertiary: Color(0xFF627AEA), // لون الإيثيريوم
          surface: Color(0xFF151922),
        ),
      ),
      home: const MainRigDashboard(),
    );
  }
}

class RigSlot {
  final int id;
  bool isUnlocked;
  final String unlockMethod;
  final int unlockCostPoints;
  final double unlockCostUSD;
  MinerBox? activeMiner;

  RigSlot({
    required this.id,
    this.isUnlocked = false,
    required this.unlockMethod,
    this.unlockCostPoints = 0,
    this.unlockCostUSD = 0.0,
    this.activeMiner,
  });
}

class MinerBox {
  final String name;
  final String type;
  final double hashRateGHs;
  final String durationType;
  final DateTime expiresAt;

  MinerBox({
    required this.name,
    required this.type,
    required this.hashRateGHs,
    required this.durationType,
    required this.expiresAt,
  });
}

class MainRigDashboard extends StatefulWidget {
  const MainRigDashboard({super.key});

  @override
  State<MainRigDashboard> createState() => _MainRigDashboardState();
}

class _MainRigDashboardState extends State<MainRigDashboard> {
  int _selectedNavIndex = 0;
  String _selectedCrypto = 'BTC'; // 'BTC' or 'ETH'

  // الأرصدة
  double _btcBalance = 0.00000000;
  double _ethBalance = 0.00000000;
  int _points = 1200; // بداية بـ 1 دولار تجريبي

  Timer? _miningTimer;
  late List<RigSlot> _slots;

  @override
  void initState() {
    super.initState();
    _initializeSlots();

    // معادلة التعدين المضبوطة: 25 GH/s = 0.25$ يومياً
    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      double totalGhs = _calculateTotalHashRate();
      if (totalGhs > 0) {
        setState(() {
          // حساب القيمة بالدولار في الثانية (0.25$ / 86400 ثانية لكل 25 GH/s)
          double usdGainedPerSec = (totalGhs / 25.0) * (0.25 / 86400.0);
          
          if (_selectedCrypto == 'BTC') {
            // افتراض سعر البيتكوين 60,000$
            _btcBalance += usdGainedPerSec / 60000.0;
          } else {
            // افتراض سعر الإيثيريوم 3,000$
            _ethBalance += usdGainedPerSec / 3000.0;
          }
        });
      }
    });
  }

  void _initializeSlots() {
    _slots = [
      RigSlot(id: 1, isUnlocked: true, unlockMethod: 'FREE'),
      RigSlot(id: 2, isUnlocked: true, unlockMethod: 'FREE'),
      RigSlot(id: 3, unlockMethod: 'POINTS', unlockCostPoints: 300),
      RigSlot(id: 4, unlockMethod: 'POINTS', unlockCostPoints: 800),
      RigSlot(id: 5, unlockMethod: 'POINTS', unlockCostPoints: 1500),
      RigSlot(id: 6, unlockMethod: 'POINTS', unlockCostPoints: 3000),
      RigSlot(id: 7, unlockMethod: 'MONEY', unlockCostUSD: 1.99),
      RigSlot(id: 8, unlockMethod: 'MONEY', unlockCostUSD: 2.99),
      RigSlot(id: 9, unlockMethod: 'MONEY', unlockCostUSD: 4.99),
      RigSlot(id: 10, unlockMethod: 'MONEY', unlockCostUSD: 7.99),
      RigSlot(id: 11, unlockMethod: 'MONEY', unlockCostUSD: 9.99),
      RigSlot(id: 12, unlockMethod: 'MONEY', unlockCostUSD: 14.99),
    ];
  }

  @override
  void dispose() {
    _miningTimer?.cancel();
    super.dispose();
  }

  double _calculateTotalHashRate() {
    double total = 0.0;
    for (var slot in _slots) {
      if (slot.isUnlocked && slot.activeMiner != null) {
        if (slot.activeMiner!.expiresAt.isAfter(DateTime.now())) {
          total += slot.activeMiner!.hashRateGHs;
        }
      }
    }
    return total;
  }

  Future<void> _openURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showMsg('تعذر فتح الرابط!', Colors.redAccent);
    }
  }

  void _unlockSlot(RigSlot slot) {
    if (slot.unlockMethod == 'POINTS') {
      if (_points >= slot.unlockCostPoints) {
        setState(() {
          _points -= slot.unlockCostPoints;
          slot.isUnlocked = true;
        });
        _showMsg('تم فتح الخانة #${slot.id}!', Colors.green);
      } else {
        _showMsg('نقاطك لا تكفي لفتح هذه الخانة!', Colors.redAccent);
      }
    } else if (slot.unlockMethod == 'MONEY') {
      _showDemoPaymentDialog('فتح خانة #${slot.id}', slot.unlockCostUSD, () {
        setState(() {
          slot.isUnlocked = true;
        });
        _showMsg('تم شراء وفتح الخانة #${slot.id}!', Colors.green);
      });
    }
  }

  void _buyBoxWithPoints(String name, String type, double ghs, int costPoints) {
    if (_points < costPoints) {
      _showMsg('رصيد Points غير كافٍ!', Colors.redAccent);
      return;
    }

    RigSlot? emptySlot;
    try {
      emptySlot = _slots.firstWhere((s) => s.isUnlocked && s.activeMiner == null);
    } catch (_) {
      emptySlot = null;
    }

    if (emptySlot == null) {
      _showMsg('افتح خانة فارغة أولاً في المستودع!', Colors.orangeAccent);
      return;
    }

    setState(() {
      _points -= costPoints;
      emptySlot!.activeMiner = MinerBox(
        name: name,
        type: type,
        hashRateGHs: ghs,
        durationType: 'DAILY',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
    });

    _showMsg('تم استئجار $name بنجاح!', Colors.green);
  }

  void _buyBoxWithMoney(String name, String type, double ghs, double costUSD) {
    RigSlot? emptySlot;
    try {
      emptySlot = _slots.firstWhere((s) => s.isUnlocked && s.activeMiner == null);
    } catch (_) {
      emptySlot = null;
    }

    if (emptySlot == null) {
      _showMsg('افتح خانة فارغة أولاً في المستودع!', Colors.orangeAccent);
      return;
    }

    _showDemoPaymentDialog('استئجار $name (شهري)', costUSD, () {
      setState(() {
        emptySlot!.activeMiner = MinerBox(
          name: name,
          type: type,
          hashRateGHs: ghs,
          durationType: 'MONTHLY',
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
      });
      _showMsg('تم استئجار $name لمدة شهر!', Colors.green);
    });
  }

  void _showMsg(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textAlign: TextAlign.center), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _showDemoPaymentDialog(String title, double amountUSD, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: Text('بوابة الشراء ($title)'),
        content: Text('المبلغ: \$$amountUSD USD\n\n(شراء تجريبي باختبار النظام)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSuccess();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            child: const Text('تأكيد الشراء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildWarehouseTab(),
      _buildShopTab(),
      _buildOfferwallTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF151922),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCrypto = _selectedCrypto == 'BTC' ? 'ETH' : 'BTC';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(
                      _selectedCrypto == 'BTC' ? Icons.currency_bitcoin : Icons.diamond,
                      color: _selectedCrypto == 'BTC' ? const Color(0xFFF7931A) : const Color(0xFF627AEA),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCrypto == 'BTC' ? _btcBalance.toStringAsFixed(8) : _ethBalance.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: _selectedCrypto == 'BTC' ? const Color(0xFFF7931A) : const Color(0xFF627AEA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00B0FF).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFF00B0FF), size: 16),
                  const SizedBox(width: 4),
                  Text('$_points Pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
                ],
              ),
            ),
          ],
        ),
      ),
      body: pages[_selectedNavIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (i) => setState(() => _selectedNavIndex = i),
        backgroundColor: const Color(0xFF151922),
        selectedItemColor: const Color(0xFFF7931A),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'المستودع'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المتجر'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'جدار العروض'),
        ],
      ),
    );
  }

  // 1. المستودع
  Widget _buildWarehouseTab() {
    double totalGhs = _calculateTotalHashRate();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('معدل التعدين النشط', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(
                      totalGhs >= 1000 ? '${(totalGhs / 1000).toStringAsFixed(2)} TH/s' : '${totalGhs.toStringAsFixed(0)} GH/s',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                    ),
                  ],
                ),
                Text('العملة: $_selectedCrypto', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
              itemCount: 12,
              itemBuilder: (context, index) => _buildSlotCard(_slots[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(RigSlot slot) {
    if (!slot.isUnlocked) {
      bool isPoints = slot.unlockMethod == 'POINTS';
      return InkWell(
        onTap: () => _unlockSlot(slot),
        child: Container(
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: isPoints ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: isPoints ? Colors.orange : Colors.green, size: 24),
              const SizedBox(height: 2),
              Text('خانة #${slot.id}', style: const TextStyle(fontSize: 10)),
              Text(isPoints ? '${slot.unlockCostPoints} Pts' : '\$${slot.unlockCostUSD}', style: TextStyle(fontSize: 10, color: isPoints ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (slot.activeMiner == null) {
      return Container(
        decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: Colors.white38, size: 26),
            Text('خانة #${slot.id}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      );
    }

    var miner = slot.activeMiner!;
    Color boxColor = Colors.brown;
    if (miner.type == 'SILVER') boxColor = Colors.grey;
    if (miner.type == 'GOLD') boxColor = Colors.amber;
    if (miner.type == 'DIAMOND') boxColor = Colors.cyan;

    return Container(
      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: boxColor, width: 1.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.developer_board, color: boxColor, size: 26),
          Text(miner.name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text('${miner.hashRateGHs.toStringAsFixed(0)} GH/s', style: const TextStyle(fontSize: 9, color: Color(0xFF00E676))),
        ],
      ),
    );
  }

  // 2. المتجر
  Widget _buildShopTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('استئجار بالـ Points (يومي - 24h)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
          const SizedBox(height: 6),
          _buildBoxShopCard('صندوق خشبي', 25, '300 Pts', () => _buyBoxWithPoints('صندوق خشبي', 'WOOD', 25, 300), Colors.brown),
          _buildBoxShopCard('صندوق فضي', 100, '800 Pts', () => _buyBoxWithPoints('صندوق فضي', 'SILVER', 100, 800), Colors.grey),
          _buildBoxShopCard('صندوق ذهبي', 500, '3000 Pts', () => _buyBoxWithPoints('صندوق ذهبي', 'GOLD', 500, 3000), Colors.amber),
          _buildBoxShopCard('صندوق الماسي', 1000, '5500 Pts', () => _buyBoxWithPoints('صندوق الماسي', 'DIAMOND', 1000, 5500), Colors.cyan),

          const SizedBox(height: 14),
          const Text('استئجار بالمال الحقيقي (شهري - 30d)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
          const SizedBox(height: 6),
          _buildBoxShopCard('صندوق فضي شهري', 100, '\$1.99 USD', () => _buyBoxWithMoney('فضي شهري', 'SILVER', 100, 1.99), Colors.grey),
          _buildBoxShopCard('صندوق ذهبي شهري', 500, '\$4.99 USD', () => _buyBoxWithMoney('ذهبي شهري', 'GOLD', 500, 4.99), Colors.amber),
          _buildBoxShopCard('صندوق الماسي شهري (1 TH/s)', 1000, '\$8.99 USD', () => _buyBoxWithMoney('الماسي شهري', 'DIAMOND', 1000, 8.99), Colors.cyan),
        ],
      ),
    );
  }

  Widget _buildBoxShopCard(String title, double ghs, String priceText, VoidCallback onBuy, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(Icons.inventory_2, size: 28, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('القوة: ${ghs >= 1000 ? "1 TH/s" : "$ghs GH/s"}', style: const TextStyle(color: Color(0xFF00E676), fontSize: 10)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
            child: Text(priceText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. جدار العروض المربوط بـ MobileRewards
  Widget _buildOfferwallTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جدار المهام والعروض', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Text('أكمل المهام لجمع الـ Points وتطوير منجمك', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 12),
          
          // كارت جدار العروض المباشر
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00B0FF))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer, color: Color(0xFF00B0FF)),
                    SizedBox(width: 8),
                    Text('جدار عروض MobileRewards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('احصل على نقاط تصل إلى +1200 Points مقابل تحميل التطبيقات وتجربة الألعاب.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openURL('https://www.mobilerewards.link/wall/UG2x1'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF), foregroundColor: Colors.black),
                    child: const Text('فتح جدار المهام الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text('مكافآت مباشرة داخل اللعبة:', style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 6),
          
          _buildTaskCard('مكافأة التسجيل اليومية', '+100 Pts', () {
            setState(() => _points += 100);
            _showMsg('تمت إضافة +100 Pts لمكافأتك اليومية!', Colors.green);
          }),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, String rewardText, VoidCallback onAction) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00B0FF), side: const BorderSide(color: Color(0xFF00B0FF))),
            child: Text(rewardText, style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
