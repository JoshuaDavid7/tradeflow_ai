// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $JobsTable extends Jobs with TableInfo<$JobsTable, Job> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientNameMeta =
      const VerificationMeta('clientName');
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
      'client_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tradeMeta = const VerificationMeta('trade');
  @override
  late final GeneratedColumn<String> trade = GeneratedColumn<String>(
      'trade', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _laborHoursMeta =
      const VerificationMeta('laborHours');
  @override
  late final GeneratedColumn<double> laborHours = GeneratedColumn<double>(
      'labor_hours', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _laborRateMeta =
      const VerificationMeta('laborRate');
  @override
  late final GeneratedColumn<double> laborRate = GeneratedColumn<double>(
      'labor_rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _materialsJsonMeta =
      const VerificationMeta('materialsJson');
  @override
  late final GeneratedColumn<String> materialsJson = GeneratedColumn<String>(
      'materials_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxAmountMeta =
      const VerificationMeta('taxAmount');
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
      'tax_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _amountPaidMeta =
      const VerificationMeta('amountPaid');
  @override
  late final GeneratedColumn<double> amountPaid = GeneratedColumn<double>(
      'amount_paid', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _amountDueMeta =
      const VerificationMeta('amountDue');
  @override
  late final GeneratedColumn<double> amountDue = GeneratedColumn<double>(
      'amount_due', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        customerId,
        title,
        clientName,
        description,
        trade,
        status,
        type,
        laborHours,
        laborRate,
        materialsJson,
        subtotal,
        taxRate,
        taxAmount,
        total,
        amountPaid,
        amountDue,
        createdAt,
        updatedAt,
        dueDate,
        paidAt,
        synced,
        syncStatus,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(Insertable<Job> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('client_name')) {
      context.handle(
          _clientNameMeta,
          clientName.isAcceptableOrUnknown(
              data['client_name']!, _clientNameMeta));
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('trade')) {
      context.handle(
          _tradeMeta, trade.isAcceptableOrUnknown(data['trade']!, _tradeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('labor_hours')) {
      context.handle(
          _laborHoursMeta,
          laborHours.isAcceptableOrUnknown(
              data['labor_hours']!, _laborHoursMeta));
    }
    if (data.containsKey('labor_rate')) {
      context.handle(_laborRateMeta,
          laborRate.isAcceptableOrUnknown(data['labor_rate']!, _laborRateMeta));
    } else if (isInserting) {
      context.missing(_laborRateMeta);
    }
    if (data.containsKey('materials_json')) {
      context.handle(
          _materialsJsonMeta,
          materialsJson.isAcceptableOrUnknown(
              data['materials_json']!, _materialsJsonMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('tax_amount')) {
      context.handle(_taxAmountMeta,
          taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta));
    } else if (isInserting) {
      context.missing(_taxAmountMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('amount_paid')) {
      context.handle(
          _amountPaidMeta,
          amountPaid.isAcceptableOrUnknown(
              data['amount_paid']!, _amountPaidMeta));
    }
    if (data.containsKey('amount_due')) {
      context.handle(_amountDueMeta,
          amountDue.isAcceptableOrUnknown(data['amount_due']!, _amountDueMeta));
    } else if (isInserting) {
      context.missing(_amountDueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Job map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Job(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      clientName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      trade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trade']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      laborHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}labor_hours'])!,
      laborRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}labor_rate'])!,
      materialsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}materials_json'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate'])!,
      taxAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_amount'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      amountPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount_paid'])!,
      amountDue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount_due'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class Job extends DataClass implements Insertable<Job> {
  final String id;
  final String userId;
  final String? customerId;
  final String title;
  final String clientName;
  final String? description;
  final String? trade;
  final String status;
  final String type;
  final double laborHours;
  final double laborRate;
  final String materialsJson;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double amountDue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final bool synced;
  final String syncStatus;
  final DateTime? lastSyncedAt;
  const Job(
      {required this.id,
      required this.userId,
      this.customerId,
      required this.title,
      required this.clientName,
      this.description,
      this.trade,
      required this.status,
      required this.type,
      required this.laborHours,
      required this.laborRate,
      required this.materialsJson,
      required this.subtotal,
      required this.taxRate,
      required this.taxAmount,
      required this.total,
      required this.amountPaid,
      required this.amountDue,
      required this.createdAt,
      required this.updatedAt,
      this.dueDate,
      this.paidAt,
      required this.synced,
      required this.syncStatus,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['title'] = Variable<String>(title);
    map['client_name'] = Variable<String>(clientName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || trade != null) {
      map['trade'] = Variable<String>(trade);
    }
    map['status'] = Variable<String>(status);
    map['type'] = Variable<String>(type);
    map['labor_hours'] = Variable<double>(laborHours);
    map['labor_rate'] = Variable<double>(laborRate);
    map['materials_json'] = Variable<String>(materialsJson);
    map['subtotal'] = Variable<double>(subtotal);
    map['tax_rate'] = Variable<double>(taxRate);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['total'] = Variable<double>(total);
    map['amount_paid'] = Variable<double>(amountPaid);
    map['amount_due'] = Variable<double>(amountDue);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    map['synced'] = Variable<bool>(synced);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      userId: Value(userId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      title: Value(title),
      clientName: Value(clientName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      trade:
          trade == null && nullToAbsent ? const Value.absent() : Value(trade),
      status: Value(status),
      type: Value(type),
      laborHours: Value(laborHours),
      laborRate: Value(laborRate),
      materialsJson: Value(materialsJson),
      subtotal: Value(subtotal),
      taxRate: Value(taxRate),
      taxAmount: Value(taxAmount),
      total: Value(total),
      amountPaid: Value(amountPaid),
      amountDue: Value(amountDue),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      paidAt:
          paidAt == null && nullToAbsent ? const Value.absent() : Value(paidAt),
      synced: Value(synced),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory Job.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Job(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      title: serializer.fromJson<String>(json['title']),
      clientName: serializer.fromJson<String>(json['clientName']),
      description: serializer.fromJson<String?>(json['description']),
      trade: serializer.fromJson<String?>(json['trade']),
      status: serializer.fromJson<String>(json['status']),
      type: serializer.fromJson<String>(json['type']),
      laborHours: serializer.fromJson<double>(json['laborHours']),
      laborRate: serializer.fromJson<double>(json['laborRate']),
      materialsJson: serializer.fromJson<String>(json['materialsJson']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      total: serializer.fromJson<double>(json['total']),
      amountPaid: serializer.fromJson<double>(json['amountPaid']),
      amountDue: serializer.fromJson<double>(json['amountDue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'customerId': serializer.toJson<String?>(customerId),
      'title': serializer.toJson<String>(title),
      'clientName': serializer.toJson<String>(clientName),
      'description': serializer.toJson<String?>(description),
      'trade': serializer.toJson<String?>(trade),
      'status': serializer.toJson<String>(status),
      'type': serializer.toJson<String>(type),
      'laborHours': serializer.toJson<double>(laborHours),
      'laborRate': serializer.toJson<double>(laborRate),
      'materialsJson': serializer.toJson<String>(materialsJson),
      'subtotal': serializer.toJson<double>(subtotal),
      'taxRate': serializer.toJson<double>(taxRate),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'total': serializer.toJson<double>(total),
      'amountPaid': serializer.toJson<double>(amountPaid),
      'amountDue': serializer.toJson<double>(amountDue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'synced': serializer.toJson<bool>(synced),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  Job copyWith(
          {String? id,
          String? userId,
          Value<String?> customerId = const Value.absent(),
          String? title,
          String? clientName,
          Value<String?> description = const Value.absent(),
          Value<String?> trade = const Value.absent(),
          String? status,
          String? type,
          double? laborHours,
          double? laborRate,
          String? materialsJson,
          double? subtotal,
          double? taxRate,
          double? taxAmount,
          double? total,
          double? amountPaid,
          double? amountDue,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> dueDate = const Value.absent(),
          Value<DateTime?> paidAt = const Value.absent(),
          bool? synced,
          String? syncStatus,
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      Job(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        customerId: customerId.present ? customerId.value : this.customerId,
        title: title ?? this.title,
        clientName: clientName ?? this.clientName,
        description: description.present ? description.value : this.description,
        trade: trade.present ? trade.value : this.trade,
        status: status ?? this.status,
        type: type ?? this.type,
        laborHours: laborHours ?? this.laborHours,
        laborRate: laborRate ?? this.laborRate,
        materialsJson: materialsJson ?? this.materialsJson,
        subtotal: subtotal ?? this.subtotal,
        taxRate: taxRate ?? this.taxRate,
        taxAmount: taxAmount ?? this.taxAmount,
        total: total ?? this.total,
        amountPaid: amountPaid ?? this.amountPaid,
        amountDue: amountDue ?? this.amountDue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        paidAt: paidAt.present ? paidAt.value : this.paidAt,
        synced: synced ?? this.synced,
        syncStatus: syncStatus ?? this.syncStatus,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  Job copyWithCompanion(JobsCompanion data) {
    return Job(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      title: data.title.present ? data.title.value : this.title,
      clientName:
          data.clientName.present ? data.clientName.value : this.clientName,
      description:
          data.description.present ? data.description.value : this.description,
      trade: data.trade.present ? data.trade.value : this.trade,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      laborHours:
          data.laborHours.present ? data.laborHours.value : this.laborHours,
      laborRate: data.laborRate.present ? data.laborRate.value : this.laborRate,
      materialsJson: data.materialsJson.present
          ? data.materialsJson.value
          : this.materialsJson,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      total: data.total.present ? data.total.value : this.total,
      amountPaid:
          data.amountPaid.present ? data.amountPaid.value : this.amountPaid,
      amountDue: data.amountDue.present ? data.amountDue.value : this.amountDue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Job(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('customerId: $customerId, ')
          ..write('title: $title, ')
          ..write('clientName: $clientName, ')
          ..write('description: $description, ')
          ..write('trade: $trade, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('laborHours: $laborHours, ')
          ..write('laborRate: $laborRate, ')
          ..write('materialsJson: $materialsJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('amountDue: $amountDue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('paidAt: $paidAt, ')
          ..write('synced: $synced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        userId,
        customerId,
        title,
        clientName,
        description,
        trade,
        status,
        type,
        laborHours,
        laborRate,
        materialsJson,
        subtotal,
        taxRate,
        taxAmount,
        total,
        amountPaid,
        amountDue,
        createdAt,
        updatedAt,
        dueDate,
        paidAt,
        synced,
        syncStatus,
        lastSyncedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Job &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.customerId == this.customerId &&
          other.title == this.title &&
          other.clientName == this.clientName &&
          other.description == this.description &&
          other.trade == this.trade &&
          other.status == this.status &&
          other.type == this.type &&
          other.laborHours == this.laborHours &&
          other.laborRate == this.laborRate &&
          other.materialsJson == this.materialsJson &&
          other.subtotal == this.subtotal &&
          other.taxRate == this.taxRate &&
          other.taxAmount == this.taxAmount &&
          other.total == this.total &&
          other.amountPaid == this.amountPaid &&
          other.amountDue == this.amountDue &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.dueDate == this.dueDate &&
          other.paidAt == this.paidAt &&
          other.synced == this.synced &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class JobsCompanion extends UpdateCompanion<Job> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> customerId;
  final Value<String> title;
  final Value<String> clientName;
  final Value<String?> description;
  final Value<String?> trade;
  final Value<String> status;
  final Value<String> type;
  final Value<double> laborHours;
  final Value<double> laborRate;
  final Value<String> materialsJson;
  final Value<double> subtotal;
  final Value<double> taxRate;
  final Value<double> taxAmount;
  final Value<double> total;
  final Value<double> amountPaid;
  final Value<double> amountDue;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> paidAt;
  final Value<bool> synced;
  final Value<String> syncStatus;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.title = const Value.absent(),
    this.clientName = const Value.absent(),
    this.description = const Value.absent(),
    this.trade = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.laborHours = const Value.absent(),
    this.laborRate = const Value.absent(),
    this.materialsJson = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.amountPaid = const Value.absent(),
    this.amountDue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsCompanion.insert({
    required String id,
    required String userId,
    this.customerId = const Value.absent(),
    required String title,
    required String clientName,
    this.description = const Value.absent(),
    this.trade = const Value.absent(),
    required String status,
    required String type,
    this.laborHours = const Value.absent(),
    required double laborRate,
    this.materialsJson = const Value.absent(),
    required double subtotal,
    this.taxRate = const Value.absent(),
    required double taxAmount,
    required double total,
    this.amountPaid = const Value.absent(),
    required double amountDue,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        clientName = Value(clientName),
        status = Value(status),
        type = Value(type),
        laborRate = Value(laborRate),
        subtotal = Value(subtotal),
        taxAmount = Value(taxAmount),
        total = Value(total),
        amountDue = Value(amountDue);
  static Insertable<Job> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? customerId,
    Expression<String>? title,
    Expression<String>? clientName,
    Expression<String>? description,
    Expression<String>? trade,
    Expression<String>? status,
    Expression<String>? type,
    Expression<double>? laborHours,
    Expression<double>? laborRate,
    Expression<String>? materialsJson,
    Expression<double>? subtotal,
    Expression<double>? taxRate,
    Expression<double>? taxAmount,
    Expression<double>? total,
    Expression<double>? amountPaid,
    Expression<double>? amountDue,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? paidAt,
    Expression<bool>? synced,
    Expression<String>? syncStatus,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (customerId != null) 'customer_id': customerId,
      if (title != null) 'title': title,
      if (clientName != null) 'client_name': clientName,
      if (description != null) 'description': description,
      if (trade != null) 'trade': trade,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (laborHours != null) 'labor_hours': laborHours,
      if (laborRate != null) 'labor_rate': laborRate,
      if (materialsJson != null) 'materials_json': materialsJson,
      if (subtotal != null) 'subtotal': subtotal,
      if (taxRate != null) 'tax_rate': taxRate,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (total != null) 'total': total,
      if (amountPaid != null) 'amount_paid': amountPaid,
      if (amountDue != null) 'amount_due': amountDue,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dueDate != null) 'due_date': dueDate,
      if (paidAt != null) 'paid_at': paidAt,
      if (synced != null) 'synced': synced,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? customerId,
      Value<String>? title,
      Value<String>? clientName,
      Value<String?>? description,
      Value<String?>? trade,
      Value<String>? status,
      Value<String>? type,
      Value<double>? laborHours,
      Value<double>? laborRate,
      Value<String>? materialsJson,
      Value<double>? subtotal,
      Value<double>? taxRate,
      Value<double>? taxAmount,
      Value<double>? total,
      Value<double>? amountPaid,
      Value<double>? amountDue,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? dueDate,
      Value<DateTime?>? paidAt,
      Value<bool>? synced,
      Value<String>? syncStatus,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? rowid}) {
    return JobsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      trade: trade ?? this.trade,
      status: status ?? this.status,
      type: type ?? this.type,
      laborHours: laborHours ?? this.laborHours,
      laborRate: laborRate ?? this.laborRate,
      materialsJson: materialsJson ?? this.materialsJson,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      amountPaid: amountPaid ?? this.amountPaid,
      amountDue: amountDue ?? this.amountDue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      synced: synced ?? this.synced,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (trade.present) {
      map['trade'] = Variable<String>(trade.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (laborHours.present) {
      map['labor_hours'] = Variable<double>(laborHours.value);
    }
    if (laborRate.present) {
      map['labor_rate'] = Variable<double>(laborRate.value);
    }
    if (materialsJson.present) {
      map['materials_json'] = Variable<String>(materialsJson.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (amountPaid.present) {
      map['amount_paid'] = Variable<double>(amountPaid.value);
    }
    if (amountDue.present) {
      map['amount_due'] = Variable<double>(amountDue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('customerId: $customerId, ')
          ..write('title: $title, ')
          ..write('clientName: $clientName, ')
          ..write('description: $description, ')
          ..write('trade: $trade, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('laborHours: $laborHours, ')
          ..write('laborRate: $laborRate, ')
          ..write('materialsJson: $materialsJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('amountDue: $amountDue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('paidAt: $paidAt, ')
          ..write('synced: $synced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
      'vendor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _expenseDateMeta =
      const VerificationMeta('expenseDate');
  @override
  late final GeneratedColumn<DateTime> expenseDate = GeneratedColumn<DateTime>(
      'expense_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _receiptPathMeta =
      const VerificationMeta('receiptPath');
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
      'receipt_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receiptUrlMeta =
      const VerificationMeta('receiptUrl');
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
      'receipt_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrTextMeta =
      const VerificationMeta('ocrText');
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
      'ocr_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _taxDeductibleMeta =
      const VerificationMeta('taxDeductible');
  @override
  late final GeneratedColumn<bool> taxDeductible = GeneratedColumn<bool>(
      'tax_deductible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("tax_deductible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _taxCategoryMeta =
      const VerificationMeta('taxCategory');
  @override
  late final GeneratedColumn<String> taxCategory = GeneratedColumn<String>(
      'tax_category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        jobId,
        customerId,
        description,
        vendor,
        category,
        amount,
        expenseDate,
        receiptPath,
        receiptUrl,
        ocrText,
        taxDeductible,
        taxCategory,
        paymentMethod,
        createdAt,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('vendor')) {
      context.handle(_vendorMeta,
          vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('expense_date')) {
      context.handle(
          _expenseDateMeta,
          expenseDate.isAcceptableOrUnknown(
              data['expense_date']!, _expenseDateMeta));
    } else if (isInserting) {
      context.missing(_expenseDateMeta);
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
          _receiptPathMeta,
          receiptPath.isAcceptableOrUnknown(
              data['receipt_path']!, _receiptPathMeta));
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
          _receiptUrlMeta,
          receiptUrl.isAcceptableOrUnknown(
              data['receipt_url']!, _receiptUrlMeta));
    }
    if (data.containsKey('ocr_text')) {
      context.handle(_ocrTextMeta,
          ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta));
    }
    if (data.containsKey('tax_deductible')) {
      context.handle(
          _taxDeductibleMeta,
          taxDeductible.isAcceptableOrUnknown(
              data['tax_deductible']!, _taxDeductibleMeta));
    }
    if (data.containsKey('tax_category')) {
      context.handle(
          _taxCategoryMeta,
          taxCategory.isAcceptableOrUnknown(
              data['tax_category']!, _taxCategoryMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id']),
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      vendor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      expenseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expense_date'])!,
      receiptPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_path']),
      receiptUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_url']),
      ocrText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_text']),
      taxDeductible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}tax_deductible'])!,
      taxCategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax_category']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String userId;
  final String? jobId;
  final String? customerId;
  final String description;
  final String? vendor;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? receiptPath;
  final String? receiptUrl;
  final String? ocrText;
  final bool taxDeductible;
  final String? taxCategory;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const Expense(
      {required this.id,
      required this.userId,
      this.jobId,
      this.customerId,
      required this.description,
      this.vendor,
      required this.category,
      required this.amount,
      required this.expenseDate,
      this.receiptPath,
      this.receiptUrl,
      this.ocrText,
      required this.taxDeductible,
      this.taxCategory,
      this.paymentMethod,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<double>(amount);
    map['expense_date'] = Variable<DateTime>(expenseDate);
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    if (!nullToAbsent || receiptUrl != null) {
      map['receipt_url'] = Variable<String>(receiptUrl);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    map['tax_deductible'] = Variable<bool>(taxDeductible);
    if (!nullToAbsent || taxCategory != null) {
      map['tax_category'] = Variable<String>(taxCategory);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      userId: Value(userId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      description: Value(description),
      vendor:
          vendor == null && nullToAbsent ? const Value.absent() : Value(vendor),
      category: Value(category),
      amount: Value(amount),
      expenseDate: Value(expenseDate),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
      receiptUrl: receiptUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptUrl),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      taxDeductible: Value(taxDeductible),
      taxCategory: taxCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(taxCategory),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      description: serializer.fromJson<String>(json['description']),
      vendor: serializer.fromJson<String?>(json['vendor']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      expenseDate: serializer.fromJson<DateTime>(json['expenseDate']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
      receiptUrl: serializer.fromJson<String?>(json['receiptUrl']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      taxDeductible: serializer.fromJson<bool>(json['taxDeductible']),
      taxCategory: serializer.fromJson<String?>(json['taxCategory']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'jobId': serializer.toJson<String?>(jobId),
      'customerId': serializer.toJson<String?>(customerId),
      'description': serializer.toJson<String>(description),
      'vendor': serializer.toJson<String?>(vendor),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double>(amount),
      'expenseDate': serializer.toJson<DateTime>(expenseDate),
      'receiptPath': serializer.toJson<String?>(receiptPath),
      'receiptUrl': serializer.toJson<String?>(receiptUrl),
      'ocrText': serializer.toJson<String?>(ocrText),
      'taxDeductible': serializer.toJson<bool>(taxDeductible),
      'taxCategory': serializer.toJson<String?>(taxCategory),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Expense copyWith(
          {String? id,
          String? userId,
          Value<String?> jobId = const Value.absent(),
          Value<String?> customerId = const Value.absent(),
          String? description,
          Value<String?> vendor = const Value.absent(),
          String? category,
          double? amount,
          DateTime? expenseDate,
          Value<String?> receiptPath = const Value.absent(),
          Value<String?> receiptUrl = const Value.absent(),
          Value<String?> ocrText = const Value.absent(),
          bool? taxDeductible,
          Value<String?> taxCategory = const Value.absent(),
          Value<String?> paymentMethod = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      Expense(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        jobId: jobId.present ? jobId.value : this.jobId,
        customerId: customerId.present ? customerId.value : this.customerId,
        description: description ?? this.description,
        vendor: vendor.present ? vendor.value : this.vendor,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        expenseDate: expenseDate ?? this.expenseDate,
        receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
        receiptUrl: receiptUrl.present ? receiptUrl.value : this.receiptUrl,
        ocrText: ocrText.present ? ocrText.value : this.ocrText,
        taxDeductible: taxDeductible ?? this.taxDeductible,
        taxCategory: taxCategory.present ? taxCategory.value : this.taxCategory,
        paymentMethod:
            paymentMethod.present ? paymentMethod.value : this.paymentMethod,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      description:
          data.description.present ? data.description.value : this.description,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      expenseDate:
          data.expenseDate.present ? data.expenseDate.value : this.expenseDate,
      receiptPath:
          data.receiptPath.present ? data.receiptPath.value : this.receiptPath,
      receiptUrl:
          data.receiptUrl.present ? data.receiptUrl.value : this.receiptUrl,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      taxDeductible: data.taxDeductible.present
          ? data.taxDeductible.value
          : this.taxDeductible,
      taxCategory:
          data.taxCategory.present ? data.taxCategory.value : this.taxCategory,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('jobId: $jobId, ')
          ..write('customerId: $customerId, ')
          ..write('description: $description, ')
          ..write('vendor: $vendor, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('ocrText: $ocrText, ')
          ..write('taxDeductible: $taxDeductible, ')
          ..write('taxCategory: $taxCategory, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      jobId,
      customerId,
      description,
      vendor,
      category,
      amount,
      expenseDate,
      receiptPath,
      receiptUrl,
      ocrText,
      taxDeductible,
      taxCategory,
      paymentMethod,
      createdAt,
      updatedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.jobId == this.jobId &&
          other.customerId == this.customerId &&
          other.description == this.description &&
          other.vendor == this.vendor &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.expenseDate == this.expenseDate &&
          other.receiptPath == this.receiptPath &&
          other.receiptUrl == this.receiptUrl &&
          other.ocrText == this.ocrText &&
          other.taxDeductible == this.taxDeductible &&
          other.taxCategory == this.taxCategory &&
          other.paymentMethod == this.paymentMethod &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> jobId;
  final Value<String?> customerId;
  final Value<String> description;
  final Value<String?> vendor;
  final Value<String> category;
  final Value<double> amount;
  final Value<DateTime> expenseDate;
  final Value<String?> receiptPath;
  final Value<String?> receiptUrl;
  final Value<String?> ocrText;
  final Value<bool> taxDeductible;
  final Value<String?> taxCategory;
  final Value<String?> paymentMethod;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.description = const Value.absent(),
    this.vendor = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.expenseDate = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.taxDeductible = const Value.absent(),
    this.taxCategory = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String userId,
    this.jobId = const Value.absent(),
    this.customerId = const Value.absent(),
    required String description,
    this.vendor = const Value.absent(),
    required String category,
    required double amount,
    required DateTime expenseDate,
    this.receiptPath = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.taxDeductible = const Value.absent(),
    this.taxCategory = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        description = Value(description),
        category = Value(category),
        amount = Value(amount),
        expenseDate = Value(expenseDate);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? jobId,
    Expression<String>? customerId,
    Expression<String>? description,
    Expression<String>? vendor,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<DateTime>? expenseDate,
    Expression<String>? receiptPath,
    Expression<String>? receiptUrl,
    Expression<String>? ocrText,
    Expression<bool>? taxDeductible,
    Expression<String>? taxCategory,
    Expression<String>? paymentMethod,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (jobId != null) 'job_id': jobId,
      if (customerId != null) 'customer_id': customerId,
      if (description != null) 'description': description,
      if (vendor != null) 'vendor': vendor,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (ocrText != null) 'ocr_text': ocrText,
      if (taxDeductible != null) 'tax_deductible': taxDeductible,
      if (taxCategory != null) 'tax_category': taxCategory,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? jobId,
      Value<String?>? customerId,
      Value<String>? description,
      Value<String?>? vendor,
      Value<String>? category,
      Value<double>? amount,
      Value<DateTime>? expenseDate,
      Value<String?>? receiptPath,
      Value<String?>? receiptUrl,
      Value<String?>? ocrText,
      Value<bool>? taxDeductible,
      Value<String?>? taxCategory,
      Value<String?>? paymentMethod,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      description: description ?? this.description,
      vendor: vendor ?? this.vendor,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      receiptPath: receiptPath ?? this.receiptPath,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      ocrText: ocrText ?? this.ocrText,
      taxDeductible: taxDeductible ?? this.taxDeductible,
      taxCategory: taxCategory ?? this.taxCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (expenseDate.present) {
      map['expense_date'] = Variable<DateTime>(expenseDate.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (taxDeductible.present) {
      map['tax_deductible'] = Variable<bool>(taxDeductible.value);
    }
    if (taxCategory.present) {
      map['tax_category'] = Variable<String>(taxCategory.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('jobId: $jobId, ')
          ..write('customerId: $customerId, ')
          ..write('description: $description, ')
          ..write('vendor: $vendor, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('ocrText: $ocrText, ')
          ..write('taxDeductible: $taxDeductible, ')
          ..write('taxCategory: $taxCategory, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _referenceMeta =
      const VerificationMeta('reference');
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
      'reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        userId,
        amount,
        method,
        reference,
        notes,
        receivedAt,
        createdAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(Insertable<Payment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(_referenceMeta,
          reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      reference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reference']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final String id;
  final String jobId;
  final String userId;
  final double amount;
  final String method;
  final String? reference;
  final String? notes;
  final DateTime receivedAt;
  final DateTime createdAt;
  final bool synced;
  const Payment(
      {required this.id,
      required this.jobId,
      required this.userId,
      required this.amount,
      required this.method,
      this.reference,
      this.notes,
      required this.receivedAt,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['user_id'] = Variable<String>(userId);
    map['amount'] = Variable<double>(amount);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      userId: Value(userId),
      amount: Value(amount),
      method: Value(method),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      receivedAt: Value(receivedAt),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      userId: serializer.fromJson<String>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String>(json['method']),
      reference: serializer.fromJson<String?>(json['reference']),
      notes: serializer.fromJson<String?>(json['notes']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'userId': serializer.toJson<String>(userId),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String>(method),
      'reference': serializer.toJson<String?>(reference),
      'notes': serializer.toJson<String?>(notes),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Payment copyWith(
          {String? id,
          String? jobId,
          String? userId,
          double? amount,
          String? method,
          Value<String?> reference = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? receivedAt,
          DateTime? createdAt,
          bool? synced}) =>
      Payment(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        reference: reference.present ? reference.value : this.reference,
        notes: notes.present ? notes.value : this.notes,
        receivedAt: receivedAt ?? this.receivedAt,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      reference: data.reference.present ? data.reference.value : this.reference,
      notes: data.notes.present ? data.notes.value : this.notes,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jobId, userId, amount, method, reference,
      notes, receivedAt, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.reference == this.reference &&
          other.notes == this.notes &&
          other.receivedAt == this.receivedAt &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<String> userId;
  final Value<double> amount;
  final Value<String> method;
  final Value<String?> reference;
  final Value<String?> notes;
  final Value<DateTime> receivedAt;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String jobId,
    required String userId,
    required double amount,
    required String method,
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime receivedAt,
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobId = Value(jobId),
        userId = Value(userId),
        amount = Value(amount),
        method = Value(method),
        receivedAt = Value(receivedAt);
  static Insertable<Payment> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? userId,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<String>? reference,
    Expression<String>? notes,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (receivedAt != null) 'received_at': receivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobId,
      Value<String>? userId,
      Value<double>? amount,
      Value<String>? method,
      Value<String?>? reference,
      Value<String?>? notes,
      Value<DateTime>? receivedAt,
      Value<DateTime>? createdAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return PaymentsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expense_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrTextMeta =
      const VerificationMeta('ocrText');
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
      'ocr_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _extractedAmountMeta =
      const VerificationMeta('extractedAmount');
  @override
  late final GeneratedColumn<double> extractedAmount = GeneratedColumn<double>(
      'extracted_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _extractedVendorMeta =
      const VerificationMeta('extractedVendor');
  @override
  late final GeneratedColumn<String> extractedVendor = GeneratedColumn<String>(
      'extracted_vendor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _extractedDateMeta =
      const VerificationMeta('extractedDate');
  @override
  late final GeneratedColumn<DateTime> extractedDate =
      GeneratedColumn<DateTime>('extracted_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _extractedItemsJsonMeta =
      const VerificationMeta('extractedItemsJson');
  @override
  late final GeneratedColumn<String> extractedItemsJson =
      GeneratedColumn<String>('extracted_items_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrStatusMeta =
      const VerificationMeta('ocrStatus');
  @override
  late final GeneratedColumn<String> ocrStatus = GeneratedColumn<String>(
      'ocr_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        expenseId,
        jobId,
        customerId,
        imagePath,
        imageUrl,
        thumbnailPath,
        ocrText,
        extractedAmount,
        extractedVendor,
        extractedDate,
        extractedItemsJson,
        ocrStatus,
        createdAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(Insertable<Receipt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('ocr_text')) {
      context.handle(_ocrTextMeta,
          ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta));
    }
    if (data.containsKey('extracted_amount')) {
      context.handle(
          _extractedAmountMeta,
          extractedAmount.isAcceptableOrUnknown(
              data['extracted_amount']!, _extractedAmountMeta));
    }
    if (data.containsKey('extracted_vendor')) {
      context.handle(
          _extractedVendorMeta,
          extractedVendor.isAcceptableOrUnknown(
              data['extracted_vendor']!, _extractedVendorMeta));
    }
    if (data.containsKey('extracted_date')) {
      context.handle(
          _extractedDateMeta,
          extractedDate.isAcceptableOrUnknown(
              data['extracted_date']!, _extractedDateMeta));
    }
    if (data.containsKey('extracted_items_json')) {
      context.handle(
          _extractedItemsJsonMeta,
          extractedItemsJson.isAcceptableOrUnknown(
              data['extracted_items_json']!, _extractedItemsJsonMeta));
    }
    if (data.containsKey('ocr_status')) {
      context.handle(_ocrStatusMeta,
          ocrStatus.isAcceptableOrUnknown(data['ocr_status']!, _ocrStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expense_id']),
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id']),
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      ocrText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_text']),
      extractedAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}extracted_amount']),
      extractedVendor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}extracted_vendor']),
      extractedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}extracted_date']),
      extractedItemsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}extracted_items_json']),
      ocrStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final String id;
  final String userId;
  final String? expenseId;
  final String? jobId;
  final String? customerId;
  final String imagePath;
  final String? imageUrl;
  final String? thumbnailPath;
  final String? ocrText;
  final double? extractedAmount;
  final String? extractedVendor;
  final DateTime? extractedDate;
  final String? extractedItemsJson;
  final String ocrStatus;
  final DateTime createdAt;
  final bool synced;
  const Receipt(
      {required this.id,
      required this.userId,
      this.expenseId,
      this.jobId,
      this.customerId,
      required this.imagePath,
      this.imageUrl,
      this.thumbnailPath,
      this.ocrText,
      this.extractedAmount,
      this.extractedVendor,
      this.extractedDate,
      this.extractedItemsJson,
      required this.ocrStatus,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || expenseId != null) {
      map['expense_id'] = Variable<String>(expenseId);
    }
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['image_path'] = Variable<String>(imagePath);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    if (!nullToAbsent || extractedAmount != null) {
      map['extracted_amount'] = Variable<double>(extractedAmount);
    }
    if (!nullToAbsent || extractedVendor != null) {
      map['extracted_vendor'] = Variable<String>(extractedVendor);
    }
    if (!nullToAbsent || extractedDate != null) {
      map['extracted_date'] = Variable<DateTime>(extractedDate);
    }
    if (!nullToAbsent || extractedItemsJson != null) {
      map['extracted_items_json'] = Variable<String>(extractedItemsJson);
    }
    map['ocr_status'] = Variable<String>(ocrStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      userId: Value(userId),
      expenseId: expenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      imagePath: Value(imagePath),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      extractedAmount: extractedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedAmount),
      extractedVendor: extractedVendor == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedVendor),
      extractedDate: extractedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedDate),
      extractedItemsJson: extractedItemsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedItemsJson),
      ocrStatus: Value(ocrStatus),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      expenseId: serializer.fromJson<String?>(json['expenseId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      extractedAmount: serializer.fromJson<double?>(json['extractedAmount']),
      extractedVendor: serializer.fromJson<String?>(json['extractedVendor']),
      extractedDate: serializer.fromJson<DateTime?>(json['extractedDate']),
      extractedItemsJson:
          serializer.fromJson<String?>(json['extractedItemsJson']),
      ocrStatus: serializer.fromJson<String>(json['ocrStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'expenseId': serializer.toJson<String?>(expenseId),
      'jobId': serializer.toJson<String?>(jobId),
      'customerId': serializer.toJson<String?>(customerId),
      'imagePath': serializer.toJson<String>(imagePath),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'ocrText': serializer.toJson<String?>(ocrText),
      'extractedAmount': serializer.toJson<double?>(extractedAmount),
      'extractedVendor': serializer.toJson<String?>(extractedVendor),
      'extractedDate': serializer.toJson<DateTime?>(extractedDate),
      'extractedItemsJson': serializer.toJson<String?>(extractedItemsJson),
      'ocrStatus': serializer.toJson<String>(ocrStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Receipt copyWith(
          {String? id,
          String? userId,
          Value<String?> expenseId = const Value.absent(),
          Value<String?> jobId = const Value.absent(),
          Value<String?> customerId = const Value.absent(),
          String? imagePath,
          Value<String?> imageUrl = const Value.absent(),
          Value<String?> thumbnailPath = const Value.absent(),
          Value<String?> ocrText = const Value.absent(),
          Value<double?> extractedAmount = const Value.absent(),
          Value<String?> extractedVendor = const Value.absent(),
          Value<DateTime?> extractedDate = const Value.absent(),
          Value<String?> extractedItemsJson = const Value.absent(),
          String? ocrStatus,
          DateTime? createdAt,
          bool? synced}) =>
      Receipt(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        expenseId: expenseId.present ? expenseId.value : this.expenseId,
        jobId: jobId.present ? jobId.value : this.jobId,
        customerId: customerId.present ? customerId.value : this.customerId,
        imagePath: imagePath ?? this.imagePath,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        ocrText: ocrText.present ? ocrText.value : this.ocrText,
        extractedAmount: extractedAmount.present
            ? extractedAmount.value
            : this.extractedAmount,
        extractedVendor: extractedVendor.present
            ? extractedVendor.value
            : this.extractedVendor,
        extractedDate:
            extractedDate.present ? extractedDate.value : this.extractedDate,
        extractedItemsJson: extractedItemsJson.present
            ? extractedItemsJson.value
            : this.extractedItemsJson,
        ocrStatus: ocrStatus ?? this.ocrStatus,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      extractedAmount: data.extractedAmount.present
          ? data.extractedAmount.value
          : this.extractedAmount,
      extractedVendor: data.extractedVendor.present
          ? data.extractedVendor.value
          : this.extractedVendor,
      extractedDate: data.extractedDate.present
          ? data.extractedDate.value
          : this.extractedDate,
      extractedItemsJson: data.extractedItemsJson.present
          ? data.extractedItemsJson.value
          : this.extractedItemsJson,
      ocrStatus: data.ocrStatus.present ? data.ocrStatus.value : this.ocrStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('expenseId: $expenseId, ')
          ..write('jobId: $jobId, ')
          ..write('customerId: $customerId, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('ocrText: $ocrText, ')
          ..write('extractedAmount: $extractedAmount, ')
          ..write('extractedVendor: $extractedVendor, ')
          ..write('extractedDate: $extractedDate, ')
          ..write('extractedItemsJson: $extractedItemsJson, ')
          ..write('ocrStatus: $ocrStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      expenseId,
      jobId,
      customerId,
      imagePath,
      imageUrl,
      thumbnailPath,
      ocrText,
      extractedAmount,
      extractedVendor,
      extractedDate,
      extractedItemsJson,
      ocrStatus,
      createdAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.expenseId == this.expenseId &&
          other.jobId == this.jobId &&
          other.customerId == this.customerId &&
          other.imagePath == this.imagePath &&
          other.imageUrl == this.imageUrl &&
          other.thumbnailPath == this.thumbnailPath &&
          other.ocrText == this.ocrText &&
          other.extractedAmount == this.extractedAmount &&
          other.extractedVendor == this.extractedVendor &&
          other.extractedDate == this.extractedDate &&
          other.extractedItemsJson == this.extractedItemsJson &&
          other.ocrStatus == this.ocrStatus &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> expenseId;
  final Value<String?> jobId;
  final Value<String?> customerId;
  final Value<String> imagePath;
  final Value<String?> imageUrl;
  final Value<String?> thumbnailPath;
  final Value<String?> ocrText;
  final Value<double?> extractedAmount;
  final Value<String?> extractedVendor;
  final Value<DateTime?> extractedDate;
  final Value<String?> extractedItemsJson;
  final Value<String> ocrStatus;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.extractedAmount = const Value.absent(),
    this.extractedVendor = const Value.absent(),
    this.extractedDate = const Value.absent(),
    this.extractedItemsJson = const Value.absent(),
    this.ocrStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String id,
    required String userId,
    this.expenseId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.customerId = const Value.absent(),
    required String imagePath,
    this.imageUrl = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.extractedAmount = const Value.absent(),
    this.extractedVendor = const Value.absent(),
    this.extractedDate = const Value.absent(),
    this.extractedItemsJson = const Value.absent(),
    this.ocrStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        imagePath = Value(imagePath);
  static Insertable<Receipt> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? expenseId,
    Expression<String>? jobId,
    Expression<String>? customerId,
    Expression<String>? imagePath,
    Expression<String>? imageUrl,
    Expression<String>? thumbnailPath,
    Expression<String>? ocrText,
    Expression<double>? extractedAmount,
    Expression<String>? extractedVendor,
    Expression<DateTime>? extractedDate,
    Expression<String>? extractedItemsJson,
    Expression<String>? ocrStatus,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (expenseId != null) 'expense_id': expenseId,
      if (jobId != null) 'job_id': jobId,
      if (customerId != null) 'customer_id': customerId,
      if (imagePath != null) 'image_path': imagePath,
      if (imageUrl != null) 'image_url': imageUrl,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (ocrText != null) 'ocr_text': ocrText,
      if (extractedAmount != null) 'extracted_amount': extractedAmount,
      if (extractedVendor != null) 'extracted_vendor': extractedVendor,
      if (extractedDate != null) 'extracted_date': extractedDate,
      if (extractedItemsJson != null)
        'extracted_items_json': extractedItemsJson,
      if (ocrStatus != null) 'ocr_status': ocrStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? expenseId,
      Value<String?>? jobId,
      Value<String?>? customerId,
      Value<String>? imagePath,
      Value<String?>? imageUrl,
      Value<String?>? thumbnailPath,
      Value<String?>? ocrText,
      Value<double?>? extractedAmount,
      Value<String?>? extractedVendor,
      Value<DateTime?>? extractedDate,
      Value<String?>? extractedItemsJson,
      Value<String>? ocrStatus,
      Value<DateTime>? createdAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      expenseId: expenseId ?? this.expenseId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      ocrText: ocrText ?? this.ocrText,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      extractedVendor: extractedVendor ?? this.extractedVendor,
      extractedDate: extractedDate ?? this.extractedDate,
      extractedItemsJson: extractedItemsJson ?? this.extractedItemsJson,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (extractedAmount.present) {
      map['extracted_amount'] = Variable<double>(extractedAmount.value);
    }
    if (extractedVendor.present) {
      map['extracted_vendor'] = Variable<String>(extractedVendor.value);
    }
    if (extractedDate.present) {
      map['extracted_date'] = Variable<DateTime>(extractedDate.value);
    }
    if (extractedItemsJson.present) {
      map['extracted_items_json'] = Variable<String>(extractedItemsJson.value);
    }
    if (ocrStatus.present) {
      map['ocr_status'] = Variable<String>(ocrStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('expenseId: $expenseId, ')
          ..write('jobId: $jobId, ')
          ..write('customerId: $customerId, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('ocrText: $ocrText, ')
          ..write('extractedAmount: $extractedAmount, ')
          ..write('extractedVendor: $extractedVendor, ')
          ..write('extractedDate: $extractedDate, ')
          ..write('extractedItemsJson: $extractedItemsJson, ')
          ..write('ocrStatus: $ocrStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalBilledMeta =
      const VerificationMeta('totalBilled');
  @override
  late final GeneratedColumn<double> totalBilled = GeneratedColumn<double>(
      'total_billed', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalPaidMeta =
      const VerificationMeta('totalPaid');
  @override
  late final GeneratedColumn<double> totalPaid = GeneratedColumn<double>(
      'total_paid', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
      'balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _jobCountMeta =
      const VerificationMeta('jobCount');
  @override
  late final GeneratedColumn<int> jobCount = GeneratedColumn<int>(
      'job_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastJobDateMeta =
      const VerificationMeta('lastJobDate');
  @override
  late final GeneratedColumn<DateTime> lastJobDate = GeneratedColumn<DateTime>(
      'last_job_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        email,
        phone,
        address,
        notes,
        totalBilled,
        totalPaid,
        balance,
        jobCount,
        lastJobDate,
        createdAt,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('total_billed')) {
      context.handle(
          _totalBilledMeta,
          totalBilled.isAcceptableOrUnknown(
              data['total_billed']!, _totalBilledMeta));
    }
    if (data.containsKey('total_paid')) {
      context.handle(_totalPaidMeta,
          totalPaid.isAcceptableOrUnknown(data['total_paid']!, _totalPaidMeta));
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('job_count')) {
      context.handle(_jobCountMeta,
          jobCount.isAcceptableOrUnknown(data['job_count']!, _jobCountMeta));
    }
    if (data.containsKey('last_job_date')) {
      context.handle(
          _lastJobDateMeta,
          lastJobDate.isAcceptableOrUnknown(
              data['last_job_date']!, _lastJobDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      totalBilled: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_billed'])!,
      totalPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_paid'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance'])!,
      jobCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}job_count'])!,
      lastJobDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_job_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final double totalBilled;
  final double totalPaid;
  final double balance;
  final int jobCount;
  final DateTime? lastJobDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const Customer(
      {required this.id,
      required this.userId,
      required this.name,
      this.email,
      this.phone,
      this.address,
      this.notes,
      required this.totalBilled,
      required this.totalPaid,
      required this.balance,
      required this.jobCount,
      this.lastJobDate,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['total_billed'] = Variable<double>(totalBilled);
    map['total_paid'] = Variable<double>(totalPaid);
    map['balance'] = Variable<double>(balance);
    map['job_count'] = Variable<int>(jobCount);
    if (!nullToAbsent || lastJobDate != null) {
      map['last_job_date'] = Variable<DateTime>(lastJobDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      totalBilled: Value(totalBilled),
      totalPaid: Value(totalPaid),
      balance: Value(balance),
      jobCount: Value(jobCount),
      lastJobDate: lastJobDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastJobDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      notes: serializer.fromJson<String?>(json['notes']),
      totalBilled: serializer.fromJson<double>(json['totalBilled']),
      totalPaid: serializer.fromJson<double>(json['totalPaid']),
      balance: serializer.fromJson<double>(json['balance']),
      jobCount: serializer.fromJson<int>(json['jobCount']),
      lastJobDate: serializer.fromJson<DateTime?>(json['lastJobDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'notes': serializer.toJson<String?>(notes),
      'totalBilled': serializer.toJson<double>(totalBilled),
      'totalPaid': serializer.toJson<double>(totalPaid),
      'balance': serializer.toJson<double>(balance),
      'jobCount': serializer.toJson<int>(jobCount),
      'lastJobDate': serializer.toJson<DateTime?>(lastJobDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Customer copyWith(
          {String? id,
          String? userId,
          String? name,
          Value<String?> email = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          double? totalBilled,
          double? totalPaid,
          double? balance,
          int? jobCount,
          Value<DateTime?> lastJobDate = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      Customer(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        phone: phone.present ? phone.value : this.phone,
        address: address.present ? address.value : this.address,
        notes: notes.present ? notes.value : this.notes,
        totalBilled: totalBilled ?? this.totalBilled,
        totalPaid: totalPaid ?? this.totalPaid,
        balance: balance ?? this.balance,
        jobCount: jobCount ?? this.jobCount,
        lastJobDate: lastJobDate.present ? lastJobDate.value : this.lastJobDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      notes: data.notes.present ? data.notes.value : this.notes,
      totalBilled:
          data.totalBilled.present ? data.totalBilled.value : this.totalBilled,
      totalPaid: data.totalPaid.present ? data.totalPaid.value : this.totalPaid,
      balance: data.balance.present ? data.balance.value : this.balance,
      jobCount: data.jobCount.present ? data.jobCount.value : this.jobCount,
      lastJobDate:
          data.lastJobDate.present ? data.lastJobDate.value : this.lastJobDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('totalBilled: $totalBilled, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('balance: $balance, ')
          ..write('jobCount: $jobCount, ')
          ..write('lastJobDate: $lastJobDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      name,
      email,
      phone,
      address,
      notes,
      totalBilled,
      totalPaid,
      balance,
      jobCount,
      lastJobDate,
      createdAt,
      updatedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.notes == this.notes &&
          other.totalBilled == this.totalBilled &&
          other.totalPaid == this.totalPaid &&
          other.balance == this.balance &&
          other.jobCount == this.jobCount &&
          other.lastJobDate == this.lastJobDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> notes;
  final Value<double> totalBilled;
  final Value<double> totalPaid;
  final Value<double> balance;
  final Value<int> jobCount;
  final Value<DateTime?> lastJobDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalBilled = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.balance = const Value.absent(),
    this.jobCount = const Value.absent(),
    this.lastJobDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalBilled = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.balance = const Value.absent(),
    this.jobCount = const Value.absent(),
    this.lastJobDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? notes,
    Expression<double>? totalBilled,
    Expression<double>? totalPaid,
    Expression<double>? balance,
    Expression<int>? jobCount,
    Expression<DateTime>? lastJobDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (totalBilled != null) 'total_billed': totalBilled,
      if (totalPaid != null) 'total_paid': totalPaid,
      if (balance != null) 'balance': balance,
      if (jobCount != null) 'job_count': jobCount,
      if (lastJobDate != null) 'last_job_date': lastJobDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String?>? email,
      Value<String?>? phone,
      Value<String?>? address,
      Value<String?>? notes,
      Value<double>? totalBilled,
      Value<double>? totalPaid,
      Value<double>? balance,
      Value<int>? jobCount,
      Value<DateTime?>? lastJobDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return CustomersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalBilled: totalBilled ?? this.totalBilled,
      totalPaid: totalPaid ?? this.totalPaid,
      balance: balance ?? this.balance,
      jobCount: jobCount ?? this.jobCount,
      lastJobDate: lastJobDate ?? this.lastJobDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (totalBilled.present) {
      map['total_billed'] = Variable<double>(totalBilled.value);
    }
    if (totalPaid.present) {
      map['total_paid'] = Variable<double>(totalPaid.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (jobCount.present) {
      map['job_count'] = Variable<int>(jobCount.value);
    }
    if (lastJobDate.present) {
      map['last_job_date'] = Variable<DateTime>(lastJobDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('totalBilled: $totalBilled, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('balance: $balance, ')
          ..write('jobCount: $jobCount, ')
          ..write('lastJobDate: $lastJobDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultLaborRateMeta =
      const VerificationMeta('defaultLaborRate');
  @override
  late final GeneratedColumn<double> defaultLaborRate = GeneratedColumn<double>(
      'default_labor_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _defaultTaxRateMeta =
      const VerificationMeta('defaultTaxRate');
  @override
  late final GeneratedColumn<double> defaultTaxRate = GeneratedColumn<double>(
      'default_tax_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _defaultTermsMeta =
      const VerificationMeta('defaultTerms');
  @override
  late final GeneratedColumn<String> defaultTerms = GeneratedColumn<String>(
      'default_terms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _defaultNotesMeta =
      const VerificationMeta('defaultNotes');
  @override
  late final GeneratedColumn<String> defaultNotes = GeneratedColumn<String>(
      'default_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lineItemsJsonMeta =
      const VerificationMeta('lineItemsJson');
  @override
  late final GeneratedColumn<String> lineItemsJson = GeneratedColumn<String>(
      'line_items_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _useCountMeta =
      const VerificationMeta('useCount');
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
      'use_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        type,
        defaultLaborRate,
        defaultTaxRate,
        defaultTerms,
        defaultNotes,
        lineItemsJson,
        useCount,
        lastUsedAt,
        createdAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(Insertable<Template> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('default_labor_rate')) {
      context.handle(
          _defaultLaborRateMeta,
          defaultLaborRate.isAcceptableOrUnknown(
              data['default_labor_rate']!, _defaultLaborRateMeta));
    }
    if (data.containsKey('default_tax_rate')) {
      context.handle(
          _defaultTaxRateMeta,
          defaultTaxRate.isAcceptableOrUnknown(
              data['default_tax_rate']!, _defaultTaxRateMeta));
    }
    if (data.containsKey('default_terms')) {
      context.handle(
          _defaultTermsMeta,
          defaultTerms.isAcceptableOrUnknown(
              data['default_terms']!, _defaultTermsMeta));
    }
    if (data.containsKey('default_notes')) {
      context.handle(
          _defaultNotesMeta,
          defaultNotes.isAcceptableOrUnknown(
              data['default_notes']!, _defaultNotesMeta));
    }
    if (data.containsKey('line_items_json')) {
      context.handle(
          _lineItemsJsonMeta,
          lineItemsJson.isAcceptableOrUnknown(
              data['line_items_json']!, _lineItemsJsonMeta));
    }
    if (data.containsKey('use_count')) {
      context.handle(_useCountMeta,
          useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      defaultLaborRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}default_labor_rate']),
      defaultTaxRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}default_tax_rate']),
      defaultTerms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_terms']),
      defaultNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_notes']),
      lineItemsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}line_items_json'])!,
      useCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}use_count'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double? defaultLaborRate;
  final double? defaultTaxRate;
  final String? defaultTerms;
  final String? defaultNotes;
  final String lineItemsJson;
  final int useCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final bool synced;
  const Template(
      {required this.id,
      required this.userId,
      required this.name,
      required this.type,
      this.defaultLaborRate,
      this.defaultTaxRate,
      this.defaultTerms,
      this.defaultNotes,
      required this.lineItemsJson,
      required this.useCount,
      this.lastUsedAt,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || defaultLaborRate != null) {
      map['default_labor_rate'] = Variable<double>(defaultLaborRate);
    }
    if (!nullToAbsent || defaultTaxRate != null) {
      map['default_tax_rate'] = Variable<double>(defaultTaxRate);
    }
    if (!nullToAbsent || defaultTerms != null) {
      map['default_terms'] = Variable<String>(defaultTerms);
    }
    if (!nullToAbsent || defaultNotes != null) {
      map['default_notes'] = Variable<String>(defaultNotes);
    }
    map['line_items_json'] = Variable<String>(lineItemsJson);
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      defaultLaborRate: defaultLaborRate == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultLaborRate),
      defaultTaxRate: defaultTaxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultTaxRate),
      defaultTerms: defaultTerms == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultTerms),
      defaultNotes: defaultNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultNotes),
      lineItemsJson: Value(lineItemsJson),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory Template.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      defaultLaborRate: serializer.fromJson<double?>(json['defaultLaborRate']),
      defaultTaxRate: serializer.fromJson<double?>(json['defaultTaxRate']),
      defaultTerms: serializer.fromJson<String?>(json['defaultTerms']),
      defaultNotes: serializer.fromJson<String?>(json['defaultNotes']),
      lineItemsJson: serializer.fromJson<String>(json['lineItemsJson']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'defaultLaborRate': serializer.toJson<double?>(defaultLaborRate),
      'defaultTaxRate': serializer.toJson<double?>(defaultTaxRate),
      'defaultTerms': serializer.toJson<String?>(defaultTerms),
      'defaultNotes': serializer.toJson<String?>(defaultNotes),
      'lineItemsJson': serializer.toJson<String>(lineItemsJson),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Template copyWith(
          {String? id,
          String? userId,
          String? name,
          String? type,
          Value<double?> defaultLaborRate = const Value.absent(),
          Value<double?> defaultTaxRate = const Value.absent(),
          Value<String?> defaultTerms = const Value.absent(),
          Value<String?> defaultNotes = const Value.absent(),
          String? lineItemsJson,
          int? useCount,
          Value<DateTime?> lastUsedAt = const Value.absent(),
          DateTime? createdAt,
          bool? synced}) =>
      Template(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        defaultLaborRate: defaultLaborRate.present
            ? defaultLaborRate.value
            : this.defaultLaborRate,
        defaultTaxRate:
            defaultTaxRate.present ? defaultTaxRate.value : this.defaultTaxRate,
        defaultTerms:
            defaultTerms.present ? defaultTerms.value : this.defaultTerms,
        defaultNotes:
            defaultNotes.present ? defaultNotes.value : this.defaultNotes,
        lineItemsJson: lineItemsJson ?? this.lineItemsJson,
        useCount: useCount ?? this.useCount,
        lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      defaultLaborRate: data.defaultLaborRate.present
          ? data.defaultLaborRate.value
          : this.defaultLaborRate,
      defaultTaxRate: data.defaultTaxRate.present
          ? data.defaultTaxRate.value
          : this.defaultTaxRate,
      defaultTerms: data.defaultTerms.present
          ? data.defaultTerms.value
          : this.defaultTerms,
      defaultNotes: data.defaultNotes.present
          ? data.defaultNotes.value
          : this.defaultNotes,
      lineItemsJson: data.lineItemsJson.present
          ? data.lineItemsJson.value
          : this.lineItemsJson,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('defaultLaborRate: $defaultLaborRate, ')
          ..write('defaultTaxRate: $defaultTaxRate, ')
          ..write('defaultTerms: $defaultTerms, ')
          ..write('defaultNotes: $defaultNotes, ')
          ..write('lineItemsJson: $lineItemsJson, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      name,
      type,
      defaultLaborRate,
      defaultTaxRate,
      defaultTerms,
      defaultNotes,
      lineItemsJson,
      useCount,
      lastUsedAt,
      createdAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.defaultLaborRate == this.defaultLaborRate &&
          other.defaultTaxRate == this.defaultTaxRate &&
          other.defaultTerms == this.defaultTerms &&
          other.defaultNotes == this.defaultNotes &&
          other.lineItemsJson == this.lineItemsJson &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<double?> defaultLaborRate;
  final Value<double?> defaultTaxRate;
  final Value<String?> defaultTerms;
  final Value<String?> defaultNotes;
  final Value<String> lineItemsJson;
  final Value<int> useCount;
  final Value<DateTime?> lastUsedAt;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.defaultLaborRate = const Value.absent(),
    this.defaultTaxRate = const Value.absent(),
    this.defaultTerms = const Value.absent(),
    this.defaultNotes = const Value.absent(),
    this.lineItemsJson = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String type,
    this.defaultLaborRate = const Value.absent(),
    this.defaultTaxRate = const Value.absent(),
    this.defaultTerms = const Value.absent(),
    this.defaultNotes = const Value.absent(),
    this.lineItemsJson = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        type = Value(type);
  static Insertable<Template> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<double>? defaultLaborRate,
    Expression<double>? defaultTaxRate,
    Expression<String>? defaultTerms,
    Expression<String>? defaultNotes,
    Expression<String>? lineItemsJson,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (defaultLaborRate != null) 'default_labor_rate': defaultLaborRate,
      if (defaultTaxRate != null) 'default_tax_rate': defaultTaxRate,
      if (defaultTerms != null) 'default_terms': defaultTerms,
      if (defaultNotes != null) 'default_notes': defaultNotes,
      if (lineItemsJson != null) 'line_items_json': lineItemsJson,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String>? type,
      Value<double?>? defaultLaborRate,
      Value<double?>? defaultTaxRate,
      Value<String?>? defaultTerms,
      Value<String?>? defaultNotes,
      Value<String>? lineItemsJson,
      Value<int>? useCount,
      Value<DateTime?>? lastUsedAt,
      Value<DateTime>? createdAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return TemplatesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultLaborRate: defaultLaborRate ?? this.defaultLaborRate,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultTerms: defaultTerms ?? this.defaultTerms,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      lineItemsJson: lineItemsJson ?? this.lineItemsJson,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (defaultLaborRate.present) {
      map['default_labor_rate'] = Variable<double>(defaultLaborRate.value);
    }
    if (defaultTaxRate.present) {
      map['default_tax_rate'] = Variable<double>(defaultTaxRate.value);
    }
    if (defaultTerms.present) {
      map['default_terms'] = Variable<String>(defaultTerms.value);
    }
    if (defaultNotes.present) {
      map['default_notes'] = Variable<String>(defaultNotes.value);
    }
    if (lineItemsJson.present) {
      map['line_items_json'] = Variable<String>(lineItemsJson.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('defaultLaborRate: $defaultLaborRate, ')
          ..write('defaultTaxRate: $defaultTaxRate, ')
          ..write('defaultTerms: $defaultTerms, ')
          ..write('defaultNotes: $defaultNotes, ')
          ..write('lineItemsJson: $lineItemsJson, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetTableMeta =
      const VerificationMeta('targetTable');
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
      'target_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataJsonMeta =
      const VerificationMeta('dataJson');
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
      'data_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        targetTable,
        recordId,
        operation,
        dataJson,
        retryCount,
        status,
        errorMessage,
        createdAt,
        lastAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
          _targetTableMeta,
          targetTable.isAcceptableOrUnknown(
              data['target_table']!, _targetTableMeta));
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(_dataJsonMeta,
          dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta));
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      targetTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      dataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_json'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String targetTable;
  final String recordId;
  final String operation;
  final String dataJson;
  final int retryCount;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  const SyncQueueData(
      {required this.id,
      required this.targetTable,
      required this.recordId,
      required this.operation,
      required this.dataJson,
      required this.retryCount,
      required this.status,
      this.errorMessage,
      required this.createdAt,
      this.lastAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['operation'] = Variable<String>(operation);
    map['data_json'] = Variable<String>(dataJson);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      operation: Value(operation),
      dataJson: Value(dataJson),
      retryCount: Value(retryCount),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'operation': serializer.toJson<String>(operation),
      'dataJson': serializer.toJson<String>(dataJson),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  SyncQueueData copyWith(
          {String? id,
          String? targetTable,
          String? recordId,
          String? operation,
          String? dataJson,
          int? retryCount,
          String? status,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> lastAttemptAt = const Value.absent()}) =>
      SyncQueueData(
        id: id ?? this.id,
        targetTable: targetTable ?? this.targetTable,
        recordId: recordId ?? this.recordId,
        operation: operation ?? this.operation,
        dataJson: dataJson ?? this.dataJson,
        retryCount: retryCount ?? this.retryCount,
        status: status ?? this.status,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      targetTable:
          data.targetTable.present ? data.targetTable.value : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('dataJson: $dataJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, targetTable, recordId, operation,
      dataJson, retryCount, status, errorMessage, createdAt, lastAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.dataJson == this.dataJson &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> operation;
  final Value<String> dataJson;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String targetTable,
    required String recordId,
    required String operation,
    required String dataJson,
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        targetTable = Value(targetTable),
        recordId = Value(recordId),
        operation = Value(operation),
        dataJson = Value(dataJson);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? operation,
    Expression<String>? dataJson,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (dataJson != null) 'data_json': dataJson,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? id,
      Value<String>? targetTable,
      Value<String>? recordId,
      Value<String>? operation,
      Value<String>? dataJson,
      Value<int>? retryCount,
      Value<String>? status,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastAttemptAt,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      dataJson: dataJson ?? this.dataJson,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('dataJson: $dataJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessSettingsTable extends BusinessSettings
    with TableInfo<$BusinessSettingsTable, BusinessSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _businessNameMeta =
      const VerificationMeta('businessName');
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
      'business_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _businessAddressMeta =
      const VerificationMeta('businessAddress');
  @override
  late final GeneratedColumn<String> businessAddress = GeneratedColumn<String>(
      'business_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _businessPhoneMeta =
      const VerificationMeta('businessPhone');
  @override
  late final GeneratedColumn<String> businessPhone = GeneratedColumn<String>(
      'business_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _businessEmailMeta =
      const VerificationMeta('businessEmail');
  @override
  late final GeneratedColumn<String> businessEmail = GeneratedColumn<String>(
      'business_email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _taxIdMeta = const VerificationMeta('taxId');
  @override
  late final GeneratedColumn<String> taxId = GeneratedColumn<String>(
      'tax_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _defaultHourlyRateMeta =
      const VerificationMeta('defaultHourlyRate');
  @override
  late final GeneratedColumn<double> defaultHourlyRate =
      GeneratedColumn<double>('default_hourly_rate', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(85.0));
  static const VerificationMeta _defaultTaxRateMeta =
      const VerificationMeta('defaultTaxRate');
  @override
  late final GeneratedColumn<double> defaultTaxRate = GeneratedColumn<double>(
      'default_tax_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _currencySymbolMeta =
      const VerificationMeta('currencySymbol');
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
      'currency_symbol', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('\$'));
  static const VerificationMeta _invoicePrefixMeta =
      const VerificationMeta('invoicePrefix');
  @override
  late final GeneratedColumn<String> invoicePrefix = GeneratedColumn<String>(
      'invoice_prefix', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextInvoiceNumberMeta =
      const VerificationMeta('nextInvoiceNumber');
  @override
  late final GeneratedColumn<int> nextInvoiceNumber = GeneratedColumn<int>(
      'next_invoice_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _defaultPaymentTermsMeta =
      const VerificationMeta('defaultPaymentTerms');
  @override
  late final GeneratedColumn<String> defaultPaymentTerms =
      GeneratedColumn<String>('default_payment_terms', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isProMeta = const VerificationMeta('isPro');
  @override
  late final GeneratedColumn<bool> isPro = GeneratedColumn<bool>(
      'is_pro', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pro" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _subscriptionStatusMeta =
      const VerificationMeta('subscriptionStatus');
  @override
  late final GeneratedColumn<String> subscriptionStatus =
      GeneratedColumn<String>('subscription_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('none'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        businessName,
        businessAddress,
        businessPhone,
        businessEmail,
        taxId,
        defaultHourlyRate,
        defaultTaxRate,
        currencySymbol,
        invoicePrefix,
        nextInvoiceNumber,
        defaultPaymentTerms,
        isPro,
        subscriptionStatus,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_settings';
  @override
  VerificationContext validateIntegrity(Insertable<BusinessSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
          _businessNameMeta,
          businessName.isAcceptableOrUnknown(
              data['business_name']!, _businessNameMeta));
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('business_address')) {
      context.handle(
          _businessAddressMeta,
          businessAddress.isAcceptableOrUnknown(
              data['business_address']!, _businessAddressMeta));
    }
    if (data.containsKey('business_phone')) {
      context.handle(
          _businessPhoneMeta,
          businessPhone.isAcceptableOrUnknown(
              data['business_phone']!, _businessPhoneMeta));
    }
    if (data.containsKey('business_email')) {
      context.handle(
          _businessEmailMeta,
          businessEmail.isAcceptableOrUnknown(
              data['business_email']!, _businessEmailMeta));
    }
    if (data.containsKey('tax_id')) {
      context.handle(
          _taxIdMeta, taxId.isAcceptableOrUnknown(data['tax_id']!, _taxIdMeta));
    }
    if (data.containsKey('default_hourly_rate')) {
      context.handle(
          _defaultHourlyRateMeta,
          defaultHourlyRate.isAcceptableOrUnknown(
              data['default_hourly_rate']!, _defaultHourlyRateMeta));
    }
    if (data.containsKey('default_tax_rate')) {
      context.handle(
          _defaultTaxRateMeta,
          defaultTaxRate.isAcceptableOrUnknown(
              data['default_tax_rate']!, _defaultTaxRateMeta));
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
          _currencySymbolMeta,
          currencySymbol.isAcceptableOrUnknown(
              data['currency_symbol']!, _currencySymbolMeta));
    }
    if (data.containsKey('invoice_prefix')) {
      context.handle(
          _invoicePrefixMeta,
          invoicePrefix.isAcceptableOrUnknown(
              data['invoice_prefix']!, _invoicePrefixMeta));
    }
    if (data.containsKey('next_invoice_number')) {
      context.handle(
          _nextInvoiceNumberMeta,
          nextInvoiceNumber.isAcceptableOrUnknown(
              data['next_invoice_number']!, _nextInvoiceNumberMeta));
    }
    if (data.containsKey('default_payment_terms')) {
      context.handle(
          _defaultPaymentTermsMeta,
          defaultPaymentTerms.isAcceptableOrUnknown(
              data['default_payment_terms']!, _defaultPaymentTermsMeta));
    }
    if (data.containsKey('is_pro')) {
      context.handle(
          _isProMeta, isPro.isAcceptableOrUnknown(data['is_pro']!, _isProMeta));
    }
    if (data.containsKey('subscription_status')) {
      context.handle(
          _subscriptionStatusMeta,
          subscriptionStatus.isAcceptableOrUnknown(
              data['subscription_status']!, _subscriptionStatusMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  BusinessSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessSetting(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      businessName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_name'])!,
      businessAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}business_address']),
      businessPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_phone']),
      businessEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_email']),
      taxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax_id']),
      defaultHourlyRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}default_hourly_rate'])!,
      defaultTaxRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}default_tax_rate'])!,
      currencySymbol: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}currency_symbol'])!,
      invoicePrefix: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_prefix']),
      nextInvoiceNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}next_invoice_number'])!,
      defaultPaymentTerms: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_payment_terms']),
      isPro: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pro'])!,
      subscriptionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subscription_status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $BusinessSettingsTable createAlias(String alias) {
    return $BusinessSettingsTable(attachedDatabase, alias);
  }
}

class BusinessSetting extends DataClass implements Insertable<BusinessSetting> {
  final String userId;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final String? taxId;
  final double defaultHourlyRate;
  final double defaultTaxRate;
  final String currencySymbol;
  final String? invoicePrefix;
  final int nextInvoiceNumber;
  final String? defaultPaymentTerms;
  final bool isPro;
  final String subscriptionStatus;
  final DateTime updatedAt;
  final bool synced;
  const BusinessSetting(
      {required this.userId,
      required this.businessName,
      this.businessAddress,
      this.businessPhone,
      this.businessEmail,
      this.taxId,
      required this.defaultHourlyRate,
      required this.defaultTaxRate,
      required this.currencySymbol,
      this.invoicePrefix,
      required this.nextInvoiceNumber,
      this.defaultPaymentTerms,
      required this.isPro,
      required this.subscriptionStatus,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['business_name'] = Variable<String>(businessName);
    if (!nullToAbsent || businessAddress != null) {
      map['business_address'] = Variable<String>(businessAddress);
    }
    if (!nullToAbsent || businessPhone != null) {
      map['business_phone'] = Variable<String>(businessPhone);
    }
    if (!nullToAbsent || businessEmail != null) {
      map['business_email'] = Variable<String>(businessEmail);
    }
    if (!nullToAbsent || taxId != null) {
      map['tax_id'] = Variable<String>(taxId);
    }
    map['default_hourly_rate'] = Variable<double>(defaultHourlyRate);
    map['default_tax_rate'] = Variable<double>(defaultTaxRate);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    if (!nullToAbsent || invoicePrefix != null) {
      map['invoice_prefix'] = Variable<String>(invoicePrefix);
    }
    map['next_invoice_number'] = Variable<int>(nextInvoiceNumber);
    if (!nullToAbsent || defaultPaymentTerms != null) {
      map['default_payment_terms'] = Variable<String>(defaultPaymentTerms);
    }
    map['is_pro'] = Variable<bool>(isPro);
    map['subscription_status'] = Variable<String>(subscriptionStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  BusinessSettingsCompanion toCompanion(bool nullToAbsent) {
    return BusinessSettingsCompanion(
      userId: Value(userId),
      businessName: Value(businessName),
      businessAddress: businessAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(businessAddress),
      businessPhone: businessPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(businessPhone),
      businessEmail: businessEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(businessEmail),
      taxId:
          taxId == null && nullToAbsent ? const Value.absent() : Value(taxId),
      defaultHourlyRate: Value(defaultHourlyRate),
      defaultTaxRate: Value(defaultTaxRate),
      currencySymbol: Value(currencySymbol),
      invoicePrefix: invoicePrefix == null && nullToAbsent
          ? const Value.absent()
          : Value(invoicePrefix),
      nextInvoiceNumber: Value(nextInvoiceNumber),
      defaultPaymentTerms: defaultPaymentTerms == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultPaymentTerms),
      isPro: Value(isPro),
      subscriptionStatus: Value(subscriptionStatus),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory BusinessSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessSetting(
      userId: serializer.fromJson<String>(json['userId']),
      businessName: serializer.fromJson<String>(json['businessName']),
      businessAddress: serializer.fromJson<String?>(json['businessAddress']),
      businessPhone: serializer.fromJson<String?>(json['businessPhone']),
      businessEmail: serializer.fromJson<String?>(json['businessEmail']),
      taxId: serializer.fromJson<String?>(json['taxId']),
      defaultHourlyRate: serializer.fromJson<double>(json['defaultHourlyRate']),
      defaultTaxRate: serializer.fromJson<double>(json['defaultTaxRate']),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
      invoicePrefix: serializer.fromJson<String?>(json['invoicePrefix']),
      nextInvoiceNumber: serializer.fromJson<int>(json['nextInvoiceNumber']),
      defaultPaymentTerms:
          serializer.fromJson<String?>(json['defaultPaymentTerms']),
      isPro: serializer.fromJson<bool>(json['isPro']),
      subscriptionStatus:
          serializer.fromJson<String>(json['subscriptionStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'businessName': serializer.toJson<String>(businessName),
      'businessAddress': serializer.toJson<String?>(businessAddress),
      'businessPhone': serializer.toJson<String?>(businessPhone),
      'businessEmail': serializer.toJson<String?>(businessEmail),
      'taxId': serializer.toJson<String?>(taxId),
      'defaultHourlyRate': serializer.toJson<double>(defaultHourlyRate),
      'defaultTaxRate': serializer.toJson<double>(defaultTaxRate),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
      'invoicePrefix': serializer.toJson<String?>(invoicePrefix),
      'nextInvoiceNumber': serializer.toJson<int>(nextInvoiceNumber),
      'defaultPaymentTerms': serializer.toJson<String?>(defaultPaymentTerms),
      'isPro': serializer.toJson<bool>(isPro),
      'subscriptionStatus': serializer.toJson<String>(subscriptionStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  BusinessSetting copyWith(
          {String? userId,
          String? businessName,
          Value<String?> businessAddress = const Value.absent(),
          Value<String?> businessPhone = const Value.absent(),
          Value<String?> businessEmail = const Value.absent(),
          Value<String?> taxId = const Value.absent(),
          double? defaultHourlyRate,
          double? defaultTaxRate,
          String? currencySymbol,
          Value<String?> invoicePrefix = const Value.absent(),
          int? nextInvoiceNumber,
          Value<String?> defaultPaymentTerms = const Value.absent(),
          bool? isPro,
          String? subscriptionStatus,
          DateTime? updatedAt,
          bool? synced}) =>
      BusinessSetting(
        userId: userId ?? this.userId,
        businessName: businessName ?? this.businessName,
        businessAddress: businessAddress.present
            ? businessAddress.value
            : this.businessAddress,
        businessPhone:
            businessPhone.present ? businessPhone.value : this.businessPhone,
        businessEmail:
            businessEmail.present ? businessEmail.value : this.businessEmail,
        taxId: taxId.present ? taxId.value : this.taxId,
        defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
        defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        invoicePrefix:
            invoicePrefix.present ? invoicePrefix.value : this.invoicePrefix,
        nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
        defaultPaymentTerms: defaultPaymentTerms.present
            ? defaultPaymentTerms.value
            : this.defaultPaymentTerms,
        isPro: isPro ?? this.isPro,
        subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  BusinessSetting copyWithCompanion(BusinessSettingsCompanion data) {
    return BusinessSetting(
      userId: data.userId.present ? data.userId.value : this.userId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      businessAddress: data.businessAddress.present
          ? data.businessAddress.value
          : this.businessAddress,
      businessPhone: data.businessPhone.present
          ? data.businessPhone.value
          : this.businessPhone,
      businessEmail: data.businessEmail.present
          ? data.businessEmail.value
          : this.businessEmail,
      taxId: data.taxId.present ? data.taxId.value : this.taxId,
      defaultHourlyRate: data.defaultHourlyRate.present
          ? data.defaultHourlyRate.value
          : this.defaultHourlyRate,
      defaultTaxRate: data.defaultTaxRate.present
          ? data.defaultTaxRate.value
          : this.defaultTaxRate,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      invoicePrefix: data.invoicePrefix.present
          ? data.invoicePrefix.value
          : this.invoicePrefix,
      nextInvoiceNumber: data.nextInvoiceNumber.present
          ? data.nextInvoiceNumber.value
          : this.nextInvoiceNumber,
      defaultPaymentTerms: data.defaultPaymentTerms.present
          ? data.defaultPaymentTerms.value
          : this.defaultPaymentTerms,
      isPro: data.isPro.present ? data.isPro.value : this.isPro,
      subscriptionStatus: data.subscriptionStatus.present
          ? data.subscriptionStatus.value
          : this.subscriptionStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessSetting(')
          ..write('userId: $userId, ')
          ..write('businessName: $businessName, ')
          ..write('businessAddress: $businessAddress, ')
          ..write('businessPhone: $businessPhone, ')
          ..write('businessEmail: $businessEmail, ')
          ..write('taxId: $taxId, ')
          ..write('defaultHourlyRate: $defaultHourlyRate, ')
          ..write('defaultTaxRate: $defaultTaxRate, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('nextInvoiceNumber: $nextInvoiceNumber, ')
          ..write('defaultPaymentTerms: $defaultPaymentTerms, ')
          ..write('isPro: $isPro, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId,
      businessName,
      businessAddress,
      businessPhone,
      businessEmail,
      taxId,
      defaultHourlyRate,
      defaultTaxRate,
      currencySymbol,
      invoicePrefix,
      nextInvoiceNumber,
      defaultPaymentTerms,
      isPro,
      subscriptionStatus,
      updatedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessSetting &&
          other.userId == this.userId &&
          other.businessName == this.businessName &&
          other.businessAddress == this.businessAddress &&
          other.businessPhone == this.businessPhone &&
          other.businessEmail == this.businessEmail &&
          other.taxId == this.taxId &&
          other.defaultHourlyRate == this.defaultHourlyRate &&
          other.defaultTaxRate == this.defaultTaxRate &&
          other.currencySymbol == this.currencySymbol &&
          other.invoicePrefix == this.invoicePrefix &&
          other.nextInvoiceNumber == this.nextInvoiceNumber &&
          other.defaultPaymentTerms == this.defaultPaymentTerms &&
          other.isPro == this.isPro &&
          other.subscriptionStatus == this.subscriptionStatus &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class BusinessSettingsCompanion extends UpdateCompanion<BusinessSetting> {
  final Value<String> userId;
  final Value<String> businessName;
  final Value<String?> businessAddress;
  final Value<String?> businessPhone;
  final Value<String?> businessEmail;
  final Value<String?> taxId;
  final Value<double> defaultHourlyRate;
  final Value<double> defaultTaxRate;
  final Value<String> currencySymbol;
  final Value<String?> invoicePrefix;
  final Value<int> nextInvoiceNumber;
  final Value<String?> defaultPaymentTerms;
  final Value<bool> isPro;
  final Value<String> subscriptionStatus;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const BusinessSettingsCompanion({
    this.userId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.businessAddress = const Value.absent(),
    this.businessPhone = const Value.absent(),
    this.businessEmail = const Value.absent(),
    this.taxId = const Value.absent(),
    this.defaultHourlyRate = const Value.absent(),
    this.defaultTaxRate = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.invoicePrefix = const Value.absent(),
    this.nextInvoiceNumber = const Value.absent(),
    this.defaultPaymentTerms = const Value.absent(),
    this.isPro = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessSettingsCompanion.insert({
    required String userId,
    required String businessName,
    this.businessAddress = const Value.absent(),
    this.businessPhone = const Value.absent(),
    this.businessEmail = const Value.absent(),
    this.taxId = const Value.absent(),
    this.defaultHourlyRate = const Value.absent(),
    this.defaultTaxRate = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.invoicePrefix = const Value.absent(),
    this.nextInvoiceNumber = const Value.absent(),
    this.defaultPaymentTerms = const Value.absent(),
    this.isPro = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        businessName = Value(businessName);
  static Insertable<BusinessSetting> custom({
    Expression<String>? userId,
    Expression<String>? businessName,
    Expression<String>? businessAddress,
    Expression<String>? businessPhone,
    Expression<String>? businessEmail,
    Expression<String>? taxId,
    Expression<double>? defaultHourlyRate,
    Expression<double>? defaultTaxRate,
    Expression<String>? currencySymbol,
    Expression<String>? invoicePrefix,
    Expression<int>? nextInvoiceNumber,
    Expression<String>? defaultPaymentTerms,
    Expression<bool>? isPro,
    Expression<String>? subscriptionStatus,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (businessName != null) 'business_name': businessName,
      if (businessAddress != null) 'business_address': businessAddress,
      if (businessPhone != null) 'business_phone': businessPhone,
      if (businessEmail != null) 'business_email': businessEmail,
      if (taxId != null) 'tax_id': taxId,
      if (defaultHourlyRate != null) 'default_hourly_rate': defaultHourlyRate,
      if (defaultTaxRate != null) 'default_tax_rate': defaultTaxRate,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (invoicePrefix != null) 'invoice_prefix': invoicePrefix,
      if (nextInvoiceNumber != null) 'next_invoice_number': nextInvoiceNumber,
      if (defaultPaymentTerms != null)
        'default_payment_terms': defaultPaymentTerms,
      if (isPro != null) 'is_pro': isPro,
      if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessSettingsCompanion copyWith(
      {Value<String>? userId,
      Value<String>? businessName,
      Value<String?>? businessAddress,
      Value<String?>? businessPhone,
      Value<String?>? businessEmail,
      Value<String?>? taxId,
      Value<double>? defaultHourlyRate,
      Value<double>? defaultTaxRate,
      Value<String>? currencySymbol,
      Value<String?>? invoicePrefix,
      Value<int>? nextInvoiceNumber,
      Value<String?>? defaultPaymentTerms,
      Value<bool>? isPro,
      Value<String>? subscriptionStatus,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return BusinessSettingsCompanion(
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      taxId: taxId ?? this.taxId,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      defaultPaymentTerms: defaultPaymentTerms ?? this.defaultPaymentTerms,
      isPro: isPro ?? this.isPro,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (businessAddress.present) {
      map['business_address'] = Variable<String>(businessAddress.value);
    }
    if (businessPhone.present) {
      map['business_phone'] = Variable<String>(businessPhone.value);
    }
    if (businessEmail.present) {
      map['business_email'] = Variable<String>(businessEmail.value);
    }
    if (taxId.present) {
      map['tax_id'] = Variable<String>(taxId.value);
    }
    if (defaultHourlyRate.present) {
      map['default_hourly_rate'] = Variable<double>(defaultHourlyRate.value);
    }
    if (defaultTaxRate.present) {
      map['default_tax_rate'] = Variable<double>(defaultTaxRate.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (invoicePrefix.present) {
      map['invoice_prefix'] = Variable<String>(invoicePrefix.value);
    }
    if (nextInvoiceNumber.present) {
      map['next_invoice_number'] = Variable<int>(nextInvoiceNumber.value);
    }
    if (defaultPaymentTerms.present) {
      map['default_payment_terms'] =
          Variable<String>(defaultPaymentTerms.value);
    }
    if (isPro.present) {
      map['is_pro'] = Variable<bool>(isPro.value);
    }
    if (subscriptionStatus.present) {
      map['subscription_status'] = Variable<String>(subscriptionStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessSettingsCompanion(')
          ..write('userId: $userId, ')
          ..write('businessName: $businessName, ')
          ..write('businessAddress: $businessAddress, ')
          ..write('businessPhone: $businessPhone, ')
          ..write('businessEmail: $businessEmail, ')
          ..write('taxId: $taxId, ')
          ..write('defaultHourlyRate: $defaultHourlyRate, ')
          ..write('defaultTaxRate: $defaultTaxRate, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('nextInvoiceNumber: $nextInvoiceNumber, ')
          ..write('defaultPaymentTerms: $defaultPaymentTerms, ')
          ..write('isPro: $isPro, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        customerId,
        name,
        description,
        status,
        createdAt,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String userId;
  final String customerId;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const Project(
      {required this.id,
      required this.userId,
      required this.customerId,
      required this.name,
      this.description,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['customer_id'] = Variable<String>(customerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      userId: Value(userId),
      customerId: Value(customerId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'customerId': serializer.toJson<String>(customerId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Project copyWith(
          {String? id,
          String? userId,
          String? customerId,
          String? name,
          Value<String?> description = const Value.absent(),
          String? status,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      Project(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        customerId: customerId ?? this.customerId,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('customerId: $customerId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, customerId, name, description,
      status, createdAt, updatedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.customerId == this.customerId &&
          other.name == this.name &&
          other.description == this.description &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> customerId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String userId,
    required String customerId,
    required String name,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        customerId = Value(customerId),
        name = Value(name);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? customerId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (customerId != null) 'customer_id': customerId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? customerId,
      Value<String>? name,
      Value<String?>? description,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('customerId: $customerId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecognizedMaterialCostsTable extends RecognizedMaterialCosts
    with TableInfo<$RecognizedMaterialCostsTable, RecognizedMaterialCost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecognizedMaterialCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _materialIndexMeta =
      const VerificationMeta('materialIndex');
  @override
  late final GeneratedColumn<int> materialIndex = GeneratedColumn<int>(
      'material_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _materialIdMeta =
      const VerificationMeta('materialId');
  @override
  late final GeneratedColumn<String> materialId = GeneratedColumn<String>(
      'material_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _provisionalCostMeta =
      const VerificationMeta('provisionalCost');
  @override
  late final GeneratedColumn<double> provisionalCost = GeneratedColumn<double>(
      'provisional_cost', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _canonicalCostMeta =
      const VerificationMeta('canonicalCost');
  @override
  late final GeneratedColumn<double> canonicalCost = GeneratedColumn<double>(
      'canonical_cost', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _recognitionDateMeta =
      const VerificationMeta('recognitionDate');
  @override
  late final GeneratedColumn<DateTime> recognitionDate =
      GeneratedColumn<DateTime>('recognition_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('invoice'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        jobId,
        materialIndex,
        materialId,
        description,
        provisionalCost,
        canonicalCost,
        recognitionDate,
        source,
        status,
        createdAt,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recognized_material_costs';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecognizedMaterialCost> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    }
    if (data.containsKey('material_index')) {
      context.handle(
          _materialIndexMeta,
          materialIndex.isAcceptableOrUnknown(
              data['material_index']!, _materialIndexMeta));
    }
    if (data.containsKey('material_id')) {
      context.handle(
          _materialIdMeta,
          materialId.isAcceptableOrUnknown(
              data['material_id']!, _materialIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('provisional_cost')) {
      context.handle(
          _provisionalCostMeta,
          provisionalCost.isAcceptableOrUnknown(
              data['provisional_cost']!, _provisionalCostMeta));
    } else if (isInserting) {
      context.missing(_provisionalCostMeta);
    }
    if (data.containsKey('canonical_cost')) {
      context.handle(
          _canonicalCostMeta,
          canonicalCost.isAcceptableOrUnknown(
              data['canonical_cost']!, _canonicalCostMeta));
    } else if (isInserting) {
      context.missing(_canonicalCostMeta);
    }
    if (data.containsKey('recognition_date')) {
      context.handle(
          _recognitionDateMeta,
          recognitionDate.isAcceptableOrUnknown(
              data['recognition_date']!, _recognitionDateMeta));
    } else if (isInserting) {
      context.missing(_recognitionDateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecognizedMaterialCost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecognizedMaterialCost(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id']),
      materialIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}material_index']),
      materialId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}material_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      provisionalCost: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}provisional_cost'])!,
      canonicalCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}canonical_cost'])!,
      recognitionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}recognition_date'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $RecognizedMaterialCostsTable createAlias(String alias) {
    return $RecognizedMaterialCostsTable(attachedDatabase, alias);
  }
}

class RecognizedMaterialCost extends DataClass
    implements Insertable<RecognizedMaterialCost> {
  final String id;
  final String userId;
  final String? jobId;
  final int? materialIndex;
  final String? materialId;
  final String description;
  final double provisionalCost;
  final double canonicalCost;
  final DateTime recognitionDate;
  final String source;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const RecognizedMaterialCost(
      {required this.id,
      required this.userId,
      this.jobId,
      this.materialIndex,
      this.materialId,
      required this.description,
      required this.provisionalCost,
      required this.canonicalCost,
      required this.recognitionDate,
      required this.source,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || materialIndex != null) {
      map['material_index'] = Variable<int>(materialIndex);
    }
    if (!nullToAbsent || materialId != null) {
      map['material_id'] = Variable<String>(materialId);
    }
    map['description'] = Variable<String>(description);
    map['provisional_cost'] = Variable<double>(provisionalCost);
    map['canonical_cost'] = Variable<double>(canonicalCost);
    map['recognition_date'] = Variable<DateTime>(recognitionDate);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  RecognizedMaterialCostsCompanion toCompanion(bool nullToAbsent) {
    return RecognizedMaterialCostsCompanion(
      id: Value(id),
      userId: Value(userId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      materialIndex: materialIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(materialIndex),
      materialId: materialId == null && nullToAbsent
          ? const Value.absent()
          : Value(materialId),
      description: Value(description),
      provisionalCost: Value(provisionalCost),
      canonicalCost: Value(canonicalCost),
      recognitionDate: Value(recognitionDate),
      source: Value(source),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory RecognizedMaterialCost.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecognizedMaterialCost(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      materialIndex: serializer.fromJson<int?>(json['materialIndex']),
      materialId: serializer.fromJson<String?>(json['materialId']),
      description: serializer.fromJson<String>(json['description']),
      provisionalCost: serializer.fromJson<double>(json['provisionalCost']),
      canonicalCost: serializer.fromJson<double>(json['canonicalCost']),
      recognitionDate: serializer.fromJson<DateTime>(json['recognitionDate']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'jobId': serializer.toJson<String?>(jobId),
      'materialIndex': serializer.toJson<int?>(materialIndex),
      'materialId': serializer.toJson<String?>(materialId),
      'description': serializer.toJson<String>(description),
      'provisionalCost': serializer.toJson<double>(provisionalCost),
      'canonicalCost': serializer.toJson<double>(canonicalCost),
      'recognitionDate': serializer.toJson<DateTime>(recognitionDate),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  RecognizedMaterialCost copyWith(
          {String? id,
          String? userId,
          Value<String?> jobId = const Value.absent(),
          Value<int?> materialIndex = const Value.absent(),
          Value<String?> materialId = const Value.absent(),
          String? description,
          double? provisionalCost,
          double? canonicalCost,
          DateTime? recognitionDate,
          String? source,
          String? status,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      RecognizedMaterialCost(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        jobId: jobId.present ? jobId.value : this.jobId,
        materialIndex:
            materialIndex.present ? materialIndex.value : this.materialIndex,
        materialId: materialId.present ? materialId.value : this.materialId,
        description: description ?? this.description,
        provisionalCost: provisionalCost ?? this.provisionalCost,
        canonicalCost: canonicalCost ?? this.canonicalCost,
        recognitionDate: recognitionDate ?? this.recognitionDate,
        source: source ?? this.source,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  RecognizedMaterialCost copyWithCompanion(
      RecognizedMaterialCostsCompanion data) {
    return RecognizedMaterialCost(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      materialIndex: data.materialIndex.present
          ? data.materialIndex.value
          : this.materialIndex,
      materialId:
          data.materialId.present ? data.materialId.value : this.materialId,
      description:
          data.description.present ? data.description.value : this.description,
      provisionalCost: data.provisionalCost.present
          ? data.provisionalCost.value
          : this.provisionalCost,
      canonicalCost: data.canonicalCost.present
          ? data.canonicalCost.value
          : this.canonicalCost,
      recognitionDate: data.recognitionDate.present
          ? data.recognitionDate.value
          : this.recognitionDate,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecognizedMaterialCost(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('jobId: $jobId, ')
          ..write('materialIndex: $materialIndex, ')
          ..write('materialId: $materialId, ')
          ..write('description: $description, ')
          ..write('provisionalCost: $provisionalCost, ')
          ..write('canonicalCost: $canonicalCost, ')
          ..write('recognitionDate: $recognitionDate, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      jobId,
      materialIndex,
      materialId,
      description,
      provisionalCost,
      canonicalCost,
      recognitionDate,
      source,
      status,
      createdAt,
      updatedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecognizedMaterialCost &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.jobId == this.jobId &&
          other.materialIndex == this.materialIndex &&
          other.materialId == this.materialId &&
          other.description == this.description &&
          other.provisionalCost == this.provisionalCost &&
          other.canonicalCost == this.canonicalCost &&
          other.recognitionDate == this.recognitionDate &&
          other.source == this.source &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class RecognizedMaterialCostsCompanion
    extends UpdateCompanion<RecognizedMaterialCost> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> jobId;
  final Value<int?> materialIndex;
  final Value<String?> materialId;
  final Value<String> description;
  final Value<double> provisionalCost;
  final Value<double> canonicalCost;
  final Value<DateTime> recognitionDate;
  final Value<String> source;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const RecognizedMaterialCostsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.materialIndex = const Value.absent(),
    this.materialId = const Value.absent(),
    this.description = const Value.absent(),
    this.provisionalCost = const Value.absent(),
    this.canonicalCost = const Value.absent(),
    this.recognitionDate = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecognizedMaterialCostsCompanion.insert({
    required String id,
    required String userId,
    this.jobId = const Value.absent(),
    this.materialIndex = const Value.absent(),
    this.materialId = const Value.absent(),
    required String description,
    required double provisionalCost,
    required double canonicalCost,
    required DateTime recognitionDate,
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        description = Value(description),
        provisionalCost = Value(provisionalCost),
        canonicalCost = Value(canonicalCost),
        recognitionDate = Value(recognitionDate);
  static Insertable<RecognizedMaterialCost> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? jobId,
    Expression<int>? materialIndex,
    Expression<String>? materialId,
    Expression<String>? description,
    Expression<double>? provisionalCost,
    Expression<double>? canonicalCost,
    Expression<DateTime>? recognitionDate,
    Expression<String>? source,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (jobId != null) 'job_id': jobId,
      if (materialIndex != null) 'material_index': materialIndex,
      if (materialId != null) 'material_id': materialId,
      if (description != null) 'description': description,
      if (provisionalCost != null) 'provisional_cost': provisionalCost,
      if (canonicalCost != null) 'canonical_cost': canonicalCost,
      if (recognitionDate != null) 'recognition_date': recognitionDate,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecognizedMaterialCostsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? jobId,
      Value<int?>? materialIndex,
      Value<String?>? materialId,
      Value<String>? description,
      Value<double>? provisionalCost,
      Value<double>? canonicalCost,
      Value<DateTime>? recognitionDate,
      Value<String>? source,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return RecognizedMaterialCostsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      materialIndex: materialIndex ?? this.materialIndex,
      materialId: materialId ?? this.materialId,
      description: description ?? this.description,
      provisionalCost: provisionalCost ?? this.provisionalCost,
      canonicalCost: canonicalCost ?? this.canonicalCost,
      recognitionDate: recognitionDate ?? this.recognitionDate,
      source: source ?? this.source,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (materialIndex.present) {
      map['material_index'] = Variable<int>(materialIndex.value);
    }
    if (materialId.present) {
      map['material_id'] = Variable<String>(materialId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (provisionalCost.present) {
      map['provisional_cost'] = Variable<double>(provisionalCost.value);
    }
    if (canonicalCost.present) {
      map['canonical_cost'] = Variable<double>(canonicalCost.value);
    }
    if (recognitionDate.present) {
      map['recognition_date'] = Variable<DateTime>(recognitionDate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecognizedMaterialCostsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('jobId: $jobId, ')
          ..write('materialIndex: $materialIndex, ')
          ..write('materialId: $materialId, ')
          ..write('description: $description, ')
          ..write('provisionalCost: $provisionalCost, ')
          ..write('canonicalCost: $canonicalCost, ')
          ..write('recognitionDate: $recognitionDate, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialCostLinksTable extends MaterialCostLinks
    with TableInfo<$MaterialCostLinksTable, MaterialCostLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialCostLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recognizedMaterialCostIdMeta =
      const VerificationMeta('recognizedMaterialCostId');
  @override
  late final GeneratedColumn<String> recognizedMaterialCostId =
      GeneratedColumn<String>('recognized_material_cost_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expense_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _allocatedAmountMeta =
      const VerificationMeta('allocatedAmount');
  @override
  late final GeneratedColumn<double> allocatedAmount = GeneratedColumn<double>(
      'allocated_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, recognizedMaterialCostId, expenseId, allocatedAmount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'material_cost_links';
  @override
  VerificationContext validateIntegrity(Insertable<MaterialCostLink> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recognized_material_cost_id')) {
      context.handle(
          _recognizedMaterialCostIdMeta,
          recognizedMaterialCostId.isAcceptableOrUnknown(
              data['recognized_material_cost_id']!,
              _recognizedMaterialCostIdMeta));
    } else if (isInserting) {
      context.missing(_recognizedMaterialCostIdMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta));
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('allocated_amount')) {
      context.handle(
          _allocatedAmountMeta,
          allocatedAmount.isAcceptableOrUnknown(
              data['allocated_amount']!, _allocatedAmountMeta));
    } else if (isInserting) {
      context.missing(_allocatedAmountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaterialCostLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialCostLink(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recognizedMaterialCostId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recognized_material_cost_id'])!,
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expense_id'])!,
      allocatedAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}allocated_amount'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MaterialCostLinksTable createAlias(String alias) {
    return $MaterialCostLinksTable(attachedDatabase, alias);
  }
}

class MaterialCostLink extends DataClass
    implements Insertable<MaterialCostLink> {
  final String id;
  final String recognizedMaterialCostId;
  final String expenseId;
  final double allocatedAmount;
  final DateTime createdAt;
  const MaterialCostLink(
      {required this.id,
      required this.recognizedMaterialCostId,
      required this.expenseId,
      required this.allocatedAmount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recognized_material_cost_id'] =
        Variable<String>(recognizedMaterialCostId);
    map['expense_id'] = Variable<String>(expenseId);
    map['allocated_amount'] = Variable<double>(allocatedAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MaterialCostLinksCompanion toCompanion(bool nullToAbsent) {
    return MaterialCostLinksCompanion(
      id: Value(id),
      recognizedMaterialCostId: Value(recognizedMaterialCostId),
      expenseId: Value(expenseId),
      allocatedAmount: Value(allocatedAmount),
      createdAt: Value(createdAt),
    );
  }

  factory MaterialCostLink.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialCostLink(
      id: serializer.fromJson<String>(json['id']),
      recognizedMaterialCostId:
          serializer.fromJson<String>(json['recognizedMaterialCostId']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      allocatedAmount: serializer.fromJson<double>(json['allocatedAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recognizedMaterialCostId':
          serializer.toJson<String>(recognizedMaterialCostId),
      'expenseId': serializer.toJson<String>(expenseId),
      'allocatedAmount': serializer.toJson<double>(allocatedAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MaterialCostLink copyWith(
          {String? id,
          String? recognizedMaterialCostId,
          String? expenseId,
          double? allocatedAmount,
          DateTime? createdAt}) =>
      MaterialCostLink(
        id: id ?? this.id,
        recognizedMaterialCostId:
            recognizedMaterialCostId ?? this.recognizedMaterialCostId,
        expenseId: expenseId ?? this.expenseId,
        allocatedAmount: allocatedAmount ?? this.allocatedAmount,
        createdAt: createdAt ?? this.createdAt,
      );
  MaterialCostLink copyWithCompanion(MaterialCostLinksCompanion data) {
    return MaterialCostLink(
      id: data.id.present ? data.id.value : this.id,
      recognizedMaterialCostId: data.recognizedMaterialCostId.present
          ? data.recognizedMaterialCostId.value
          : this.recognizedMaterialCostId,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      allocatedAmount: data.allocatedAmount.present
          ? data.allocatedAmount.value
          : this.allocatedAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialCostLink(')
          ..write('id: $id, ')
          ..write('recognizedMaterialCostId: $recognizedMaterialCostId, ')
          ..write('expenseId: $expenseId, ')
          ..write('allocatedAmount: $allocatedAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, recognizedMaterialCostId, expenseId, allocatedAmount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialCostLink &&
          other.id == this.id &&
          other.recognizedMaterialCostId == this.recognizedMaterialCostId &&
          other.expenseId == this.expenseId &&
          other.allocatedAmount == this.allocatedAmount &&
          other.createdAt == this.createdAt);
}

class MaterialCostLinksCompanion extends UpdateCompanion<MaterialCostLink> {
  final Value<String> id;
  final Value<String> recognizedMaterialCostId;
  final Value<String> expenseId;
  final Value<double> allocatedAmount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MaterialCostLinksCompanion({
    this.id = const Value.absent(),
    this.recognizedMaterialCostId = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.allocatedAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialCostLinksCompanion.insert({
    required String id,
    required String recognizedMaterialCostId,
    required String expenseId,
    required double allocatedAmount,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        recognizedMaterialCostId = Value(recognizedMaterialCostId),
        expenseId = Value(expenseId),
        allocatedAmount = Value(allocatedAmount);
  static Insertable<MaterialCostLink> custom({
    Expression<String>? id,
    Expression<String>? recognizedMaterialCostId,
    Expression<String>? expenseId,
    Expression<double>? allocatedAmount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recognizedMaterialCostId != null)
        'recognized_material_cost_id': recognizedMaterialCostId,
      if (expenseId != null) 'expense_id': expenseId,
      if (allocatedAmount != null) 'allocated_amount': allocatedAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialCostLinksCompanion copyWith(
      {Value<String>? id,
      Value<String>? recognizedMaterialCostId,
      Value<String>? expenseId,
      Value<double>? allocatedAmount,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MaterialCostLinksCompanion(
      id: id ?? this.id,
      recognizedMaterialCostId:
          recognizedMaterialCostId ?? this.recognizedMaterialCostId,
      expenseId: expenseId ?? this.expenseId,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recognizedMaterialCostId.present) {
      map['recognized_material_cost_id'] =
          Variable<String>(recognizedMaterialCostId.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (allocatedAmount.present) {
      map['allocated_amount'] = Variable<double>(allocatedAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialCostLinksCompanion(')
          ..write('id: $id, ')
          ..write('recognizedMaterialCostId: $recognizedMaterialCostId, ')
          ..write('expenseId: $expenseId, ')
          ..write('allocatedAmount: $allocatedAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  _$AppDatabase.connect(DatabaseConnection c) : super.connect(c);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $BusinessSettingsTable businessSettings =
      $BusinessSettingsTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $RecognizedMaterialCostsTable recognizedMaterialCosts =
      $RecognizedMaterialCostsTable(this);
  late final $MaterialCostLinksTable materialCostLinks =
      $MaterialCostLinksTable(this);
  late final JobDao jobDao = JobDao(this as AppDatabase);
  late final ExpenseDao expenseDao = ExpenseDao(this as AppDatabase);
  late final ReceiptDao receiptDao = ReceiptDao(this as AppDatabase);
  late final CustomerDao customerDao = CustomerDao(this as AppDatabase);
  late final ProjectDao projectDao = ProjectDao(this as AppDatabase);
  late final MaterialCostDao materialCostDao =
      MaterialCostDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        jobs,
        expenses,
        payments,
        receipts,
        customers,
        templates,
        syncQueue,
        businessSettings,
        projects,
        recognizedMaterialCosts,
        materialCostLinks
      ];
}

typedef $$JobsTableCreateCompanionBuilder = JobsCompanion Function({
  required String id,
  required String userId,
  Value<String?> customerId,
  required String title,
  required String clientName,
  Value<String?> description,
  Value<String?> trade,
  required String status,
  required String type,
  Value<double> laborHours,
  required double laborRate,
  Value<String> materialsJson,
  required double subtotal,
  Value<double> taxRate,
  required double taxAmount,
  required double total,
  Value<double> amountPaid,
  required double amountDue,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> dueDate,
  Value<DateTime?> paidAt,
  Value<bool> synced,
  Value<String> syncStatus,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$JobsTableUpdateCompanionBuilder = JobsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> customerId,
  Value<String> title,
  Value<String> clientName,
  Value<String?> description,
  Value<String?> trade,
  Value<String> status,
  Value<String> type,
  Value<double> laborHours,
  Value<double> laborRate,
  Value<String> materialsJson,
  Value<double> subtotal,
  Value<double> taxRate,
  Value<double> taxAmount,
  Value<double> total,
  Value<double> amountPaid,
  Value<double> amountDue,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> dueDate,
  Value<DateTime?> paidAt,
  Value<bool> synced,
  Value<String> syncStatus,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$JobsTableFilterComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trade => $composableBuilder(
      column: $table.trade, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get laborHours => $composableBuilder(
      column: $table.laborHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get laborRate => $composableBuilder(
      column: $table.laborRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get materialsJson => $composableBuilder(
      column: $table.materialsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amountPaid => $composableBuilder(
      column: $table.amountPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amountDue => $composableBuilder(
      column: $table.amountDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$JobsTableOrderingComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trade => $composableBuilder(
      column: $table.trade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get laborHours => $composableBuilder(
      column: $table.laborHours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get laborRate => $composableBuilder(
      column: $table.laborRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get materialsJson => $composableBuilder(
      column: $table.materialsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amountPaid => $composableBuilder(
      column: $table.amountPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amountDue => $composableBuilder(
      column: $table.amountDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$JobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get trade =>
      $composableBuilder(column: $table.trade, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get laborHours => $composableBuilder(
      column: $table.laborHours, builder: (column) => column);

  GeneratedColumn<double> get laborRate =>
      $composableBuilder(column: $table.laborRate, builder: (column) => column);

  GeneratedColumn<String> get materialsJson => $composableBuilder(
      column: $table.materialsJson, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get amountPaid => $composableBuilder(
      column: $table.amountPaid, builder: (column) => column);

  GeneratedColumn<double> get amountDue =>
      $composableBuilder(column: $table.amountDue, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$JobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JobsTable,
    Job,
    $$JobsTableFilterComposer,
    $$JobsTableOrderingComposer,
    $$JobsTableAnnotationComposer,
    $$JobsTableCreateCompanionBuilder,
    $$JobsTableUpdateCompanionBuilder,
    (Job, BaseReferences<_$AppDatabase, $JobsTable, Job>),
    Job,
    PrefetchHooks Function()> {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> clientName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> trade = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> laborHours = const Value.absent(),
            Value<double> laborRate = const Value.absent(),
            Value<String> materialsJson = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<double> amountPaid = const Value.absent(),
            Value<double> amountDue = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              JobsCompanion(
            id: id,
            userId: userId,
            customerId: customerId,
            title: title,
            clientName: clientName,
            description: description,
            trade: trade,
            status: status,
            type: type,
            laborHours: laborHours,
            laborRate: laborRate,
            materialsJson: materialsJson,
            subtotal: subtotal,
            taxRate: taxRate,
            taxAmount: taxAmount,
            total: total,
            amountPaid: amountPaid,
            amountDue: amountDue,
            createdAt: createdAt,
            updatedAt: updatedAt,
            dueDate: dueDate,
            paidAt: paidAt,
            synced: synced,
            syncStatus: syncStatus,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> customerId = const Value.absent(),
            required String title,
            required String clientName,
            Value<String?> description = const Value.absent(),
            Value<String?> trade = const Value.absent(),
            required String status,
            required String type,
            Value<double> laborHours = const Value.absent(),
            required double laborRate,
            Value<String> materialsJson = const Value.absent(),
            required double subtotal,
            Value<double> taxRate = const Value.absent(),
            required double taxAmount,
            required double total,
            Value<double> amountPaid = const Value.absent(),
            required double amountDue,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              JobsCompanion.insert(
            id: id,
            userId: userId,
            customerId: customerId,
            title: title,
            clientName: clientName,
            description: description,
            trade: trade,
            status: status,
            type: type,
            laborHours: laborHours,
            laborRate: laborRate,
            materialsJson: materialsJson,
            subtotal: subtotal,
            taxRate: taxRate,
            taxAmount: taxAmount,
            total: total,
            amountPaid: amountPaid,
            amountDue: amountDue,
            createdAt: createdAt,
            updatedAt: updatedAt,
            dueDate: dueDate,
            paidAt: paidAt,
            synced: synced,
            syncStatus: syncStatus,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JobsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JobsTable,
    Job,
    $$JobsTableFilterComposer,
    $$JobsTableOrderingComposer,
    $$JobsTableAnnotationComposer,
    $$JobsTableCreateCompanionBuilder,
    $$JobsTableUpdateCompanionBuilder,
    (Job, BaseReferences<_$AppDatabase, $JobsTable, Job>),
    Job,
    PrefetchHooks Function()>;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String userId,
  Value<String?> jobId,
  Value<String?> customerId,
  required String description,
  Value<String?> vendor,
  required String category,
  required double amount,
  required DateTime expenseDate,
  Value<String?> receiptPath,
  Value<String?> receiptUrl,
  Value<String?> ocrText,
  Value<bool> taxDeductible,
  Value<String?> taxCategory,
  Value<String?> paymentMethod,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> jobId,
  Value<String?> customerId,
  Value<String> description,
  Value<String?> vendor,
  Value<String> category,
  Value<double> amount,
  Value<DateTime> expenseDate,
  Value<String?> receiptPath,
  Value<String?> receiptUrl,
  Value<String?> ocrText,
  Value<bool> taxDeductible,
  Value<String?> taxCategory,
  Value<String?> paymentMethod,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vendor => $composableBuilder(
      column: $table.vendor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expenseDate => $composableBuilder(
      column: $table.expenseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get taxDeductible => $composableBuilder(
      column: $table.taxDeductible, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxCategory => $composableBuilder(
      column: $table.taxCategory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vendor => $composableBuilder(
      column: $table.vendor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expenseDate => $composableBuilder(
      column: $table.expenseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get taxDeductible => $composableBuilder(
      column: $table.taxDeductible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxCategory => $composableBuilder(
      column: $table.taxCategory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get expenseDate => $composableBuilder(
      column: $table.expenseDate, builder: (column) => column);

  GeneratedColumn<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => column);

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<bool> get taxDeductible => $composableBuilder(
      column: $table.taxDeductible, builder: (column) => column);

  GeneratedColumn<String> get taxCategory => $composableBuilder(
      column: $table.taxCategory, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> vendor = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> expenseDate = const Value.absent(),
            Value<String?> receiptPath = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> ocrText = const Value.absent(),
            Value<bool> taxDeductible = const Value.absent(),
            Value<String?> taxCategory = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            userId: userId,
            jobId: jobId,
            customerId: customerId,
            description: description,
            vendor: vendor,
            category: category,
            amount: amount,
            expenseDate: expenseDate,
            receiptPath: receiptPath,
            receiptUrl: receiptUrl,
            ocrText: ocrText,
            taxDeductible: taxDeductible,
            taxCategory: taxCategory,
            paymentMethod: paymentMethod,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> jobId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            required String description,
            Value<String?> vendor = const Value.absent(),
            required String category,
            required double amount,
            required DateTime expenseDate,
            Value<String?> receiptPath = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> ocrText = const Value.absent(),
            Value<bool> taxDeductible = const Value.absent(),
            Value<String?> taxCategory = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            userId: userId,
            jobId: jobId,
            customerId: customerId,
            description: description,
            vendor: vendor,
            category: category,
            amount: amount,
            expenseDate: expenseDate,
            receiptPath: receiptPath,
            receiptUrl: receiptUrl,
            ocrText: ocrText,
            taxDeductible: taxDeductible,
            taxCategory: taxCategory,
            paymentMethod: paymentMethod,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()>;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  required String id,
  required String jobId,
  required String userId,
  required double amount,
  required String method,
  Value<String?> reference,
  Value<String?> notes,
  required DateTime receivedAt,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<String> jobId,
  Value<String> userId,
  Value<double> amount,
  Value<String> method,
  Value<String?> reference,
  Value<String?> notes,
  Value<DateTime> receivedAt,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
    Payment,
    PrefetchHooks Function()> {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String?> reference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> receivedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion(
            id: id,
            jobId: jobId,
            userId: userId,
            amount: amount,
            method: method,
            reference: reference,
            notes: notes,
            receivedAt: receivedAt,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobId,
            required String userId,
            required double amount,
            required String method,
            Value<String?> reference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime receivedAt,
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion.insert(
            id: id,
            jobId: jobId,
            userId: userId,
            amount: amount,
            method: method,
            reference: reference,
            notes: notes,
            receivedAt: receivedAt,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
    Payment,
    PrefetchHooks Function()>;
typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  required String id,
  required String userId,
  Value<String?> expenseId,
  Value<String?> jobId,
  Value<String?> customerId,
  required String imagePath,
  Value<String?> imageUrl,
  Value<String?> thumbnailPath,
  Value<String?> ocrText,
  Value<double?> extractedAmount,
  Value<String?> extractedVendor,
  Value<DateTime?> extractedDate,
  Value<String?> extractedItemsJson,
  Value<String> ocrStatus,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> expenseId,
  Value<String?> jobId,
  Value<String?> customerId,
  Value<String> imagePath,
  Value<String?> imageUrl,
  Value<String?> thumbnailPath,
  Value<String?> ocrText,
  Value<double?> extractedAmount,
  Value<String?> extractedVendor,
  Value<DateTime?> extractedDate,
  Value<String?> extractedItemsJson,
  Value<String> ocrStatus,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get extractedAmount => $composableBuilder(
      column: $table.extractedAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extractedVendor => $composableBuilder(
      column: $table.extractedVendor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get extractedDate => $composableBuilder(
      column: $table.extractedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extractedItemsJson => $composableBuilder(
      column: $table.extractedItemsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ocrStatus => $composableBuilder(
      column: $table.ocrStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get extractedAmount => $composableBuilder(
      column: $table.extractedAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extractedVendor => $composableBuilder(
      column: $table.extractedVendor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get extractedDate => $composableBuilder(
      column: $table.extractedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extractedItemsJson => $composableBuilder(
      column: $table.extractedItemsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ocrStatus => $composableBuilder(
      column: $table.ocrStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<double> get extractedAmount => $composableBuilder(
      column: $table.extractedAmount, builder: (column) => column);

  GeneratedColumn<String> get extractedVendor => $composableBuilder(
      column: $table.extractedVendor, builder: (column) => column);

  GeneratedColumn<DateTime> get extractedDate => $composableBuilder(
      column: $table.extractedDate, builder: (column) => column);

  GeneratedColumn<String> get extractedItemsJson => $composableBuilder(
      column: $table.extractedItemsJson, builder: (column) => column);

  GeneratedColumn<String> get ocrStatus =>
      $composableBuilder(column: $table.ocrStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ReceiptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
    Receipt,
    PrefetchHooks Function()> {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> expenseId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> ocrText = const Value.absent(),
            Value<double?> extractedAmount = const Value.absent(),
            Value<String?> extractedVendor = const Value.absent(),
            Value<DateTime?> extractedDate = const Value.absent(),
            Value<String?> extractedItemsJson = const Value.absent(),
            Value<String> ocrStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion(
            id: id,
            userId: userId,
            expenseId: expenseId,
            jobId: jobId,
            customerId: customerId,
            imagePath: imagePath,
            imageUrl: imageUrl,
            thumbnailPath: thumbnailPath,
            ocrText: ocrText,
            extractedAmount: extractedAmount,
            extractedVendor: extractedVendor,
            extractedDate: extractedDate,
            extractedItemsJson: extractedItemsJson,
            ocrStatus: ocrStatus,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> expenseId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            required String imagePath,
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> ocrText = const Value.absent(),
            Value<double?> extractedAmount = const Value.absent(),
            Value<String?> extractedVendor = const Value.absent(),
            Value<DateTime?> extractedDate = const Value.absent(),
            Value<String?> extractedItemsJson = const Value.absent(),
            Value<String> ocrStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion.insert(
            id: id,
            userId: userId,
            expenseId: expenseId,
            jobId: jobId,
            customerId: customerId,
            imagePath: imagePath,
            imageUrl: imageUrl,
            thumbnailPath: thumbnailPath,
            ocrText: ocrText,
            extractedAmount: extractedAmount,
            extractedVendor: extractedVendor,
            extractedDate: extractedDate,
            extractedItemsJson: extractedItemsJson,
            ocrStatus: ocrStatus,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReceiptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
    Receipt,
    PrefetchHooks Function()>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String userId,
  required String name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  Value<double> totalBilled,
  Value<double> totalPaid,
  Value<double> balance,
  Value<int> jobCount,
  Value<DateTime?> lastJobDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  Value<double> totalBilled,
  Value<double> totalPaid,
  Value<double> balance,
  Value<int> jobCount,
  Value<DateTime?> lastJobDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalBilled => $composableBuilder(
      column: $table.totalBilled, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jobCount => $composableBuilder(
      column: $table.jobCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastJobDate => $composableBuilder(
      column: $table.lastJobDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalBilled => $composableBuilder(
      column: $table.totalBilled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jobCount => $composableBuilder(
      column: $table.jobCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastJobDate => $composableBuilder(
      column: $table.lastJobDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get totalBilled => $composableBuilder(
      column: $table.totalBilled, builder: (column) => column);

  GeneratedColumn<double> get totalPaid =>
      $composableBuilder(column: $table.totalPaid, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get jobCount =>
      $composableBuilder(column: $table.jobCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastJobDate => $composableBuilder(
      column: $table.lastJobDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<double> totalBilled = const Value.absent(),
            Value<double> totalPaid = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<int> jobCount = const Value.absent(),
            Value<DateTime?> lastJobDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            userId: userId,
            name: name,
            email: email,
            phone: phone,
            address: address,
            notes: notes,
            totalBilled: totalBilled,
            totalPaid: totalPaid,
            balance: balance,
            jobCount: jobCount,
            lastJobDate: lastJobDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<double> totalBilled = const Value.absent(),
            Value<double> totalPaid = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<int> jobCount = const Value.absent(),
            Value<DateTime?> lastJobDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            email: email,
            phone: phone,
            address: address,
            notes: notes,
            totalBilled: totalBilled,
            totalPaid: totalPaid,
            balance: balance,
            jobCount: jobCount,
            lastJobDate: lastJobDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()>;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String userId,
  required String name,
  required String type,
  Value<double?> defaultLaborRate,
  Value<double?> defaultTaxRate,
  Value<String?> defaultTerms,
  Value<String?> defaultNotes,
  Value<String> lineItemsJson,
  Value<int> useCount,
  Value<DateTime?> lastUsedAt,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String> type,
  Value<double?> defaultLaborRate,
  Value<double?> defaultTaxRate,
  Value<String?> defaultTerms,
  Value<String?> defaultNotes,
  Value<String> lineItemsJson,
  Value<int> useCount,
  Value<DateTime?> lastUsedAt,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get defaultLaborRate => $composableBuilder(
      column: $table.defaultLaborRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get defaultTaxRate => $composableBuilder(
      column: $table.defaultTaxRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultTerms => $composableBuilder(
      column: $table.defaultTerms, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultNotes => $composableBuilder(
      column: $table.defaultNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lineItemsJson => $composableBuilder(
      column: $table.lineItemsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get useCount => $composableBuilder(
      column: $table.useCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get defaultLaborRate => $composableBuilder(
      column: $table.defaultLaborRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get defaultTaxRate => $composableBuilder(
      column: $table.defaultTaxRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultTerms => $composableBuilder(
      column: $table.defaultTerms,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultNotes => $composableBuilder(
      column: $table.defaultNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lineItemsJson => $composableBuilder(
      column: $table.lineItemsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get useCount => $composableBuilder(
      column: $table.useCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get defaultLaborRate => $composableBuilder(
      column: $table.defaultLaborRate, builder: (column) => column);

  GeneratedColumn<double> get defaultTaxRate => $composableBuilder(
      column: $table.defaultTaxRate, builder: (column) => column);

  GeneratedColumn<String> get defaultTerms => $composableBuilder(
      column: $table.defaultTerms, builder: (column) => column);

  GeneratedColumn<String> get defaultNotes => $composableBuilder(
      column: $table.defaultNotes, builder: (column) => column);

  GeneratedColumn<String> get lineItemsJson => $composableBuilder(
      column: $table.lineItemsJson, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$TemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TemplatesTable,
    Template,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (Template, BaseReferences<_$AppDatabase, $TemplatesTable, Template>),
    Template,
    PrefetchHooks Function()> {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double?> defaultLaborRate = const Value.absent(),
            Value<double?> defaultTaxRate = const Value.absent(),
            Value<String?> defaultTerms = const Value.absent(),
            Value<String?> defaultNotes = const Value.absent(),
            Value<String> lineItemsJson = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion(
            id: id,
            userId: userId,
            name: name,
            type: type,
            defaultLaborRate: defaultLaborRate,
            defaultTaxRate: defaultTaxRate,
            defaultTerms: defaultTerms,
            defaultNotes: defaultNotes,
            lineItemsJson: lineItemsJson,
            useCount: useCount,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            required String type,
            Value<double?> defaultLaborRate = const Value.absent(),
            Value<double?> defaultTaxRate = const Value.absent(),
            Value<String?> defaultTerms = const Value.absent(),
            Value<String?> defaultNotes = const Value.absent(),
            Value<String> lineItemsJson = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            defaultLaborRate: defaultLaborRate,
            defaultTaxRate: defaultTaxRate,
            defaultTerms: defaultTerms,
            defaultNotes: defaultNotes,
            lineItemsJson: lineItemsJson,
            useCount: useCount,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TemplatesTable,
    Template,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (Template, BaseReferences<_$AppDatabase, $TemplatesTable, Template>),
    Template,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String targetTable,
  required String recordId,
  required String operation,
  required String dataJson,
  Value<int> retryCount,
  Value<String> status,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> targetTable,
  Value<String> recordId,
  Value<String> operation,
  Value<String> dataJson,
  Value<int> retryCount,
  Value<String> status,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> targetTable = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> dataJson = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            targetTable: targetTable,
            recordId: recordId,
            operation: operation,
            dataJson: dataJson,
            retryCount: retryCount,
            status: status,
            errorMessage: errorMessage,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String targetTable,
            required String recordId,
            required String operation,
            required String dataJson,
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            targetTable: targetTable,
            recordId: recordId,
            operation: operation,
            dataJson: dataJson,
            retryCount: retryCount,
            status: status,
            errorMessage: errorMessage,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$BusinessSettingsTableCreateCompanionBuilder
    = BusinessSettingsCompanion Function({
  required String userId,
  required String businessName,
  Value<String?> businessAddress,
  Value<String?> businessPhone,
  Value<String?> businessEmail,
  Value<String?> taxId,
  Value<double> defaultHourlyRate,
  Value<double> defaultTaxRate,
  Value<String> currencySymbol,
  Value<String?> invoicePrefix,
  Value<int> nextInvoiceNumber,
  Value<String?> defaultPaymentTerms,
  Value<bool> isPro,
  Value<String> subscriptionStatus,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$BusinessSettingsTableUpdateCompanionBuilder
    = BusinessSettingsCompanion Function({
  Value<String> userId,
  Value<String> businessName,
  Value<String?> businessAddress,
  Value<String?> businessPhone,
  Value<String?> businessEmail,
  Value<String?> taxId,
  Value<double> defaultHourlyRate,
  Value<double> defaultTaxRate,
  Value<String> currencySymbol,
  Value<String?> invoicePrefix,
  Value<int> nextInvoiceNumber,
  Value<String?> defaultPaymentTerms,
  Value<bool> isPro,
  Value<String> subscriptionStatus,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$BusinessSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTable> {
  $$BusinessSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessName => $composableBuilder(
      column: $table.businessName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessAddress => $composableBuilder(
      column: $table.businessAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessPhone => $composableBuilder(
      column: $table.businessPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessEmail => $composableBuilder(
      column: $table.businessEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxId => $composableBuilder(
      column: $table.taxId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get defaultHourlyRate => $composableBuilder(
      column: $table.defaultHourlyRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get defaultTaxRate => $composableBuilder(
      column: $table.defaultTaxRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoicePrefix => $composableBuilder(
      column: $table.invoicePrefix, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextInvoiceNumber => $composableBuilder(
      column: $table.nextInvoiceNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultPaymentTerms => $composableBuilder(
      column: $table.defaultPaymentTerms,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPro => $composableBuilder(
      column: $table.isPro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subscriptionStatus => $composableBuilder(
      column: $table.subscriptionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$BusinessSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTable> {
  $$BusinessSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessName => $composableBuilder(
      column: $table.businessName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessAddress => $composableBuilder(
      column: $table.businessAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessPhone => $composableBuilder(
      column: $table.businessPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessEmail => $composableBuilder(
      column: $table.businessEmail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxId => $composableBuilder(
      column: $table.taxId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get defaultHourlyRate => $composableBuilder(
      column: $table.defaultHourlyRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get defaultTaxRate => $composableBuilder(
      column: $table.defaultTaxRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoicePrefix => $composableBuilder(
      column: $table.invoicePrefix,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextInvoiceNumber => $composableBuilder(
      column: $table.nextInvoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultPaymentTerms => $composableBuilder(
      column: $table.defaultPaymentTerms,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPro => $composableBuilder(
      column: $table.isPro, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subscriptionStatus => $composableBuilder(
      column: $table.subscriptionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$BusinessSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTable> {
  $$BusinessSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
      column: $table.businessName, builder: (column) => column);

  GeneratedColumn<String> get businessAddress => $composableBuilder(
      column: $table.businessAddress, builder: (column) => column);

  GeneratedColumn<String> get businessPhone => $composableBuilder(
      column: $table.businessPhone, builder: (column) => column);

  GeneratedColumn<String> get businessEmail => $composableBuilder(
      column: $table.businessEmail, builder: (column) => column);

  GeneratedColumn<String> get taxId =>
      $composableBuilder(column: $table.taxId, builder: (column) => column);

  GeneratedColumn<double> get defaultHourlyRate => $composableBuilder(
      column: $table.defaultHourlyRate, builder: (column) => column);

  GeneratedColumn<double> get defaultTaxRate => $composableBuilder(
      column: $table.defaultTaxRate, builder: (column) => column);

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol, builder: (column) => column);

  GeneratedColumn<String> get invoicePrefix => $composableBuilder(
      column: $table.invoicePrefix, builder: (column) => column);

  GeneratedColumn<int> get nextInvoiceNumber => $composableBuilder(
      column: $table.nextInvoiceNumber, builder: (column) => column);

  GeneratedColumn<String> get defaultPaymentTerms => $composableBuilder(
      column: $table.defaultPaymentTerms, builder: (column) => column);

  GeneratedColumn<bool> get isPro =>
      $composableBuilder(column: $table.isPro, builder: (column) => column);

  GeneratedColumn<String> get subscriptionStatus => $composableBuilder(
      column: $table.subscriptionStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$BusinessSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BusinessSettingsTable,
    BusinessSetting,
    $$BusinessSettingsTableFilterComposer,
    $$BusinessSettingsTableOrderingComposer,
    $$BusinessSettingsTableAnnotationComposer,
    $$BusinessSettingsTableCreateCompanionBuilder,
    $$BusinessSettingsTableUpdateCompanionBuilder,
    (
      BusinessSetting,
      BaseReferences<_$AppDatabase, $BusinessSettingsTable, BusinessSetting>
    ),
    BusinessSetting,
    PrefetchHooks Function()> {
  $$BusinessSettingsTableTableManager(
      _$AppDatabase db, $BusinessSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> businessName = const Value.absent(),
            Value<String?> businessAddress = const Value.absent(),
            Value<String?> businessPhone = const Value.absent(),
            Value<String?> businessEmail = const Value.absent(),
            Value<String?> taxId = const Value.absent(),
            Value<double> defaultHourlyRate = const Value.absent(),
            Value<double> defaultTaxRate = const Value.absent(),
            Value<String> currencySymbol = const Value.absent(),
            Value<String?> invoicePrefix = const Value.absent(),
            Value<int> nextInvoiceNumber = const Value.absent(),
            Value<String?> defaultPaymentTerms = const Value.absent(),
            Value<bool> isPro = const Value.absent(),
            Value<String> subscriptionStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BusinessSettingsCompanion(
            userId: userId,
            businessName: businessName,
            businessAddress: businessAddress,
            businessPhone: businessPhone,
            businessEmail: businessEmail,
            taxId: taxId,
            defaultHourlyRate: defaultHourlyRate,
            defaultTaxRate: defaultTaxRate,
            currencySymbol: currencySymbol,
            invoicePrefix: invoicePrefix,
            nextInvoiceNumber: nextInvoiceNumber,
            defaultPaymentTerms: defaultPaymentTerms,
            isPro: isPro,
            subscriptionStatus: subscriptionStatus,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String businessName,
            Value<String?> businessAddress = const Value.absent(),
            Value<String?> businessPhone = const Value.absent(),
            Value<String?> businessEmail = const Value.absent(),
            Value<String?> taxId = const Value.absent(),
            Value<double> defaultHourlyRate = const Value.absent(),
            Value<double> defaultTaxRate = const Value.absent(),
            Value<String> currencySymbol = const Value.absent(),
            Value<String?> invoicePrefix = const Value.absent(),
            Value<int> nextInvoiceNumber = const Value.absent(),
            Value<String?> defaultPaymentTerms = const Value.absent(),
            Value<bool> isPro = const Value.absent(),
            Value<String> subscriptionStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BusinessSettingsCompanion.insert(
            userId: userId,
            businessName: businessName,
            businessAddress: businessAddress,
            businessPhone: businessPhone,
            businessEmail: businessEmail,
            taxId: taxId,
            defaultHourlyRate: defaultHourlyRate,
            defaultTaxRate: defaultTaxRate,
            currencySymbol: currencySymbol,
            invoicePrefix: invoicePrefix,
            nextInvoiceNumber: nextInvoiceNumber,
            defaultPaymentTerms: defaultPaymentTerms,
            isPro: isPro,
            subscriptionStatus: subscriptionStatus,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BusinessSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BusinessSettingsTable,
    BusinessSetting,
    $$BusinessSettingsTableFilterComposer,
    $$BusinessSettingsTableOrderingComposer,
    $$BusinessSettingsTableAnnotationComposer,
    $$BusinessSettingsTableCreateCompanionBuilder,
    $$BusinessSettingsTableUpdateCompanionBuilder,
    (
      BusinessSetting,
      BaseReferences<_$AppDatabase, $BusinessSettingsTable, BusinessSetting>
    ),
    BusinessSetting,
    PrefetchHooks Function()>;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String userId,
  required String customerId,
  required String name,
  Value<String?> description,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> customerId,
  Value<String> name,
  Value<String?> description,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()> {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            userId: userId,
            customerId: customerId,
            name: name,
            description: description,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String customerId,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            userId: userId,
            customerId: customerId,
            name: name,
            description: description,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()>;
typedef $$RecognizedMaterialCostsTableCreateCompanionBuilder
    = RecognizedMaterialCostsCompanion Function({
  required String id,
  required String userId,
  Value<String?> jobId,
  Value<int?> materialIndex,
  Value<String?> materialId,
  required String description,
  required double provisionalCost,
  required double canonicalCost,
  required DateTime recognitionDate,
  Value<String> source,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$RecognizedMaterialCostsTableUpdateCompanionBuilder
    = RecognizedMaterialCostsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> jobId,
  Value<int?> materialIndex,
  Value<String?> materialId,
  Value<String> description,
  Value<double> provisionalCost,
  Value<double> canonicalCost,
  Value<DateTime> recognitionDate,
  Value<String> source,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$RecognizedMaterialCostsTableFilterComposer
    extends Composer<_$AppDatabase, $RecognizedMaterialCostsTable> {
  $$RecognizedMaterialCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get materialIndex => $composableBuilder(
      column: $table.materialIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get provisionalCost => $composableBuilder(
      column: $table.provisionalCost,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get canonicalCost => $composableBuilder(
      column: $table.canonicalCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recognitionDate => $composableBuilder(
      column: $table.recognitionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$RecognizedMaterialCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecognizedMaterialCostsTable> {
  $$RecognizedMaterialCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get materialIndex => $composableBuilder(
      column: $table.materialIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get provisionalCost => $composableBuilder(
      column: $table.provisionalCost,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get canonicalCost => $composableBuilder(
      column: $table.canonicalCost,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recognitionDate => $composableBuilder(
      column: $table.recognitionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$RecognizedMaterialCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecognizedMaterialCostsTable> {
  $$RecognizedMaterialCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get materialIndex => $composableBuilder(
      column: $table.materialIndex, builder: (column) => column);

  GeneratedColumn<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get provisionalCost => $composableBuilder(
      column: $table.provisionalCost, builder: (column) => column);

  GeneratedColumn<double> get canonicalCost => $composableBuilder(
      column: $table.canonicalCost, builder: (column) => column);

  GeneratedColumn<DateTime> get recognitionDate => $composableBuilder(
      column: $table.recognitionDate, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$RecognizedMaterialCostsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecognizedMaterialCostsTable,
    RecognizedMaterialCost,
    $$RecognizedMaterialCostsTableFilterComposer,
    $$RecognizedMaterialCostsTableOrderingComposer,
    $$RecognizedMaterialCostsTableAnnotationComposer,
    $$RecognizedMaterialCostsTableCreateCompanionBuilder,
    $$RecognizedMaterialCostsTableUpdateCompanionBuilder,
    (
      RecognizedMaterialCost,
      BaseReferences<_$AppDatabase, $RecognizedMaterialCostsTable,
          RecognizedMaterialCost>
    ),
    RecognizedMaterialCost,
    PrefetchHooks Function()> {
  $$RecognizedMaterialCostsTableTableManager(
      _$AppDatabase db, $RecognizedMaterialCostsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecognizedMaterialCostsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RecognizedMaterialCostsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecognizedMaterialCostsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<int?> materialIndex = const Value.absent(),
            Value<String?> materialId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> provisionalCost = const Value.absent(),
            Value<double> canonicalCost = const Value.absent(),
            Value<DateTime> recognitionDate = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecognizedMaterialCostsCompanion(
            id: id,
            userId: userId,
            jobId: jobId,
            materialIndex: materialIndex,
            materialId: materialId,
            description: description,
            provisionalCost: provisionalCost,
            canonicalCost: canonicalCost,
            recognitionDate: recognitionDate,
            source: source,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> jobId = const Value.absent(),
            Value<int?> materialIndex = const Value.absent(),
            Value<String?> materialId = const Value.absent(),
            required String description,
            required double provisionalCost,
            required double canonicalCost,
            required DateTime recognitionDate,
            Value<String> source = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecognizedMaterialCostsCompanion.insert(
            id: id,
            userId: userId,
            jobId: jobId,
            materialIndex: materialIndex,
            materialId: materialId,
            description: description,
            provisionalCost: provisionalCost,
            canonicalCost: canonicalCost,
            recognitionDate: recognitionDate,
            source: source,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecognizedMaterialCostsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RecognizedMaterialCostsTable,
        RecognizedMaterialCost,
        $$RecognizedMaterialCostsTableFilterComposer,
        $$RecognizedMaterialCostsTableOrderingComposer,
        $$RecognizedMaterialCostsTableAnnotationComposer,
        $$RecognizedMaterialCostsTableCreateCompanionBuilder,
        $$RecognizedMaterialCostsTableUpdateCompanionBuilder,
        (
          RecognizedMaterialCost,
          BaseReferences<_$AppDatabase, $RecognizedMaterialCostsTable,
              RecognizedMaterialCost>
        ),
        RecognizedMaterialCost,
        PrefetchHooks Function()>;
typedef $$MaterialCostLinksTableCreateCompanionBuilder
    = MaterialCostLinksCompanion Function({
  required String id,
  required String recognizedMaterialCostId,
  required String expenseId,
  required double allocatedAmount,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$MaterialCostLinksTableUpdateCompanionBuilder
    = MaterialCostLinksCompanion Function({
  Value<String> id,
  Value<String> recognizedMaterialCostId,
  Value<String> expenseId,
  Value<double> allocatedAmount,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$MaterialCostLinksTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialCostLinksTable> {
  $$MaterialCostLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recognizedMaterialCostId => $composableBuilder(
      column: $table.recognizedMaterialCostId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get allocatedAmount => $composableBuilder(
      column: $table.allocatedAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MaterialCostLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialCostLinksTable> {
  $$MaterialCostLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recognizedMaterialCostId => $composableBuilder(
      column: $table.recognizedMaterialCostId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get allocatedAmount => $composableBuilder(
      column: $table.allocatedAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MaterialCostLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialCostLinksTable> {
  $$MaterialCostLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recognizedMaterialCostId => $composableBuilder(
      column: $table.recognizedMaterialCostId, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<double> get allocatedAmount => $composableBuilder(
      column: $table.allocatedAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MaterialCostLinksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MaterialCostLinksTable,
    MaterialCostLink,
    $$MaterialCostLinksTableFilterComposer,
    $$MaterialCostLinksTableOrderingComposer,
    $$MaterialCostLinksTableAnnotationComposer,
    $$MaterialCostLinksTableCreateCompanionBuilder,
    $$MaterialCostLinksTableUpdateCompanionBuilder,
    (
      MaterialCostLink,
      BaseReferences<_$AppDatabase, $MaterialCostLinksTable, MaterialCostLink>
    ),
    MaterialCostLink,
    PrefetchHooks Function()> {
  $$MaterialCostLinksTableTableManager(
      _$AppDatabase db, $MaterialCostLinksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialCostLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaterialCostLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaterialCostLinksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recognizedMaterialCostId = const Value.absent(),
            Value<String> expenseId = const Value.absent(),
            Value<double> allocatedAmount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MaterialCostLinksCompanion(
            id: id,
            recognizedMaterialCostId: recognizedMaterialCostId,
            expenseId: expenseId,
            allocatedAmount: allocatedAmount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String recognizedMaterialCostId,
            required String expenseId,
            required double allocatedAmount,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MaterialCostLinksCompanion.insert(
            id: id,
            recognizedMaterialCostId: recognizedMaterialCostId,
            expenseId: expenseId,
            allocatedAmount: allocatedAmount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MaterialCostLinksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MaterialCostLinksTable,
    MaterialCostLink,
    $$MaterialCostLinksTableFilterComposer,
    $$MaterialCostLinksTableOrderingComposer,
    $$MaterialCostLinksTableAnnotationComposer,
    $$MaterialCostLinksTableCreateCompanionBuilder,
    $$MaterialCostLinksTableUpdateCompanionBuilder,
    (
      MaterialCostLink,
      BaseReferences<_$AppDatabase, $MaterialCostLinksTable, MaterialCostLink>
    ),
    MaterialCostLink,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$BusinessSettingsTableTableManager get businessSettings =>
      $$BusinessSettingsTableTableManager(_db, _db.businessSettings);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$RecognizedMaterialCostsTableTableManager get recognizedMaterialCosts =>
      $$RecognizedMaterialCostsTableTableManager(
          _db, _db.recognizedMaterialCosts);
  $$MaterialCostLinksTableTableManager get materialCostLinks =>
      $$MaterialCostLinksTableTableManager(_db, _db.materialCostLinks);
}
