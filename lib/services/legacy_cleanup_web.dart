import 'package:web/web.dart' as web;

void removeLegacyCredentials() {
  try {
    web.window.localStorage.removeItem('vedomax_accounts');
    web.window.localStorage.removeItem('vedomax_current_user');
  } catch (_) {
    // Restricted storage must not prevent guest practice.
  }
}
