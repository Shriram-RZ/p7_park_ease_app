import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:park_ease/app/app.dart';
import 'package:park_ease/app/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('ParkFlow boots into splash', (WidgetTester tester) async {
    final state = await AppState.bootstrap();
    addTearDown(() {
      state.simulation.stop();
      state.dispose();
    });
    await tester.pumpWidget(ParkFlowApp(state: state));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('ParkFlow'), findsWidgets);
  });
}
