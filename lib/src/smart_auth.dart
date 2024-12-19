import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:smart_auth/src/smart_auth_api.g.dart';

part 'models/sms_code_result.dart';

const _defaultCodeMatcher = '\\d{4,8}';

/// Flutter package for listening SMS code on Android, suggesting phone number, email, saving a credential.
///
/// If you need pin code input like shown below, take a look at [Pinput](https:///github.com/Tkko/Flutter_Pinput) package, SmartAuth is already integrated into it and you can build highly customizable input, that your designers can't even draw in Figma 🤭
/// `Note that only Android is supported, I faked other operating systems because other package is depended on this one and that package works on every system`
///
/// <img src="https:///user-images.githubusercontent.com/26390946/155599527-fe934f2c-5124-4754-bbf6-bb97d55a77c0.gif" height="600"/>
///
/// ## Features:
/// - Android Autofill
///   - SMS Retriever [API](https:///developers.google.com/identity/sms-retriever/overview?hl=en)
///   - SMS User Consent [API](https:///developers.google.com/identity/sms-retriever/user-consent/overview)
/// - Showing Hint Dialog
/// - Getting Saved Credential
/// - Saving Credential
/// - Deleting Credential
class SmartAuth {
  final SmartAuthApi _api = SmartAuthApi();

  /// This method outputs hash that is required for SMS Retriever API https://developers.google.com/identity/sms-retriever/overview?hl=en
  /// SMS must contain this hash at the end of the text
  /// Note that hash for debug and release if different
  Future<SmartAuthResult<String>> getAppSignature() async {
    try {
      final result = await _api.getAppSignature();
      return SmartAuthResult<String>.success(result);
    } catch (error) {
      debugPrint('Pinput/SmartAuth: getAppSignature failed: $error');
      return SmartAuthResult.failure(
        'Failed to get app signature with error: $error',
      );
    }
  }

  /// Starts listening to SMS that contains the App signature [getAppSignature] in the text
  /// returns code if it matches with matcher
  /// More about SMS Retriever API https://developers.google.com/identity/sms-retriever/overview?hl=en
  Future<SmsCodeResult> getSmsWithRetrieverApi({
    /// used to extract code from SMS
    String matcher = _defaultCodeMatcher,
  }) async {
    try {
      final result = await _api.getSmsWithRetrieverApi();
      return SmsCodeResult.fromSms(result, matcher);
    } catch (error) {
      debugPrint('Pinput/SmartAuth: getSmsWithRetrieverApi failed: $error');
      return SmsCodeResult.fromSms(null, matcher);
    }
  }

  /// Starts listening to SMS User Consent API https://developers.google.com/identity/sms-retriever/user-consent/overview
  /// Which shows confirmations dialog to user to confirm reading the SMS content
  /// returns code if it matches with matcher
  Future<SmsCodeResult> getSmsWithUserConsentApi({
    /// used to extract code from SMS
    String matcher = _defaultCodeMatcher,

    /// Optional parameter for User Consent API
    String? senderPhoneNumber,
  }) async {
    try {
      final result = await _api.getSmsWithUserConsentApi(senderPhoneNumber);
      return SmsCodeResult.fromSms(result, matcher);
    } catch (error) {
      if (error is PlatformException &&
          error.details is SmartAuthRequestCanceled) {
        debugPrint('Pinput/SmartAuth: ${error.message}');
        return SmsCodeResult(canceled: true);
      }

      debugPrint('Pinput/SmartAuth: getSmsWithUserConsentApi failed: $error');
      return SmsCodeResult.fromSms(null, matcher);
    }
  }

  /// Removes listener for [getSmsWithUserConsentApi]
  Future<SmartAuthResult<void>> removeUserConsentApiListener() async {
    try {
      await _api.removeUserConsentListener();
      return SmartAuthResult<void>.success(null);
    } catch (error) {
      debugPrint('Pinput/SmartAuth: removeUserConsentListener failed: $error');
      return SmartAuthResult<void>.failure(
        'Failed to remove user consent listener with error: $error',
      );
    }
  }

  /// Removes listener for [getSmsWithRetrieverApi]
  Future<SmartAuthResult<void>> removeSmsRetrieverApiListener() async {
    try {
      await _api.removeSmsRetrieverListener();
      return SmartAuthResult<void>.success(null);
    } catch (error) {
      debugPrint('Pinput/SmartAuth: removeSmsRetrieverListener failed: $error');
      return SmartAuthResult<void>.failure(
        'Failed to remove sms retriever listener with error: $error',
      );
    }
  }

  /// Runs the Phone Number Hint API, a library powered by Google Play services
  /// provides a frictionless way to show a user’s (SIM-based) phone numbers as a hint.
  /// https://developers.google.com/identity/phone-number-hint/android
  Future<SmartAuthResult<void>> requestPhoneNumberHint() async {
    try {
      final result = await _api.requestPhoneNumberHint();
      return SmartAuthResult<String>.success(result);
    } catch (error) {
      if (error is PlatformException &&
          error.details is SmartAuthRequestCanceled) {
        debugPrint('Pinput/SmartAuth: ${error.message}');
        return SmartAuthResult<void>.canceled(error.message);
      }

      final message = 'Failed to request phone number hint with error: $error';
      debugPrint('Pinput/SmartAuth: $message');
      return SmartAuthResult<void>.failure(message);
    }
  }
}
