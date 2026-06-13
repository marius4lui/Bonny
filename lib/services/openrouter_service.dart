import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/debug_log.dart';
import '../models/receipt.dart';
import 'debug_log_service.dart';

class ReceiptExtraction {
  const ReceiptExtraction({
    required this.merchant,
    required this.date,
    required this.currency,
    required this.receiptTotal,
    required this.items,
    required this.trace,
  });

  factory ReceiptExtraction.empty() {
    return ReceiptExtraction(
      merchant: '',
      date: DateTime.now(),
      currency: 'EUR',
      receiptTotal: 0,
      items: const [],
      trace: const {},
    );
  }

  final String merchant;
  final DateTime date;
  final String currency;
  final double receiptTotal;
  final List<ReceiptItem> items;
  final Map<String, dynamic> trace;
}

class OpenRouterService {
  OpenRouterService({this.debugLog});

  static const model = 'google/gemma-4-26b-a4b-it:free';
  static const endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const promptVersion = 'receipt-extraction-v1';
  static const _uuid = Uuid();

  DebugLogService? debugLog;

  Future<ReceiptExtraction> extractReceipt({
    required String apiKey,
    required String imagePath,
    Map<String, dynamic>? debugMetadata,
  }) async {
    final requestId = _uuid.v4();
    final timestamp = DateTime.now();
    final stopwatch = Stopwatch()..start();
    if (apiKey.trim().isEmpty) {
      throw const OpenRouterException(
        'Add your OpenRouter API key in Settings first.',
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw const OpenRouterException('Receipt image was not found.');
    }

    final imageBytes = await file.readAsBytes();
    final mime = _mimeType(imagePath);
    final dataUrl = 'data:$mime;base64,${base64Encode(imageBytes)}';
    final imageMetadata = {...?debugLog?.imageMetadata(file), 'mime': mime};
    final headers = {
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://bonny.local',
      'X-Title': 'Bonny',
    };
    final requestBody = {
      'model': model,
      'temperature': 0,
      'response_format': {
        'type': 'json_schema',
        'json_schema': {
          'name': 'receipt_extraction',
          'strict': true,
          'schema': extractionSchema,
        },
      },
      'messages': [
        {
          'role': 'system',
          'content':
              'You extract structured data from grocery receipts. Return only valid JSON matching the schema. Use null when uncertain. Do not invent totals.',
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Read this receipt. Extract merchant, ISO date, currency, final receipt total, and line items. Categories should be simple user-friendly groups such as Groceries, Drinks, Snacks, Household, Personal Care, Other.',
            },
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
    };

    http.Response? response;
    Map<String, dynamic>? decodedResponse;
    Map<String, dynamic>? parsedJson;
    Map<String, dynamic>? normalizedJson;
    List<String>? validationWarnings;
    String? rawModelOutput;
    String? cleanedJson;
    String? extractionId;
    Object? caughtError;
    StackTrace? caughtStackTrace;

    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decodedResponse['choices']?[0]?['message']?['content'];
      rawModelOutput = _contentToText(content);
      cleanedJson = _cleanJsonText(rawModelOutput);
      parsedJson = _decodeJsonText(rawModelOutput);
      normalizedJson = normalizeReceiptJson(parsedJson);
      extractionId = _uuid.v4();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OpenRouterException(
          'OpenRouter returned ${response.statusCode}. ${_compactError(response.body)}',
        );
      }

      final extraction = _parseExtraction(normalizedJson);
      validationWarnings = [
        ..._schemaAliasWarnings(parsedJson),
        ..._validationWarnings(normalizedJson, extraction),
      ];
      final trace = <String, dynamic>{
        'requestId': requestId,
        'extractionId': extractionId,
        'timestamp': timestamp.toIso8601String(),
        'promptVersion': promptVersion,
        'model': model,
        ...?debugMetadata,
        'imageMetadata': imageMetadata,
        'rawModelOutput': rawModelOutput,
        'cleanedJson': cleanedJson,
        'parsedJson': parsedJson,
        'normalizedJson': normalizedJson,
        'validationWarnings': validationWarnings,
        'totals': {
          'receiptTotal': extraction.receiptTotal,
          'itemTotal': calculateTotals(extraction.items).total,
        },
      };
      if (debugMetadata != null) {
        trace['queueMetadata'] = debugMetadata;
      }
      return ReceiptExtraction(
        merchant: extraction.merchant,
        date: extraction.date,
        currency: extraction.currency,
        receiptTotal: extraction.receiptTotal,
        items: extraction.items,
        trace: trace,
      );
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStackTrace = stackTrace;
      rethrow;
    } finally {
      stopwatch.stop();
      final requestLog = <String, dynamic>{
        'requestId': requestId,
        ...?debugMetadata,
        'timestamp': timestamp.toIso8601String(),
        'endpoint': endpoint,
        'model': model,
        'status': caughtError == null ? 'success' : 'error',
        'httpCode': response?.statusCode,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'headers': headers,
        'requestBody': requestBody,
        'rawResponse': response?.body,
        'parsedResponse': decodedResponse,
        'rawModelOutput': rawModelOutput,
        'cleanedJson': cleanedJson,
        'parsedJson': parsedJson,
        'normalizedJson': normalizedJson,
        'validationWarnings': validationWarnings,
        if (caughtError != null) 'error': caughtError.toString(),
        if (caughtStackTrace != null) 'stackTrace': caughtStackTrace.toString(),
      };
      if (extractionId != null) {
        requestLog['extractionId'] = extractionId;
      }
      await debugLog?.log(
        DebugLogType.request,
        'OpenRouter receipt extraction',
        requestLog,
      );
    }
  }

