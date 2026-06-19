import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/models/local_account.dart';
import 'package:memory2care/models/medication.dart';
import 'package:memory2care/models/medication_plan.dart';
import 'package:memory2care/models/user_profile.dart';
import 'package:memory2care/platform/database_factory_initializer.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class LocalStore {
  LocalStore._(this._db);

  static const _profileKey = 'profile';
  static const _medicationKey = 'medication';
  static const _takenMedicationsKey = 'taken_medications';
  static const _tokenKey = 'auth_token';
  static const _localAccountKey = 'local_account';
  static const _localAccountsKey = 'local_accounts';
  static const _activeAccountEmailKey = 'active_account_email';
  static const _migrationFlagKey = 'migrated_from_shared_prefs_v1';

  static const _appStateTable = 'app_state';
  static const _accountsTable = 'accounts';
  static const _medicationsTable = 'medications';
  static const _takenMedicationsTable = 'taken_medications';
  static const _dbVersion = 2;

  final Database _db;

  UserProfile? _profileCache;
  String? _activeAccountEmailCache;
  final Map<String, LocalAccount> _accountsCache = <String, LocalAccount>{};
  MedicationPlan _medicationPlanCache = MedicationPlan.empty();
  final Map<DateTime, Set<String>> _takenMedsCache = <DateTime, Set<String>>{};

  static Future<LocalStore>? _instanceFuture;

  static Future<LocalStore> instance() async {
    _instanceFuture ??= _create();
    return _instanceFuture!;
  }

  static Future<LocalStore> _create() async {
    initializeDesktopDatabaseFactory();
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'memory2care.db'),
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_appStateTable (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $_accountsTable (
            email TEXT PRIMARY KEY,
            password_hash TEXT,
            password_salt TEXT,
            legacy_password TEXT,
            full_name TEXT NOT NULL,
            phone TEXT NOT NULL,
            gender TEXT NOT NULL,
            birth_date TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_medicationsTable (
            id TEXT PRIMARY KEY,
            account_email TEXT NOT NULL,
            name TEXT NOT NULL,
            dose TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT,
            times_of_day TEXT NOT NULL,
            weekdays TEXT NOT NULL,
            is_active INTEGER NOT NULL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $_takenMedicationsTable (
            date TEXT NOT NULL,
            account_email TEXT NOT NULL,
            medication_id TEXT NOT NULL,
            PRIMARY KEY (date, account_email, medication_id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_medicationsTable ADD COLUMN account_email TEXT',
          );
          await db.execute(
            'ALTER TABLE $_takenMedicationsTable ADD COLUMN account_email TEXT',
          );

          final activeEmail = await _readMigrationOwner(db);
          if (activeEmail != null && activeEmail.isNotEmpty) {
            await db.update(
              _medicationsTable,
              {'account_email': activeEmail},
              where: 'account_email IS NULL OR account_email = ""',
            );
            await db.update(
              _takenMedicationsTable,
              {'account_email': activeEmail},
              where: 'account_email IS NULL OR account_email = ""',
            );
          }

          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_medications_account_id ON $_medicationsTable(account_email, id)',
          );
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_taken_medications_account_date_med ON $_takenMedicationsTable(account_email, date, medication_id)',
          );
        }
      },
    );

    final store = LocalStore._(database);
    await store._migrateFromSharedPreferencesIfNeeded();
    await store._loadCaches();
    return store;
  }

  Future<void> _loadCaches() async {
    _accountsCache
      ..clear()
      ..addAll(await _readAccountsFromDb());

    if (kDebugMode && _accountsCache.isNotEmpty) {
      debugPrint(
        '[LocalStore] Loaded ${_accountsCache.length} account(s) from database',
      );
    }

    _profileCache = await _readProfileFromDb();
    _activeAccountEmailCache = await _readAppState(_activeAccountEmailKey);
    await _loadActiveAccountData();
  }

  Future<void> _loadActiveAccountData() async {
    final activeEmail = readActiveAccountEmail();
    if (activeEmail == null || activeEmail.isEmpty) {
      _medicationPlanCache = MedicationPlan.empty();
      _takenMedsCache.clear();
      return;
    }

    _medicationPlanCache = MedicationPlan(
      medications: await _readMedicationsFromDb(activeEmail: activeEmail),
    );

    _takenMedsCache
      ..clear()
      ..addAll(await _readTakenMedsFromDb(activeEmail: activeEmail));
  }

  Future<void> reloadActiveAccountState() async {
    _profileCache = await _readProfileFromDb();
    _activeAccountEmailCache = await _readAppState(_activeAccountEmailKey);
    await _loadActiveAccountData();
  }

  static Future<String?> _readMigrationOwner(Database db) async {
    final activeRows = await db.query(
      _appStateTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_activeAccountEmailKey],
      limit: 1,
    );
    if (activeRows.isNotEmpty) {
      final activeEmail = activeRows.first['value'] as String?;
      if (activeEmail != null && activeEmail.isNotEmpty) {
        return activeEmail.toLowerCase();
      }
    }

    final accounts = await db.query(
      _accountsTable,
      columns: ['email'],
      limit: 1,
    );
    if (accounts.isEmpty) {
      return null;
    }

    return accounts.first['email'] as String?;
  }

  Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    final alreadyMigrated = await _readAppState(_migrationFlagKey) == '1';
    if (alreadyMigrated) {
      if (kDebugMode) {
        debugPrint(
          '[LocalStore] Migration already completed; skipping migration',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[LocalStore] Starting migration from SharedPreferences to SQLite...',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final batch = _db.batch();

    final profileRaw = prefs.getString(_profileKey);
    if (profileRaw != null) {
      batch.insert(_appStateTable, {
        'key': _profileKey,
        'value': profileRaw,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final token = prefs.getString(_tokenKey);
    if (token != null) {
      batch.insert(_appStateTable, {
        'key': _tokenKey,
        'value': token,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final activeEmail = prefs.getString(_activeAccountEmailKey);
    if (activeEmail != null) {
      batch.insert(_appStateTable, {
        'key': _activeAccountEmailKey,
        'value': activeEmail.toLowerCase(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final localAccountsRaw = prefs.getString(_localAccountsKey);
    if (localAccountsRaw != null) {
      final decoded = jsonDecode(localAccountsRaw) as Map<String, dynamic>;
      if (kDebugMode) {
        debugPrint(
          '[LocalStore] Migrating ${decoded.length} account(s) from SharedPreferences',
        );
      }
      for (final entry in decoded.entries) {
        final account = LocalAccount.fromMap(
          entry.value as Map<String, dynamic>,
        );
        batch.insert(
          _accountsTable,
          _accountToRow(account),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } else {
      final legacyRaw = prefs.getString(_localAccountKey);
      if (legacyRaw != null) {
        final account = LocalAccount.fromMap(
          jsonDecode(legacyRaw) as Map<String, dynamic>,
        );
        batch.insert(
          _accountsTable,
          _accountToRow(account),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    final medicationRaw = prefs.getString(_medicationKey);
    if (medicationRaw != null) {
      final plan = MedicationPlan.fromMap(
        jsonDecode(medicationRaw) as Map<String, dynamic>,
      );
      for (final medication in plan.medications) {
        batch.insert(
          _medicationsTable,
          _medicationToRow(medication, accountEmail: activeEmail),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    final takenRaw = prefs.getString(_takenMedicationsKey);
    if (takenRaw != null) {
      final decoded = jsonDecode(takenRaw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.key));
        final meds = (entry.value as List<dynamic>).map((e) => e as String);
        for (final medicationId in meds) {
          batch.insert(_takenMedicationsTable, {
            'date': date,
            'account_email': activeEmail,
            'medication_id': medicationId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }

    batch.insert(_appStateTable, {
      'key': _migrationFlagKey,
      'value': '1',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await batch.commit(noResult: true);
    if (kDebugMode) {
      debugPrint('[LocalStore] Migration completed successfully');
    }
  }

  Future<String?> _readAppState(String key) async {
    final rows = await _db.query(
      _appStateTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> _writeAppState(String key, String? value) async {
    if (value == null) {
      await _db.delete(_appStateTable, where: 'key = ?', whereArgs: [key]);
      return;
    }

    await _db.insert(_appStateTable, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserProfile?> _readProfileFromDb() async {
    final raw = await _readAppState(_profileKey);
    if (raw == null) {
      return null;
    }
    return UserProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<Map<String, LocalAccount>> _readAccountsFromDb() async {
    final rows = await _db.query(_accountsTable);
    final accounts = <String, LocalAccount>{};
    for (final row in rows) {
      final account = _rowToAccount(row);
      accounts[account.email.toLowerCase()] = account;
    }
    return accounts;
  }

  Future<List<Medication>> _readMedicationsFromDb({String? activeEmail}) async {
    final rows = await _db.query(
      _medicationsTable,
      where: activeEmail == null ? null : 'account_email = ?',
      whereArgs: activeEmail == null ? null : [activeEmail.toLowerCase()],
    );
    return rows.map((row) => _rowToMedication(row)).toList();
  }

  Future<Map<DateTime, Set<String>>> _readTakenMedsFromDb({String? activeEmail}) async {
    final rows = await _db.query(
      _takenMedicationsTable,
      where: activeEmail == null ? null : 'account_email = ?',
      whereArgs: activeEmail == null ? null : [activeEmail.toLowerCase()],
    );
    final result = <DateTime, Set<String>>{};
    for (final row in rows) {
      final date = DateTime.parse(row['date'] as String);
      result.putIfAbsent(date, () => <String>{});
      result[date]!.add(row['medication_id'] as String);
    }
    return result;
  }

  Map<String, dynamic> _accountToRow(LocalAccount account) {
    return {
      'email': account.email.toLowerCase(),
      'password_hash': account.passwordHash,
      'password_salt': account.passwordSalt,
      'legacy_password': account.legacyPassword,
      'full_name': account.profile.fullName,
      'phone': account.profile.phone,
      'gender': account.profile.gender,
      'birth_date': account.profile.birthDate.toIso8601String(),
    };
  }

  LocalAccount _rowToAccount(Map<String, Object?> row) {
    final email = row['email']! as String;
    return LocalAccount(
      email: email,
      passwordHash: row['password_hash'] as String?,
      passwordSalt: row['password_salt'] as String?,
      legacyPassword: row['legacy_password'] as String?,
      profile: UserProfile(
        fullName: row['full_name']! as String,
        email: email,
        phone: row['phone']! as String,
        gender: row['gender']! as String,
        birthDate: DateTime.parse(row['birth_date']! as String),
      ),
    );
  }

  Map<String, dynamic> _medicationToRow(
    Medication medication, {
    String? accountEmail,
  }) {
    final activeEmail = accountEmail ?? readActiveAccountEmail();
    if (activeEmail == null || activeEmail.isEmpty) {
      throw StateError('Active account is required to save medication data');
    }

    final map = medication.toMap();
    return {
      'id': map['id'] as String,
      'account_email': activeEmail.toLowerCase(),
      'name': map['name'] as String,
      'dose': map['dose'] as String,
      'start_date': map['startDate'] as String,
      'end_date': map['endDate'] as String?,
      'times_of_day': jsonEncode(map['timesOfDay'] as List<dynamic>),
      'weekdays': jsonEncode(map['weekdays'] as List<dynamic>),
      'is_active': (map['isActive'] as bool) ? 1 : 0,
      'notes': map['notes'] as String?,
    };
  }

  Medication _rowToMedication(Map<String, Object?> row) {
    return MedicationPlan.fromMap({
      'medications': [
        {
          'id': row['id'],
          'name': row['name'],
          'dose': row['dose'],
          'startDate': row['start_date'],
          'endDate': row['end_date'],
          'timesOfDay': jsonDecode(row['times_of_day']! as String),
          'weekdays': jsonDecode(row['weekdays']! as String),
          'isActive': (row['is_active'] as int) == 1,
          'notes': row['notes'],
        },
      ],
    }).medications.first;
  }

  UserProfile? readProfile() {
    return _profileCache;
  }

  UserProfile? readStoredUserProfile() {
    return readProfile() ?? readActiveLocalAccount()?.profile;
  }

  Future<void> saveProfile(UserProfile profile) {
    _profileCache = profile;
    return _writeAppState(_profileKey, jsonEncode(profile.toMap()));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await saveProfile(profile);

    final account = readActiveLocalAccount();
    if (account == null) {
      return;
    }

    final oldEmail = account.email.toLowerCase();
    final newEmail = profile.email.toLowerCase();
    final updatedAccount = account.copyWith(
      email: profile.email,
      profile: profile,
    );

    if (oldEmail != newEmail) {
      final accounts = readLocalAccounts();
      accounts.remove(oldEmail);
      accounts[newEmail] = updatedAccount;
      await _db.transaction((txn) async {
        await txn.delete(
          _accountsTable,
          where: 'email = ?',
          whereArgs: [oldEmail],
        );
        await txn.insert(
          _accountsTable,
          _accountToRow(updatedAccount),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      _accountsCache
        ..remove(oldEmail)
        ..[newEmail] = updatedAccount;
    } else {
      await upsertLocalAccount(updatedAccount);
    }

    await setActiveAccountEmail(profile.email);
  }

  MedicationPlan? readMedicationPlan() {
    return _medicationPlanCache.medications.isEmpty
        ? null
        : _medicationPlanCache;
  }

  Future<void> saveMedicationPlan(MedicationPlan plan) async {
    final activeEmail = readActiveAccountEmail();
    if (activeEmail == null || activeEmail.isEmpty) {
      throw StateError('Active account is required to save medication data');
    }

    await _db.transaction((txn) async {
      await txn.delete(
        _medicationsTable,
        where: 'account_email = ?',
        whereArgs: [activeEmail],
      );
      for (final medication in plan.medications) {
        await txn.insert(
          _medicationsTable,
          _medicationToRow(medication, accountEmail: activeEmail),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _medicationPlanCache = plan;
  }

  Set<DateTime> readTakenDates() {
    return _takenMedsCache.keys.toSet();
  }

  Future<void> saveTakenDates(Set<DateTime> dates) {
    return Future<void>.value();
  }

  Map<DateTime, Set<String>> readTakenMedicationsByDate() {
    return Map<DateTime, Set<String>>.from(
      _takenMedsCache.map(
        (key, value) => MapEntry(
          DateTime(key.year, key.month, key.day),
          Set<String>.from(value),
        ),
      ),
    );
  }

  Future<void> saveTakenMedicationsByDate(
    Map<DateTime, Set<String>> takenMeds,
  ) async {
    final activeEmail = readActiveAccountEmail();
    if (activeEmail == null || activeEmail.isEmpty) {
      throw StateError('Active account is required to save taken medication data');
    }

    await _db.transaction((txn) async {
      await txn.delete(
        _takenMedicationsTable,
        where: 'account_email = ?',
        whereArgs: [activeEmail],
      );
      for (final entry in takenMeds.entries) {
        final date = DateFormat('yyyy-MM-dd').format(entry.key);
        for (final medicationId in entry.value) {
          await txn.insert(_takenMedicationsTable, {
            'date': date,
            'account_email': activeEmail,
            'medication_id': medicationId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });

    _takenMedsCache
      ..clear()
      ..addAll(
        takenMeds.map(
          (key, value) => MapEntry(
            DateTime(key.year, key.month, key.day),
            Set<String>.from(value),
          ),
        ),
      );
  }

  Future<void> saveAuthToken(String token) {
    return _writeAppState(_tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    _profileCache = null;
    _activeAccountEmailCache = null;
    _medicationPlanCache = MedicationPlan.empty();
    _takenMedsCache.clear();
    await _writeAppState(_tokenKey, null);
    await _writeAppState(_profileKey, null);
    await _writeAppState(_activeAccountEmailKey, null);
  }

  LocalAccount? readLegacyLocalAccount() {
    return _accountsCache.values.isEmpty ? null : _accountsCache.values.first;
  }

  Map<String, LocalAccount> readLocalAccounts() {
    return Map<String, LocalAccount>.from(_accountsCache);
  }

  LocalAccount? readLocalAccountByEmail(String email) {
    return readLocalAccounts()[email.toLowerCase()];
  }

  LocalAccount? readActiveLocalAccount() {
    final activeEmail = readActiveAccountEmail();
    if (activeEmail == null || activeEmail.isEmpty) {
      return null;
    }
    return readLocalAccountByEmail(activeEmail);
  }

  String? readActiveAccountEmail() {
    return _activeAccountEmailCache;
  }

  Future<void> setActiveAccountEmail(String email) {
    _activeAccountEmailCache = email.toLowerCase();
    return _writeAppState(_activeAccountEmailKey, _activeAccountEmailCache);
  }

  Future<void> upsertLocalAccount(LocalAccount account) async {
    final targetKey = account.email.toLowerCase();

    if (kDebugMode) {
      debugPrint('[LocalStore] Saving account: $targetKey');
    }

    await _db.insert(
      _accountsTable,
      _accountToRow(account.copyWith(email: targetKey)),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _accountsCache[targetKey] = account.copyWith(email: targetKey);
  }
}
