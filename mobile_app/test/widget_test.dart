import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/providers/ranking_provider.dart';

void main() {
  testWidgets('App smoke test loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RankingProvider()),
        ],
        child: const DarazRankApp(),
      ),
    );

    expect(find.text('Daraz Rank Radar'), findsOneWidget);
  });
}