  Future<void> testConnection(String apiKey) async {
    final requestId = _uuid.v4();
    final timestamp = DateTime.now();
    final stopwatch = Stopwatch()..start();
    if (apiKey.trim().isEmpty) {
      throw const OpenRouterException('Enter an API key first.');
    }
    final headers = {
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://bonny.local',
      'X-Title': 'Bonny',
    };
    final requestBody = {
      'model': model,
      'temperature': 0,
      'messages': [
        {'role': 'user', 'content': 'Reply with JSON: {"ok": true}'},
      ],
    };
    http.Response? response;
    Object? caughtError;
    StackTrace? caughtStackTrace;
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OpenRouterException(
          'Connection failed with ${response.statusCode}. ${_compactError(response.body)}',
        );
      }
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStackTrace = stackTrace;
      rethrow;
    } finally {
      stopwatch.stop();
      await debugLog?.log(DebugLogType.request, 'OpenRouter connection test', {
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'endpoint': endpoint,
        'model': model,
        'status': caughtError == null ? 'success' : 'error',
        'httpCode': response?.statusCode,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'headers': headers,
        'requestBody': requestBody,
        'rawResponse': response?.body,
        if (caughtError != null) 'error': caughtError.toString(),
        if (caughtStackTrace != null) 'stackTrace': caughtStackTrace.toString(),
      });
    }
  }

  List<String> _validationWarnings(
    Map<String, dynamic> json,
    ReceiptExtraction extraction,
  ) {
    final warnings = <String>[];
    if ((json['merchant'] as String?)?.trim().isEmpty != false) {
      warnings.add('Merchant missing or empty.');
    }
    if (json['date'] == null) warnings.add('Date missing.');
    if (extraction.receiptTotal <= 0) {
      warnings.add('Receipt total missing or zero.');
    }
    if (extraction.items.isEmpty) warnings.add('No line items extracted.');
    for (final item in extraction.items) {
      if (item.totalPrice <= 0) {
        warnings.add('Item "${item.name}" has no positive total price.');
      }
    }
    final itemTotal = calculateTotals(extraction.items).total;
    if (extraction.receiptTotal > 0 && itemTotal > 0) {
      final delta = (extraction.receiptTotal - itemTotal).abs();
      if (delta > 0.05) {
        warnings.add(
          'Receipt total and item total differ by ${delta.toStringAsFixed(2)}.',
        );
      }
    }
    return warnings;
  }

  String _contentToText(dynamic content) {
    if (content is Map<String, dynamic>) return jsonEncode(content);
    if (content is List) {
      return content
          .whereType<Map>()
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n');
    }
    if (content is String) return content;
    throw const OpenRouterException(
      'The model returned an unreadable response.',
    );
  }

  String _cleanJsonText(String text) {
    final trimmed = text.trim();
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(trimmed);
    return fenced?.group(1)?.trim() ?? trimmed;
  }

  static const Map<String, dynamic> extractionSchema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['merchant', 'date', 'currency', 'receipt_total', 'items'],
    'properties': {
      'merchant': {
        'type': ['string', 'null'],
      },
      'date': {
        'type': ['string', 'null'],
        'description': 'Purchase date in YYYY-MM-DD format.',
      },
      'currency': {
        'type': ['string', 'null'],
        'description': 'ISO 4217 currency code, for example EUR.',
      },
      'receipt_total': {
        'type': ['number', 'null'],
      },
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'name',
            'quantity',
            'unit_price',
            'total_price',
            'category',
          ],
          'properties': {
            'name': {'type': 'string'},
            'quantity': {
              'type': ['number', 'null'],
            },
            'unit_price': {
              'type': ['number', 'null'],
            },
            'total_price': {
              'type': ['number', 'null'],
            },
            'category': {
              'type': ['string', 'null'],
            },
          },
        },
      },
    },
  };

  ReceiptExtraction _parseExtraction(Map<String, dynamic> json) {
    final normalized = normalizeReceiptJson(json);
    final items = (normalized['items'] as List? ?? [])
        .whereType<Map>()
        .map(
          (item) => ReceiptItem.create(
            name: item['name']?.toString() ?? 'Unnamed item',
            quantity: _nullableDouble(item['quantity']),
            unitPrice: _nullableDouble(item['unit_price']),
            totalPrice: _nullableDouble(item['total_price']),
            category: item['category']?.toString(),
          ),
        )
        .toList();

    return ReceiptExtraction(
      merchant: normalized['merchant']?.toString() ?? '',
      date:
          DateTime.tryParse(normalized['date']?.toString() ?? '') ??
          DateTime.now(),
      currency: normalized['currency']?.toString().toUpperCase() ?? 'EUR',
      receiptTotal: _nullableDouble(normalized['receipt_total']) ?? 0,
      items: items,
      trace: const {},
    );
  }

  Map<String, dynamic> _decodeJsonText(String text) {
    final jsonText = _cleanJsonText(text);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const OpenRouterException(
        'The extraction response was not a JSON object.',
      );
    }
    return decoded;
  }

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String _compactError(String body) {
    if (body.length <= 180) return body;
    return '${body.substring(0, 180)}...';
  }
}

