class HelpSupportContactEntity {
  const HelpSupportContactEntity({
    this.whatsappPhone,
    this.whatsappUrl,
    this.initialMessage,
  });

  final String? whatsappPhone;
  final String? whatsappUrl;
  final String? initialMessage;

  bool get isConfigured => _normalizedUrl != null || _normalizedPhone != null;

  Uri? toUri() {
    final url = _normalizedUrl;
    if (url != null) {
      return Uri.tryParse(url);
    }

    final phone = _normalizedPhone;
    if (phone == null) {
      return null;
    }

    final message = _normalizedMessage;
    return Uri.https(
      'wa.me',
      '/$phone',
      message == null ? null : {'text': message},
    );
  }

  String? get _normalizedUrl {
    final value = whatsappUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? get _normalizedPhone {
    final value = whatsappPhone?.replaceAll(RegExp(r'\D'), '');
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? get _normalizedMessage {
    final value = initialMessage?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}
