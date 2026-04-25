import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';

class WalletNotifier extends AsyncNotifier<List<WalletTransaction>> {
  @override
  Future<List<WalletTransaction>> build() => _fetchTransactions();

  Future<List<WalletTransaction>> _fetchTransactions() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final res = await supabase
        .from('wallet_transactions')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List).map((e) => WalletTransaction.fromJson(e)).toList();
  }

  Future<int> addCoins({
    required int amount,
    required String source,
    String? note,
  }) async {
    final uid = currentUserId;
    if (uid == null) return 0;

    final newBalance =
        await supabase.rpc(
              'add_coins',
              params: {
                'p_user_id': uid,
                'p_amount': amount,
                'p_source': source,
                'p_note': note,
              },
            )
            as int;

    // Refresh transaction list
    ref.invalidateSelf();

    return newBalance;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchTransactions);
  }
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, List<WalletTransaction>>(
      WalletNotifier.new,
    );
