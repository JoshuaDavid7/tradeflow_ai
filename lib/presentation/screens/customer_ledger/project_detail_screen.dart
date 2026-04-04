import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/supabase_service.dart';
import '../../../screens/draft_review_screen.dart';
import 'note_editor_screen.dart';
import 'block_editor/note_block.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> project;
  final String customerName;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.customerName,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  String get _projectId => widget.project['id'] ?? '';
  String get _customerId => widget.project['customer_id'] ?? '';
  String get _projectName => widget.project['name'] ?? 'Untitled Project';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              if (value == 'invoice') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DraftReviewScreen(
                      jobData: {
                        'type': 'invoice',
                        'materials': [],
                        'clientName': widget.customerName,
                        'client_name': widget.customerName,
                        'customer_id': _customerId,
                        'description':
                            'Project: $_projectName',
                      },
                    ),
                  ),
                );
              } else if (value == 'quote') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DraftReviewScreen(
                      jobData: {
                        'type': 'quote',
                        'materials': [],
                        'clientName': widget.customerName,
                        'client_name': widget.customerName,
                        'customer_id': _customerId,
                        'description':
                            'Project: $_projectName',
                      },
                    ),
                  ),
                );
              } else if (value == 'note') {
                _openNoteEditor();
              } else if (value == 'delete') {
                _confirmDeleteProject();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'invoice',
                child: ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('New Invoice'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'quote',
                child: ListTile(
                  leading: Icon(Icons.request_quote),
                  title: Text('New Quote'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'note',
                child: ListTile(
                  leading: Icon(Icons.note_add),
                  title: Text('Add Note'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Delete Project',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildProjectContent(),
    );
  }

  Widget _buildProjectContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadProjectNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Project info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('Client: ${widget.customerName}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 14, color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  ),
                  if (widget.project['description'] != null &&
                      widget.project['description']
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.project['description'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14)),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      (widget.project['status'] ?? 'active')
                          .toString()
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notes',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _openNoteEditor,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Note'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (notes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.note, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(height: 8),
                      Text('No notes yet',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              ...notes.map((note) => _buildNoteCard(note)),
          ],
        );
      },
    );
  }

  Color _statusColor(BuildContext context) {
    final status = widget.project['status']?.toString() ?? 'active';
    switch (status) {
      case 'completed':
        return AppColors.paid(context);
      case 'archived':
        return AppColors.draft(context);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _parseColor(String name) {
    switch (name) {
      case 'green':
        return AppColors.noteGreen;
      case 'orange':
        return AppColors.noteOrange;
      case 'red':
        return AppColors.noteRed;
      case 'purple':
        return AppColors.notePurple;
      case 'teal':
        return AppColors.noteTeal;
      default:
        return AppColors.noteBlue;
    }
  }

  Future<List<Map<String, dynamic>>> _loadProjectNotes() async {
    final supabase = ref.read(supabaseServiceProvider);
    final userId = ref.read(userIdProvider);
    if (userId == null) return [];

    try {
      await supabase.ensureValidSession();
      // Filter by project_id so only notes for THIS project appear
      final data = await supabase.client
          .from('project_notes')
          .select()
          .eq('user_id', userId)
          .eq('customer_id', _customerId)
          .eq('project_id', _projectId)
          .order('updated_at', ascending: false);
      final notes = List<Map<String, dynamic>>.from(data as List);
      // Sort pinned notes first
      notes.sort((a, b) {
        final aPinned = a['pinned'] == true ? 0 : 1;
        final bPinned = b['pinned'] == true ? 0 : 1;
        if (aPinned != bPinned) return aPinned.compareTo(bPinned);
        final aDate = DateTime.tryParse(a['updated_at']?.toString() ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(b['updated_at']?.toString() ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return notes;
    } catch (e) {
      // project_id or customer_id column may not exist — return empty
      // rather than leaking unrelated notes.
      debugPrint('Project notes fetch failed (column may not exist): $e');
      return [];
    }
  }

  // ─── Note Editor Navigation ─────────────────────────────────────────────

  Future<void> _confirmDeleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'This will permanently delete "$_projectName" and all its notes. '
          'Linked invoices and quotes will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final projectId = widget.project['id']?.toString();
      if (projectId == null) return;

      final supabase = Supabase.instance.client;
      // Delete project notes first
      await supabase
          .from('project_notes')
          .delete()
          .eq('project_id', projectId);
      // Delete the project
      await supabase.from('projects').delete().eq('id', projectId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete project'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _openNoteEditor({Map<String, dynamic>? existingNote}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: existingNote,
          customerId: _customerId,
          customerName: widget.customerName,
          projectId: _projectId,
          projectName: _projectName,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  // ─── Professional Note Card ─────────────────────────────────────────────

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final color = _parseColor(note['color']?.toString() ?? 'blue');
    final pinned = note['pinned'] == true;
    final title = note['title']?.toString() ?? 'Untitled';
    final content = note['content']?.toString() ?? '';
    final images = _parseNoteImages(note);
    final updatedAt = DateTime.tryParse(note['updated_at']?.toString() ?? '');

    return GestureDetector(
      onTap: () => _openNoteEditor(existingNote: note),
      onLongPress: () => _showNoteActions(note),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (pinned) ...[
                            Icon(Icons.push_pin,
                                size: 14, color: AppColors.sent(context)),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ],
                      ),
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(plainTextPreview(content, maxLength: 100),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.4)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (images.isNotEmpty) ...[
                            Icon(Icons.photo_outlined,
                                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text('${images.length}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                          ],
                          if (updatedAt != null)
                            Text(DateFormat('MMM d, y').format(updatedAt),
                                style: TextStyle(
                                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Thumbnail
                if (images.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.network(
                        images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          child: Icon(Icons.photo,
                              color: Theme.of(context).colorScheme.outlineVariant, size: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _parseNoteImages(Map<String, dynamic> note) {
    final raw = note['images'];
    if (raw == null) return [];
    try {
      final list = raw is String ? jsonDecode(raw) : raw;
      if (list is! List) return [];
      return list
          .map((e) => e is Map ? e['url']?.toString() : null)
          .whereType<String>()
          .toList();
    } catch (e) {
      debugPrint('Image URL extraction failed: $e');
      return [];
    }
  }

  void _showNoteActions(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openNoteEditor(existingNote: note);
                },
              ),
              ListTile(
                leading: Icon(
                  note['pinned'] == true
                      ? Icons.push_pin_outlined
                      : Icons.push_pin,
                ),
                title: Text(
                    note['pinned'] == true ? 'Unpin' : 'Pin to top'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _togglePin(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteNote(note);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePin(Map<String, dynamic> note) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.ensureValidSession();
      final newPinned = !(note['pinned'] == true);
      await supabase.client
          .from('project_notes')
          .update({'pinned': newPinned}).eq('id', note['id']);
      setState(() {});
    } catch (e) {
      debugPrint('Note pin toggle failed: $e');
    }
  }

  void _confirmDeleteNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('Delete "${note['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.ensureValidSession();
                await supabase.client
                    .from('project_notes')
                    .delete()
                    .eq('id', note['id']);
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note deleted'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not delete note. Please try again.'),
                        backgroundColor: Colors.red),
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
}
