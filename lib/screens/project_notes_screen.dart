import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../presentation/screens/customer_ledger/note_editor_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchNotes();
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
      // Table may not exist yet — that's OK, just show empty state
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    final q = _searchQuery.toLowerCase();
    return _notes.where((n) {
      final title = (n['title'] ?? '').toString().toLowerCase();
      final content = (n['content'] ?? '').toString().toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Project Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteEditor(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),

                // Notes list or empty state
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchNotes,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _noteCard(filtered[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _noteCard(Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? 'Untitled';
    final content = note['content']?.toString() ?? '';
    final color = _parseColor(note['color']?.toString());
    final updatedAt = DateTime.tryParse(note['updated_at']?.toString() ?? '') ?? DateTime.now();
    final pinned = note['pinned'] == true;
    final images = _parseNoteImages(note);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openNoteEditor(existingNote: note),
        onLongPress: () => _showNoteActions(note),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (pinned) ...[
                          Icon(Icons.push_pin,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall),
                        ),
                      ],
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    } catch (_) {
      return [];
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notes_rounded, size: 64,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No matching notes' : 'No project notes yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Store site measurements, client preferences,\nor job-specific details.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openNoteEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Create First Note'),
            ),
          ],
        ],
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
          customerName: 'General',
        ),
      ),
    ).then((_) => _fetchNotes());
  }

  void _showNoteActions(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
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
                note['pinned'] == true ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note['pinned'] == true ? 'Unpin' : 'Pin to top'),
              onTap: () async {
                Navigator.pop(ctx);
                await _togglePin(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(Map<String, dynamic> note) async {
    try {
      final newPinned = !(note['pinned'] == true);
      await _supabase.from('project_notes').update({'pinned': newPinned}).eq('id', note['id']);
      await _fetchNotes();
    } catch (e) {
      // silently fail
    }
  }

  void _confirmDelete(Map<String, dynamic> note) {
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
                await _supabase.from('project_notes').delete().eq('id', note['id']);
                await _fetchNotes();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (mounted) {
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

  Color _parseColor(String? colorName) {
    switch (colorName) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      default: return Colors.blue;
    }
  }
}
