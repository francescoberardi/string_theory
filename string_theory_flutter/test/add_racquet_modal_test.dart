import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:flutter_test/flutter_test.dart' hide test;
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/add_racquet_modal.dart';

/// ATDD Red-Phase test runner helper allowing `test.skip(...)` syntax in Dart.
// ignore: camel_case_types
class test {
  static void skip(
    String description,
    dynamic Function() body, {
    String? reason,
  }) {
    flutter_test.test(
      description,
      body,
      skip: reason ?? 'ATDD RED PHASE: Scaffold pending implementation',
    );
  }

  static void skipWidgets(
    String description,
    flutter_test.WidgetTesterCallback callback, {
    String? reason,
  }) {
    flutter_test.testWidgets(
      description,
      callback,
      skip: true,
    );
  }
}

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  late MockBagBloc mockBagBloc;

  setUpAll(() {
    registerFallbackValue(
      AddRacquet(
        name: 'Fallback Racquet',
        stringBrand: 'Babolat',
        stringModel: 'RPM Blast',
        tension: 52.0,
        maxRatedHours: 20.0,
        stringingDate: DateTime.utc(2026, 10, 1),
      ),
    );
  });

  setUp(() {
    mockBagBloc = MockBagBloc();
  });

  group('Story 1.4: Add Racquet Form with Smart Defaults & Presets', () {
    test.skipWidgets(
      '[P0] AC-1 should render AddRacquetModal with required racquet and string input fields',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: Scaffold(
              body: AddRacquetModal(bagBloc: mockBagBloc),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: modal name field exists
        expect(
          find.byKey(AddRacquetModal.keyNameField),
          findsOneWidget,
          reason: 'Racquet name / frame field must be rendered in AddRacquetModal',
        );

        // Secondary assertions for form inputs
        expect(find.byKey(AddRacquetModal.keyCategoryField), findsOneWidget);
        expect(find.byKey(AddRacquetModal.keyStringBrandField), findsOneWidget);
        expect(find.byKey(AddRacquetModal.keyStringModelField), findsOneWidget);
        expect(find.byKey(AddRacquetModal.keyTensionField), findsOneWidget);
        expect(find.byKey(AddRacquetModal.keyMaxHoursField), findsOneWidget);
        expect(find.byKey(AddRacquetModal.keyDateField), findsOneWidget);
        expect(find.byKey(AddRacquetModal.keyPresetRpmBlast), findsOneWidget);
        expect(find.byKey(AddRacquetModal.keySubmitButton), findsOneWidget);
      },
    );

    test.skipWidgets(
      '[P0] AC-2 should pre-populate Manufacturer Max Hours to 20.0 hrs when Co-Polyester category is selected',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: Scaffold(
              body: AddRacquetModal(bagBloc: mockBagBloc),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select Co-Polyester
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Co-Polyester').last);
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: Max hours pre-populates to 20.0 hrs
        final maxHoursFinder = find.byKey(AddRacquetModal.keyMaxHoursField);
        expect(
          find.descendant(of: maxHoursFinder, matching: find.text('20.0')),
          findsOneWidget,
          reason: 'Co-Polyester selection must automatically pre-populate max hours to 20.0 hrs',
        );
      },
    );

    test.skipWidgets(
      '[P0] AC-3 should pre-populate Max Hours for Multifilament (35h), Synthetic Gut (30h), Natural Gut (50h) and remain editable',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: Scaffold(
              body: AddRacquetModal(bagBloc: mockBagBloc),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Multifilament -> 35.0 hrs
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Multifilament').last);
        await tester.pumpAndSettle();
        expect(find.text('35.0'), findsOneWidget);

        // 2. Synthetic Gut -> 30.0 hrs
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Synthetic Gut').last);
        await tester.pumpAndSettle();
        expect(find.text('30.0'), findsOneWidget);

        // 3. Natural Gut -> 50.0 hrs
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Natural Gut').last);
        await tester.pumpAndSettle();
        expect(find.text('50.0'), findsOneWidget);

        // 4. User can manually edit the pre-populated hours
        await tester.enterText(find.byKey(AddRacquetModal.keyMaxHoursField), '45.0');
        await tester.pumpAndSettle();
        expect(find.text('45.0'), findsOneWidget);
      },
    );

    test.skipWidgets(
      '[P0] AC-4 should instantly fill racquet frame, string model, tension, and defaults when Popular Poly preset is tapped',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: Scaffold(
              body: AddRacquetModal(bagBloc: mockBagBloc),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap preset button
        await tester.tap(find.byKey(AddRacquetModal.keyPresetRpmBlast));
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: frame / name populated with Babolat Pure Aero
        expect(
          find.text('Babolat Pure Aero'),
          findsOneWidget,
          reason: 'Popular Poly preset must fill racquet frame name with Babolat Pure Aero',
        );

        // Secondary assertions: string specs and tension
        expect(find.text('Babolat'), findsWidgets);
        expect(find.text('RPM Blast'), findsOneWidget);
        expect(find.text('52.0'), findsOneWidget);
        expect(find.text('20.0'), findsOneWidget);
      },
    );

    test.skipWidgets(
      '[P0] AC-5 should validate form inputs and dispatch AddRacquet event to BagBloc upon submission',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: Scaffold(
              body: AddRacquetModal(bagBloc: mockBagBloc),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap preset to populate form quickly
        await tester.tap(find.byKey(AddRacquetModal.keyPresetRpmBlast));
        await tester.pumpAndSettle();

        // Tap Submit
        await tester.tap(find.byKey(AddRacquetModal.keySubmitButton));
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: BagBloc.add(AddRacquet(...)) is called
        verify(
          () => mockBagBloc.add(
            any(
              that: isA<AddRacquet>()
                  .having((e) => e.name, 'name', 'Babolat Pure Aero')
                  .having(
                    (e) => e.materialCategory,
                    'category',
                    StringMaterialCategory.coPoly,
                  )
                  .having((e) => e.stringBrand, 'stringBrand', 'Babolat')
                  .having((e) => e.stringModel, 'stringModel', 'RPM Blast')
                  .having((e) => e.tension, 'tension', 52.0)
                  .having((e) => e.maxRatedHours, 'maxRatedHours', 20.0),
            ),
          ),
        ).called(1);
      },
    );
  });
}
