import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const CryptoMinerApp());
}

class CryptoMinerApp extends StatelessWidget {
  const CryptoMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitcoin Mining Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        primaryColor: const Color(0xFFF7931A), // Bitcoin Orange
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7931A),
          secondary: Color(0xFF00E676), // Neon Green
          surface: Color(0xFF1A1D24),
        ),
      ),
      home: const MinerHomeScreen(),
    );
  }
}

class MinerHomeScreen extends StatefulWidget {
  const MinerHomeScreen({super.key});

  @override
  State<MinerHomeScreen> createState() => _MinerHomeScreenState();
}

class _MinerHomeScreenState extends State<MinerHomeScreen>
    with SingleTickerProviderStateMixin {
  double _balance = 0.00000000;
  double _hashRate = 100.0; // GH/s
  Timer? _minerTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // أنيميشن النبض لحلقة التعدين
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // مؤقت التعدين لتحديث الرصيد كل ثانية
    _minerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _balance += (_hashRate * 0.0000000001);
      });
    });
  }

  @override
  void dispose() {
    _minerTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _boostSpeed() {
    setState(() {
      _hashRate += 50.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '🚀 تم زياده سرعة التعدين بمقدار +50 GH/s!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _requestWithdraw() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFFF7931A)),
            SizedBox(width: 10),
            Text('طلب سحب الأرباح', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'رصيدك الحالي هو:\n${_balance.toStringAsFixed(8)} BTC\n\nالحد الأدنى للسحب هو 0.005 BTC.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Color(0xFFF7931A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_bitcoin, color: Color(0xFFF7931A), size: 28),
            SizedBox(width: 8),
            Text(
              'BITCOIN MINER',
              style: TextStyle(
                fontWeight: FontWeight.extrabold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. عنصر الرسوم المتحركة للتعدين (Mining Pulse Element)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1D24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF7931A).withOpacity(0.2 + (_pulseController.value * 0.3)),
                          blurRadius: 30 + (_pulseController.value * 20),
                          spreadRadius: 5 + (_pulseController.value * 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.memory,
                      size: 70,
                      color: Color.lerp(
                        const Color(0xFFF7931A),
                        const Color(0xFFFFB74D),
                        _pulseController.value,
                      ),
                    ),
                  );
                },
              ),

              // 2. بطاقات وعرض الرصيد المجمع
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'الرصيد المجمع الحالي',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_balance.toStringAsFixed(8)} BTC',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF7931A),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. عرض سرعة التعدين الحالية
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF00E676)),
                        SizedBox(width: 8),
                        Text(
                          'سرعة التعدين',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      '${_hashRate.toStringAsFixed(1)} GH/s',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. أزرار التحكم والعمليات
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _boostSpeed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.play_circle_fill, size: 28),
                      label: const Text(
                        'شاهد إعلان لزيادة السرعة +50 GH/s',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: _requestWithdraw,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFF7931A), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFF7931A)),
                      label: const Text(
                        'طلب سحب الأرباح',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

