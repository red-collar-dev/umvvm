import 'dart:async';

import 'package:flutter/material.dart';
import 'package:umvvm/umvvm.dart';

typedef ValidatorsMap = Map<GlobalKey, Future<FieldValidationState> Function()>;

/// Mixin with helper methods to create form views
mixin FormViewModelMixin<Widget extends StatefulWidget, State>
    on BaseViewModel<Widget, State> {
  final Map<GlobalKey, Observable<FieldValidationState>> fieldStates = {};
  final Map<GlobalKey, Future<FieldValidationState> Function()>
      _actualValidators = {};

  final _disable = Observable.initial(false);

  /// Stream of disable flags
  Stream<bool> get disableStream =>
      _disable.stream.map((event) => event.next ?? false);

  /// Returns true if form is currently disabled
  bool get isFormDisabled => _disable.current ?? false;

  /// Map of validators for current form
  ValidatorsMap get validators;

  /// Stream of [FieldValidationState] for given field key
  Stream<FieldValidationState?> fieldStateStream(GlobalKey key) {
    return fieldStates[key]!.stream.map((event) => event.next);
  }

  /// Current value of [FieldValidationState] for given field key
  FieldValidationState? currentFieldState(GlobalKey key) {
    return fieldStates[key]!.current;
  }

  /// Returns validator for given field key
  Future<FieldValidationState> validatorForKey(GlobalKey key) {
    return _actualValidators[key]!();
  }

  /// Runs all registered validators for this form
  Future<bool> validateAllFields() async {
    var result = true;

    for (final element in _actualValidators.keys) {
      final validationFunction = _actualValidators[element];

      final validationResult = await validationFunction!();
      updateFieldState(element, validationResult);

      result &= validationResult is! ErrorFieldState;
    }

    return result;
  }

  /// Updates [FieldValidationState] for given field key
  void updateFieldState(GlobalKey key, FieldValidationState state) {
    fieldStates[key]!.update(state);
  }

  @override
  @mustCallSuper
  void onLaunch(widget) {
    prefillFields();
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();

    fieldStates.forEach((key, value) {
      value.dispose();
    });
  }

  /// Prefills all field in form
  /// This is run when view model is created
  @mustCallSuper
  void prefillFields() {
    for (final key in validators.keys) {
      fieldStates[key] = Observable.initial(IgnoredFieldState());

      _actualValidators[key] = () => validators[key]!().then(
            (value) {
              fieldStates[key]!.update(value);

              return value;
            },
          );
    }
  }

  /// Runs action when submitting form
  Future<void> submit();

  /// Function where you can add additional checks to form
  /// besides of registered validators
  Future<bool> additionalCheck() async {
    return true;
  }

  /// Runs action when submitting form
  Future<void> executeSubmitAction() async {
    removeInputFocus();

    await validateAllFields();

    final additionalCheckResult = await additionalCheck();

    for (final key in _actualValidators.keys) {
      if ((await _actualValidators[key]!()) is ErrorFieldState) {
        ensureVisible(key);

        return;
      }
    }

    if (!additionalCheckResult) {
      return;
    }

    _disable.update(true);

    await submit();

    _disable.update(false);
  }

  /// Brings view to the center of the screen
  // coverage:ignore-start
  void ensureVisible(GlobalKey key, {double alignment = 0.3}) async {
    try {
      await Scrollable.ensureVisible(
        key.currentContext!,
        duration: UINavigationSettings.transitionDuration,
        alignment: alignment,
      );
    } catch (e) {
      // ignore
    }
  }
  // coverage:ignore-end
}
