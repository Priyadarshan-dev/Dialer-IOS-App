import '../../domain/entities/call_history_entity.dart';

class CallHistoryState {
  final List<CallHistoryEntity> calls;
  final List<CallHistoryEntity> pendingCalls;
  final bool isLoading;
  final String? error;

  CallHistoryState({
    this.calls = const [],
    this.pendingCalls = const [],
    this.isLoading = false,
    this.error,
  });

  CallHistoryState copyWith({
    List<CallHistoryEntity>? calls,
    List<CallHistoryEntity>? pendingCalls,
    bool? isLoading,
    String? error,
  }) {
    return CallHistoryState(
      calls: calls ?? this.calls,
      pendingCalls: pendingCalls ?? this.pendingCalls,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
