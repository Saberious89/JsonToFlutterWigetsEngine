import 'package:dynamic_form_builder/doc_list_widget.dart';
import 'package:dynamic_form_builder/timer_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:syncfusion_flutter_gauges/gauges.dart';

typedef OnSubmit = void Function(Map<String, dynamic> values);
typedef SecondaryFunc = void Function(dynamic values);
typedef GetDocList = void Function(dynamic values);

class FormBuilderEngine extends StatefulWidget {
  final bool? isSubmitLoading;
  final bool isUploadLoading;
  final bool? isAllFilesUploaded;
  final Map<String, dynamic> formJson;
  final Map<String, dynamic>? initialData;
  final ValueNotifier<double>? uploadedProgress;
  // final int uploadedDocCount;
  final OnSubmit? onSubmit;
  final Function(dynamic) onUploadDone;
  final SecondaryFunc? onSecondaryCall;
  final Function(Map<String, dynamic> doc)? docUpload;

  const FormBuilderEngine({
    super.key,
    required this.formJson,
    this.initialData,
    this.onSubmit,
    this.onSecondaryCall,
    this.isSubmitLoading,
    this.uploadedProgress,
    this.docUpload,
    required this.isUploadLoading,
    // required this.uploadedDocCount,
    required this.onUploadDone,
    this.isAllFilesUploaded,
  });

  @override
  FormBuilderEngineState createState() => FormBuilderEngineState();
}

