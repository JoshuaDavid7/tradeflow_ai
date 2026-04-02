import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/env_config.dart';
import '../../core/errors/error_handler.dart';

/// A single line item extracted from a receipt
class ReceiptLineItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const ReceiptLineItem({
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
      };

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    return ReceiptLineItem(
      name: json['name']?.toString() ?? 'Unknown Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Full AI-extracted receipt result
class ReceiptAiResult {
  final String? storeName;
  final List<ReceiptLineItem> items;
  final double? subtotal;
  final double? tax;
  final double? total;
  final String? date;

  const ReceiptAiResult({
    this.storeName,
    this.items = const [],
    this.subtotal,
    this.tax,
    this.total,
    this.date,
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'date': date,
      };

  factory ReceiptAiResult.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)
            ?.whereType<Map>()
            .map((i) =>
                ReceiptLineItem.fromJson(Map<String, dynamic>.from(i)))
            .toList() ??
        [];

    return ReceiptAiResult(
      storeName: json['storeName']?.toString(),
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      date: json['date']?.toString(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ReceiptAiResult.fromJsonString(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ReceiptAiResult.fromJson(map);
    } catch (e) {
      debugPrint('ReceiptAiResult.fromJsonString parse error: $e');
      return const ReceiptAiResult();
    }
  }
}

/// Service that uses Gemini API to extract itemized data from receipt OCR text
class ReceiptAiService {
  final Dio _dio;
  final String _apiKey;
  static const String _geminiModel = 'gemini-3.1-flash-lite-preview';

  ReceiptAiService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// Extract structured line items from raw OCR text using Gemini
  Future<ReceiptAiResult> extractItems(String ocrText) async {
    if (ocrText.trim().isEmpty) {
      return const ReceiptAiResult();
    }

    try {
      ErrorHandler.debug('Sending receipt text to Gemini for extraction', {
        'textLength': ocrText.length,
      });

      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '''You are a receipt parser. Extract all line items from this receipt text.

Return ONLY valid JSON in this exact format (no markdown, no code blocks, just raw JSON):
{
  "storeName": "Store Name Here",
  "items": [
    {"name": "Item name", "quantity": 1, "unitPrice": 9.99, "totalPrice": 9.99}
  ],
  "subtotal": 19.98,
  "tax": 1.60,
  "total": 21.58,
  "date": "2024-01-15"
}

Rules:
- Extract every individual item/product with its price
- If quantity is not clear, use 1
- unitPrice is price per single unit, totalPrice is quantity * unitPrice
- If you cannot determine subtotal/tax/total, set them to null
- If you cannot determine date, set it to null
- If you cannot determine store name, set it to null
- Do NOT include tax lines, total lines, or payment method lines as items
- Return only the JSON object, nothing else

Receipt text:
$ocrText'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2048,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final responseData = response.data as Map<String, dynamic>;
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        ErrorHandler.warning('Gemini returned no candidates', {});
        return const ReceiptAiResult();
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return const ReceiptAiResult();
      }

      String rawText = (parts[0]['text'] as String? ?? '').trim();

      // Strip markdown code blocks if present
      if (rawText.startsWith('```')) {
        rawText = rawText.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
        rawText = rawText.replaceFirst(RegExp(r'\s*```$'), '');
      }

      final decoded = jsonDecode(rawText);
      if (decoded is! Map<String, dynamic>) {
        ErrorHandler.warning('Gemini returned non-object JSON', {
          'type': decoded.runtimeType.toString(),
        });
        return const ReceiptAiResult();
      }
      final result = ReceiptAiResult.fromJson(decoded);

      ErrorHandler.info('Gemini receipt extraction complete', {
        'itemCount': result.items.length,
        'storeName': result.storeName,
        'total': result.total,
      });

      return result;
    } on DioException catch (e) {
      ErrorHandler.warning('Gemini API call failed', {
        'status': e.response?.statusCode,
        'message': e.message,
      });
      return const ReceiptAiResult();
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace);
      return const ReceiptAiResult();
    }
  }

  void dispose() {
    _dio.close();
  }
}

/// Provider for the receipt AI service
final receiptAiServiceProvider = Provider<ReceiptAiService>((ref) {
  final service = ReceiptAiService(apiKey: EnvConfig.geminiApiKey);
  ref.onDispose(() => service.dispose());
  return service;
});
