import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/customer_ledger_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../screens/draft_review_screen.dart';
import '../../../screens/pdf_preview_screen.dart';
import 'project_detail_screen.dart';
import 'note_editor_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String get _customerId => widget.customer['id'] ?? '';
  String get _customerName => widget.customer['name'] ?? 'Unknown';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customerName),
        actions: [
          // Create invoice for this customer
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
                        'clientName': _customerName,
                        'client_name': _customerName,
                        'customer_id': _customerId,
                        'clientPhone': widget.customer['phone'] ?? '',
                        'clientEmail': widget.customer['email'] ?? '',
                        'clientAddress': widget.customer['address'] ?? '',
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
                        'clientName': _customerName,
                        'client_name': _customerName,
                        'customer_id': _customerId,
                        'clientPhone': widget.customer['phone'] ?? '',
                        'clientEmail': widget.customer['email'] ?? '',
                        'clientAddress': widget.customer['address'] ?? '',
                      },
                    ),
                  ),
                );
              } else if (value == 'project') {
                _showAddProjectDialog();
              } else if (value == 'note') {
                _openNoteEditor();
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
                value: 'project',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder),
                  title: Text('New Project'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'note',
                child: ListTile(
                  leading: Icon(Icons.note_add),
                  title: Text('New Note'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Projects'),
            Tab(text: 'Jobs'),
            Tab(text: 'Expenses'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Customer summary card
          _buildSummaryCard(),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectsTab(),
                _buildJobsTab(),
                _buildExpensesTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final jobsAsync = ref.watch(customerJobsProvider(_customerId));

    return jobsAsync.when(
      data: (jobs) {
        // Compute totals from actual job data
        double totalBilled = 0.0;
        double totalPaid = 0.0;
        for (final job in jobs) {
          final type = (job['type']?.toString().toLowerCase() ?? 'invoice');
          if (type == 'quote') continue; // Don't count quotes as billed
          final total = (job['total_amount'] as num?)?.toDouble() ?? 0.0;
          totalBilled += total;
          // Payment state is derived from amounts, not from status column.
          final amountPaid =
              (job['amount_paid'] as num?)?.toDouble() ?? 0.0;
          totalPaid += amountPaid;
        }
        final balance = totalBilled - totalPaid;

        return _buildSummaryRow(totalBilled, totalPaid, balance);
      },
      loading: () {
        // Fall back to customer record while loading
        final totalBilled =
            (widget.customer['total_billed'] as num?)?.toDouble() ?? 0.0;
        final totalPaid =
            (widget.customer['total_paid'] as num?)?.toDouble() ?? 0.0;
        final balance = (widget.customer['balance'] as num?)?.toDouble() ?? 0.0;
        return _buildSummaryRow(totalBilled, totalPaid, balance);
      },
      error: (_, __) => _buildSummaryRow(0, 0, 0),
    );
  }

  Widget _buildSummaryRow(double totalBilled, double totalPaid, double balance) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(child: _buildStat('Billed', '\$${totalBilled.toStringAsFixed(0)}',
              Theme.of(context).colorScheme.primary)),
          Container(height: 30, width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Flexible(child: _buildStat(
              'Paid', '\$${totalPaid.toStringAsFixed(0)}', AppColors.paid(context))),
          Container(height: 30, width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Flexible(child: _buildStat(
            'Outstanding',
            '\$${balance.toStringAsFixed(0)}',
            balance > 0 ? AppColors.sent(context) : AppColors.paid(context),
          )),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildProjectsTab() {
    final projectsAsync = ref.watch(customerProjectsProvider(_customerId));

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return _emptyState(
            icon: Icons.folder_open,
            message: 'No projects yet',
            subtitle: 'Tap + to create a project for $_customerName',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            final status = project['status'] ?? 'active';
            final statusColor = status == 'completed'
                ? AppColors.paid(context)
                : status == 'archived'
                    ? AppColors.draft(context)
                    : Theme.of(context).colorScheme.primary;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(
                      project: project,
                      customerName: _customerName,
                    ),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  child: Icon(Icons.folder, color: statusColor, size: 20),
                ),
                title: Text(project['name'] ?? 'Untitled',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(project['description'] ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => _emptyState(
        icon: Icons.folder_open,
        message: 'No projects yet',
        subtitle: 'Tap + to create a project',
      ),
    );
  }

  Widget _buildJobsTab() {
    final jobsAsync = ref.watch(customerJobsProvider(_customerId));

    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return _emptyState(
            icon: Icons.receipt_long,
            message: 'No invoices or quotes',
            subtitle: 'Create one using the + button above',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            final type = job['type'] ?? 'invoice';
            final status = job['status'] ?? 'draft';
            final total =
                (job['total_amount'] as num?)?.toDouble() ?? 0.0;
            final createdAt = DateTime.tryParse(
                    job['created_at']?.toString() ?? '') ??
                DateTime.now();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () {
                  final jobStatus =
                      (job['status']?.toString().toLowerCase()) ?? 'draft';
                  final isSent = jobStatus == 'sent' ||
                      jobStatus == 'paid' ||
                      jobStatus == 'cancelled';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isSent
                          ? PdfPreviewScreen(jobData: job)
                          : DraftReviewScreen(jobData: job),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: type == 'quote'
                      ? AppColors.paid(context).withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(
                    type == 'quote'
                        ? Icons.request_quote
                        : Icons.receipt_long,
                    color:
                        type == 'quote' ? AppColors.paid(context) : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  job['title'] ?? job['client_name'] ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${type.toUpperCase()} \u2022 ${status.toUpperCase()} \u2022 ${DateFormat('MMM d, y').format(createdAt)}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                trailing: Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => _emptyState(
        icon: Icons.receipt_long,
        message: 'No invoices or quotes',
      ),
    );
  }

  Widget _buildExpensesTab() {
    final expensesAsync = ref.watch(customerExpensesProvider(_customerId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return _emptyState(
            icon: Icons.money_off,
            message: 'No expenses tracked',
            subtitle: 'Expenses linked to this client will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final amount =
                (expense['amount'] as num?)?.toDouble() ?? 0.0;
            final vendor = expense['vendor'] ?? '';
            final desc = expense['description'] ?? 'Expense';
            final dateStr = expense['expense_date']?.toString() ?? '';
            final date = DateTime.tryParse(dateStr);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.expense(context).withValues(alpha: 0.1),
                  child: Icon(Icons.receipt, color: AppColors.expense(context), size: 20),
                ),
                title: Text(desc,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    if (vendor.isNotEmpty) vendor,
                    if (date != null) DateFormat('MMM d, y').format(date),
                  ].join(' \u2022 '),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                trailing: Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.expense(context)),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => _emptyState(
        icon: Icons.money_off,
        message: 'No expenses tracked',
      ),
    );
  }

  Widget _buildNotesTab() {
    final notesAsync = ref.watch(customerNotesProvider(_customerId));

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_alt_outlined, size: 56, color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 14),
                Text('No notes yet',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text('Record measurements, site details,\nor client preferences',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openNoteEditor,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Note'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        // Separate pinned and unpinned
        final pinned = notes.where((n) => n['pinned'] == true).toList();
        final unpinned = notes.where((n) => n['pinned'] != true).toList();

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                if (pinned.isNotEmpty) ...[
                  _noteSectionHeader('Pinned', Icons.push_pin, AppColors.sent(context)),
                  ...pinned.map(_buildNoteCard),
                  const SizedBox(height: 12),
                ],
                if (unpinned.isNotEmpty) ...[
                  if (pinned.isNotEmpty)
                    _noteSectionHeader('Notes', Icons.note_alt_outlined, Theme.of(context).colorScheme.onSurfaceVariant),
                  ...unpinned.map(_buildNoteCard),
                ],
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _openNoteEditor,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => _emptyState(
        icon: Icons.note,
        message: 'No notes yet',
      ),
    );
  }

  Widget _noteSectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? 'Untitled';
    final content = note['content']?.toString() ?? '';
    final colorStr = note['color']?.toString() ?? 'blue';
    final color = _parseNoteColor(colorStr);
    final updatedAt = DateTime.tryParse(note['updated_at']?.toString() ?? '');
    final pinned = note['pinned'] == true;
    final images = _parseNoteImages(note['images']);
    final firstImageUrl = images.isNotEmpty ? images.first['url']?.toString() : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNoteEditor(existingNote: note),
        onLongPress: () => _showNoteActions(note),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with pin
                    Row(
                      children: [
                        if (pinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin,
                                size: 14, color: AppColors.sent(context)),
                          ),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(content,
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    // Metadata row
                    Row(
                      children: [
                        if (images.isNotEmpty) ...[
                          Icon(Icons.image,
                              size: 13, color: Theme.of(context).colorScheme.outlineVariant),
                          const SizedBox(width: 2),
                          Text('${images.length}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 8),
                        ],
                        if (updatedAt != null)
                          Text(
                            DateFormat('MMM d, y').format(updatedAt),
                            style: TextStyle(
                                fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Thumbnail
              if (firstImageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstImageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Icon(Icons.image,
                          color: Theme.of(context).colorScheme.outlineVariant, size: 24),
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

  List<Map<String, dynamic>> _parseNoteImages(dynamic imagesJson) {
    if (imagesJson == null) return [];
    if (imagesJson is List) {
      return imagesJson
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }

  Color _parseNoteColor(String? name) {
    switch (name) {
      case 'green': return AppColors.noteGreen;
      case 'orange': return AppColors.noteOrange;
      case 'red': return AppColors.noteRed;
      case 'purple': return AppColors.notePurple;
      case 'teal': return AppColors.noteTeal;
      default: return AppColors.noteBlue;
    }
  }

  void _openNoteEditor({Map<String, dynamic>? existingNote}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: existingNote,
          customerId: _customerId,
          customerName: _customerName,
        ),
      ),
    ).then((_) {
      ref.invalidate(customerNotesProvider(_customerId));
    });
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
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final supabase = ref.read(supabaseServiceProvider);
                  try {
                    await supabase.ensureValidSession();
                    await supabase.client
                        .from('project_notes')
                        .update({'pinned': !(note['pinned'] == true)})
                        .eq('id', note['id']);
                    ref.invalidate(customerNotesProvider(_customerId));
                  } catch (_) {}
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

  void _confirmDeleteNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text(
            'Delete "${note['title']}"? This cannot be undone.'),
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
                ref.invalidate(customerNotesProvider(_customerId));
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
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  void _showAddProjectDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Project for $_customerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final supabase = ref.read(supabaseServiceProvider);
              final userId = ref.read(userIdProvider);
              if (userId == null) return;

              final now = DateTime.now().toIso8601String();
              try {
                await supabase.ensureValidSession();
                await supabase.client.from('projects').insert({
                  'id': const Uuid().v4(),
                  'user_id': userId,
                  'customer_id': _customerId,
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  'status': 'active',
                  'created_at': now,
                  'updated_at': now,
                });
                ref.invalidate(customerProjectsProvider(_customerId));
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(
                          'Failed to create project. Please run the latest '
                          'database migration and try again.'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
