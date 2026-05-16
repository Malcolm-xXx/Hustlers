import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/models/wallet_models.dart';

class WalletState {
  final double balance;
  final double moneyIn;
  final double moneyOut;
  final List<WalletTransaction> transactions;
  final List<WalletSavedCard> savedCards;
  final List<LinkedBankAccount> linkedAccounts;
  final bool isLoading;
  final bool isBalanceVisible;
  final TransactionFilter activeFilter;

  const WalletState({
    this.balance = 0,
    this.moneyIn = 0,
    this.moneyOut = 0,
    this.transactions = const [],
    this.savedCards = const [],
    this.linkedAccounts = const [],
    this.isLoading = false,
    this.isBalanceVisible = true,
    this.activeFilter = TransactionFilter.all,
  });

  WalletState copyWith({
    double? balance,
    double? moneyIn,
    double? moneyOut,
    List<WalletTransaction>? transactions,
    List<WalletSavedCard>? savedCards,
    List<LinkedBankAccount>? linkedAccounts,
    bool? isLoading,
    bool? isBalanceVisible,
    TransactionFilter? activeFilter,
  }) =>
      WalletState(
        balance: balance ?? this.balance,
        moneyIn: moneyIn ?? this.moneyIn,
        moneyOut: moneyOut ?? this.moneyOut,
        transactions: transactions ?? this.transactions,
        savedCards: savedCards ?? this.savedCards,
        linkedAccounts: linkedAccounts ?? this.linkedAccounts,
        isLoading: isLoading ?? this.isLoading,
        isBalanceVisible: isBalanceVisible ?? this.isBalanceVisible,
        activeFilter: activeFilter ?? this.activeFilter,
      );

  List<WalletTransaction> get filteredTransactions {
    switch (activeFilter) {
      case TransactionFilter.all:
        return transactions;
      case TransactionFilter.orders:
        return transactions
            .where((t) => t.type == TransactionType.order)
            .toList();
      case TransactionFilter.topUps:
        return transactions
            .where((t) => t.type == TransactionType.topUp)
            .toList();
      case TransactionFilter.withdrawals:
        return transactions
            .where((t) => t.type == TransactionType.withdrawal)
            .toList();
    }
  }
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    Future.microtask(refresh);
    return const WalletState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(walletRemoteDatasourceProvider);
      final results = await Future.wait([
        ds.getAnalytics(),
        ds.getTransactions(),
      ]);
      final analytics = results[0] as WalletAnalyticsModel;
      final txList = results[1] as List<WalletTransactionApiModel>;

      state = state.copyWith(
        isLoading: false,
        balance: analytics.availableBalance.toDouble(),
        moneyIn: analytics.moneyInThisWeek.toDouble(),
        moneyOut: analytics.moneyOutThisWeek.toDouble(),
        transactions: txList.map((t) => t.toDisplayModel()).toList(),
      );
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleBalanceVisibility() =>
      state = state.copyWith(isBalanceVisible: !state.isBalanceVisible);

  void setFilter(TransactionFilter filter) =>
      state = state.copyWith(activeFilter: filter);
}

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);
