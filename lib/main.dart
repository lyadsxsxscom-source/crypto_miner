import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MiningRigApp());
}

class MiningRigApp extends StatelessWidget {
  const MiningRigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Mining Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        primaryColor: const Color(0xFFF7931A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7931A),
          secondary: Color(0xFF00E676),
          tertiary: Color(0xFF00B0FF),
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
  final String unlockMethod; // 'FREE', 'POINTS', 'MONEY'
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
  final String type; // 'WOOD', 'SILVER', 'GOLD', 'DIAMOND'
  final double hashRateGHs;
  final String durationType; // 'DAILY', 'MONTHLY'
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

  // اقتصاد اللعبة
  double _btcBalance = 0.00000000;
  int _points = 1000; // نقاط بداية للتجربة
  Timer? _miningTimer;

  // إعداد الـ 12 خانة
  late List<RigSlot> _slots;

  @override
  void initState() {
    super.initState();
    _initializeSlots();

    // محرك حساب التعدين اللحظي
    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      double currentHashRate = _calculateTotalHashRate();
      if (currentHashRate > 0) {
        setState(() {
          _btcBalance += (currentHashRate * 0.00000000002);
        });
      }
    });
  }

  void _initializeSlots() {
    _slots = [
      // 2 خانات مجانية
      RigSlot(id: 1, isUnlocked: true, unlockMethod: 'FREE'),
      RigSlot(id: 2, isUnlocked: true, unlockMethod: 'FREE'),

      // 4 خانات بالنقاط (Points)
      RigSlot(id: 3, unlockMethod: 'POINTS', unlockCostPoints: 500),
      RigSlot(id: 4, unlockMethod: 'POINTS', unlockCostPoints: 1000),
      RigSlot(id: 5, unlockMethod: 'POINTS', unlockCostPoints: 2000),
      RigSlot(id: 6, unlockMethod: 'POINTS', unlockCostPoints: 3500),

      // 6 خانات بالمال الحقيقي (USD)
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

  void _unlockSlot(RigSlot slot) {
    if (slot.unlockMethod == 'POINTS') {
      if (_points >= slot.unlockCostPoints) {
        setState(() {
          _points -= slot.unlockCostPoints;
          slot.isUnlocked = true;
        });
        _showMsg('تم فتح الخانة رقم ${slot.id} بنجاح!', Colors.green);
      } else {
        _showMsg('عفواً، لا تملك Points كافية لفتح هذه الخانة!', Colors.redAccent);
      }
    } else if (slot.unlockMethod == 'MONEY') {
      // محاكاة عملية الدفع بالمال الحقيقي للتجربة
      _showDemoPaymentDialog('فتح خانة ممتازة #${slot.id}', slot.unlockCostUSD, () {
        setState(() {
          slot.isUnlocked = true;
        });
        _showMsg('تم شراء وفتح الخانة الممتازة #${slot.id} بنجاح (تجريبي)!', Colors.green);
      });
    }
  }

  void _buyBoxWithPoints(String name, String type, double ghs, int costPoints) {
    if (_points < costPoints) {
      _showMsg('ليس لديك رصيد Points كافٍ!', Colors.redAccent);
      return;
    }

    // البحث عن أول خانة مفتوحة وفارغة
    RigSlot? emptySlot;
    try {
      emptySlot = _slots.firstWhere((s) => s.isUnlocked && s.activeMiner == null);
    } catch (_) {
      emptySlot = null;
    }

    if (emptySlot == null) {
      _showMsg('لا توجد خانة مفتوحة وفارغة! قم بفتح خانة جديدة أولاً.', Colors.orangeAccent);
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

    _showMsg('تم استئجار $name لمدّة 24 ساعة بنجاح!', Colors.green);
  }

  void _buyBoxWithMoney(String name, String type, double ghs, double costUSD) {
    RigSlot? emptySlot;
    try {
      emptySlot = _slots.firstWhere((s) => s.isUnlocked && s.activeMiner == null);
    } catch (_) {
      emptySlot = null;
    }

    if (emptySlot == null) {
      _showMsg('لا توجد خانة مفتوحة وفارغة! قم بفتح خانة جديدة أولاً.', Colors.orangeAccent);
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
      _showMsg('تم استئجار $name لمدّة 30 يوماً بنجاح (تجريبي)!', Colors.green);
    });
  }

  void _completeTask(int reward, String taskTitle) {
    setState(() {
      _points += reward;
    });
    _showMsg('أحسنت! أتممت $taskTitle وحصلت على +$reward Points!', const Color(0xFF00B0FF));
  }

  void _showMsg(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDemoPaymentDialog(String title, double amountUSD, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: Text('بوابة الدفع التجريبية ($title)'),
        content: Text('السعر المطلوب: \$$amountUSD USD\n\nتنبيه: هذه عملية شراء تجريبية لاختبار التطبيق قبل النشر الرسمّي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSuccess();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            child: const Text('تأكيد الدفع التجريبي'),
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
        elevation: 2,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_bitcoin, color: Color(0xFFF7931A), size: 22),
                const SizedBox(width: 4),
                Text(_btcBalance.toStringAsFixed(8), style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFFF7931A))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00B0FF).withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00B0FF))),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFF00B0FF), size: 16),
                  const SizedBox(width: 4),
                  Text('$_points Points', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
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
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'المستودع (12)'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'متجر الصناديق'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'المهام والروابط'),
        ],
      ),
    );
  }

  // 1. واجهة مستودع الخانات الـ 12
  Widget _buildWarehouseTab() {
    double totalGhs = _calculateTotalHashRate();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('سرعة المنجم الإجمالية', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(
                      totalGhs >= 1000 ? '${(totalGhs / 1000).toStringAsFixed(2)} TH/s' : '${totalGhs.toStringAsFixed(0)} GH/s',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                    ),
                  ],
                ),
                Text('الخانات المفتوحة: ${_slots.where((s) => s.isUnlocked).length}/12', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
              itemCount: 12,
              itemBuilder: (context, index) {
                var slot = _slots[index];
                return _buildSlotCard(slot);
              },
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
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: isPoints ? Colors.orange.withOpacity(0.4) : Colors.green.withOpacity(0.4))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: isPoints ? Colors.orange : Colors.green, size: 28),
              const SizedBox(height: 4),
              Text('خانة #${slot.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                isPoints ? '${slot.unlockCostPoints} Pts' : '\$${slot.unlockCostUSD}',
                style: TextStyle(fontSize: 11, color: isPoints ? Colors.orange : Colors.green, fontWeight: FontWeight.bold),
              ),
              const Text('اضغط للفتح', style: TextStyle(fontSize: 9, color: Colors.white38)),
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
            const Icon(Icons.add_circle_outline, color: Colors.white38, size: 30),
            const SizedBox(height: 4),
            Text('خانة #${slot.id}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
            const Text('فارغة', style: TextStyle(fontSize: 10, color: Colors.white38)),
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
          Icon(Icons.developer_board, color: boxColor, size: 28),
          const SizedBox(height: 4),
          Text(miner.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text('${miner.hashRateGHs.toStringAsFixed(0)} GH/s', style: const TextStyle(fontSize: 10, color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          Text(miner.durationType == 'DAILY' ? 'يومي (24h)' : 'شهري (30d)', style: const TextStyle(fontSize: 8, color: Colors.white38)),
        ],
      ),
    );
  }

  // 2. واجهة متجر الصناديق
  Widget _buildShopTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('استئجار بالـ Points (يومي - 24 ساعة)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
          const SizedBox(height: 8),
          _buildBoxShopCard('صندوق خشبي', 'WOOD', 25, '300 Points', () => _buyBoxWithPoints('صندوق خشبي', 'WOOD', 25, 300), Colors.brown),
          _buildBoxShopCard('صندوق فضي', 'SILVER', 100, '800 Points', () => _buyBoxWithPoints('صندوق فضي', 'SILVER', 100, 800), Colors.grey),
          _buildBoxShopCard('صندوق ذهبي', 'GOLD', 500, '3000 Points', () => _buyBoxWithPoints('صندوق ذهبي', 'GOLD', 500, 3000), Colors.amber),
          _buildBoxShopCard('صندوق الماسي', 'DIAMOND', 1000, '5500 Points', () => _buyBoxWithPoints('صندوق الماسي', 'DIAMOND', 1000, 5500), Colors.cyan),

          const SizedBox(height: 16),
          const Text('استئجار بالمال الحقيقي (شهري - 30 يوماً)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
          const SizedBox(height: 8),
          _buildBoxShopCard('صندوق فضي شهري', 'SILVER', 100, '\$1.99 USD', () => _buyBoxWithMoney('فضي شهري', 'SILVER', 100, 1.99), Colors.grey),
          _buildBoxShopCard('صندوق ذهبي شهري', 'GOLD', 500, '\$4.99 USD', () => _buyBoxWithMoney('ذهبي شهري', 'GOLD', 500, 4.99), Colors.amber),
          _buildBoxShopCard('صندوق الماسي شهري (1 TH/s)', 'DIAMOND', 1000, '\$8.99 USD', () => _buyBoxWithMoney('الماسي شهري', 'DIAMOND', 1000, 8.99), Colors.cyan),
        ],
      ),
    );
  }

  Widget _buildBoxShopCard(String title, String type, double ghs, String priceText, VoidCallback onBuy, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(Icons.inventory_2, size: 32, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('قوة التعدين: ${ghs >= 1000 ? "1 TH/s" : "$ghs GH/s"}', style: const TextStyle(color: Color(0xFF00E676), fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: Text(priceText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. واجهة جدار المهام والروابط
  Widget _buildOfferwallTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جدار المهام والروابط', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Text('أكمل المهام للحصول على Points لتأجير الصناديق وفتح الخانات', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 12),
          _buildTaskCard('زيارة رابط المختصر الأول', '+150 Points', () => _completeTask(150, 'زيارة رابط مختصر')),
          _buildTaskCard('إكمال استبيان عام', '+350 Points', () => _completeTask(350, 'إكمال استبيان')),
          _buildTaskCard('مشاهدة إعلان فيديو', '+200 Points', () => _completeTask(200, 'مشاهدة إعلان')),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, String rewardText, VoidCallback onAction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Color(0xFF00B0FF), size: 24),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00B0FF), side: const BorderSide(color: Color(0xFF00B0FF))),
            child: Text(rewardText, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
