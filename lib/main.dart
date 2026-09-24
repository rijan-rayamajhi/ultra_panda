import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/player_wallet.dart';
import 'core/progression.dart';
import 'widgets/common/reward_fly.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen immersive mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Landscape orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  PlayerWallet.instance.onCredit = (coins, gems) {
    RewardFly.play(RewardKind.coins, coins);
    RewardFly.play(RewardKind.gems, gems);
  };

  runApp(const UltraPandaApp());
}

class UltraPandaApp extends StatelessWidget {
  const UltraPandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultra Panda',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      navigatorKey: rootNavigatorKey,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const LoadingScreen(),
    );
  }
}
