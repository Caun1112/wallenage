import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/asset_provider.dart';
import 'providers/exchange_rate_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExchangeRateProvider()),
        ChangeNotifierProxyProvider<ExchangeRateProvider, AssetProvider>(
          create: (_) => AssetProvider(),
          update: (_, rates, assets) => assets!..setRateProvider(rates),
        ),
      ],
      child: const WalletApp(),
    ),
  );
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return MaterialApp(
      title: '资产管家',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5A623),
          surface: Color(0xFF13131A),
          onSurface: Color(0xFFE8E8F0),
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      home: const HomeScreen(),
    );
  }
}
