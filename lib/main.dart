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
          tertiary: Color(0xFF627AEA),
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
  final String coinType; // 'BTC' or 'ETH'
  final String type; // 'WOOD', 'SILVER', 'GOLD', 'DIAMOND'
  final double hashRateGHs;
  final DateTime expiresAt;

  MinerBox({
    required this.name,
    required this.coinType,
    required this.type,
    required this.hashRateGHs,
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
  final String _userName = "المعدن الذهبي";

  double _btcBalance = 0.00000000;
  double _ethBalance = 0.00000000;
  int _points = 1200;

  Timer? _miningTimer;
  late List<RigSlot> _slots;

  @override
  void initState() {
    super.initState();
    _initializeSlots();

    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      double btcGhs = _calculateHashRateForCoin('BTC');
      double ethGhs = _calculateHashRateForCoin('ETH');

      if (btcGhs > 0 || ethGhs > 0) {
        setState(() {
          if (btcGhs > 0) {
            double btcUsd = (btcGhs / 25.0) * (0.25 / 86400.0);
            _btcBalance += btcUsd / 60000.0;
          }
          if (ethGhs > 0) {
            double ethUsd = (ethGhs / 25.0) * (0.25 / 86400.0);
            _ethBalance += ethUsd / 3000.0;
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

  double _calculateHashRateForCoin(String coin) {
    double total = 0.0;
    for (var slot in _slots) {
      if (slot.isUnlocked && slot.activeMiner != null) {
        if (slot.activeMiner!.coinType == coin && slot.activeMiner!.expiresAt.isAfter(DateTime.now())) {
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

  void _buyBoxWithPoints(String name, String coinType, String type, double ghs, int costPoints) {
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
      _showMsg('لا توجد خانة فارغة في المستودع!', Colors.orangeAccent);
      return;
    }

    setState(() {
      _points -= costPoints;
      emptySlot!.activeMiner = MinerBox(
        name: name,
        coinType: coinType,
        type: type,
        hashRateGHs: ghs,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
    });

    _showMsg('تم استئجار $name ($coinType) بنجاح!', Colors.green);
  }

  void _buyBoxWithMoney(String name, String coinType, String type, double ghs, double costUSD) {
    RigSlot? emptySlot;
    try {
      emptySlot = _slots.firstWhere((s) => s.isUnlocked && s.activeMiner == null);
    } catch (_) {
      emptySlot = null;
    }

    if (emptySlot == null) {
      _showMsg('لا توجد خانة فارغة في المستودع!', Colors.orangeAccent);
      return;
    }

    _showDemoPaymentDialog('استئجار $name', costUSD, () {
      setState(() {
        emptySlot!.activeMiner = MinerBox(
          name: name,
          coinType: coinType,
          type: type,
          hashRateGHs: ghs,
          expiresAt: DateTime.now().add(const Duration(days: 30)), // شهر كامل
        );
      });
      _showMsg('تم استئجار $name لمدة شهر بنجاح!', Colors.green);
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
        content: Text('المبلغ: \$$amountUSD USD\n\n(شراء تجريبي لتفعيل العامل)'),
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
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF151922),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_bitcoin, color: Color(0xFFF7931A), size: 16),
                Text(_btcBalance.toStringAsFixed(6), style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFFF7931A))),
                const SizedBox(width: 8),
                const Icon(Icons.diamond, color: Color(0xFF627AEA), size: 16),
                Text(_ethBalance.toStringAsFixed(5), style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF627AEA))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF00B0FF).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFF00B0FF), size: 14),
                  const SizedBox(width: 2),
                  Text('$_points Pts', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'المستودع'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المتجر'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف'),
        ],
      ),
    );
  }

  // 1. المستودع
  Widget _buildWarehouseTab() {
    double btcGhs = _calculateHashRateForCoin('BTC');
    double ethGhs = _calculateHashRateForCoin('ETH');

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('معدل BTC', style: TextStyle(color: Color(0xFFF7931A), fontSize: 10)),
                    Text('${btcGhs.toStringAsFixed(0)} GH/s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Container(height: 20, width: 1, color: Colors.white10),
                Column(
                  children: [
                    const Text('معدل ETH', style: TextStyle(color: Color(0xFF627AEA), fontSize: 10)),
                    Text('${ethGhs.toStringAsFixed(0)} GH/s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 0.8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) => _buildCompactSlotCard(_slots[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSlotCard(RigSlot slot) {
    if (!slot.isUnlocked) {
      bool isPoints = slot.unlockMethod == 'POINTS';
      return InkWell(
        onTap: () => _unlockSlot(slot),
        child: Container(
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8), border: Border.all(color: isPoints ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: isPoints ? Colors.orange : Colors.green, size: 18),
              const SizedBox(height: 2),
              Text('#${slot.id}', style: const TextStyle(fontSize: 9, color: Colors.white54)),
              Text(isPoints ? '${slot.unlockCostPoints}P' : '\$${slot.unlockCostUSD}', style: TextStyle(fontSize: 8, color: isPoints ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (slot.activeMiner == null) {
      return InkWell(
        onTap: () {
          // الانتقال التلقائي للمتجر عند الضغط على خانة مفتوحة وفارغة
          setState(() {
            _selectedNavIndex = 1; 
          });
        },
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withOpacity(0.5))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_shopping_cart, color: Color(0xFF00E676), size: 20),
              Text('#${slot.id} فارغة', style: const TextStyle(fontSize: 8, color: Color(0xFF00E676))),
            ],
          ),
        ),
      );
    }

    var miner = slot.activeMiner!;
    Color coinColor = miner.coinType == 'BTC' ? const Color(0xFFF7931A) : const Color(0xFF627AEA);

    return Container(
      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(8), border: Border.all(color: coinColor, width: 1)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(miner.coinType == 'BTC' ? Icons.currency_bitcoin : Icons.diamond, color: coinColor, size: 18),
          Text(miner.name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          Text('${miner.hashRateGHs.toStringAsFixed(0)} GH/s', style: TextStyle(fontSize: 7, color: coinColor)),
        ],
      ),
    );
  }

  // 2. المتجر (يحتوي على Points و USD للشراء)
  Widget _buildShopTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFFF7931A),
            tabs: [
              Tab(text: 'عمال البيتكوين (BTC)'),
              Tab(text: 'عمال الإيثيريوم (ETH)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCoinShopList('BTC'),
                _buildCoinShopList('ETH'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinShopList(String coin) {
    Color coinColor = coin == 'BTC' ? const Color(0xFFF7931A) : const Color(0xFF627AEA);

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Text('تأجير عمال $coin بـ النقاط (يومي)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: coinColor)),
        const SizedBox(height: 6),
        _buildShopItemCard('عامل خشبي', coin, 'WOOD', 25, '300 Pts', () => _buyBoxWithPoints('عامل خشبي', coin, 'WOOD', 25, 300), coinColor),
        _buildShopItemCard('عامل فضي', coin, 'SILVER', 100, '800 Pts', () => _buyBoxWithPoints('عامل فضي', coin, 'SILVER', 100, 800), coinColor),
        _buildShopItemCard('عامل ذهبي', coin, 'GOLD', 500, '3000 Pts', () => _buyBoxWithPoints('عامل ذهبي', coin, 'GOLD', 500, 3000), coinColor),
        _buildShopItemCard('عامل ماسي', coin, 'DIAMOND', 1000, '5500 Pts', () => _buyBoxWithPoints('عامل ماسي', coin, 'DIAMOND', 1000, 5500), coinColor),

        const SizedBox(height: 14),
        Text('شراء عمال $coin بالمال الحقيقي (شهري - 30 يوم)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        const SizedBox(height: 6),
        _buildShopItemCard('عامل فضي شهري', coin, 'SILVER', 100, '\$1.99', () => _buyBoxWithMoney('عامل فضي شهري', coin, 'SILVER', 100, 1.99), Colors.green),
        _buildShopItemCard('عامل ذهبي شهري', coin, 'GOLD', 500, '\$4.99', () => _buyBoxWithMoney('عامل ذهبي شهري', coin, 'GOLD', 500, 4.99), Colors.green),
        _buildShopItemCard('عامل ماسي شهري (1TH)', coin, 'DIAMOND', 1000, '\$8.99', () => _buyBoxWithMoney('عامل ماسي شهري', coin, 'DIAMOND', 1000, 8.99), Colors.green),
      ],
    );
  }

  Widget _buildShopItemCard(String name, String coinType, String type, double ghs, String priceText, VoidCallback onBuy, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(coinType == 'BTC' ? Icons.currency_bitcoin : Icons.diamond, size: 22, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('القوة: +${ghs >= 1000 ? "1 TH/s" : "$ghs GH/s"}', style: TextStyle(color: color, fontSize: 9)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
            child: Text(priceText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. المهام
  Widget _buildOfferwallTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00B0FF))),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer, color: Color(0xFF00B0FF)),
                    SizedBox(width: 8),
                    Text('MobileRewards Offerwall', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('أكمل المهام اليومية للحصول على النقاط وتطوير العمال.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openURL('https://www.mobilerewards.link/wall/UG2x1'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF), foregroundColor: Colors.black),
                    child: const Text('فتح المهام', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. الملف الشخصي
  Widget _buildProfileTab() {
    double totalUsdBalance = (_btcBalance * 60000.0) + (_ethBalance * 3000.0);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFF7931A),
            child: Icon(Icons.person, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(_userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('مُعدِّن محترف', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00E676))),
            child: Column(
              children: [
                const Text('إجمالي قيمة الأرصدة التقديرية', style: TextStyle(fontSize: 10, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('\$${totalUsdBalance.toStringAsFixed(4)} USD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
              ],
            ),
          ),

          const SizedBox(height: 12),
          ListTile(
            tileColor: const Color(0xFF151922),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            leading: const Icon(Icons.stars, color: Color(0xFF00B0FF)),
            title: const Text('رصيد النقاط', style: TextStyle(fontSize: 12)),
            trailing: Text('$_points Pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
