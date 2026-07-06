import 'dart:convert';
import 'dart:js_interop';

import 'aws_auth_service.dart';
import 'aws_session_store.dart';

@JS('localStorage')
external _LocalStorage get _localStorage;

extension type _LocalStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

AwsSessionStore createPlatformAwsSessionStore() => BrowserAwsSessionStore();

class BrowserAwsSessionStore implements AwsSessionStore {
  static const _storageKey = 'campus_budget_aws_session_v1';

  @override
  AwsSession? loadSession() {
    final payload = _localStorage.getItem(_storageKey.toJS)?.toDart;
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final session = AwsSession.fromJson(decoded);
      return session.isValid ? session : null;
    } catch (_) {
      return null;
    }
  }

  @override
  void saveSession(AwsSession session) {
    _localStorage.setItem(_storageKey.toJS, jsonEncode(session.toJson()).toJS);
  }

  @override
  void clearSession() {
    _localStorage.removeItem(_storageKey.toJS);
  }
}
