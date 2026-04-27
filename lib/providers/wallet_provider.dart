import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';

class WalletNotifier extends AsyncNotifier<List<WalletTransaction>> {
  @override
  Future<List<WalletTransaction>> build() => _fetchTransactions();

  // ── Fetch ─────────────────────────────────────────────
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

  // ── Add coins (earn or spend based on amount sign) ────
  // Positive amount = earn, negative amount = spend
  Future<int> addCoins({
    required int amount,
    required TxSource source, // uses enum — no raw strings
    String? note,
  }) async {
    final uid = currentUserId;
    if (uid == null) return 0;

    // Guard: zero amount makes no sense
    if (amount == 0) {
      throw ArgumentError('addCoins: amount cannot be zero');
    }

    try {
      final newBalance =
          await supabase.rpc(
                'add_coins',
                params: {
                  'p_user_id': uid,
                  'p_amount': amount,
                  'p_source': WalletTransaction.sourceToString(source),
                  'p_note': note,
                },
              )
              as int;

      // Refresh transaction list after successful RPC
      ref.invalidateSelf();

      return newBalance;
    } on Exception catch (e) {
      // Re-throw so callers (_deductCoins, _refundCoins) can handle
      throw Exception('addCoins failed: $e');
    }
  }

  // ── Convenience: earn ─────────────────────────────────
  Future<int> earn({
    required int amount,
    required TxSource source,
    String? note,
  }) {
    assert(amount > 0, 'earn: amount must be positive');
    return addCoins(amount: amount, source: source, note: note);
  }

  // ── Convenience: spend ────────────────────────────────
  Future<int> spend({
    required int amount, // pass positive — negated internally
    required TxSource source,
    String? note,
  }) {
    assert(amount > 0, 'spend: amount must be positive');
    return addCoins(amount: -amount, source: source, note: note);
  }

  // ── Refresh ───────────────────────────────────────────
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchTransactions);
  }
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, List<WalletTransaction>>(
      WalletNotifier.new,
    );