class OpenRouterException implements Exception {
  const OpenRouterException(this.message);

  final String message;

  @override
  String toString() => message;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

Map<String, dynamic> normalizeReceiptJson(Map<String, dynamic> raw) {
  final rawItems = _firstPresent(raw, const [
    'items',
    'line_items',
    'products',
  ]);
  final items = rawItems is List ? rawItems : const [];

  return {
    'merchant': raw['merchant'],
    'date': _firstPresent(raw, const ['date', 'iso_date', 'purchase_date']),
    'currency': raw['currency'],
    'receipt_total': _firstPresent(raw, const [
      'receipt_total',
      'final_receipt_total',
      'total_amount',
      'total',
    ]),
    'items': items.whereType<Map>().map((item) {
      final normalized = Map<String, dynamic>.from(item);
      final category = _firstPresent(normalized, const ['category']);
      return {
        'name': _firstPresent(normalized, const [
          'name',
          'item_name',
          'description',
        ]),
        'quantity': _firstPresent(normalized, const ['quantity', 'qty']),
        'unit_price': _firstPresent(normalized, const [
          'unit_price',
          'price_each',
        ]),
        'total_price': _firstPresent(normalized, const [
          'total_price',
          'line_total',
          'price',
        ]),
        'category': category == null || category.toString().trim().isEmpty
            ? 'Other'
            : category,
      };
    }).toList(),
  };
}

List<String> _schemaAliasWarnings(Map<String, dynamic> raw) {
  final usedAlias =
      _usedAlias(raw, 'date', const ['iso_date', 'purchase_date']) ||
      _usedAlias(raw, 'receipt_total', const [
        'final_receipt_total',
        'total_amount',
        'total',
      ]) ||
      _usedAlias(raw, 'items', const ['line_items', 'products']) ||
      _itemsUseAliases(raw);
  return usedAlias ? const ['Schema aliases normalized'] : const [];
}

bool _itemsUseAliases(Map<String, dynamic> raw) {
  final rawItems = _firstPresent(raw, const [
    'items',
    'line_items',
    'products',
  ]);
  if (rawItems is! List) return false;
  return rawItems.whereType<Map>().any((item) {
    final normalized = Map<String, dynamic>.from(item);
    return _usedAlias(normalized, 'name', const ['item_name', 'description']) ||
        _usedAlias(normalized, 'quantity', const ['qty']) ||
        _usedAlias(normalized, 'unit_price', const ['price_each']) ||
        _usedAlias(normalized, 'total_price', const ['line_total', 'price']);
  });
}

bool _usedAlias(
  Map<String, dynamic> raw,
  String canonical,
  List<String> aliases,
) {
  final canonicalValue = raw[canonical];
  if (canonicalValue != null) return false;
  return aliases.any((alias) => raw[alias] != null);
}

dynamic _firstPresent(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    if (raw.containsKey(key) && raw[key] != null) return raw[key];
  }
  return null;
}
