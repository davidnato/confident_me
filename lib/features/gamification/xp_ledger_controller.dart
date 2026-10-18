import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../models/xp_transaction.dart';

/// The XP history. Total XP is the sum of this list. There is deliberately no
/// way to remove or reduce an entry.
class XpLedgerController extends Notifier<List<XpTransaction>> {
  @override
  List<XpTransaction> build() => ref.read(xpStoreProvider).load();

  bool hasSource(String sourceKey) => state.any((t) => t.sourceKey == sourceKey);

  /// Adds the transaction unless one with the same source key already exists.
  /// Returns true only when XP was actually added.
  Future<bool> award(XpTransaction transaction) async {
    if (transaction.amount <= 0) return false;
    if (hasSource(transaction.sourceKey)) return false;
    // State first: a second call made while saving will see this entry.
    final next = [...state, transaction];
    state = next;
    await ref.read(xpStoreProvider).save(next);
    return true;
  }

  /// Clears the whole history. XP can never be reduced by normal use; this is
  /// only called by the explicit "reset progress" / "delete all data" actions.
  Future<void> clearAll() async {
    state = [];
    await ref.read(xpStoreProvider).clear();
  }
}

final xpLedgerProvider =
    NotifierProvider<XpLedgerController, List<XpTransaction>>(
  XpLedgerController.new,
);
