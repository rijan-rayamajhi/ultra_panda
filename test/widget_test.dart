import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_panda/main.dart';
import 'package:ultra_panda/screens/loading_screen.dart';
import 'package:ultra_panda/screens/lobby_screen.dart';

void main() {
  testWidgets('UltraPandaApp boots through loading into the lobby', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'ageConfirmed': true});
    await tester.pumpWidget(const UltraPandaApp());
    expect(find.byType(LoadingScreen), findsOneWidget);

    // Past the precache cap + min show time + fade.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(LobbyScreen), findsOneWidget);
  });
}
