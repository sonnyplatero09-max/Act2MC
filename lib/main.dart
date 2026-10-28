import 'package:flutter/material.dart';
import 'services/network_monitor_service.dart';
import 'services/request_queue_manager.dart';
import 'screens/home_screen.dart';
import 'screens/network_monitor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize network monitor and request queue services
  await NetworkMonitorService.instance.initialize();
  RequestQueueManager.instance.initialize();

  runApp(const MasterCompilationApp());
}

class MasterCompilationApp extends StatelessWidget {
  const MasterCompilationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Computing Master Compilation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/network_monitor': (context) => const NetworkMonitorScreen(),
      },
    );
  }
}
