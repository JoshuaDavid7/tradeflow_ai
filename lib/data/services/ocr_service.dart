import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// OCR result with extracted data
class OcrResult {
  final String fullText;
  final double? amount;
  final String? vendor;
  final DateTime? date;

  const OcrResult({
    required this.fullText,
    this.amount,
    this.vendor,
    this.date,
  });
}

/// OCR service for receipt scanning
class OcrService {
  final TextRecognizer _textRecognizer;

  OcrService() : _textRecognizer = TextRecognizer();

  /// Process receipt image and extract text
  Future<OcrResult> processReceipt(String imagePath) async {
    try {
      ErrorHandler.debug('Processing receipt', {'path': imagePath});

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text;

      if (fullText.isEmpty) {
        throw VoiceCaptureException(
          message: 'No text found in image. Please try again with better lighting.',
          code: 'NO_TEXT_FOUND',
        );
      }

      // Extract structured data from text
      final amount = _extractAmount(fullText);
      final vendor = _extractVendor(recognizedText);
      final date = _extractDate(fullText);

      ErrorHandler.debug('OCR completed', {
        'textLength': fullText.length,
        'hasAmount': amount != null,
        'hasVendor': vendor != null,
        'hasDate': date != null,
      });

      return OcrResult(
        fullText: fullText,
        amount: amount,
        vendor: vendor,
        date: date,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      
      if (error is VoiceCaptureException) {
        rethrow;
      }

      throw VoiceCaptureException(
        message: 'Failed to process receipt image',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract total amount from receipt text
  double? _extractAmount(String text) {
    try {
      // Common patterns for total amount
      final patterns = [
        RegExp(r'total[:\s]*\$?(\d+\.?\d*)', caseSensitive: false),
        RegExp(r'amount[:\s]*\$?(\d+\.?\d*)', caseSensitive: false),
        RegExp(r'\$(\d+\.?\d+)(?:\s|$)'),
        RegExp(r'(\d+\.\d{2})(?:\s|$)'), // Last resort: any decimal amount
      ];

      for (final pattern in patterns) {
        final matches = pattern.allMatches(text);
        if (matches.isNotEmpty) {
          final match = matches.last; // Usually the total is at the bottom
          final amountStr = match.group(1);
          if (amountStr != null) {
            return double.tryParse(amountStr);
          }
        }
      }
    } catch (e) {
      ErrorHandler.debug('Failed to extract amount', {'error': e});
    }

    return null;
  }

  /// Extract vendor/merchant name from receipt
  String? _extractVendor(RecognizedText recognizedText) {
    try {
      // Usually the vendor name is in the first few lines
      final firstFewBlocks = recognizedText.blocks.take(3);
      
      for (final block in firstFewBlocks) {
        final text = block.text.trim();
        
        // Skip very short text (likely not a business name)
        if (text.length < 3) continue;
        
        // Skip lines that look like addresses or phone numbers
        if (RegExp(r'\d{3}[-.]?\d{3}[-.]?\d{4}').hasMatch(text)) continue;
        if (RegExp(r'^\d+\s+[A-Za-z\s]+$').hasMatch(text)) continue;
        
        // If it's mostly letters and reasonable length, it's likely the vendor
        if (text.length >= 3 && text.length <= 50) {
          return text;
        }
      }
    } catch (e) {
      ErrorHandler.debug('Failed to extract vendor', {'error': e});
    }

    return null;
  }

  /// Extract date from receipt
  DateTime? _extractDate(String text) {
    try {
      // Common date patterns
      final patterns = [
        RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})'), // MM/DD/YYYY
        RegExp(r'(\d{1,2})-(\d{1,2})-(\d{2,4})'), // MM-DD-YYYY
        RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // YYYY-MM-DD
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          try {
            int year, month, day;
            
            if (pattern == patterns[2]) {
              // YYYY-MM-DD format
              year = int.parse(match.group(1)!);
              month = int.parse(match.group(2)!);
              day = int.parse(match.group(3)!);
            } else {
              // MM/DD/YYYY or MM-DD-YYYY format
              month = int.parse(match.group(1)!);
              day = int.parse(match.group(2)!);
              year = int.parse(match.group(3)!);
              
              // Handle 2-digit year
              if (year < 100) {
                year += 2000;
              }
            }

            return DateTime(year, month, day);
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      ErrorHandler.debug('Failed to extract date', {'error': e});
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

/// Provider for OCR service
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});
