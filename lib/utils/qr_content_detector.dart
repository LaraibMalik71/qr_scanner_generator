enum QRContentType { website, text, phone, email, wifi, contact, sms, location }

class QRContentDetector {
  static QRContentType detect(String content) {
    final value = content.trim();

    if (value.startsWith('WIFI:')) {
      return QRContentType.wifi;
    }

    if (value.startsWith('BEGIN:VCARD')) {
      return QRContentType.contact;
    }

    if (value.startsWith('SMSTO:') || value.startsWith('sms:')) {
      return QRContentType.sms;
    }

    if (value.startsWith('geo:')) {
      return QRContentType.location;
    }

    if (value.startsWith('tel:')) {
      return QRContentType.phone;
    }

    if (value.startsWith('mailto:')) {
      return QRContentType.email;
    }

    final uri = Uri.tryParse(value);

    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return QRContentType.website;
    }

    if (RegExp(r'^[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return QRContentType.email;
    }

    if (RegExp(r'^\+?[0-9\s()-]{7,}$').hasMatch(value)) {
      return QRContentType.phone;
    }

    return QRContentType.text;
  }

  static String getTypeLabel(QRContentType type) {
    switch (type) {
      case QRContentType.website:
        return 'Website URL';
      case QRContentType.text:
        return 'Plain Text';
      case QRContentType.phone:
        return 'Phone Number';
      case QRContentType.email:
        return 'Email Address';
      case QRContentType.wifi:
        return 'Wi-Fi Credentials';
      case QRContentType.contact:
        return 'Contact Information';
      case QRContentType.sms:
        return 'SMS Message';
      case QRContentType.location:
        return 'Location';
    }
  }
}
