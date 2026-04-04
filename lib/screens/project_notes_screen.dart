import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../presentation/screens/customer_ledger/note_editor_screen.dart';
import '../presentation/screens/customer_ledger/block_editor/note_block.dart';

class ProjectNotesScreen extends StatefulWidget {
  const ProjectNotesScreen({super.key});

  @override
  State<ProjectNotesScreen> createState() => _ProjectNotesScreenState();
}

class _ProjectNotesScreenState extends State<ProjectNotesScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notes = [];
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('project_notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _notes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    final q = _searchQuery.toLowerCase();
    return _notes.where((n) {
      final title = (n['title'] ?? '').toString().toLowerCase();
      final content = (n['content'] ?? '').toString().toLowerCase();
      final preview = plainTextPreview(content).toLowerCase();
      return title.contains(q) || preview.contains(q) || content.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredNotes;
    final pinned = filtered.where((n) => n['pinned'] == true).toList();
    final unpinned = filtered.where((n) => n['pinned'] != true).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Notes',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.3,
            )),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'project_notes_fab',
        onPressed: () => _openNoteEditor(),
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search notes…',
                      prefixIcon: Icon(Icons.search,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),

                // Notes list
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchNotes,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            children: [
                              // Pinned section
                              if (pinned.isNotEmpty) ...[
                                _buildSectionHeader(
                                    'Pinned', Icons.push_pin_rounded),
                                ...pinned.map((n) => _noteCard(n)),
                                if (unpinned.isNotEmpty)
                                  const SizedBox(height: 12),
                              ],

                              // All / Other section
                              if (unpinned.isNotEmpty) ...[
                                if (pinned.isNotEmpty)
                                  _buildSectionHeader('Other', null),
                                ...unpinned.map((n) => _noteCard(n)),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String label, IconData? icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _noteCard(Map<String, dynamic> note) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = note['title']?.toString() ?? '';
    final content = note['content']?.toString() ?? '';
    final color = _parseColor(note['color']?.toString());
    final updatedAt = DateTime.tryParse(note['updated_at']?.toString() ?? '') ??
        DateTime.now();
    final pinned = note['pinned'] == true;

    // Use block-aware preview
    final preview = plainTextPreview(content, maxLength: 100);

    // Get image URLs for thumbnail
    final imageUrls = extractImageUrls(content, note['images']);
    final hasImages = imageUrls.isNotEmpty;

    // Format date
    final now = DateTime.now();
    final isToday = updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day;
    final dateStr = isToday
        ? DateFormat('h:mm a').format(updatedAt)
        : DateFormat('MMM d').format(updatedAt);

    // Count checklist items
    final checklistInfo = _getChecklistInfo(content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: InkWell(
        onTap: () => _openNoteEditor(existingNote: note),
        onLongPress: () => _showNoteActions(note),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color accent dot
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 12),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        if (pinned) ...[
                          Icon(Icons.push_pin_rounded,
                              size: 11,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            title.isNotEmpty ? title : 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: title.isNotEmpty
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        // Date — right aligned
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.35),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    // Preview text
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.55),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],

                    // Subtle meta chips
                    if (hasImages || checklistInfo != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (hasImages) ...[
                            Icon(Icons.photo_outlined,
                                size: 12,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3)),
                            const SizedBox(width: 3),
                            Text('${imageUrls.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.35),
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                          if (hasImages && checklistInfo != null)
                            const SizedBox(width: 10),
                          if (checklistInfo != null) ...[
                            Icon(Icons.check_circle_outline_rounded,
                                size: 12,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3)),
                            const SizedBox(width: 3),
                            Text(checklistInfo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.35),
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Thumbnail — slightly larger, cleaner
              if (hasImages) ...[
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.network(
                      imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colorScheme.surfaceContainerLow,
                        child: Icon(Icons.photo_rounded,
                            color: colorScheme.outlineVariant, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Extract checklist progress from content (e.g. "3/5").
  String? _getChecklistInfo(String content) {
    try {
      final trimmed = content.trim();
      if (trimmed.startsWith('{') && trimmed.contains('"v"')) {
        final blocks = parseNoteContent(content, null);
        final checklists =
            blocks.where((b) => b.type == NoteBlockType.checklist).toList();
        if (checklists.isEmpty) return null;
        final checked = checklists.where((b) => b.checked).length;
        return '$checked/${checklists.length}';
      }
      // Legacy: count ☐ and ☑
      final unchecked = RegExp('☐').allMatches(content).length;
      final checked = RegExp('☑').allMatches(content).length;
      final total = unchecked + checked;
      if (total == 0) return null;
      return '$checked/$total';
    } catch (_) {
      return null;
    }
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined,
                size: 44,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No matching notes' : 'No notes yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Capture site notes, punch lists,\nand job details with photos.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openNoteEditor({Map<String, dynamic>? existingNote}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: existingNote,
          customerId: '',
          customerName: '',
        ),
      ),
    ).then((_) => _fetchNotes());
  }

  void _showNoteActions(Map<String, dynamic> note) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openNoteEditor(existingNote: note);
                },
              ),
              ListTile(
                leading: Icon(
                  note['pinned'] == true
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                ),
                title: Text(note['pinned'] == true ? 'Unpin' : 'Pin to top'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _togglePin(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(note);
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
      final newPinned = !(note['pinned'] == true);
      await _supabase
          .from('project_notes')
          .update({'pinned': newPinned}).eq('id', note['id']);
      await _fetchNotes();
    } catch (e) {
      debugPrint('Toggle pin failed: $e');
    }
  }

  void _confirmDelete(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text(
          'Delete "${note['title']?.toString().isNotEmpty == true ? note['title'] : 'Untitled'}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Delete images from storage
                final blocks =
                    parseNoteContent(note['content']?.toString(), null);
                final paths = blocks
                    .where((b) => b.storagePath != null)
                    .map((b) => b.storagePath!)
                    .toList();
                if (paths.isNotEmpty) {
                  try {
                    await _supabase.storage.from('notes').remove(paths);
                  } catch (_) {}
                }

                await _supabase
                    .from('project_notes')
                    .delete()
                    .eq('id', note['id']);
                await _fetchNotes();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note deleted'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
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

  Color _parseColor(String? colorName) {
    const colors = {
      'blue': AppColors.noteBlue,
      'green': AppColors.noteGreen,
      'orange': AppColors.noteOrange,
      'red': AppColors.noteRed,
      'purple': AppColors.notePurple,
      'teal': AppColors.noteTeal,
    };
    return colors[colorName] ?? AppColors.noteBlue;
  }
}
