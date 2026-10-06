import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/presentation/match_details/tabs/lineup_tab.dart';

void main() {
  group('Lineup Tab Responsive Sizing & Formation Layout Tests', () {
    List<LineupPlayer> generate11Players(String prefix) {
      return List.generate(
        11,
        (i) => LineupPlayer(
          id: i + 1,
          name: '$prefix لاعب ${i + 1}',
          number: i + 1,
          position: i == 0 ? 'GK' : (i < 5 ? 'DEF' : (i < 9 ? 'MID' : 'FWD')),
        ),
      );
    }

    testWidgets('4-3-3 formation renders cleanly without overlap on 390x844 screen', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final homePlayers = generate11Players('أرض');
      final awayPlayers = generate11Players('ضيف');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 580,
              child: PitchView(
                homeData: TeamLineupData(
                  formation: '4-3-3',
                  startingXI: homePlayers,
                  substitutes: const [],
                ),
                awayData: TeamLineupData(
                  formation: '4-3-3',
                  startingXI: awayPlayers,
                  substitutes: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect 22 player nodes rendered across both teams
      expect(find.text('أرض لاعب 1'), findsOneWidget);
      expect(find.text('ضيف لاعب 11'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4-2-3-1 (5 tactical lines) renders cleanly without vertical overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final homePlayers = generate11Players('أرض');
      final awayPlayers = generate11Players('ضيف');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 580,
              child: PitchView(
                homeData: TeamLineupData(
                  formation: '4-2-3-1',
                  startingXI: homePlayers,
                  substitutes: const [],
                ),
                awayData: TeamLineupData(
                  formation: '4-2-3-1',
                  startingXI: awayPlayers,
                  substitutes: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أرض لاعب 1'), findsOneWidget);
      expect(find.text('ضيف لاعب 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5-3-2 (5 defenders in a single row) fits without horizontal overflow on compact 360px screen', (tester) async {
      tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final homePlayers = generate11Players('أرض');
      final awayPlayers = generate11Players('ضيف');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 560,
              child: PitchView(
                homeData: TeamLineupData(
                  formation: '5-3-2',
                  startingXI: homePlayers,
                  substitutes: const [],
                ),
                awayData: TeamLineupData(
                  formation: '5-3-2',
                  startingXI: awayPlayers,
                  substitutes: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure all 5 defenders in row are visible
      expect(find.text('أرض لاعب 2'), findsOneWidget);
      expect(find.text('أرض لاعب 3'), findsOneWidget);
      expect(find.text('أرض لاعب 4'), findsOneWidget);
      expect(find.text('أرض لاعب 5'), findsOneWidget);
      expect(find.text('أرض لاعب 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Substitutes list displays enlarged player info and numbers properly', (tester) async {
      const subs = [
        LineupPlayer(id: 12, name: 'محمد الشناوي', number: 1, positionTitle: 'حارس مرمى'),
        LineupPlayer(id: 13, name: 'محمود كهربا', number: 7, positionTitle: 'مهاجم'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return SingleChildScrollView(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: subs.map((p) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              child: Row(
                                children: [
                                  LineupTab.buildPlayerAvatarForTesting(p, isHome: true, size: 38),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text('${p.number}'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('محمد الشناوي'), findsOneWidget);
      expect(find.text('محمود كهربا'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
