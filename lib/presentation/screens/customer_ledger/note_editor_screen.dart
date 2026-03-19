import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../providers/customer_ledger_provider.dart';

/// A single image attached to a note.
class NoteImage {
  final String? url;
  final String? storagePath;
  final String? localPath;
  final String createdAt;

  NoteImage({this.url, this.storagePath, this.localPath, required this.createdAt});

  bool get isLocal => localPath != null && url == null;

  Map<String, dynamic> toJson() => {
    'url': url,
    'path': storagePath,
    'created_at': createdAt,
  };

  factory NoteImage.fromJson(Map<String, dynamic> json) => NoteImage(
    url: json['url']?.toString(),
    storagePath: json['path']?.toString(),
    createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
  );
}

/// Full-screen note editor inspired by Apple Notes / Bear.
class NoteEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingNote;
  final String customerId;
  final String customerName;
  final String? projectId;
  final String? projectName;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    required this.customerId,
    required this.customerName,
    this.projectId,
    this.projectName,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;

  String _selectedColor = 'blue';
  bool _pinned = false;
  List<NoteImage> _images = [];
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  String? _noteId;
  int _previousContentLength = 0;

  bool get _isEditing => widget.existingNote != null;

  static const _colors = {
    'blue': AppColors.noteBlue,
    'green': AppColors.noteGreen,
    'orange': AppColors.noteOrange,
    'red': AppColors.noteRed,
    'purple': AppColors.notePurple,
    'teal': AppColors.noteTeal,
  };

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleCtrl = TextEditingController(text: note?['title']?.toString() ?? '');
    _contentCtrl = TextEditingController(text: note?['content']?.toString() ?? '');
    _previousContentLength = _contentCtrl.text.length;
    _selectedColor = note?['color']?.toString() ?? 'blue';
    _pinned = note?['pinned'] == true;
    _noteId = note?['id']?.toString();

    // Parse existing images
    final rawImages = note?['images'];
    if (rawImages is List) {
      _images = rawImages
          .map((e) => e is Map<String, dynamic> ? NoteImage.fromJson(e) : null)
          .whereType<NoteImage>()
          .toList();
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (_hasUnsavedChanges && (_titleCtrl.text.trim().isNotEmpty || _contentCtrl.text.trim().isNotEmpty)) {
        _saveNote();
      }
    });
  }

  // ─── Save ────────────────────────────────────────────────────────────────

  Future<void> _saveNote({bool silent = true}) async {
    // Allow saving without title — only skip if completely empty (no title, no content)
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final supabase = ref.read(supabaseServiceProvider);
    final userId = ref.read(userIdProvider);
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await supabase.ensureValidSession();

      // Upload pending local images
      await _uploadPendingImages(supabase, userId);

      final now = DateTime.now().toIso8601String();
      final imagesJson = _images
          .where((i) => !i.isLocal)
          .map((i) => i.toJson())
          .toList();

      final noteData = <String, dynamic>{
        'user_id': userId,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'color': _selectedColor,
        'pinned': _pinned,
        'updated_at': now,
        'images': imagesJson,
      };

      // Add customer/project links
      if (widget.customerId.isNotEmpty) {
        noteData['customer_id'] = widget.customerId;
      }
      if (widget.projectId != null && widget.projectId!.isNotEmpty) {
        noteData['project_id'] = widget.projectId;
      }

      if (_noteId != null) {
        // Update existing
        try {
          await supabase.client
              .from('project_notes')
              .update(noteData)
              .eq('id', _noteId!);
        } catch (_) {
          // Fallback: remove columns that may not exist
          noteData.remove('customer_id');
          noteData.remove('project_id');
          noteData.remove('images');
          await supabase.client
              .from('project_notes')
              .update(noteData)
              .eq('id', _noteId!);
        }
      } else {
        // Insert new
        _noteId = const Uuid().v4();
        noteData['id'] = _noteId;
        noteData['created_at'] = now;
        try {
          await supabase.client.from('project_notes').insert(noteData);
        } catch (_) {
          noteData.remove('customer_id');
          noteData.remove('project_id');
          noteData.remove('images');
          await supabase.client.from('project_notes').insert(noteData);
        }
      }

      if (widget.customerId.isNotEmpty) {
        ref.invalidate(customerNotesProvider(widget.customerId));
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note saved'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save note. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Images ──────────────────────────────────────────────────────────────

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final images = await ImagePicker().pickMultiImage(
          maxWidth: 1920,
          imageQuality: 85,
        );
        for (final img in images) {
          _images.add(NoteImage(
            localPath: img.path,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      } else {
        final image = await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          imageQuality: 85,
        );
        if (image != null) {
          _images.add(NoteImage(
            localPath: image.path,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }
      setState(() {});
      _markDirty();
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _uploadPendingImages(
      SupabaseService supabase, String userId) async {
    for (int i = 0; i < _images.length; i++) {
      final img = _images[i];
      if (!img.isLocal) continue;

      final file = File(img.localPath!);
      if (!await file.exists()) continue;

      final ext = _normalizedExt(img.localPath!);
      final imageId = const Uuid().v4();
      final noteId = _noteId ?? const Uuid().v4();
      if (_noteId == null) _noteId = noteId;
      final storagePath = '$userId/notes/$noteId/$imageId.$ext';

      try {
        await supabase.uploadFile(
          bucket: 'notes',
          path: storagePath,
          file: file,
          contentType: _contentType(ext),
        );

        final signedUrl = await supabase.client.storage
            .from('notes')
            .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

        _images[i] = NoteImage(
          url: signedUrl,
          storagePath: storagePath,
          createdAt: img.createdAt,
        );
      } catch (e) {
        debugPrint('Image upload failed: $e');
      }
    }
  }

  void _removeImage(int index) {
    final img = _images[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo?'),
        content: const Text('This photo will be removed from the note.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Delete from storage if uploaded
              if (img.storagePath != null) {
                try {
                  final supabase = ref.read(supabaseServiceProvider);
                  await supabase.deleteFile(
                    bucket: 'notes',
                    paths: [img.storagePath!],
                  );
                } catch (_) {}
              }
              setState(() => _images.removeAt(index));
              _markDirty();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewImage(NoteImage img) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: img.isLocal
                  ? Image.file(File(img.localPath!), fit: BoxFit.contain)
                  : Image.network(img.url!, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This note and its photos will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_noteId == null) {
                Navigator.pop(context);
                return;
              }
              try {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.ensureValidSession();

                // Delete images from storage
                final paths = _images
                    .where((i) => i.storagePath != null)
                    .map((i) => i.storagePath!)
                    .toList();
                if (paths.isNotEmpty) {
                  try {
                    await supabase.deleteFile(bucket: 'notes', paths: paths);
                  } catch (_) {}
                }

                await supabase.client
                    .from('project_notes')
                    .delete()
                    .eq('id', _noteId!);

                if (widget.customerId.isNotEmpty) {
                  ref.invalidate(customerNotesProvider(widget.customerId));
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note deleted'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not delete note. Please try again.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Back guard ──────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Save your changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveNote(silent: false);
    }
    return true;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _normalizedExt(String path) {
    final segs = path.split('.');
    if (segs.length < 2) return 'jpg';
    final ext = segs.last.trim().toLowerCase();
    return ext == 'jpeg' ? 'jpg' : (ext.isEmpty ? 'jpg' : ext);
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Color _colorForName(String? name) => _colors[name] ?? AppColors.noteBlue;

  // ─── List formatting ────────────────────────────────────────────────────

  static const _checkboxUnchecked = '☐ ';
  static const _checkboxChecked = '☑ ';
  static const _bulletPrefix = '• ';

  /// Insert a checklist line at the cursor.
  void _insertChecklist() {
    _insertListPrefix(_checkboxUnchecked);
  }

  /// Insert a bullet line at the cursor.
  void _insertBullet() {
    _insertListPrefix(_bulletPrefix);
  }

  void _insertListPrefix(String prefix) {
    final text = _contentCtrl.text;
    final sel = _contentCtrl.selection;
    final offset = sel.isValid ? sel.baseOffset : text.length;

    // Find the start of the current line
    int lineStart = offset;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    final lineEnd = text.indexOf('\n', offset);
    final currentLine = text.substring(
      lineStart,
      lineEnd == -1 ? text.length : lineEnd,
    );

    // If the line already has this prefix, remove it (toggle off)
    if (currentLine.startsWith(prefix)) {
      _contentCtrl.text = text.replaceRange(lineStart, lineStart + prefix.length, '');
      _contentCtrl.selection = TextSelection.collapsed(
        offset: (offset - prefix.length).clamp(0, _contentCtrl.text.length),
      );
      _previousContentLength = _contentCtrl.text.length;
      _markDirty();
      return;
    }

    // If the line already has a different list prefix, replace it
    for (final p in [_checkboxUnchecked, _checkboxChecked, _bulletPrefix]) {
      if (currentLine.startsWith(p)) {
        _contentCtrl.text = text.replaceRange(lineStart, lineStart + p.length, prefix);
        _contentCtrl.selection = TextSelection.collapsed(
          offset: (offset - p.length + prefix.length).clamp(0, _contentCtrl.text.length),
        );
        _previousContentLength = _contentCtrl.text.length;
        _markDirty();
        return;
      }
    }

    // Insert prefix at line start
    _contentCtrl.text = text.replaceRange(lineStart, lineStart, prefix);
    _contentCtrl.selection = TextSelection.collapsed(
      offset: offset + prefix.length,
    );
    _previousContentLength = _contentCtrl.text.length;
    _markDirty();
  }

  /// Handle Enter key to continue list formatting.
  void _onContentChanged(String newText) {
    final prevLen = _previousContentLength;
    _previousContentLength = newText.length;
    _markDirty();

    // Check if exactly one character was inserted (likely a newline from Enter)
    if (newText.length == prevLen + 1) {
      final sel = _contentCtrl.selection;
      if (!sel.isValid) return;
      final offset = sel.baseOffset;
      if (offset > 0 && newText[offset - 1] == '\n') {
        // Find the previous line
        int prevLineStart = offset - 2;
        while (prevLineStart >= 0 && newText[prevLineStart] != '\n') {
          prevLineStart--;
        }
        prevLineStart++;
        final prevLine = newText.substring(prevLineStart, offset - 1);

        // Continue checkbox/bullet if previous line had one
        String? continuationPrefix;
        if (prevLine.startsWith(_checkboxUnchecked)) {
          // If the previous line was ONLY the prefix (empty item), remove it
          if (prevLine.trim() == _checkboxUnchecked.trim()) {
            _contentCtrl.text = newText.replaceRange(prevLineStart, offset, '');
            _contentCtrl.selection = TextSelection.collapsed(
              offset: prevLineStart,
            );
            _previousContentLength = _contentCtrl.text.length;
            return;
          }
          continuationPrefix = _checkboxUnchecked;
        } else if (prevLine.startsWith(_checkboxChecked)) {
          if (prevLine.trim() == _checkboxChecked.trim()) {
            _contentCtrl.text = newText.replaceRange(prevLineStart, offset, '');
            _contentCtrl.selection = TextSelection.collapsed(
              offset: prevLineStart,
            );
            _previousContentLength = _contentCtrl.text.length;
            return;
          }
          continuationPrefix = _checkboxUnchecked; // new items start unchecked
        } else if (prevLine.startsWith(_bulletPrefix)) {
          if (prevLine.trim() == _bulletPrefix.trim()) {
            _contentCtrl.text = newText.replaceRange(prevLineStart, offset, '');
            _contentCtrl.selection = TextSelection.collapsed(
              offset: prevLineStart,
            );
            _previousContentLength = _contentCtrl.text.length;
            return;
          }
          continuationPrefix = _bulletPrefix;
        }

        if (continuationPrefix != null) {
          _contentCtrl.text = newText.replaceRange(
            offset, offset, continuationPrefix,
          );
          _contentCtrl.selection = TextSelection.collapsed(
            offset: offset + continuationPrefix.length,
          );
          _previousContentLength = _contentCtrl.text.length;
        }
      }
    }
  }

  /// Toggle checkbox state when a checkbox line is tapped.
  void _toggleCheckboxAtCursor() {
    final text = _contentCtrl.text;
    final sel = _contentCtrl.selection;
    if (!sel.isValid) return;

    final offset = sel.baseOffset;
    int lineStart = offset;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    final lineEnd = text.indexOf('\n', lineStart);
    final currentLine = text.substring(
      lineStart,
      lineEnd == -1 ? text.length : lineEnd,
    );

    if (currentLine.startsWith(_checkboxUnchecked)) {
      _contentCtrl.text = text.replaceRange(
        lineStart,
        lineStart + _checkboxUnchecked.length,
        _checkboxChecked,
      );
      _contentCtrl.selection = TextSelection.collapsed(offset: offset);
      _previousContentLength = _contentCtrl.text.length;
      _markDirty();
    } else if (currentLine.startsWith(_checkboxChecked)) {
      _contentCtrl.text = text.replaceRange(
        lineStart,
        lineStart + _checkboxChecked.length,
        _checkboxUnchecked,
      );
      _contentCtrl.selection = TextSelection.collapsed(offset: offset);
      _previousContentLength = _contentCtrl.text.length;
      _markDirty();
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _colorForName(_selectedColor);
    final colorScheme = Theme.of(context).colorScheme;
    final updatedAt = widget.existingNote?['updated_at'] != null
        ? DateTime.tryParse(widget.existingNote!['updated_at'].toString())
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
          title: _buildContextChip(),
          titleSpacing: 0,
          actions: [
            // Pin toggle
            IconButton(
              icon: Icon(
                _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _pinned ? color : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20,
              ),
              tooltip: _pinned ? 'Unpin' : 'Pin to top',
              onPressed: () {
                setState(() => _pinned = !_pinned);
                _markDirty();
              },
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: () => _saveNote(silent: false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: Text(_hasUnsavedChanges ? 'Save' : 'Done'),
                    ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Thin color accent — subtle note identity
            Container(
              height: 2,
              color: color.withValues(alpha: 0.35),
            ),

            // Main editor — continuous writing canvas
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date — minimal, left-aligned
                      if (updatedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            DateFormat('MMM d, y \u2022 h:mm a').format(updatedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                      // Title — clean heading, no box
                      TextField(
                        controller: _titleCtrl,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.3,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Untitled',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: _markDirty,
                      ),

                      // Subtle divider between title and body
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),

                      // Body — open writing surface, no box
                      TextField(
                        controller: _contentCtrl,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.65,
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                          letterSpacing: -0.1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Start writing\u2026',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                            height: 1.65,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        maxLines: null,
                        minLines: 12,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        onChanged: _onContentChanged,
                      ),

                      const SizedBox(height: 24),

                      // Images grid
                      if (_images.isNotEmpty) _buildImageGrid(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom toolbar — attachments, colors, status
            _buildBottomToolbar(color, updatedAt),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────

  Widget _buildContextChip() {
    final parts = <String>[];
    if (widget.customerName.isNotEmpty) parts.add(widget.customerName);
    if (widget.projectName != null && widget.projectName!.isNotEmpty) {
      parts.add(widget.projectName!);
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, size: 13,
              color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              parts.join(' \u203a '),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '${_images.length} photo${_images.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final img = _images[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _viewImage(img),
                  onLongPress: () => _removeImage(index),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: img.isLocal
                              ? Image.file(File(img.localPath!),
                                  fit: BoxFit.cover)
                              : Image.network(img.url!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                                    child: Icon(Icons.broken_image,
                                        color: Theme.of(context).colorScheme.outlineVariant),
                                  ),
                                ),
                        ),
                      ),
                      // Upload indicator for local images
                      if (img.isLocal)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.cloud_upload_outlined,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      // Remove button
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBottomToolbar(Color activeColor, DateTime? updatedAt) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        )),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // List formatting buttons
              _toolbarIcon(Icons.checklist_rounded, 'Checklist',
                  _insertChecklist),
              _toolbarIcon(Icons.format_list_bulleted_rounded, 'Bullet list',
                  _insertBullet),
              _toolbarIcon(Icons.check_box_outlined, 'Toggle checkbox',
                  _toggleCheckboxAtCursor),

              // Divider
              Container(
                width: 1, height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),

              // Attachment buttons
              _toolbarIcon(Icons.camera_alt_outlined, 'Camera',
                  () => _pickImages(ImageSource.camera)),
              _toolbarIcon(Icons.photo_outlined, 'Gallery',
                  () => _pickImages(ImageSource.gallery)),

              // Divider
              Container(
                width: 1, height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),

              // Color dots — compact
              ..._colors.entries.map((e) {
                final isSelected = e.key == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = e.key);
                    _markDirty();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 20 : 16,
                      height: isSelected ? 20 : 16,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: colorScheme.onSurface, width: 2)
                            : Border.all(
                                color: e.value.withValues(alpha: 0.4), width: 1),
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              // Save status
              if (_isSaving)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('Saving\u2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        )),
                  ],
                )
              else if (!_hasUnsavedChanges && _noteId != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 14,
                        color: AppColors.paid(context)),
                    const SizedBox(width: 4),
                    Text('Saved',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.paid(context),
                        )),
                  ],
                ),

              // Delete — far right, muted (edit only)
              if (_isEditing)
                _toolbarIcon(Icons.delete_outline, 'Delete', _deleteNote,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, String tooltip, VoidCallback onTap,
      {Color? color}) {
    return IconButton(
      icon: Icon(icon, size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
