import 'package:dynamic_form_builder/form_builder_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'test_utils.dart';

void main() {
  group('FormBuilderEngine Tests', () {
    testWidgets('should render empty form when formJson is invalid',
        (WidgetTester tester) async {
      const formJson = <String, dynamic>{};

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should render Screen with SafeArea and SingleChildScrollView',
        (WidgetTester tester) async {
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [],
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should render MatNumberField with correct properties',
        (WidgetTester tester) async {
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'MatNumberField',
              'key': 'amount',
              'props': {
                'label': {'value': 'Amount'},
                'useThousandSeparator': {'value': true},
                'amountInWords': {'value': true},
                'showEndAdornment': {'value': true},
              },
              'schema': {
                'validations': [
                  {
                    'key': 'required',
                    'args': {'message': 'Amount is required'}
                  }
                ]
              }
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('should render MatAutoComplete with dropdown options',
        (WidgetTester tester) async {
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'MatAutoComplete',
              'key': 'costCenterId',
              'props': {
                'label': {'value': 'Cost Center'},
                'type': {'value': 'cost_center'},
                'additionalDetails': {'value': '[]'},
              },
              'schema': {
                'validations': [
                  {
                    'key': 'required',
                    'args': {'message': 'Cost Center is required'}
                  }
                ]
              }
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Cost Center'), findsOneWidget);
    });

    testWidgets('should render RsContainer with flex layout',
        (WidgetTester tester) async {
      disableOverflowErrors();
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'RsContainer',
              'css': {
                'any': {
                  'object': {'flexDirection': 'row', 'flexWrap': 'nowrap'}
                }
              },
              'children': [
                {
                  'type': 'MatNumberField',
                  'key': 'field1',
                  'props': {
                    'label': {'value': 'Field 1'}
                  },
                  'schema': {'validations': []}
                },
                {
                  'type': 'MatNumberField',
                  'key': 'field2',
                  'props': {
                    'label': {'value': 'Field 2'}
                  },
                  'schema': {'validations': []}
                }
              ]
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      expect(find.byType(Flex), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should render RsContainer with wrap layout',
        (WidgetTester tester) async {
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'RsContainer',
              'css': {
                'any': {
                  'object': {'flexDirection': 'row', 'flexWrap': 'wrap'}
                }
              },
              'children': [
                {
                  'type': 'MatNumberField',
                  'key': 'field1',
                  'props': {
                    'label': {'value': 'Field 1'}
                  },
                  'schema': {'validations': []}
                }
              ]
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'MatNumberField',
              'key': 'amount',
              'props': {
                'label': {'value': 'Amount'}
              },
              'schema': {
                'validations': [
                  {
                    'key': 'required',
                    'args': {'message': 'Amount is required'}
                  }
                ]
              }
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      // Find the form and trigger validation
      final form = find.byType(Form);
      final formState = tester.state<FormState>(form);

      // Validate without entering any data
      final isValid = formState.validate();
      await tester.pump();

      expect(isValid, isFalse);
      expect(find.text('Amount is required'), findsOneWidget);
    });

    testWidgets('should handle dropdown selection and show additional details',
        (WidgetTester tester) async {
      final additionalDetails = [
        {'label': 'Output Amount', 'value': 'outputAmount'},
        {'label': 'Remaining Amount', 'value': 'remainingAmount'}
      ];

      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'MatAutoComplete',
              'key': 'costCenterId',
              'props': {
                'label': {'value': 'Cost Center'},
                'type': {'value': 'cost_center'},
                'additionalDetails': {'value': jsonEncode(additionalDetails)},
              },
              'schema': {'validations': []}
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select an option
      await tester.tap(find.text('مرکز هزینه ۱ - تولید').last);
      await tester.pumpAndSettle();

      // Check if additional details are shown
      expect(find.textContaining('Output Amount:'), findsOneWidget);
      expect(find.textContaining('Remaining Amount:'), findsOneWidget);
    });

    testWidgets('should format numbers with thousands separator',
        (WidgetTester tester) async {
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'MatNumberField',
              'key': 'amount',
              'props': {
                'label': {'value': 'Amount'},
                'useThousandSeparator': {'value': true},
              },
              'schema': {'validations': []}
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      // Enter a number
      await tester.enterText(find.byType(TextFormField), '1234567');
      await tester.pump();

      // Check if the number is formatted with thousands separator
      expect(find.text('1,234,567'), findsOneWidget);
    });

    testWidgets('should show amount in words when enabled',
        (WidgetTester tester) async {
      final formJson = {
        'form': {
          'type': 'Screen',
          'children': [
            {
              'type': 'MatNumberField',
              'key': 'amount',
              'props': {
                'label': {'value': 'Amount'},
                'amountInWords': {'value': true},
              },
              'schema': {'validations': []}
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FormBuilderEngine(
            formJson: formJson,
          ),
        ),
      );

      // Enter a number
      await tester.enterText(find.byType(TextFormField), '1000');
      await tester.pump();

      // Check if amount in words is shown
      expect(find.textContaining('مبلغ به حروف:'), findsOneWidget);
    });
  });

  group('ThousandsSeparatorInputFormatter Tests', () {
    late ThousandsSeparatorInputFormatter formatter;

    setUp(() {
      formatter = ThousandsSeparatorInputFormatter();
    });

    test('should format numbers with thousands separator', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '1234567');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('1,234,567'));
    });

    test('should handle empty input', () {
      const oldValue = TextEditingValue(text: '123');
      const newValue = TextEditingValue(text: '');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals(''));
    });

    test('should reject non-numeric input', () {
      const oldValue = TextEditingValue(text: '123');
      const newValue = TextEditingValue(text: '123abc');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('123'));
    });

    test('should handle single digit', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '5');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('5'));
    });

    test('should handle numbers less than 1000', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '999');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('999'));
    });

    test('should format large numbers correctly', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '1234567890');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('1,234,567,890'));
    });
  });
}
