import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/voice_capture_service.dart';
import '../../../data/repositories/voice_repository.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../providers/customer_ledger_provider.dart';
import 'block_editor/note_block.dart';

/// A single image attached to a note (kept for backward compat with list screens).
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

/// Full-screen block-based note editor.
class NoteEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingNote;
  final String customerId;
  final String customerName;
  final String? projectId;
  final String? projectName;
  final String? initialTitle;
  final String? initialContent;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    required this.customerId,
    required this.customerName,
    this.projectId,
    this.projectName,
    this.initialTitle,
    this.initialContent,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late List<NoteBlock> _blocks;

  // Per-block controllers and focus nodes
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};

  String _selectedColor = 'blue';
  bool _pinned = false;
  bool _isRecordingVoice = false;
  VoiceCaptureService? _voiceService;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  String? _noteId;
  final _titleFocus = FocusNode();
  final _scrollController = ScrollController();

  // Track which block index to focus after rebuild
  int? _pendingFocusIndex;
  int? _pendingCursorOffset;

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
    _titleCtrl = TextEditingController(
      text: note?['title']?.toString() ?? widget.initialTitle ?? '',
    );
    _selectedColor = note?['color']?.toString() ?? 'blue';
    _pinned = note?['pinned'] == true;
    _noteId = note?['id']?.toString();

    // Parse content into blocks
    final content = note?['content']?.toString() ?? widget.initialContent;
    final legacyImages = note?['images'];
    _blocks = parseNoteContent(content, legacyImages is List ? legacyImages : null);

    // Initialize controllers for all text blocks
    for (final block in _blocks) {
      _ensureController(block);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _voiceService?.dispose();
    _titleCtrl.dispose();
    _titleFocus.dispose();
    _scrollController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  TextEditingController _ensureController(NoteBlock block) {
    return _controllers.putIfAbsent(block.id, () {
      return TextEditingController(text: block.text);
    });
  }

  FocusNode _ensureFocusNode(NoteBlock block) {
    return _focusNodes.putIfAbsent(block.id, () {
      final fn = FocusNode();
      fn.onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          final ctrl = _controllers[block.id];
          if (ctrl != null &&
              ctrl.selection.isValid &&
              ctrl.selection.baseOffset == 0 &&
              ctrl.selection.extentOffset == 0) {
            final idx = _blocks.indexWhere((b) => b.id == block.id);
            if (idx >= 0) {
              _onBlockBackspaceAtStart(idx);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      };
      return fn;
    });
  }

  void _cleanupBlock(String blockId) {
    _controllers.remove(blockId)?.dispose();
    _focusNodes.remove(blockId)?.dispose();
  }

  // ─── Dirty / autosave ──────────────────────────────────────────────────

  void _markDirty() {
    if (!_hasUnsavedChanges && mounted) setState(() => _hasUnsavedChanges = true);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (_hasUnsavedChanges) {
        final hasContent = _titleCtrl.text.trim().isNotEmpty ||
            _blocks.any((b) =>
                (b.isTextBlock && b.text.isNotEmpty) ||
                b.type == NoteBlockType.image);
        if (hasContent) _saveNote();
      }
    });
  }

  /// Sync all TextEditingControllers back into _blocks.
  void _syncBlockTexts() {
    for (int i = 0; i < _blocks.length; i++) {
      final b = _blocks[i];
      if (b.isTextBlock) {
        final ctrl = _controllers[b.id];
        if (ctrl != null && ctrl.text != b.text) {
          _blocks[i] = b.copyWith(text: ctrl.text);
        }
      }
    }
  }

  // ─── Save ──────────────────────────────────────────────────────────────

  Future<void> _saveNote({bool silent = true}) async {
    _syncBlockTexts();
    final title = _titleCtrl.text.trim();
    final hasContent = title.isNotEmpty ||
        _blocks.any((b) =>
            (b.isTextBlock && b.text.isNotEmpty) ||
            b.type == NoteBlockType.image);
    if (!hasContent) return;
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

      // Build legacy images array for backward compat with list screens
      final legacyImages = _blocks
          .where((b) => b.type == NoteBlockType.image && b.url != null)
          .map((b) => {
                'url': b.url,
                'path': b.storagePath,
                'created_at': now,
              })
          .toList();

      final noteData = <String, dynamic>{
        'user_id': userId,
        'title': title,
        'content': blocksToJson(_blocks),
        'color': _selectedColor,
        'pinned': _pinned,
        'updated_at': now,
        'images': legacyImages,
      };

      if (widget.customerId.isNotEmpty) {
        noteData['customer_id'] = widget.customerId;
      }
      if (widget.projectId != null && widget.projectId!.isNotEmpty) {
        noteData['project_id'] = widget.projectId;
      }

      if (_noteId != null) {
        try {
          await supabase.client
              .from('project_notes')
              .update(noteData)
              .eq('id', _noteId!);
        } catch (e) {
          debugPrint('Note update failed, retrying without optional columns: $e');
          noteData.remove('customer_id');
          noteData.remove('project_id');
          noteData.remove('images');
          await supabase.client
              .from('project_notes')
              .update(noteData)
              .eq('id', _noteId!);
        }
      } else {
        _noteId = const Uuid().v4();
        noteData['id'] = _noteId;
        noteData['created_at'] = now;
        try {
          await supabase.client.from('project_notes').insert(noteData);
        } catch (e) {
          debugPrint('Note insert failed, retrying without optional columns: $e');
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
          const SnackBar(
            content: Text('Could not save note. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Image upload ─────────────────────────────────────────────────────

  Future<void> _uploadPendingImages(SupabaseService supabase, String userId) async {
    for (int i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if (!block.isLocalImage) continue;

      final file = File(block.localPath!);
      if (!await file.exists()) continue;

      final ext = _normalizedExt(block.localPath!);
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

        _blocks[i] = block.copyWith(
          url: signedUrl,
          storagePath: storagePath,
          localPath: null,
        );
      } catch (e) {
        debugPrint('Image upload failed: $e');
      }
    }
  }

  // ─── Block operations ─────────────────────────────────────────────────

  void _insertBlockAfter(int index, NoteBlock newBlock) {
    setState(() {
      _blocks.insert(index + 1, newBlock);
      if (newBlock.isTextBlock) {
        _ensureController(newBlock);
      }
      _pendingFocusIndex = index + 1;
      _pendingCursorOffset = 0;
    });
    _markDirty();
  }

  void _removeBlock(int index) {
    if (_blocks.length <= 1 && _blocks[index].isTextBlock) {
      // Don't remove the last text block — just clear it
      final block = _blocks[index];
      _controllers[block.id]?.clear();
      _blocks[index] = block.copyWith(text: '', type: NoteBlockType.paragraph);
      setState(() {});
      _markDirty();
      return;
    }

    final removed = _blocks.removeAt(index);
    _cleanupBlock(removed.id);
    setState(() {});
    _markDirty();
  }

  void _updateBlock(int index, NoteBlock updated) {
    _blocks[index] = updated;
    _markDirty();
    setState(() {});
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
      _renumberBlocks();
    });
    _markDirty();
  }

  void _renumberBlocks() {
    int num = 1;
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].type == NoteBlockType.numbered) {
        _blocks[i] = _blocks[i].copyWith(number: num++);
      } else {
        num = 1;
      }
    }
  }

  /// Handle Enter key in a text block.
  void _onBlockEnter(int index) {
    _syncBlockTexts();
    final block = _blocks[index];
    final ctrl = _controllers[block.id];
    if (ctrl == null) return;

    final text = ctrl.text;
    final cursorPos = ctrl.selection.baseOffset.clamp(0, text.length);

    // If empty list block, convert to paragraph (exit list mode)
    if (block.isListBlock && text.trim().isEmpty) {
      _blocks[index] = NoteBlock(
        id: block.id,
        type: NoteBlockType.paragraph,
        text: '',
      );
      ctrl.text = '';
      setState(() {});
      _markDirty();
      return;
    }

    // Split text at cursor
    final before = text.substring(0, cursorPos);
    final after = text.substring(cursorPos);

    // Update current block with text before cursor
    ctrl.text = before;
    ctrl.selection = TextSelection.collapsed(offset: before.length);
    _blocks[index] = block.copyWith(text: before);

    // Create new block with text after cursor, same type
    NoteBlock newBlock;
    if (block.type == NoteBlockType.checklist) {
      newBlock = NoteBlock.checklist(after, false);
    } else if (block.type == NoteBlockType.bullet) {
      newBlock = NoteBlock.bullet(after);
    } else if (block.type == NoteBlockType.numbered) {
      newBlock = NoteBlock.numbered(after, block.number + 1);
    } else {
      newBlock = NoteBlock.paragraph(after);
    }

    _ensureController(newBlock).text = after;
    _insertBlockAfter(index, newBlock);
    _renumberBlocks();
  }

  /// Handle Backspace at position 0 in a text block.
  void _onBlockBackspaceAtStart(int index) {
    _syncBlockTexts();
    final block = _blocks[index];

    // If it's a list/heading block, convert to paragraph first
    if (block.type != NoteBlockType.paragraph) {
      _blocks[index] = block.copyWith(type: NoteBlockType.paragraph);
      setState(() {});
      _markDirty();
      return;
    }

    // Merge with previous text block
    if (index == 0) return;

    // Find previous text block
    int prevIndex = index - 1;
    while (prevIndex >= 0 && !_blocks[prevIndex].isTextBlock) {
      prevIndex--;
    }
    if (prevIndex < 0) return;

    final prevBlock = _blocks[prevIndex];
    final prevCtrl = _controllers[prevBlock.id];
    final currentCtrl = _controllers[block.id];
    if (prevCtrl == null || currentCtrl == null) return;

    final mergePoint = prevCtrl.text.length;
    final mergedText = prevCtrl.text + currentCtrl.text;

    prevCtrl.text = mergedText;
    _blocks[prevIndex] = prevBlock.copyWith(text: mergedText);

    // Remove current block
    _blocks.removeAt(index);
    _cleanupBlock(block.id);

    setState(() {
      _pendingFocusIndex = prevIndex;
      _pendingCursorOffset = mergePoint;
    });
    _markDirty();
  }

  /// Insert image(s) at the current focus position.
  /// Record voice and insert transcribed text as a new paragraph block.
  Future<void> _voiceDictate() async {
    if (_isRecordingVoice) {
      // Stop recording and process
      try {
        setState(() => _isRecordingVoice = false);
        final result = await _voiceService!.stopAndProcess();
        final transcript = result.transcript.trim();
        if (transcript.isNotEmpty && mounted) {
          // Insert transcript as a new paragraph block at the end
          final newBlock = NoteBlock(
            id: const Uuid().v4(),
            type: NoteBlockType.paragraph,
            text: transcript,
          );
          setState(() {
            _blocks.add(newBlock);
          });
          _markDirty();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice note added'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isRecordingVoice = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Voice capture failed. Try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else {
      // Start recording
      try {
        _voiceService ??= VoiceCaptureService(
          ref.read(voiceRepositoryProvider),
          ConnectivityService.instance,
        );
        await _voiceService!.startRecording();
        if (mounted) setState(() => _isRecordingVoice = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not start recording'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      // Find focused block index
      int insertAfter = _blocks.length - 1;
      for (int i = 0; i < _blocks.length; i++) {
        final fn = _focusNodes[_blocks[i].id];
        if (fn != null && fn.hasFocus) {
          insertAfter = i;
          break;
        }
      }

      List<String> paths = [];
      if (source == ImageSource.gallery) {
        final images = await ImagePicker().pickMultiImage(
          maxWidth: 1920,
          imageQuality: 85,
        );
        paths = images.map((i) => i.path).toList();
      } else {
        final image = await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          imageQuality: 85,
        );
        if (image != null) paths.add(image.path);
      }

      if (paths.isEmpty) return;

      setState(() {
        for (int i = 0; i < paths.length; i++) {
          final imgBlock = NoteBlock.image(localPath: paths[i]);
          _blocks.insert(insertAfter + 1 + i, imgBlock);
        }
        // Add empty paragraph after last image if needed
        final lastInserted = insertAfter + paths.length;
        if (lastInserted >= _blocks.length - 1 ||
            !_blocks[lastInserted + 1].isTextBlock) {
          final para = NoteBlock.paragraph();
          _blocks.insert(lastInserted + 1, para);
          _ensureController(para);
          _pendingFocusIndex = lastInserted + 1;
          _pendingCursorOffset = 0;
        } else {
          _pendingFocusIndex = lastInserted + 1;
          _pendingCursorOffset = 0;
        }
      });
      _markDirty();
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _removeImageBlock(int index) {
    final block = _blocks[index];
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
              if (block.storagePath != null) {
                try {
                  final supabase = ref.read(supabaseServiceProvider);
                  await supabase.deleteFile(
                    bucket: 'notes',
                    paths: [block.storagePath!],
                  );
                } catch (e) {
                  debugPrint('Storage delete failed: $e');
                }
              }
              _removeBlock(index);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewImage(NoteBlock block) {
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
              child: block.localPath != null
                  ? Image.file(File(block.localPath!), fit: BoxFit.contain)
                  : Image.network(block.url!, fit: BoxFit.contain,
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

  // ─── Toolbar actions ──────────────────────────────────────────────────

  void _insertBlockType(NoteBlockType type) {
    _syncBlockTexts();

    // Find focused block
    int focusedIndex = _blocks.length - 1;
    for (int i = 0; i < _blocks.length; i++) {
      final fn = _focusNodes[_blocks[i].id];
      if (fn != null && fn.hasFocus) {
        focusedIndex = i;
        break;
      }
    }

    final current = _blocks[focusedIndex];

    // If current block is empty text, convert it instead of inserting new
    if (current.isTextBlock) {
      final ctrl = _controllers[current.id];
      if (ctrl != null && ctrl.text.trim().isEmpty) {
        // Toggle: if already this type, revert to paragraph
        final newType = current.type == type ? NoteBlockType.paragraph : type;
        _blocks[focusedIndex] = current.copyWith(type: newType);
        setState(() {});
        _markDirty();
        return;
      }
    }

    // Insert new block after focused
    NoteBlock newBlock;
    switch (type) {
      case NoteBlockType.checklist:
        newBlock = NoteBlock.checklist();
      case NoteBlockType.bullet:
        newBlock = NoteBlock.bullet();
      case NoteBlockType.numbered:
        newBlock = NoteBlock.numbered();
      case NoteBlockType.heading:
        newBlock = NoteBlock.heading();
      case NoteBlockType.divider:
        newBlock = NoteBlock.divider();
      default:
        newBlock = NoteBlock.paragraph();
    }
    _ensureController(newBlock);
    _insertBlockAfter(focusedIndex, newBlock);
    _renumberBlocks();
  }

  // ─── Delete note ──────────────────────────────────────────────────────

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

                final paths = _blocks
                    .where((b) => b.storagePath != null)
                    .map((b) => b.storagePath!)
                    .toList();
                if (paths.isNotEmpty) {
                  try {
                    await supabase.deleteFile(bucket: 'notes', paths: paths);
                  } catch (e) {
                    debugPrint('Storage cleanup failed: $e');
                  }
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
                    const SnackBar(
                      content: Text('Could not delete note.'),
                      backgroundColor: Colors.red,
                    ),
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

  // ─── Back guard ────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    _syncBlockTexts();
    if (!_hasUnsavedChanges) return true;
    final hasContent = _titleCtrl.text.trim().isNotEmpty ||
        _blocks.any((b) =>
            (b.isTextBlock && b.text.isNotEmpty) ||
            b.type == NoteBlockType.image);
    if (!hasContent) return true;

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
    if (result == 'save') await _saveNote(silent: false);
    return true;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _normalizedExt(String path) {
    final segs = path.split('.');
    if (segs.length < 2) return 'jpg';
    final ext = segs.last.trim().toLowerCase();
    return ext == 'jpeg' ? 'jpg' : (ext.isEmpty ? 'jpg' : ext);
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'png': return 'image/png';
      case 'heic': return 'image/heic';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  Color _colorForName(String? name) => _colors[name] ?? AppColors.noteBlue;

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _colorForName(_selectedColor);
    final colorScheme = Theme.of(context).colorScheme;
    final updatedAt = widget.existingNote?['updated_at'] != null
        ? DateTime.tryParse(widget.existingNote!['updated_at'].toString())
        : null;

    // Handle pending focus requests
    if (_pendingFocusIndex != null) {
      final idx = _pendingFocusIndex!;
      final cursorOffset = _pendingCursorOffset ?? 0;
      _pendingFocusIndex = null;
      _pendingCursorOffset = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (idx < _blocks.length) {
          final block = _blocks[idx];
          final fn = _focusNodes[block.id];
          final ctrl = _controllers[block.id];
          fn?.requestFocus();
          if (ctrl != null) {
            ctrl.selection = TextSelection.collapsed(
              offset: cursorOffset.clamp(0, ctrl.text.length),
            );
          }
        }
      });
    }

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
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
          titleSpacing: 0,
          title: _buildSaveStatus(colorScheme),
          actions: [
            // More actions menu (pin, color, divider, delete)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, size: 22,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                switch (value) {
                  case 'pin':
                    setState(() => _pinned = !_pinned);
                    _markDirty();
                  case 'divider':
                    _insertBlockType(NoteBlockType.divider);
                  case 'delete':
                    _deleteNote();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Row(children: [
                    Icon(_pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 18, color: _pinned ? colorScheme.primary : null),
                    const SizedBox(width: 10),
                    Text(_pinned ? 'Unpin note' : 'Pin note'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'divider',
                  child: Row(children: [
                    Icon(Icons.horizontal_rule_rounded, size: 18,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    const Text('Insert divider'),
                  ]),
                ),
                if (_isEditing) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 10),
                      const Text('Delete note', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: _isSaving ? null : () async {
                  _syncBlockTexts();
                  await _saveNote(silent: false);
                  if (context.mounted) Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Editor body — clean document canvas
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_blocks.isEmpty || !_blocks.last.isTextBlock) {
                    final para = NoteBlock.paragraph();
                    _ensureController(para);
                    setState(() {
                      _blocks.add(para);
                      _pendingFocusIndex = _blocks.length - 1;
                    });
                  } else {
                    final lastBlock = _blocks.last;
                    _ensureFocusNode(lastBlock).requestFocus();
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date — quiet, editorial
                      if (updatedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            DateFormat('EEEE, MMM d, y \u2022 h:mm a').format(updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                              letterSpacing: 0.1,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                      // Title — large, bold, borderless
                      TextField(
                        key: const ValueKey('note_title_field'),
                        controller: _titleCtrl,
                        focusNode: _titleFocus,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.6,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.32),
                            fontWeight: FontWeight.w600,
                            fontSize: 28,
                            letterSpacing: -0.6,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _markDirty(),
                        onSubmitted: (_) {
                          if (_blocks.isNotEmpty && _blocks.first.isTextBlock) {
                            _ensureFocusNode(_blocks.first).requestFocus();
                          }
                        },
                      ),

                      // Breathing space after title
                      const SizedBox(height: 16),

                      // Block list — seamless, no visual borders
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 4,
                            shadowColor: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.surface,
                            child: child,
                          );
                        },
                        onReorder: _onReorder,
                        itemCount: _blocks.length,
                        itemBuilder: (context, index) {
                          final block = _blocks[index];
                          return _buildBlockWidget(
                            key: ValueKey(block.id),
                            block: block,
                            index: index,
                            colorScheme: colorScheme,
                          );
                        },
                      ),

                      // Generous tap zone at end
                      GestureDetector(
                        onTap: () {
                          if (_blocks.isEmpty || !_blocks.last.isTextBlock) {
                            final para = NoteBlock.paragraph();
                            _ensureController(para);
                            setState(() {
                              _blocks.add(para);
                              _pendingFocusIndex = _blocks.length - 1;
                            });
                          } else {
                            _ensureFocusNode(_blocks.last).requestFocus();
                          }
                        },
                        child: Container(
                          height: 280,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Compact toolbar
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  // ─── Save status indicator (in app bar) ────────────────────────────────

  Widget _buildSaveStatus(ColorScheme colorScheme) {
    if (_isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 6),
          Text('Saving…',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                fontWeight: FontWeight.w400,
              )),
        ],
      );
    }
    if (!_hasUnsavedChanges && _noteId != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done_outlined, size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(width: 5),
          Text('Saved',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                fontWeight: FontWeight.w400,
              )),
        ],
      );
    }
    // Show context chip when not showing save status
    return _buildContextChip();
  }

  // ─── Block widget builder ──────────────────────────────────────────────

  Widget _buildBlockWidget({
    required Key key,
    required NoteBlock block,
    required int index,
    required ColorScheme colorScheme,
  }) {
    switch (block.type) {
      case NoteBlockType.image:
        return _buildImageBlock(key: key, block: block, index: index, colorScheme: colorScheme);
      case NoteBlockType.divider:
        return _buildDividerBlock(key: key, block: block, index: index, colorScheme: colorScheme);
      default:
        return _buildTextBlock(key: key, block: block, index: index, colorScheme: colorScheme);
    }
  }

  Widget _buildTextBlock({
    required Key key,
    required NoteBlock block,
    required int index,
    required ColorScheme colorScheme,
  }) {
    final ctrl = _ensureController(block);
    final focusNode = _ensureFocusNode(block);

    // Document-native text styles
    TextStyle textStyle;
    switch (block.type) {
      case NoteBlockType.heading:
        textStyle = TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          height: 1.35,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        );
      default:
        textStyle = TextStyle(
          fontSize: 16,
          height: 1.55,
          color: colorScheme.onSurface.withValues(alpha: 0.85),
          letterSpacing: -0.15,
        );
    }

    // Quiet hint text
    String hintText;
    switch (block.type) {
      case NoteBlockType.heading:
        hintText = 'Heading';
      case NoteBlockType.checklist:
        hintText = 'To-do';
      case NoteBlockType.bullet:
      case NoteBlockType.numbered:
        hintText = 'List item';
      default:
        hintText = '';
    }

    // Leading widgets — elegant, not heavy
    Widget? leading;
    double leadingIndent = 0;
    switch (block.type) {
      case NoteBlockType.checklist:
        leadingIndent = 0;
        leading = GestureDetector(
          onTap: () {
            _blocks[index] = block.copyWith(checked: !block.checked);
            setState(() {});
            _markDirty();
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 10, top: 1),
            child: SizedBox(
              width: 22, height: 22,
              child: block.checked
                  ? Icon(Icons.check_circle_rounded, size: 20,
                      color: colorScheme.primary.withValues(alpha: 0.7))
                  : Icon(Icons.radio_button_unchecked_rounded, size: 20,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            ),
          ),
        );
      case NoteBlockType.bullet:
        leadingIndent = 4;
        leading = Padding(
          padding: const EdgeInsets.only(right: 10, top: 10),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
        );
      case NoteBlockType.numbered:
        leadingIndent = 0;
        leading = Padding(
          padding: const EdgeInsets.only(right: 8, top: 1),
          child: SizedBox(
            width: 22,
            child: Text(
              '${block.number}.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                height: 1.55,
              ),
            ),
          ),
        );
      default:
        break;
    }

    final textField = TextField(
      key: ValueKey('block_text_${block.id}'),
      controller: ctrl,
      focusNode: focusNode,
      style: block.type == NoteBlockType.checklist && block.checked
          ? textStyle.copyWith(
              decoration: TextDecoration.lineThrough,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            )
          : textStyle,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.18),
          height: textStyle.height,
          fontSize: textStyle.fontSize,
        ),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      inputFormatters: [
        _BlockTextInputFormatter(
          onEnter: () => _onBlockEnter(index),
          onBackspaceAtStart: () => _onBlockBackspaceAtStart(index),
        ),
      ],
      onChanged: (text) {
        _blocks[index] = block.copyWith(text: text);
        _markDirty();
      },
    );

    // Clean layout: optional leading + text, with invisible drag surface
    return ReorderableDragStartListener(
      key: key,
      index: index,
      child: Padding(
        padding: EdgeInsets.only(
          left: leading != null ? leadingIndent : 0,
          bottom: block.type == NoteBlockType.heading ? 4 : 0,
          top: block.type == NoteBlockType.heading && index > 0 ? 8 : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) leading,
            Expanded(child: textField),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBlock({
    required Key key,
    required NoteBlock block,
    required int index,
    required ColorScheme colorScheme,
  }) {
    final isLocal = block.localPath != null;
    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isLocal
          ? Image.file(
              File(block.localPath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 220,
            )
          : Image.network(
              block.url!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 220,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: colorScheme.outlineVariant, size: 32),
                ),
              ),
            ),
    );

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _viewImage(block),
        child: Stack(
          children: [
            imageWidget,
            // Subtle gradient at top for controls
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Drag handle — subtle, top-left
            Positioned(
              top: 8,
              left: 8,
              child: ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.open_with_rounded,
                      color: Colors.white70, size: 14),
                ),
              ),
            ),
            // Upload indicator
            if (isLocal)
              Positioned(
                top: 8,
                right: 42,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Colors.white70,
                    ),
                  ),
                ),
              ),
            // Remove — subtle X
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImageBlock(index),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerBlock({
    required Key key,
    required NoteBlock block,
    required int index,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      key: key,
      onDoubleTap: () => _removeBlock(index),
      child: ReorderableDragStartListener(
        index: index,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Context chip ──────────────────────────────────────────────────────

  Widget _buildContextChip() {
    final parts = <String>[];
    if (widget.customerName.isNotEmpty && widget.customerName != 'General') {
      parts.add(widget.customerName);
    }
    if (widget.projectName != null && widget.projectName!.isNotEmpty) {
      parts.add(widget.projectName!);
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_outline_rounded, size: 13,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            parts.join(' \u203a '),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // ─── Bottom toolbar — focused and clean ────────────────────────────────

  Widget _buildToolbar() {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Formatting tools
              _toolbarBtn(Icons.checklist_rounded, 'Checklist',
                  () => _insertBlockType(NoteBlockType.checklist), iconColor),
              _toolbarBtn(Icons.format_list_bulleted_rounded, 'Bullets',
                  () => _insertBlockType(NoteBlockType.bullet), iconColor),
              _toolbarBtn(Icons.format_list_numbered_rounded, 'Numbered',
                  () => _insertBlockType(NoteBlockType.numbered), iconColor),
              _toolbarBtn(Icons.title_rounded, 'Heading',
                  () => _insertBlockType(NoteBlockType.heading), iconColor),

              // Separator
              Container(
                width: 1, height: 20,
                color: colorScheme.outlineVariant.withValues(alpha: 0.12),
              ),

              // Media
              _toolbarBtn(Icons.camera_alt_rounded, 'Camera',
                  () => _pickImages(ImageSource.camera), iconColor),
              _toolbarBtn(Icons.photo_library_rounded, 'Photos',
                  () => _pickImages(ImageSource.gallery), iconColor),

              // Separator
              Container(
                width: 1, height: 20,
                color: colorScheme.outlineVariant.withValues(alpha: 0.12),
              ),

              // Voice dictation
              _toolbarBtn(
                _isRecordingVoice ? Icons.stop_rounded : Icons.mic_rounded,
                _isRecordingVoice ? 'Stop' : 'Dictate',
                _voiceDictate,
                _isRecordingVoice ? colorScheme.error : colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarBtn(IconData icon, String tooltip, VoidCallback onTap, Color color) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 20,
    );
  }
}

// ─── Custom TextInputFormatter for Enter/Backspace interception ──────────

class _BlockTextInputFormatter extends TextInputFormatter {
  final VoidCallback onEnter;
  final VoidCallback onBackspaceAtStart;

  _BlockTextInputFormatter({
    required this.onEnter,
    required this.onBackspaceAtStart,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Detect Enter key (newline inserted)
    if (newValue.text.length == oldValue.text.length + 1) {
      final insertedChar = newValue.text.length > 0 &&
              newValue.selection.baseOffset > 0
          ? newValue.text[newValue.selection.baseOffset - 1]
          : null;
      if (insertedChar == '\n') {
        // Block the newline, handle via block split
        WidgetsBinding.instance.addPostFrameCallback((_) => onEnter());
        return oldValue; // Reject the newline
      }
    }

    // Detect Backspace at position 0
    if (newValue.text.length == oldValue.text.length - 1 &&
        oldValue.selection.baseOffset == 0 &&
        oldValue.selection.extentOffset == 0 &&
        newValue.selection.baseOffset == 0) {
      // This pattern doesn't quite work because backspace at 0 doesn't change text.
      // We need a different approach.
    }

    // Detect backspace at start: old cursor was at 0, text didn't change (nothing to delete)
    // Actually: if selection was at 0 with no selection, and we get a composing change that
    // results in same text, it means backspace was pressed at position 0.
    // This is handled via RawKeyboardListener instead.

    return newValue;
  }
}
