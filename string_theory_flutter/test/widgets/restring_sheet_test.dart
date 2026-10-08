import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/restring_sheet.dart';

class MockBagBloc extends Mock implements BagBloc {}

class FakeBagEvent extends Fake implements BagEvent {}

void main() {
  late MockBagBloc mockBagBloc;

  final racquet = Racquet(
    id: 7,
    userId: Namespace.nil.uuidValue,
    name: 'Wilson Blade 98',
    isPrimary: true,
    activeStringJob: StringJob(
      id: 70,
      userId: Namespace.nil.uuidValue,
      racquetId: 7,
      materialCategory: StringMaterialCategory.coPoly,
      brand: 'Luxilon',
      model: 'ALU Power',
      stringingDate: DateTime.utc(2026, 8, 1),
      installedTension: 52.0,
      maxRatedHours: 20.0,
      totalCourtHours: 18.0,
      currentHealthScore: 30,
      isActive: true,
      createdAt: DateTime.utc(2026, 8, 1),
    ),
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeBagEvent());
  });

  setUp(() {
    mockBagBloc = MockBagBloc();
  });

  Future<void> openSheet(WidgetTester tester, {Racquet? subject}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CourtMidnightTheme.themeData,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => RestringSheet.show(
                context,
                racquet: subject ?? racquet,
                bagBloc: mockBagBloc,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> expandChangeSpecs(WidgetTester tester) async {
    await tester.tap(find.byKey(RestringSheet.keyChangeSpecsToggle));
    await tester.pumpAndSettle();
  }

  Future<void> submitSpecs(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(RestringSheet.keySubmitButton));
    await tester.tap(find.byKey(RestringSheet.keySubmitButton));
    await tester.pumpAndSettle();
  }

  group('Story 4.2: RestringSheet', () {
    testWidgets('shows both options with the specs form collapsed', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.byKey(RestringSheet.keySheet), findsOneWidget);
      expect(find.text('Wilson Blade 98'), findsOneWidget);
      expect(find.byKey(RestringSheet.keyKeepSameButton), findsOneWidget);
      expect(find.byKey(RestringSheet.keyChangeSpecsToggle), findsOneWidget);
      expect(find.text('Keep Same & Reset'), findsOneWidget);
      expect(find.text('Change Specs'), findsOneWidget);
      expect(find.byKey(RestringSheet.keyBrandField), findsNothing);
      expect(find.byKey(RestringSheet.keySubmitButton), findsNothing);
    });

    testWidgets(
      'Keep Same & Reset dispatches keepSame and closes in one tap',
      (tester) async {
        await openSheet(tester);

        await tester.tap(find.byKey(RestringSheet.keyKeepSameButton));
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(const RestringRacquet(7, keepSame: true)),
        ).called(1);
        expect(find.byKey(RestringSheet.keySheet), findsNothing);
      },
    );

    testWidgets('Change Specs expands fields prefilled from the active job', (
      tester,
    ) async {
      await openSheet(tester);
      await expandChangeSpecs(tester);

      String textOf(Key key) =>
          tester.widget<TextFormField>(find.byKey(key)).controller!.text;
      expect(textOf(RestringSheet.keyBrandField), 'Luxilon');
      expect(textOf(RestringSheet.keyModelField), 'ALU Power');
      expect(textOf(RestringSheet.keyTensionField), '52.0');
      expect(find.text('Co-Polyester'), findsOneWidget);
      verifyNever(() => mockBagBloc.add(any()));
    });

    testWidgets(
      'submitting edited specs dispatches keepSame false and keeps max hours when the category is unchanged',
      (tester) async {
        await openSheet(tester);
        await expandChangeSpecs(tester);

        await tester.enterText(
          find.byKey(RestringSheet.keyBrandField),
          'Babolat',
        );
        await tester.enterText(
          find.byKey(RestringSheet.keyModelField),
          'RPM Blast',
        );
        await tester.enterText(
          find.byKey(RestringSheet.keyTensionField),
          '54.5',
        );
        await submitSpecs(tester);

        verify(
          () => mockBagBloc.add(
            const RestringRacquet(
              7,
              keepSame: false,
              materialCategory: StringMaterialCategory.coPoly,
              stringBrand: 'Babolat',
              stringModel: 'RPM Blast',
              tension: 54.5,
              maxRatedHours: 20.0,
            ),
          ),
        ).called(1);
        expect(find.byKey(RestringSheet.keySheet), findsNothing);
      },
    );

    testWidgets('changing the category applies that category max hours', (
      tester,
    ) async {
      await openSheet(tester);
      await expandChangeSpecs(tester);

      await tester.ensureVisible(find.byKey(RestringSheet.keyCategoryField));
      await tester.tap(find.byKey(RestringSheet.keyCategoryField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Multifilament').last);
      await tester.pumpAndSettle();
      await submitSpecs(tester);

      verify(
        () => mockBagBloc.add(
          const RestringRacquet(
            7,
            keepSame: false,
            materialCategory: StringMaterialCategory.multifilament,
            stringBrand: 'Luxilon',
            stringModel: 'ALU Power',
            tension: 52.0,
            maxRatedHours: 35.0,
          ),
        ),
      ).called(1);
    });

    testWidgets('blank brand or model and invalid tension block submit', (
      tester,
    ) async {
      await openSheet(tester);
      await expandChangeSpecs(tester);

      await tester.enterText(find.byKey(RestringSheet.keyBrandField), '  ');
      await tester.enterText(find.byKey(RestringSheet.keyModelField), '');
      await tester.enterText(find.byKey(RestringSheet.keyTensionField), '0');
      await submitSpecs(tester);

      expect(find.text('String brand is required'), findsOneWidget);
      expect(find.text('String model is required'), findsOneWidget);
      expect(find.text('Invalid tension'), findsOneWidget);
      verifyNever(() => mockBagBloc.add(any()));
      expect(find.byKey(RestringSheet.keySheet), findsOneWidget);
    });

    testWidgets('non-numeric tension is rejected', (tester) async {
      await openSheet(tester);
      await expandChangeSpecs(tester);

      await tester.enterText(find.byKey(RestringSheet.keyTensionField), 'abc');
      await submitSpecs(tester);

      expect(find.text('Invalid tension'), findsOneWidget);
      verifyNever(() => mockBagBloc.add(any()));
    });

    testWidgets('prefills tension without rounding and submits it unchanged', (
      tester,
    ) async {
      final preciseJob = racquet.activeStringJob!.copyWith(
        installedTension: 52.25,
      );
      await openSheet(
        tester,
        subject: racquet.copyWith(activeStringJob: preciseJob),
      );
      await expandChangeSpecs(tester);

      expect(
        tester
            .widget<TextFormField>(find.byKey(RestringSheet.keyTensionField))
            .controller!
            .text,
        '52.25',
      );
      await submitSpecs(tester);
      verify(
        () => mockBagBloc.add(
          any(
            that: isA<RestringRacquet>().having(
              (e) => e.tension,
              'tension',
              52.25,
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets(
      're-selecting the current category keeps a custom max hours value',
      (tester) async {
        final customJob = racquet.activeStringJob!.copyWith(
          maxRatedHours: 25.0,
        );
        await openSheet(
          tester,
          subject: racquet.copyWith(activeStringJob: customJob),
        );
        await expandChangeSpecs(tester);

        await tester.ensureVisible(find.byKey(RestringSheet.keyCategoryField));
        await tester.tap(find.byKey(RestringSheet.keyCategoryField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Co-Polyester').last);
        await tester.pumpAndSettle();
        await submitSpecs(tester);

        verify(
          () => mockBagBloc.add(
            any(
              that: isA<RestringRacquet>().having(
                (e) => e.maxRatedHours,
                'maxRatedHours',
                25.0,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('collapsing Change Specs hides the form again', (tester) async {
      await openSheet(tester);
      await expandChangeSpecs(tester);
      expect(find.byKey(RestringSheet.keyBrandField), findsOneWidget);

      await expandChangeSpecs(tester);
      expect(find.byKey(RestringSheet.keyBrandField), findsNothing);
    });
  });
}
