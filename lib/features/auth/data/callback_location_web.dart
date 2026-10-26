import 'dart:js_interop';

@JS('window.history.replaceState')
external void _replaceState(JSAny? data, JSString title, JSString url);

/// Remove one-use codes and provider errors without logging or reloading them.
void clearWebAuthLocation() {
  _replaceState(null, ''.toJS, Uri.base.path.toJS);
}
