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
        stringBrand: 'Baseline',
        stringModel: 'Spin Poly',
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
    testWidgets(
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
          reason:
              'Racquet name / frame field must be rendered in AddRacquetModal',
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

    testWidgets(
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
          reason:
              'Co-Polyester selection must automatically pre-populate max hours to 20.0 hrs',
        );
      },
    );

    testWidgets(
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
        await tester.enterText(
          find.byKey(AddRacquetModal.keyMaxHoursField),
          '45.0',
        );
        await tester.pumpAndSettle();
        expect(find.text('45.0'), findsOneWidget);
      },
    );

    testWidgets(
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

        // Criterion-defining primary assertion: frame / name populated with Baseline Spin 100
        expect(
          find.text('Baseline Spin 100'),
          findsOneWidget,
          reason:
              'Popular Poly preset must fill racquet frame name with Baseline Spin 100',
        );

        // Secondary assertions: string specs and tension
        expect(find.text('Baseline'), findsWidgets);
        expect(find.text('Spin Poly'), findsOneWidget);
        expect(find.text('52.0'), findsOneWidget);
        expect(find.text('20.0'), findsOneWidget);
      },
    );

    testWidgets(
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
                  .having((e) => e.name, 'name', 'Baseline Spin 100')
                  .having(
                    (e) => e.materialCategory,
                    'category',
                    StringMaterialCategory.coPoly,
                  )
                  .having((e) => e.stringBrand, 'stringBrand', 'Baseline')
                  .having((e) => e.stringModel, 'stringModel', 'Spin Poly')
                  .having((e) => e.tension, 'tension', 52.0)
                  .having((e) => e.maxRatedHours, 'maxRatedHours', 20.0),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '[Edge-Case] should prevent submission and show validation warnings when required fields are missing',
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

        // Attempt submission without filling fields
        await tester.tap(find.byKey(AddRacquetModal.keySubmitButton));
        await tester.pumpAndSettle();

        // Verify validation error messages are displayed
        expect(find.text('Racquet name is required'), findsOneWidget);
        expect(find.text('Please select a material category'), findsOneWidget);
        expect(find.text('String brand is required'), findsOneWidget);
        expect(find.text('String model is required'), findsOneWidget);
        expect(find.text('Tension is required'), findsOneWidget);
        expect(find.text('Max hours is required'), findsOneWidget);

        // Verify no event dispatched to BagBloc
        verifyNever(() => mockBagBloc.add(any()));
      },
    );

    testWidgets(
      '[Edge-Case] should allow manual entry of custom racquet and string specifications',
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

        // Enter frame details
        await tester.enterText(
          find.byKey(AddRacquetModal.keyNameField),
          'Wilson Pro Staff 97',
        );
        await tester.enterText(
          find.byKey(AddRacquetModal.keyBrandField),
          'Baseline',
        );
        await tester.enterText(
          find.byKey(AddRacquetModal.keyModelField),
          'Pro Staff 97',
        );

        // Select category
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Natural Gut').last);
        await tester.pumpAndSettle();

        // Enter string details
        await tester.enterText(
          find.byKey(AddRacquetModal.keyStringBrandField),
          'Baseline',
        );
        await tester.enterText(
          find.byKey(AddRacquetModal.keyStringModelField),
          'Poly Tour',
        );
        await tester.enterText(
          find.byKey(AddRacquetModal.keyTensionField),
          '54.5',
        );

        // Toggle primary switch
        await tester.tap(find.byKey(AddRacquetModal.keyPrimarySwitch));
        await tester.pumpAndSettle();

        // Submit form
        await tester.tap(find.byKey(AddRacquetModal.keySubmitButton));
        await tester.pumpAndSettle();

        // Verify custom event dispatched
        verify(
          () => mockBagBloc.add(
            any(
              that: isA<AddRacquet>()
                  .having((e) => e.name, 'name', 'Wilson Pro Staff 97')
                  .having((e) => e.brand, 'brand', 'Baseline')
                  .having((e) => e.model, 'model', 'Pro Staff 97')
                  .having((e) => e.isPrimary, 'isPrimary', true)
                  .having(
                    (e) => e.materialCategory,
                    'category',
                    StringMaterialCategory.naturalGut,
                  )
                  .having((e) => e.stringBrand, 'stringBrand', 'Baseline')
                  .having((e) => e.stringModel, 'stringModel', 'Poly Tour')
                  .having((e) => e.tension, 'tension', 54.5)
                  .having((e) => e.maxRatedHours, 'maxRatedHours', 50.0),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '[Edge-Case] should allow date picker selection and dispatch custom stringingDate',
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

        // Tap preset to populate basic fields
        await tester.tap(find.byKey(AddRacquetModal.keyPresetRpmBlast));
        await tester.pumpAndSettle();

        // Tap Date picker field
        await tester.tap(find.byKey(AddRacquetModal.keyDateField));
        await tester.pumpAndSettle();

        // Tap 1st day of month in date picker dialog and confirm
        await tester.tap(find.text('1').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Submit form
        await tester.tap(find.byKey(AddRacquetModal.keySubmitButton));
        await tester.pumpAndSettle();

        // Verify stringingDate day was dispatched as 1
        verify(
          () => mockBagBloc.add(
            any(
              that: isA<AddRacquet>().having(
                (e) => e.stringingDate.day,
                'stringingDate.day',
                1,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '[Edge-Case] should show validation errors for invalid, negative, or non-numeric tension and max hours',
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

        // Fill valid name, brand, category, string
        await tester.tap(find.byKey(AddRacquetModal.keyPresetRpmBlast));
        await tester.pumpAndSettle();

        // Enter non-numeric / negative values
        await tester.enterText(
          find.byKey(AddRacquetModal.keyTensionField),
          'not-a-number',
        );
        await tester.enterText(
          find.byKey(AddRacquetModal.keyMaxHoursField),
          '-5.0',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(AddRacquetModal.keySubmitButton));
        await tester.pumpAndSettle();

        expect(find.text('Invalid tension'), findsOneWidget);
        expect(find.text('Invalid max hours'), findsOneWidget);
        verifyNever(() => mockBagBloc.add(any()));
      },
    );

    testWidgets(
      '[Edge-Case] should pre-populate smart defaults for Kevlar (25h), Hybrid (25h), and Other (20h)',
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

        // 1. Kevlar -> 25.0 hrs
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kevlar').last);
        await tester.pumpAndSettle();
        expect(find.text('25.0'), findsOneWidget);

        // 2. Hybrid -> 25.0 hrs
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hybrid').last);
        await tester.pumpAndSettle();
        expect(find.text('25.0'), findsOneWidget);

        // 3. Other -> 20.0 hrs
        await tester.tap(find.byKey(AddRacquetModal.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Other').last);
        await tester.pumpAndSettle();
        expect(find.text('20.0'), findsOneWidget);
      },
    );

    testWidgets(
      '[Edge-Case] should update category dropdown display to Co-Polyester after preset tap',
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

        // Verify category dropdown displays 'Co-Polyester'
        expect(
          find.descendant(
            of: find.byKey(AddRacquetModal.keyCategoryField),
            matching: find.text('Co-Polyester'),
          ),
          findsOneWidget,
          reason:
              'Category dropdown must display Co-Polyester after preset is tapped',
        );
      },
    );
  });
}