class FormBuilderEngineState extends State<FormBuilderEngine> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, dynamic>{};
  final _focusNodes = <String, FocusNode>{};
  // Map<String, dynamic>? _initialValues;
  List<Map<String, dynamic>>? allNumberFieldInitValue;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _initialValues = widget.initialData;
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void clearValues() {
    setState(() {
      _values.clear();
    });
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
    final props = widgetData['props'] as Map<dynamic, dynamic>? ?? {};
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
      case 'RsLabel':
        child = _buildRsLabel(props, css, wrapperCss);
        break;
      case 'MatAutoComplete':
        child = _buildMatAutoComplete(key, props, schema);
        break;
      case 'MatNumberField':
        child = _buildMatNumberField(key, props, schema,
            initValues: widget.initialData);
        break;
      case 'MatTextField':
        child = _buildMatTextField(key, props, schema,
            initValues: widget.initialData);
        break;
      case 'MobileTimerField':
        child = _buildTimer(key, props, schema);
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
        child = _buildMatUpload(key, props, schema,
            initalValues: widget.initialData);
        break;
      case 'MatButton':
        child = _buildMatButton(key, props, schema);
        break;
      case 'Guage':
        child = _buildGuage(key, props, schema);
        break;
      default:
        child = const SizedBox.shrink();
    }

    // Apply wrapper CSS if exists
    if (wrapperCss.isNotEmpty) {
      child = _applyWrapperCss(child, wrapperCss);
    }

    return Directionality(textDirection: TextDirection.rtl, child: child);
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

  Widget _buildRsLabel(Map<dynamic, dynamic> props, Map<String, dynamic> css,
      Map<String, dynamic> wrapperCss) {
    // Extract text value
    String textValue = props['text']?['value'] ?? '';

    // Handle text alignment
    TextAlign textAlign = TextAlign.start;
    switch (css['textAlign']) {
      case 'center':
        textAlign = TextAlign.center;
        break;
      case 'right':
        textAlign = TextAlign.right;
        break;
      case 'left':
        textAlign = TextAlign.left;
        break;
    }

    // Handle wrapper CSS (margin, padding, etc.)
    EdgeInsetsGeometry? margin;
    if (wrapperCss['marginBottom'] != null) {
      final value = wrapperCss['marginBottom'] as String;
      if (value.endsWith('px')) {
        final px = double.tryParse(value.replaceAll('px', '')) ?? 0.0;
        margin = EdgeInsets.only(bottom: px);
      }
    }

    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(textValue);

    final placeholders = matches.map((m) => m.group(1)).toList();
    if (placeholders.isNotEmpty &&
        (widget.initialData?['${placeholders.first}'] != null)) {
      textValue = (textValue).replaceAll('#${placeholders.first}',
          widget.initialData?['${placeholders.first}']);
    }

    final textWidget = Text(
      textValue,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 16,
      ),
    );

    if (margin != null) {
      return Container(
        margin: margin,
        child: textWidget,
      );
    } else {
      return textWidget;
    }
  }

  Widget _buildMatAutoComplete(
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema) {
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
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema,
      {Map<String, dynamic>? initValues}) {
    final label = _getStringValue(props['label']);

    final useThousandSeparator = _getBoolValue(props['useThousandSeparator']);
    _getBoolValue(props['amountInWords']);
    bool readOnly = false;
    bool required = false;
    int? maxLength;
    if (props['disabled'] != null) {
      readOnly = props['disabled']['value'];
    }
    if (props['required'] != null) {
      required = props['required']['value'];
    }
    if (props['maxLength'] != null) {
      maxLength = props['maxLength']['value'];
    }
    final showEndAdornment = _getBoolValue(props['showEndAdornment']);
    final validations = (props['requireValidationMessage'] != null &&
            props['requireValidationMessage'] != '')
        ? props['requireValidationMessage']['value']
        : _getValidations(schema);

    final lengthValidation = (props['maxLengthValidationMessage'] != null &&
            props['maxLengthValidationMessage'] != '')
        ? props['maxLengthValidationMessage']['value']
        : '';

    final controller =
        _controllers.putIfAbsent(key, () => TextEditingController());
    final focusNode = _focusNodes.putIfAbsent(key, () => FocusNode());
    if (initValues != null && initValues.containsKey(key) && key != 'otp') {
      controller.text = initValues[key];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          maxLength: maxLength,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (useThousandSeparator) ThousandsSeparatorInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            counterText: '',
            suffixIcon:
                showEndAdornment ? const Icon(Icons.attach_money) : null,
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return validations;
            }
            if (maxLength != null && value!.length > (maxLength)) {
              return lengthValidation;
            }
            return null;
            // return _validateField(value, validations);
          },
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

  Widget _buildTimer(
    String key,
    Map<dynamic, dynamic> props,
    Map<String, dynamic> schema,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TimerWidget(
          props: props,
          thisKey: key,
          schema: schema,
          onSocondaryCall: (val) => widget.onSecondaryCall?.call(val),
        ),
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
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema,
      {Map<String, dynamic>? initValues}) {
    final label = _getStringValue(props['label']);
    final validations = _getValidations(schema);

    final controller =
        _controllers.putIfAbsent(key, () => TextEditingController());
    final focusNode = _focusNodes.putIfAbsent(key, () => FocusNode());
    if (initValues != null && initValues.containsKey(key)) {
      controller.text = initValues[key];
    }

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
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']);
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
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema) {
    final label = _getStringValue(props['label']);
    final isActive = _getBoolValue(props['isActive']);
    final activeColor = _parseColor(props['activeColor']);
    _parseColor(props['diactiveColor']); // Note: typo in JSON 'diactiveColor'
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
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema) {
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
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema,
      {Map<String, dynamic>? initalValues}) {
    if (initalValues != null &&
        initalValues.isNotEmpty &&
        initalValues.containsKey(key)) {
      // widget.getDocCount!(initalValues[key].length);
      String customerId = initalValues['customerId'];
      String agreementId = initalValues['agreementId'];
      props['customerId'] = customerId;
      props['agreementId'] = agreementId;
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            Expanded(
              child: DocUploaderWidget(
                docList: initalValues[key],
                additionalParameters: [props],
                uploadedProgress:
                    widget.uploadedProgress ?? ValueNotifier<double>(0),
                isLoading: widget.isUploadLoading,
                // uploadedDocCount: widget.uploadedDocCount,
                upload: (doc) {
                  widget.docUpload!(doc);
                },
                onUploadDone: (val) {
                  widget.onUploadDone(val);
                },
              ),
            ),
            ElevatedButton(
                style: const ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(Colors.white)),
                onPressed: widget.isAllFilesUploaded == true
                    ? () {
                        widget.onUploadDone(null);
                        print('allDocPicked ***');
                      }
                    : null,
                child: const Text('تایید'))
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    // final label = _getStringValue(props['label']);
    // final validations = _getValidations(schema);

    // final uploadedFiles = _values[key] as List<String>? ?? [];

    // return FormField<List<String>>(
    //   initialValue: uploadedFiles,
    //   validator: (value) {
    //     final stringValue = value?.join(',') ?? '';
    //     return _validateField(stringValue, validations);
    //   },
    //   builder: (field) {
    //     return Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Container(
    //           width: double.infinity,
    //           padding: const EdgeInsets.all(16),
    //           decoration: BoxDecoration(
    //             border: Border.all(color: Colors.grey),
    //             borderRadius: BorderRadius.circular(4),
    //           ),
    //           child: Column(
    //             children: [
    //               Icon(
    //                 Icons.cloud_upload,
    //                 size: 48,
    //                 color: Colors.grey[600],
    //               ),
    //               const SizedBox(height: 8),
    //               Text(
    //                 label,
    //                 style: TextStyle(
    //                   fontSize: 16,
    //                   color: Colors.grey[700],
    //                 ),
    //               ),
    //               const SizedBox(height: 8),
    //               ElevatedButton(
    //                 onPressed: () {
    //                   // Simulate file selection
    //                   _simulateFileUpload(key, field);
    //                 },
    //                 child: const Text('انتخاب فایل'),
    //               ),
    //             ],
    //           ),
    //         ),
    //         if (uploadedFiles.isNotEmpty)
    //           Padding(
    //             padding: const EdgeInsets.only(top: 8.0),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: uploadedFiles.map((fileName) {
    //                 return Padding(
    //                   padding: const EdgeInsets.symmetric(vertical: 2.0),
    //                   child: Row(
    //                     children: [
    //                       const Icon(Icons.attachment, size: 16),
    //                       const SizedBox(width: 4),
    //                       Expanded(child: Text(fileName)),
    //                       IconButton(
    //                         icon: const Icon(Icons.close, size: 16),
    //                         onPressed: () {
    //                           setState(() {
    //                             uploadedFiles.remove(fileName);
    //                             _values[key] = uploadedFiles;
    //                           });
    //                           field.didChange(uploadedFiles);
    //                         },
    //                       ),
    //                     ],
    //                   ),
    //                 );
    //               }).toList(),
    //             ),
    //           ),
    //         if (field.hasError)
    //           Padding(
    //             padding: const EdgeInsets.only(top: 4.0),
    //             child: Text(
    //               field.errorText!,
    //               style: const TextStyle(color: Colors.red, fontSize: 12),
    //             ),
    //           ),
    //       ],
    //     );
    //   },
    // );
  }

  Widget _buildMatButton(
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema) {
    String? urlLink;
    final label = _getStringValue(props['label']);
    final backgroundColor = _parseColor(props['backgroundColor']);
    final textColor = _parseColor(props['textColor']) ?? Colors.white;
    final clickType = props['clickType']['value'];
    if (props['urlKey'] != null) {
      final urlKey = props['urlKey']['value'];

      urlLink = widget.initialData?[urlKey];
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: () {
          if (clickType == 'redirect') {
            openUrl(urlLink ?? '');
          } else {
            submitForm();
          }
        },
        child: widget.isSubmitLoading == true
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildGuage(
      String key, Map<dynamic, dynamic> props, Map<String, dynamic> schema) {
    double _scoreRate = 0.0;
    return Stack(
      children: [
        SfRadialGauge(axes: <RadialAxis>[
          RadialAxis(
              minimum: 250,
              maximum: 900,
              radiusFactor: 0.60,
              labelOffset: -50,
              tickOffset: 20,
              showLastLabel: true,
              centerY: 0.4,
              axisLabelStyle: const GaugeTextStyle(),
              ranges: <GaugeRange>[
                GaugeRange(
                    startWidth: 24,
                    endWidth: 24,
                    startValue: 250,
                    endValue: 460,
                    label: "خیلی ضعیف",
                    labelStyle: const GaugeTextStyle(color: Colors.white),
                    color: Colors.red),
                GaugeRange(
                    startWidth: 24,
                    endWidth: 24,
                    startValue: 460,
                    endValue: 520,
                    label: "ضعیف",
                    labelStyle: const GaugeTextStyle(
                      color: Colors.white,
                    ),
                    color: Colors.orange),
                GaugeRange(
                    startWidth: 24,
                    endWidth: 24,
                    startValue: 520,
                    endValue: 580,
                    label: "متوسط",
                    labelStyle: const GaugeTextStyle(color: Colors.white),
                    color: Colors.yellow.shade700),
                GaugeRange(
                    startWidth: 24,
                    endWidth: 24,
                    startValue: 580,
                    endValue: 640,
                    label: "خوب",
                    labelStyle: const GaugeTextStyle(
                      color: Colors.white,
                    ),
                    color: Colors.green.shade200),
                GaugeRange(
                    startWidth: 24,
                    endWidth: 24,
                    startValue: 640,
                    endValue: 900,
                    label: "خیلی خوب",
                    labelStyle: const GaugeTextStyle(
                      color: Colors.white,
                    ),
                    color: Colors.green)
              ],
              pointers: <GaugePointer>[
                NeedlePointer(value: double.parse((0).toString()))
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    widget: SizedBox(
                      height: 54,
                      child: Column(
                        children: [
                          Text((0).toString(),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('امتیاز اعتباری',
                              style: TextStyle(fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0.7)
              ])
        ]),
        Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.sizeOf(context).height * .32,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'رتبه اعتباری',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                '',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          const Text(
                            '',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'امتیاز شما',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _star(_scoreRate >= 1
                                    ? 0
                                    : _scoreRate < 0
                                        ? 2
                                        : 1),
                                _star(_scoreRate >= 2
                                    ? 0
                                    : _scoreRate < 1
                                        ? 2
                                        : 1),
                                _star(_scoreRate >= 3
                                    ? 0
                                    : _scoreRate < 2
                                        ? 2
                                        : 1),
                                _star(_scoreRate >= 4
                                    ? 0
                                    : _scoreRate < 3
                                        ? 2
                                        : 1),
                                _star(_scoreRate >= 5
                                    ? 0
                                    : _scoreRate < 4
                                        ? 2
                                        : 1),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ))
      ],
    );
  }

  Widget _star(int state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 2, 1, 0),
      child: Icon(
        state == 0
            ? CupertinoIcons.star_fill
            : state == 1
                ? CupertinoIcons.star_lefthalf_fill
                : CupertinoIcons.star,
        size: 16,
        color: state == 0 || state == 1
            ? const Color(0xffFFD700)
            : Colors.grey.shade300,
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

  void submitForm() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    widget.onSubmit?.call(_values);
  }

  void openUrl(String urlLink) {
    //
    // if (widget.initialData!.containsKey('paymentLinkForCreditValidation')) {
    //   widget.onSecondaryCall!.call({
    //     "redirectUrl": widget.initialData?['paymentLinkForCreditValidation']
    //   });
    // }

    widget.onSecondaryCall!.call({"redirectUrl": urlLink});
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
