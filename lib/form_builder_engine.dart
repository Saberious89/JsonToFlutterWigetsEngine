import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

typedef OnSubmit = void Function(Map<String, dynamic> values);

class FormBuilderEngine extends StatefulWidget {
  final Map<String, dynamic> formJson;
  final OnSubmit? onSubmit;

  const FormBuilderEngine({
    super.key,
    required this.formJson,
    this.onSubmit,
  });

  @override
  _FormBuilderEngineState createState() => _FormBuilderEngineState();
}

class _FormBuilderEngineState extends State<FormBuilderEngine> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, dynamic>{};
  final _focusNodes = <String, FocusNode>{};

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _focusNodes.values.forEach((f) => f.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.formJson['form'] as Map<String, dynamic>?;
    if (form == null) return const SizedBox.shrink();

    return Form(
      key: _formKey,
      child: _buildWidget(form),
    );
  }

  Widget _buildWidget(Map<String, dynamic> widgetData) {
    final type = widgetData['type'] as String? ?? '';
    final key = widgetData['key'] as String? ?? '';
    final props = widgetData['props'] as Map<String, dynamic>? ?? {};
    final css = widgetData['css'] as Map<String, dynamic>? ?? {};
    final wrapperCss = widgetData['wrapperCss'] as Map<String, dynamic>? ?? {};
    final children = widgetData['children'] as List? ?? [];
    final schema = widgetData['schema'] as Map<String, dynamic>? ?? {};

    Widget child;

    switch (type) {
      case 'Screen':
        child = _buildScreen(children);
        break;
      case 'RsContainer':
        child = _buildRsContainer(children, css);
        break;
      case 'MatAutoComplete':
        child = _buildMatAutoComplete(key, props, schema);
        break;
      case 'MatNumberField':
        child = _buildMatNumberField(key, props, schema);
        break;
      case 'MatTextField':
        child = _buildMatTextField(key, props, schema);
        break;
      case 'MatDatePicker':
        child = _buildMatDatePicker(key, props, schema);
        break;
      case 'Checkbox':
        child = _buildCheckbox(key, props, schema);
        break;
      case 'radioButton':
        child = _buildRadioButton(key, props, schema);
        break;
      case 'MatUpload':
        child = _buildMatUpload(key, props, schema);
        break;
      case 'MatButton':
        child = _buildMatButton(key, props, schema);
        break;
      default:
        child = const SizedBox.shrink();
    }

    // Apply wrapper CSS if exists
    if (wrapperCss.isNotEmpty) {
      child = _applyWrapperCss(child, wrapperCss);
    }

    return child;
  }

  Widget _buildScreen(List children) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .cast<Map<String, dynamic>>()
                .map((child) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildWidget(child),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRsContainer(List children, Map<String, dynamic> css) {
    final flexDirection = _getFlexDirection(css);
    final flexWrap = _getFlexWrap(css);

    if (flexDirection == Axis.horizontal && flexWrap) {
      return Wrap(
        direction: Axis.horizontal,
        spacing: 8.0,
        runSpacing: 8.0,
        children: children
            .cast<Map<String, dynamic>>()
            .map((child) => _buildWidget(child))
            .toList(),
      );
    } else {
      return Flex(
        direction: flexDirection,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .cast<Map<String, dynamic>>()
            .map((child) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: _buildWidget(child),
                ))
            .toList(),
      );
    }
  }

  Widget _buildMatAutoComplete(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']);
    final type = _getStringValue(props['type']);
    final additionalDetailsJson = _getStringValue(props['additionalDetails']);
    final validations = _getValidations(schema);

    List<Map<String, dynamic>> additionalDetails = [];
    if (additionalDetailsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(additionalDetailsJson);
        if (decoded is List) {
          additionalDetails = decoded.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        print('Error parsing additionalDetails: $e');
      }
    }

    // Get dropdown options based on type - you'll need to implement this data source
    final options = _getDropdownOptions(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          value: _values[key],
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label'] ?? ''),
            );
          }).toList(),
          validator: (value) => _validateField(value, validations),
          onChanged: (value) {
            setState(() {
              _values[key] = value;
            });
          },
          onSaved: (value) => _values[key] = value,
        ),
        if (additionalDetails.isNotEmpty && _values[key] != null)
          ...additionalDetails.map((detail) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${detail['label']}: ${_getDetailValue(detail['value'])}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              )),
      ],
    );
  }

  Widget _buildMatNumberField(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']);
    final useThousandSeparator = _getBoolValue(props['useThousandSeparator']);
    final amountInWords = _getBoolValue(props['amountInWords']);
    final showEndAdornment = _getBoolValue(props['showEndAdornment']);
    final validations = _getValidations(schema);

    final controller =
        _controllers.putIfAbsent(key, () => TextEditingController());
    final focusNode = _focusNodes.putIfAbsent(key, () => FocusNode());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (useThousandSeparator) ThousandsSeparatorInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon:
                showEndAdornment ? const Icon(Icons.attach_money) : null,
          ),
          validator: (value) => _validateField(value, validations),
          onChanged: (value) {
            setState(() {
              _values[key] = value;
            });
          },
          onSaved: (value) => _values[key] = value,
        ),
        // if (amountInWords && _values[key] != null && _values[key].toString().isNotEmpty)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 4.0),
        //     child: Text(
        //       _numberToWords(_values[key].toString().replaceAll(',', '')),
        //       style: const TextStyle(color: Colors.blue, fontSize: 12),
        //     ),
        //   ),
      ],
    );
  }

  Widget _applyWrapperCss(Widget child, Map<String, dynamic> wrapperCss) {
    final anyStyles = wrapperCss['any'] as Map<String, dynamic>? ?? {};
    final objectStyles = anyStyles['object'] as Map<String, dynamic>? ?? {};

    double? width;
    double? height;

    if (objectStyles['width'] != null) {
      final widthStr = objectStyles['width'].toString();
      if (widthStr.endsWith('px')) {
        width = double.tryParse(widthStr.replaceAll('px', ''));
      }
    }

    if (objectStyles['height'] != null) {
      final heightStr = objectStyles['height'].toString();
      if (heightStr.endsWith('px')) {
        height = double.tryParse(heightStr.replaceAll('px', ''));
      }
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }

    return child;
  }

  Axis _getFlexDirection(Map<String, dynamic> css) {
    final anyStyles = css['any'] as Map<String, dynamic>? ?? {};
    final objectStyles = anyStyles['object'] as Map<String, dynamic>? ?? {};
    final flexDirection = objectStyles['flexDirection'] as String? ?? 'column';
    return flexDirection == 'row' ? Axis.horizontal : Axis.vertical;
  }

  bool _getFlexWrap(Map<String, dynamic> css) {
    final anyStyles = css['any'] as Map<String, dynamic>? ?? {};
    final objectStyles = anyStyles['object'] as Map<String, dynamic>? ?? {};
    final flexWrap = objectStyles['flexWrap'] as String? ?? 'nowrap';
    return flexWrap == 'wrap';
  }

  String _getStringValue(dynamic prop) {
    if (prop is Map<String, dynamic> && prop.containsKey('value')) {
      return prop['value']?.toString() ?? '';
    }
    return prop?.toString() ?? '';
  }

  bool _getBoolValue(dynamic prop) {
    if (prop is Map<String, dynamic> && prop.containsKey('value')) {
      return prop['value'] == true;
    }
    return prop == true;
  }

  List<Map<String, dynamic>> _getValidations(Map<String, dynamic> schema) {
    final validations = schema['validations'] as List? ?? [];
    return validations.cast<Map<String, dynamic>>();
  }

  String? _validateField(
      String? value, List<Map<String, dynamic>> validations) {
    for (final validation in validations) {
      final key = validation['key'] as String? ?? '';
      final args = validation['args'] as Map<String, dynamic>? ?? {};
      final message = args['message'] as String? ?? 'Invalid value';

      switch (key) {
        case 'required':
          if (value == null || value.trim().isEmpty) {
            return message;
          }
          break;
        case 'code':
          final code = args['code'] as String? ?? '';
          // Simple evaluation for the given example
          if (code.contains("return value===''") && value == '') {
            return message;
          }
          break;
      }
    }
    return null;
  }

  List<Map<String, String>> _getDropdownOptions(String type) {
    // This would typically fetch from a data source or API
    // For demo purposes, returning sample data based on type
    switch (type) {
      case 'cost_center':
        return [
          {'value': 'cc1', 'label': 'مرکز هزینه ۱ - تولید'},
          {'value': 'cc2', 'label': 'مرکز هزینه ۲ - فروش'},
          {'value': 'cc3', 'label': 'مرکز هزینه ۳ - اداری'},
          {'value': 'cc4', 'label': 'مرکز هزینه ۴ - پژوهش'},
        ];
      default:
        return [
          {'value': 'option1', 'label': 'گزینه ۱'},
          {'value': 'option2', 'label': 'گزینه ۲'},
        ];
    }
  }

  String _getDetailValue(String key) {
    // This would typically fetch from a data source based on selected cost center
    // For demo purposes, returning placeholder values
    final selectedCostCenter = _values['costCenterId'];
    if (selectedCostCenter == null) return '';

    switch (key) {
      case 'outputAmount':
        // Return different values based on selected cost center
        switch (selectedCostCenter) {
          case 'cc1':
            return '5,000,000';
          case 'cc2':
            return '3,000,000';
          case 'cc3':
            return '2,000,000';
          case 'cc4':
            return '4,000,000';
          default:
            return '0';
        }
      case 'remainingAmount':
        switch (selectedCostCenter) {
          case 'cc1':
            return '2,500,000';
          case 'cc2':
            return '1,500,000';
          case 'cc3':
            return '1,000,000';
          case 'cc4':
            return '2,000,000';
          default:
            return '0';
        }
      default:
        return '';
    }
  }

  Widget _buildMatTextField(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']);
    final validations = _getValidations(schema);

    final controller =
        _controllers.putIfAbsent(key, () => TextEditingController());
    final focusNode = _focusNodes.putIfAbsent(key, () => FocusNode());

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => _validateField(value, validations),
      onChanged: (value) {
        setState(() {
          _values[key] = value;
        });
      },
      onSaved: (value) => _values[key] = value,
    );
  }

  Widget _buildMatDatePicker(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']) ?? 'تاریخ را انتخاب کنید';
    final validations = _getValidations(schema);

    final controller =
        _controllers.putIfAbsent(key, () => TextEditingController());

    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      validator: (value) => _validateField(value, validations),
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );

        if (selectedDate != null) {
          final formattedDate =
              '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}';
          controller.text = formattedDate;
          setState(() {
            _values[key] = formattedDate;
          });
        }
      },
      onSaved: (value) => _values[key] = value,
    );
  }

  Widget _buildCheckbox(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']);
    final isActive = _getBoolValue(props['isActive']);
    final activeColor = _parseColor(props['activeColor']);
    final inactiveColor = _parseColor(
        props['diactiveColor']); // Note: typo in JSON 'diactiveColor'
    final validations = _getValidations(schema);

    final currentValue = _values[key] as bool? ?? isActive;

    return FormField<bool>(
      initialValue: currentValue,
      validator: (value) {
        // Convert bool validation to string for reuse
        final stringValue = value?.toString() ?? 'false';
        return _validateField(stringValue, validations);
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: currentValue,
                  activeColor: activeColor,
                  onChanged: (value) {
                    setState(() {
                      _values[key] = value ?? false;
                    });
                    field.didChange(value);
                  },
                ),
                if (label.isNotEmpty)
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRadioButton(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final isActive = _getBoolValue(props['isActive']);
    final activeColor = _parseColor(props['activeColor']);
    final validations = _getValidations(schema);

    final currentValue = _values[key] as bool? ?? isActive;

    return FormField<bool>(
      initialValue: currentValue,
      validator: (value) {
        final stringValue = value?.toString() ?? 'false';
        return _validateField(stringValue, validations);
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<bool>(
              value: true,
              groupValue: currentValue,
              activeColor: activeColor,
              onChanged: (value) {
                setState(() {
                  _values[key] = value ?? false;
                });
                field.didChange(value);
              },
            ),
            if (field.hasError)
              Text(
                field.errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMatUpload(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']) ?? 'آپلود فایل';
    final validations = _getValidations(schema);

    final uploadedFiles = _values[key] as List<String>? ?? [];

    return FormField<List<String>>(
      initialValue: uploadedFiles,
      validator: (value) {
        final stringValue = value?.join(',') ?? '';
        return _validateField(stringValue, validations);
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Simulate file selection
                      _simulateFileUpload(key, field);
                    },
                    child: const Text('انتخاب فایل'),
                  ),
                ],
              ),
            ),
            if (uploadedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: uploadedFiles.map((fileName) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          const Icon(Icons.attachment, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(fileName)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                uploadedFiles.remove(fileName);
                                _values[key] = uploadedFiles;
                              });
                              field.didChange(uploadedFiles);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMatButton(
      String key, Map<String, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']) ?? 'ارسال';
    final backgroundColor = _parseColor(props['backgroundColor']);
    final textColor = _parseColor(props['textColor']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: () => submitForm(),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color? _parseColor(dynamic colorProp) {
    final colorString = _getStringValue(colorProp);
    if (colorString.isEmpty) return null;

    // Parse rgba(r, g, b, a) format
    final rgbaMatch = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([0-9.]+)\)')
        .firstMatch(colorString);
    if (rgbaMatch != null) {
      final r = int.parse(rgbaMatch.group(1)!);
      final g = int.parse(rgbaMatch.group(2)!);
      final b = int.parse(rgbaMatch.group(3)!);
      final a = double.parse(rgbaMatch.group(4)!);
      return Color.fromRGBO(r, g, b, a);
    }

    // Parse hex format
    if (colorString.startsWith('#')) {
      final hex = colorString.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }

    return null;
  }

  void _simulateFileUpload(String key, FormFieldState<List<String>> field) {
    // Simulate file picker - in real app, you'd use file_picker package
    final uploadedFiles = _values[key] as List<String>? ?? [];
    final newFileName = 'file_${DateTime.now().millisecondsSinceEpoch}.pdf';

    setState(() {
      uploadedFiles.add(newFileName);
      _values[key] = uploadedFiles;
    });

    field.didChange(uploadedFiles);
  }

  void submitForm() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    widget.onSubmit?.call(_values);
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = newValue.text.replaceAll(',', '');
    if (int.tryParse(number) == null) {
      return oldValue;
    }

    final formattedText = _addThousandsSeparator(number);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _addThousandsSeparator(String number) {
    final reversed = number.split('').reversed.join('');
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final end = i + 3;
      chunks.add(
          reversed.substring(i, end > reversed.length ? reversed.length : end));
    }

    return chunks.join(',').split('').reversed.join('');
  }
}
