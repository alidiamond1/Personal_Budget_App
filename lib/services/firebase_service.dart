import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated and throw error if not
  Future<void> _checkAuth() async {
    print('Checking authentication...');
    final user = _auth.currentUser;
    print('Current user: ${user?.uid}');
    if (user == null) {
      print('No user authenticated');
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'unauthenticated',
        message: 'User must be authenticated to perform this operation',
      );
    }
    print('User authenticated successfully');
  }

  // Budget Operations
  Future<void> addBudget({
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    await _checkAuth();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('budgets')
          .add({
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'add_budget_failed',
        message: 'Failed to add budget: ${e.toString()}',
      );
    }
  }

  // Income Operations
  Future<void> addIncome({
    required double amount,
    required String source,
    required DateTime date,
    String? description,
    required bool isRecurring,
    String? frequency,
  }) async {
    await _checkAuth();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('incomes')
          .add({
        'amount': amount,
        'source': source,
        'date': Timestamp.fromDate(date),
        'description': description,
        'isRecurring': isRecurring,
        'frequency': frequency,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'add_income_failed',
        message: 'Failed to add income: ${e.toString()}',
      );
    }
  }

  // Expense Operations
  Future<void> addExpense({
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
    required bool isRecurring,
    String? frequency,
  }) async {
    await _checkAuth();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .add({
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
        'notes': notes,
        'isRecurring': isRecurring,
        'frequency': frequency,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'add_expense_failed',
        message: 'Failed to add expense: ${e.toString()}',
      );
    }
  }

  // Initialize user document if it doesn't exist
  Future<void> initializeUserDocument() async {
    print('Initializing user document...');
    await _checkAuth();

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      print('User document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        print('Creating new user document...');
        await _firestore.collection('users').doc(currentUserId).set({
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('User document created successfully');
      }
    } catch (e, stackTrace) {
      print('Error initializing user document: $e');
      print('Stack trace: $stackTrace');
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'init_user_failed',
        message: 'Failed to initialize user document: ${e.toString()}',
      );
    }
  }

  // Get total income for current month
  Future<double> getCurrentMonthIncome() async {
    print('Getting current month income...');
    await _checkAuth();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      print('Date range: $startOfMonth to $endOfMonth');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('incomes')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      print('Found ${querySnapshot.docs.length} income documents');
      double total = 0;
      for (var doc in querySnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        print('Income amount: $amount');
        total += amount;
      }
      print('Total income: $total');
      return total;
    } catch (e, stackTrace) {
      print('Error getting income: $e');
      print('Stack trace: $stackTrace');
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'get_income_failed',
        message: 'Failed to get income: ${e.toString()}',
      );
    }
  }

  // Get total expenses for current month
  Future<double> getCurrentMonthExpenses() async {
    print('Getting current month expenses...');
    await _checkAuth();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      print('Date range: $startOfMonth to $endOfMonth');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      print('Found ${querySnapshot.docs.length} expense documents');
      double total = 0;
      for (var doc in querySnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        print('Expense amount: $amount');
        total += amount;
      }
      print('Total expenses: $total');
      return total;
    } catch (e, stackTrace) {
      print('Error getting expenses: $e');
      print('Stack trace: $stackTrace');
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'get_expenses_failed',
        message: 'Failed to get expenses: ${e.toString()}',
      );
    }
  }

  // Get expenses by category for current month
  Future<Map<String, double>> getCurrentMonthExpensesByCategory() async {
    await _checkAuth();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      Map<String, double> categoryTotals = {};
      for (var doc in querySnapshot.docs) {
        final category = doc.data()['category'] as String;
        final amount = (doc.data()['amount'] as num).toDouble();
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
      return categoryTotals;
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'get_expenses_by_category_failed',
        message: 'Failed to get expenses by category: ${e.toString()}',
      );
    }
  }

  // Get budgets for current month
  Future<Map<String, double>> getCurrentMonthBudgets() async {
    await _checkAuth();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('budgets')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      Map<String, double> budgets = {};
      for (var doc in querySnapshot.docs) {
        final category = doc.data()['category'] as String;
        final amount = (doc.data()['amount'] as num).toDouble();
        budgets[category] = amount;
      }
      return budgets;
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'get_budgets_failed',
        message: 'Failed to get budgets: ${e.toString()}',
      );
    }
  }

  // Get recent transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions(
      {int limit = 3}) async {
    await _checkAuth();

    try {
      // Get recent expenses
      final expensesQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      // Get recent incomes
      final incomesQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('incomes')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> allTransactions = [];

      // Add expenses
      for (var doc in expensesQuery.docs) {
        allTransactions.add({
          ...doc.data(),
          'type': 'expense',
          'id': doc.id,
        });
      }

      // Add incomes
      for (var doc in incomesQuery.docs) {
        allTransactions.add({
          ...doc.data(),
          'type': 'income',
          'id': doc.id,
        });
      }

      // Sort by date
      allTransactions.sort((a, b) {
        final aDate = (a['date'] as Timestamp).toDate();
        final bDate = (b['date'] as Timestamp).toDate();
        return bDate.compareTo(aDate);
      });

      // Return only the most recent transactions
      return allTransactions.take(limit).toList();
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'get_transactions_failed',
        message: 'Failed to get recent transactions: ${e.toString()}',
      );
    }
  }

  Future<List<String>> getCategories() async {
    await _checkAuth();
    final expenseCategories = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('expenses')
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => doc.data()['category'] as String)
            .toSet()
            .toList());

    final incomeCategories = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('incomes')
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => doc.data()['source'] as String)
            .toSet()
            .toList());

    return <String>{...expenseCategories, ...incomeCategories}.toList();
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    await _checkAuth();

    // Get expenses
    final expenses = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .get()
        .then((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['type'] = 'expense';
              return data;
            }).toList());

    // Get income
    final income = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('incomes')
        .orderBy('date', descending: true)
        .get()
        .then((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['type'] = 'income';
              return data;
            }).toList());

    // Combine and sort by date
    final allTransactions = [...expenses, ...income];
    allTransactions.sort(
        (a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

    return allTransactions;
  }
}
