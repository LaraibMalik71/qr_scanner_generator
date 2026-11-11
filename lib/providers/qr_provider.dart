import 'package:flutter/foundation.dart';

class QRProvider extends ChangeNotifier {
  String _generatedContent = '';

  String get generatedContent => _generatedContent;

  void generate({required String type, required Map<String, String> values}) {
    String content = '';

    switch (type) {
      case 'Text':
        content = values['text'] ?? '';
        break;

      case 'Website':
        final url = values['url'] ?? '';
        content = url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url';
        break;

      case 'Phone':
        content = 'tel:${values['phone'] ?? ''}';
        break;

      case 'Email':
        content = 'mailto:${values['email'] ?? ''}';
        break;

      case 'SMS':
        content = 'SMSTO:${values['phone'] ?? ''}:${values['message'] ?? ''}';
        break;

      case 'Wi-Fi':
        final security = values['security'] ?? 'WPA';
        final ssid = _escapeWifi(values['ssid'] ?? '');
        final password = _escapeWifi(values['password'] ?? '');

        content = 'WIFI:T:$security;S:$ssid;P:$password;;';
        break;

      case 'Contact':
        content =
            '''
BEGIN:VCARD
VERSION:3.0
FN:${values['name'] ?? ''}
TEL:${values['phone'] ?? ''}
EMAIL:${values['email'] ?? ''}
END:VCARD''';
        break;

      case 'Location':
        final latitude = values['latitude'] ?? '';
        final longitude = values['longitude'] ?? '';
        content = 'geo:$latitude,$longitude';
        break;

      case 'Social':
        final url = values['url'] ?? '';
        content = url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url';
        break;
    }

    _generatedContent = content.trim();
    notifyListeners();
  }

  String _escapeWifi(String value) {
    return value.replaceAll(RegExp(r'([\\;,:"])'), r'\$1');
  }

  void clearGeneratedContent() {
    _generatedContent = '';
    notifyListeners();
  }
}
