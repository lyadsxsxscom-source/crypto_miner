import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MiningApp());
}

class MiningApp extends StatelessWidget {
  const MiningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Miner',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double userBalanceSats = 0.00000050; // رصيد تجريبي
  double hashRateGhs = 800.0;
  Timer? _miningTimer;
  final TextEditingController _walletController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startMining();
  }

  void _startMining() {
    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        userBalanceSats += (hashRateGhs / 100) * 0.00000001;
      });
    });
  }

  void _watchAdToBoost() {
    setState(() {
      hashRateGhs += 50.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت زيادة السرعة +50 GH/s!')),
    );
  }

  // نافذة طلب السحب
  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سحب الأرباح (BTC)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رصيدك: ${userBalanceSats.toStringAsFixed(8)} BTC'),
            const SizedBox(height: 15),
            TextField(
              controller: _walletController,
              decoration: const InputDecoration(
                labelText: 'عنوان محفظة Bitcoin / Speed',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_walletController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال طلب السحب بنجاح!')),
                );
              }
            },
            child: const Text('سحب الآن'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _miningTimer?.cancel();
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitcoin Mining Game'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('الرصيد المجمع:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              '${userBalanceSats.toStringAsFixed(8)} BTC',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(Icons.flash_on, color: Colors.orange),
                title: const Text('سرعة التعدين الحالية'),
                trailing: Text('$hashRateGhs GH/s', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _watchAdToBoost,
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('شاهد إعلان لزيادة السرعة +50 GH/s'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: _showWithdrawDialog,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('طلب سحب الأرباح'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
