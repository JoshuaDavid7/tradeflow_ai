import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:tradeflow_ai/core/config/env_config.dart';
import 'package:tradeflow_ai/data/local/database.dart';
import 'package:tradeflow_ai/data/repositories/expense_repository.dart';
import 'package:tradeflow_ai/data/repositories/job_repository.dart';
import 'package:tradeflow_ai/data/repositories/material_cost_repository.dart';
import 'package:tradeflow_ai/data/services/supabase_service.dart';
import 'package:tradeflow_ai/domain/models/business_profile.dart';
import 'package:tradeflow_ai/domain/models/expense.dart' as domain;
import 'package:tradeflow_ai/domain/models/job.dart' as job_domain;
import 'package:tradeflow_ai/presentation/providers/analytics_provider.dart';
import 'package:tradeflow_ai/presentation/providers/profile_provider.dart';
import 'package:tradeflow_ai/presentation/widgets/material_cost_status.dart';

const _userId = 'audit-user';
const _currencySymbol = '\$';
const _baselineRevenue = 5205.0;
const _baselineSpent = 3520.0;
final _auditMonth = DateTime(2026, 3, 1);
const _uuid = Uuid();

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EnvConfig.initialize(environment: 'development');
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      debug: true,
    );
  });

  Future<void> seedBaselineExpense(IExpenseRepository expenseRepo) async {
    await expenseRepo.createExpense(
      domain.Expense(
        id: _uuid.v4(),
        userId: _userId,
        description: 'Baseline operating expenses',
        vendor: 'Audit Seed',
        category: domain.ExpenseCategory.tools,
        amount: _baselineSpent,
        expenseDate: DateTime(2026, 3, 2),
        paymentMethod: domain.PaymentMethod.card,
        createdAt: DateTime(2026, 3, 2),
        updatedAt: DateTime(2026, 3, 2),
      ),
    );
  }

  Future<_Harness> createHarness() async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{'material_cost_backfill_done': true},
    );

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final expenseRepo = ExpenseRepository(db);
    final materialRepo = MaterialCostRepository(db);
    const jobRepo = _FakeJobRepository(
      monthlyCollected: _baselineRevenue,
    );

    await seedBaselineExpense(expenseRepo);

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
        materialCostRepositoryProvider.overrideWithValue(materialRepo),
        jobRepositoryProvider.overrideWithValue(jobRepo),
        userIdProvider.overrideWithValue(_userId),
        businessProfileProvider.overrideWithValue(
          const BusinessProfile(
            id: _userId,
            businessName: 'Audit Plumbing Co.',
            defaultHourlyRate: 85,
            defaultTaxRate: 0,
            currencySymbol: _currencySymbol,
          ),
        ),
        currencySymbolProvider.overrideWithValue(_currencySymbol),
      ],
    );

    return _Harness(
      db: db,
      expenseRepo: expenseRepo,
      materialRepo: materialRepo,
      container: container,
    );
  }

  Future<void> pumpMaterialSection(
    WidgetTester tester,
    ProviderContainer container, {
    required String jobId,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: MaterialCostStatusSection(
                    jobId: jobId,
                    userId: _userId,
                    currencySymbol: _currencySymbol,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<BusinessAnalytics> loadAnalytics(ProviderContainer container) async {
    await container.read(analyticsProvider.notifier).loadAnalytics(
          month: _auditMonth,
        );
    final state = container.read(analyticsProvider);
    expect(state.hasValue, isTrue);
    return state.requireValue;
  }

  Future<domain.Expense> addExpense(
    IExpenseRepository expenseRepo, {
    required String description,
    required double amount,
    required domain.ExpenseCategory category,
    String? jobId,
    DateTime? expenseDate,
  }) {
    final when = expenseDate ?? DateTime(2026, 3, 10);
    return expenseRepo.createExpense(
      domain.Expense(
        id: _uuid.v4(),
        userId: _userId,
        jobId: jobId,
        description: description,
        vendor: 'Audit Vendor',
        category: category,
        amount: amount,
        expenseDate: when,
        paymentMethod: domain.PaymentMethod.card,
        createdAt: when,
        updatedAt: when,
      ),
    );
  }

  Future<void> expandMaterialSection(WidgetTester tester) async {
    final header = find.byKey(const ValueKey('material_cost_section_header'));
    await tester.ensureVisible(header);
    await tester.tap(header, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> tapLinkForCost(WidgetTester tester, String costId) async {
    final button = find.byKey(ValueKey('material_cost_link_$costId'));
    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> tapSuggestedLink(
    WidgetTester tester,
    String costId,
    String expenseId,
  ) async {
    final suggestionKey = ValueKey(
      'material_cost_pick_suggested_button_${costId}_$expenseId',
    );
    final fallbackKey =
        ValueKey('material_cost_pick_all_button_${costId}_$expenseId');
    if (find.byKey(suggestionKey).evaluate().isNotEmpty) {
      final suggestion = find.byKey(suggestionKey);
      await tester.ensureVisible(suggestion);
      await tester.tap(suggestion, warnIfMissed: false);
    } else {
      final fallback = find.byKey(fallbackKey);
      await tester.ensureVisible(fallback);
      await tester.tap(fallback, warnIfMissed: false);
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapUnlinkForCost(WidgetTester tester, String costId) async {
    final button = find.byKey(ValueKey('material_cost_unlink_$costId'));
    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Unlink receipt?'), findsOneWidget);
    expect(
      find.text(
        'The app will stop using the receipt amount and go back to the invoice cost for this material.',
      ),
      findsOneWidget,
    );

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.tap(find.descendant(
      of: dialog,
      matching: find.widgetWithText(FilledButton, 'Unlink'),
    ));
    await tester.pumpAndSettle();
  }

  void logSnapshot(String label, BusinessAnalytics analytics) {
    // ignore: avoid_print
    print(
      'AUDIT_RESULT|$label|collected=${analytics.monthlyRevenue.toStringAsFixed(2)}'
      '|spent=${analytics.monthlyExpenses.toStringAsFixed(2)}'
      '|profit=${analytics.monthlyProfit.toStringAsFixed(2)}',
    );
  }

  testWidgets(
      'TEST A markup uses billed amount on invoice and cost basis in spent',
      (tester) async {
    final harness = await createHarness();
    addTearDown(() async {
      harness.container.dispose();
      await harness.db.close();
    });

    final jobId = _uuid.v4();
    final materials = [
      {
        'id': _uuid.v4(),
        'item': 'Copper pipe kit',
        'cost': 50.0,
        'originalCost': 30.0,
        'fromReceipt': true,
      },
    ];

    await harness.materialRepo.recognizeMaterialCosts(
      _userId,
      jobId,
      materials,
      DateTime(2026, 3, 12),
    );

    final recognized = await harness.materialRepo.getCostsForJob(jobId);
    expect(recognized, hasLength(1));
    expect(recognized.single.provisionalCost, 30.0);
    expect(recognized.single.canonicalCost, 30.0);

    final analytics = await loadAnalytics(harness.container);
    logSnapshot('TEST_A_AFTER_SEND', analytics);

    expect(analytics.monthlyRevenue, _baselineRevenue);
    expect(analytics.monthlyExpenses, 3550.0);
    expect(analytics.monthlyProfit, 1655.0);
  });

  testWidgets('TESTS B C and F link unlink relink flows stay canonical',
      (tester) async {
    final harness = await createHarness();
    addTearDown(() async {
      harness.container.dispose();
      await harness.db.close();
    });

    final jobId = _uuid.v4();
    final materials = [
      {
        'id': _uuid.v4(),
        'item': 'Expansion valve',
        'cost': 30.0,
      },
    ];

    await harness.materialRepo.recognizeMaterialCosts(
      _userId,
      jobId,
      materials,
      DateTime(2026, 3, 12),
    );

    final initialAnalytics = await loadAnalytics(harness.container);
    logSnapshot('TEST_B_INITIAL_PROVISIONAL', initialAnalytics);
    expect(initialAnalytics.monthlyExpenses, 3550.0);

    final expense = await addExpense(
      harness.expenseRepo,
      description: 'Expansion valve receipt',
      amount: 35.0,
      category: domain.ExpenseCategory.materials,
      jobId: jobId,
      expenseDate: DateTime(2026, 3, 13),
    );

    final beforeLink = await loadAnalytics(harness.container);
    logSnapshot('TEST_B_BEFORE_LINK', beforeLink);
    expect(beforeLink.monthlyExpenses, 3585.0);
    expect(beforeLink.monthlyProfit, 1620.0);

    await pumpMaterialSection(tester, harness.container, jobId: jobId);

    await expandMaterialSection(tester);
    await binding.takeScreenshot('material_cost_test_f_provisional_expanded');

    final cost = (await harness.materialRepo.getCostsForJob(jobId)).single;
    await tapLinkForCost(tester, cost.id);
    await binding.takeScreenshot('material_cost_test_f_suggested_matches');
    await tapSuggestedLink(tester, cost.id, expense.id);
    await binding.takeScreenshot('material_cost_test_f_linked_state');

    final afterLink = await loadAnalytics(harness.container);
    logSnapshot('TEST_B_AFTER_LINK', afterLink);
    expect(afterLink.monthlyExpenses, 3555.0);
    expect(afterLink.monthlyProfit, 1650.0);

    final linkedCost =
        (await harness.materialRepo.getCostsForJob(jobId)).single;
    final links =
        await harness.db.materialCostDao.getLinksForCost(linkedCost.id);
    expect(links, hasLength(1));
    expect(links.single.expenseId, expense.id);
    expect(linkedCost.canonicalCost, 35.0);
    expect(linkedCost.provisionalCost, 30.0);
    expect(linkedCost.source, 'both');

    await tapUnlinkForCost(tester, linkedCost.id);

    final afterUnlink = await loadAnalytics(harness.container);
    logSnapshot('TEST_C_AFTER_UNLINK', afterUnlink);
    expect(afterUnlink.monthlyExpenses, 3585.0);
    expect(afterUnlink.monthlyProfit, 1620.0);

    final unlinkedCost =
        (await harness.materialRepo.getCostsForJob(jobId)).single;
    final unlinkedLinks =
        await harness.db.materialCostDao.getLinksForCost(unlinkedCost.id);
    expect(unlinkedLinks, isEmpty);
    expect(unlinkedCost.canonicalCost, 30.0);
    expect(unlinkedCost.source, 'invoice');

    await tapLinkForCost(tester, unlinkedCost.id);
    await tapSuggestedLink(tester, unlinkedCost.id, expense.id);

    final afterRelink = await loadAnalytics(harness.container);
    logSnapshot('TEST_C_AFTER_RELINK', afterRelink);
    expect(afterRelink.monthlyExpenses, 3555.0);
    expect(afterRelink.monthlyProfit, 1650.0);
  });

  testWidgets(
      'TEST D expense first then invoice later counts once after linking',
      (tester) async {
    final harness = await createHarness();
    addTearDown(() async {
      harness.container.dispose();
      await harness.db.close();
    });

    final jobId = _uuid.v4();
    final expense = await addExpense(
      harness.expenseRepo,
      description: 'PVC fitting receipt',
      amount: 30.0,
      category: domain.ExpenseCategory.materials,
      jobId: jobId,
      expenseDate: DateTime(2026, 3, 8),
    );

    final beforeInvoice = await loadAnalytics(harness.container);
    logSnapshot('TEST_D_BEFORE_INVOICE', beforeInvoice);
    expect(beforeInvoice.monthlyExpenses, 3550.0);
    expect(beforeInvoice.monthlyProfit, 1655.0);

    final materials = [
      {
        'id': _uuid.v4(),
        'item': 'PVC fitting',
        'cost': 30.0,
      },
    ];

    await harness.materialRepo.recognizeMaterialCosts(
      _userId,
      jobId,
      materials,
      DateTime(2026, 3, 12),
    );

    final afterInvoiceBeforeLink = await loadAnalytics(harness.container);
    logSnapshot('TEST_D_AFTER_INVOICE_BEFORE_LINK', afterInvoiceBeforeLink);
    expect(afterInvoiceBeforeLink.monthlyExpenses, 3580.0);
    expect(afterInvoiceBeforeLink.monthlyProfit, 1625.0);

    await pumpMaterialSection(tester, harness.container, jobId: jobId);
    await expandMaterialSection(tester);

    final cost = (await harness.materialRepo.getCostsForJob(jobId)).single;
    await tapLinkForCost(tester, cost.id);
    await tapSuggestedLink(tester, cost.id, expense.id);

    final afterLink = await loadAnalytics(harness.container);
    logSnapshot('TEST_D_AFTER_LINK', afterLink);
    expect(afterLink.monthlyExpenses, 3550.0);
    expect(afterLink.monthlyProfit, 1655.0);
  });

  testWidgets('TEST E replacement revision supersedes original costs',
      (tester) async {
    final harness = await createHarness();
    addTearDown(() async {
      harness.container.dispose();
      await harness.db.close();
    });

    final originalJobId = _uuid.v4();
    final revisionJobId = _uuid.v4();

    await harness.materialRepo.recognizeMaterialCosts(
      _userId,
      originalJobId,
      [
        {
          'id': _uuid.v4(),
          'item': 'Original compressor',
          'cost': 30.0,
        },
      ],
      DateTime(2026, 3, 12),
    );

    final afterOriginal = await loadAnalytics(harness.container);
    logSnapshot('TEST_E_AFTER_ORIGINAL', afterOriginal);
    expect(afterOriginal.monthlyExpenses, 3550.0);
    expect(afterOriginal.monthlyProfit, 1655.0);

    await harness.materialRepo.supersedeCostsForJob(originalJobId);
    await harness.materialRepo.recognizeMaterialCosts(
      _userId,
      revisionJobId,
      [
        {
          'id': _uuid.v4(),
          'item': 'Revised compressor',
          'cost': 45.0,
        },
      ],
      DateTime(2026, 3, 14),
    );

    final afterRevision = await loadAnalytics(harness.container);
    logSnapshot('TEST_E_AFTER_REPLACEMENT', afterRevision);
    expect(afterRevision.monthlyExpenses, 3565.0);
    expect(afterRevision.monthlyProfit, 1640.0);

    final allCosts =
        await harness.db.select(harness.db.recognizedMaterialCosts).get();
    final original = allCosts.singleWhere((row) => row.jobId == originalJobId);
    final revision = allCosts.singleWhere((row) => row.jobId == revisionJobId);
    expect(original.status, 'superseded');
    expect(revision.status, 'active');

    final activeTotal = allCosts
        .where((row) => row.status == 'active')
        .fold<double>(0.0, (sum, row) => sum + row.canonicalCost);
    expect(activeTotal, 45.0);
  });
}

class _Harness {
  final AppDatabase db;
  final ExpenseRepository expenseRepo;
  final MaterialCostRepository materialRepo;
  final ProviderContainer container;

  const _Harness({
    required this.db,
    required this.expenseRepo,
    required this.materialRepo,
    required this.container,
  });
}

class _FakeJobRepository implements IJobRepository {
  final double monthlyCollected;

  const _FakeJobRepository({required this.monthlyCollected});

  @override
  Future<Map<String, dynamic>> getJobStats(String userId,
      {DateTime? month}) async {
    return {
      'monthlyRevenue': monthlyCollected,
      'outstandingRevenue': 0.0,
      'totalRevenue': monthlyCollected,
      'totalPaid': monthlyCollected,
      'totalBilled': monthlyCollected,
      'totalJobs': 1,
      'activeJobsCount': 0,
      'paidJobsCount': 1,
      'draftCount': 0,
      'sentUnpaidCount': 0,
      'cancelledCount': 0,
      'outstandingInvoiceCount': 0,
      'averagePaymentDays': 0.0,
    };
  }

  @override
  Future<Map<DateTime, double>> getMonthlyCollectedForMonths(
    String userId,
    List<DateTime> months,
  ) async {
    return {
      for (final month in months)
        DateTime(month.year, month.month):
            month.year == _auditMonth.year && month.month == _auditMonth.month
                ? monthlyCollected
                : 0.0,
    };
  }

  @override
  Future<job_domain.Job> createJob(job_domain.Job job) =>
      throw UnimplementedError();

  @override
  Future<void> deleteJob(String id) => throw UnimplementedError();

  @override
  Future<job_domain.Job> getJob(String id) => throw UnimplementedError();

  @override
  Future<List<job_domain.Job>> getJobs(String userId) async => const [];

  @override
  Future<List<job_domain.Job>> getJobsByStatus(
    String userId,
    job_domain.JobStatus status,
  ) async =>
      const [];

  @override
  Future<void> recordPayment(
    String jobId,
    double amount,
    String method, {
    DateTime? receivedAt,
    String? reference,
    String? notes,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateJobStatus(String jobId, String newStatus) =>
      throw UnimplementedError();

  @override
  Future<job_domain.Job> updateJob(String id, job_domain.Job job) =>
      throw UnimplementedError();
}
