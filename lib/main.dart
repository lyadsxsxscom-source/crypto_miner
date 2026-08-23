import 'package:flutter/material.dart';

void main() {
  runApp(const CryptoMinerApp());
}

class CryptoMinerApp extends StatelessWidget {
  const CryptoMinerApp({super.key});

  @appOverride
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Miner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const Center(child: Text('المستودع', style: TextStyle(fontSize: 20))),
          const Center(child: Text('المتجر', style: TextStyle(fontSize: 20))),
          const Center(child: Text('المهام', style: TextStyle(fontSize: 20))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, size: 50, color: Colors.black),
                ),
                const SizedBox(height: 16),
                const Text('المعدن الذهبي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('مُعَدّن زائر', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.login, color: Colors.red),
                  label: const Text('تسجيل الدخول باستخدام Google', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جاري إعداد خدمة تسجيل الدخول...')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
}
