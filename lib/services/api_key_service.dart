class ApiKeyService {
  const ApiKeyService();

  String normalize(String value) => value.trim();

  bool looksLikeOpenRouterKey(String value) {
    final trimmed = normalize(value);
    return trimmed.isEmpty || trimmed.startsWith('sk-or-');
  }

  String? lastFour(String value) {
    final trimmed = normalize(value);
    if (trimmed.isEmpty) return null;
    return trimmed.length <= 4
        ? trimmed
        : trimmed.substring(trimmed.length - 4);
  }

  String mask(String? valueOrLastFour) {
    final value = valueOrLastFour?.trim() ?? '';
    if (value.isEmpty) return 'Not saved';
    final suffix = value.length <= 4
        ? value
        : value.substring(value.length - 4);
    return 'sk-or-****$suffix';
  }
}
