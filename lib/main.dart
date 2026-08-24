import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  // 1. ضمان تهيئة Flutter قبل كل شيء
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CryptoMinerApp());
}

class CryptoMinerApp extends StatelessWidget {
  const CryptoMinerApp({super.key});

  static const FirebaseOptions _firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyCJRpc2021fgsi4JNAITf1RWWAVt2BsX18",
    appId: "1:1017358589643:android:f367b9c036f786e2b5054e",
    messagingSenderId: "1017358589643",
    projectId: "asyr-asyr-tab8",
    storageBucket: "asyr-asyr-tab8.firebasestorage.app",
  );

  // دالة آمنة لتهيئة الفايربيس دون تعليق الواجهة
  Future<FirebaseApp> _initFirebase() async {
    if (Firebase.apps.isEmpty) {
      return await Firebase.initializeApp(options: _firebaseOptions);
    }
    return Firebase.app();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Miner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // استخدام FutureBuilder في الشاشة الرئيسية لمنع الشاشة البيضاء أثناء التهيئة
      home: FutureBuilder<FirebaseApp>(
        future: _initFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'خطأ في الاتصال بالفايربيس:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }

          return const MainNavigationScreen();
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildPlaceholderView('المستودع', Icons.grid_view),
          _buildPlaceholderView('المتجر', Icons.store),
          _buildPlaceholderView('المهام', Icons.assignment),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'المستودع'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المتجر'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف'),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoggingIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoggingIn = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '1017358589643-fan84jsi99geh5bpo37qaj5bhamasdlq.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التسجيل: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildLoggedOutUI();
        }

        final user = snapshot.data;
        if (user != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName ?? 'مستخدم Google',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                  onPressed: _handleSignOut,
                ),
              ],
            ),
          );
        }

        return _buildLoggedOutUI();
      },
    );
  }

  Widget _buildLoggedOutUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoggingIn)
            const CircularProgressIndicator(color: Colors.amber)
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول بواسطة Google'),
              onPressed: _handleGoogleSignIn,
            ),
        ],
      ),
    );
  }
}
