import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_template.dart';

/// Handles saving/loading invoice templates and uploading logos to Supabase Storage.
class TemplateService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'logos';
  static const _cacheKeyLast = 'invoice_template_cache_last';
  static const _cacheKeyPrefix = 'invoice_template_cache_user_';

  static Future<void> _cacheTemplate(InvoiceTemplate template,
      {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachePayload = {'id': template.id, ...template.toJson()};
      final encoded = jsonEncode(cachePayload);
      await prefs.setString(_cacheKeyLast, encoded);
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString('$_cacheKeyPrefix$userId', encoded);
      }
    } catch (e) {
      debugPrint('TemplateService._cacheTemplate error: $e');
    }
  }

  static bool _isUuid(String value) {
    return RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$')
        .hasMatch(value.trim());
  }

  static Future<InvoiceTemplate?> _readCachedTemplate(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return InvoiceTemplate.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      debugPrint('TemplateService._readCachedTemplate error: $e');
      return null;
    }
  }

  /// Load the active template for the current user.
  /// Returns the default template if none has been saved.
  static Future<InvoiceTemplate> loadTemplate() async {
    final userId = _supabase.auth.currentUser?.id;
    try {
      if (userId == null || userId.isEmpty) {
        final cached = await _readCachedTemplate(_cacheKeyLast);
        return cached ?? InvoiceTemplate.defaultTemplate();
      }

      final rows = await _supabase
          .from('invoice_templates')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        final loaded = InvoiceTemplate.fromJson(rows.first);
        await _cacheTemplate(loaded, userId: userId);
        return loaded;
      }

      final cachedForUser =
          await _readCachedTemplate('$_cacheKeyPrefix$userId');
      if (cachedForUser != null) return cachedForUser;

      final cached = await _readCachedTemplate(_cacheKeyLast);
      return cached ?? InvoiceTemplate.defaultTemplate();
    } catch (e) {
      debugPrint('TemplateService.loadTemplate error: $e');
      if (userId != null && userId.isNotEmpty) {
        final cachedForUser =
            await _readCachedTemplate('$_cacheKeyPrefix$userId');
        if (cachedForUser != null) return cachedForUser;
      }
      final cached = await _readCachedTemplate(_cacheKeyLast);
      return cached ?? InvoiceTemplate.defaultTemplate();
    }
  }

  /// Save (upsert) the template for the current user.
  static Future<InvoiceTemplate> saveTemplate(InvoiceTemplate template) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      final localSaved = template.id == 'default'
          ? template.copyWith(id: 'local-template')
          : template;
      await _cacheTemplate(localSaved);
      return localSaved;
    }

    final isNew = template.id == 'default' ||
        template.id.isEmpty ||
        !_isUuid(template.id);
    final id = isNew ? const Uuid().v4() : template.id;

    final payload = {
      'id': id,
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
      ...template.copyWith(id: id).toJson(),
    };

    await _supabase.from('invoice_templates').upsert(payload);
    final saved = template.copyWith(id: id);
    await _cacheTemplate(saved, userId: userId);
    return saved;
  }

  /// Upload a logo image file to Supabase Storage.
  /// Returns the public URL of the uploaded file.
  static Future<String> uploadLogo(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName = '$userId/logo.$ext';

    await _supabase.storage.from(_bucket).upload(
          fileName,
          imageFile,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true, // replace existing logo
          ),
        );

    final url = _supabase.storage.from(_bucket).getPublicUrl(fileName);
    // Append a cache-busting timestamp so Flutter re-fetches the new image
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Download logo bytes from a URL for use in the PDF renderer.
  static Future<Uint8List?> downloadLogoBytes(String url) async {
    try {
      // Strip cache-busting query param for storage download
      final cleanUrl = url.split('?').first;
      // Extract path after /object/public/logos/
      final uri = Uri.parse(cleanUrl);
      final segments = uri.pathSegments;
      final logoIndex = segments.indexOf('logos');
      if (logoIndex < 0) return null;
      final storagePath = segments.sublist(logoIndex + 1).join('/');

      final bytes = await _supabase.storage.from(_bucket).download(storagePath);
      return bytes;
    } catch (e) {
      debugPrint('TemplateService.downloadLogoBytes error: $e');
      return null;
    }
  }

  /// Convert a hex colour string like '#1565C0' to a 0xFF1565C0 int.
  static int hexToInt(String hex) {
    final normalized =
        InvoiceTemplate.normalizeHexColor(hex, fallback: '#1565C0');
    final h = normalized.replaceAll('#', '');
    return int.parse('FF$h', radix: 16);
  }
}
