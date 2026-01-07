import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class ThemeRippleRequest extends Equatable {
  final int id;
  final Offset origin;
  final ThemeMode targetMode;
  const ThemeRippleRequest({
    required this.id,
    required this.origin,
    required this.targetMode,
  });
  @override
  List<Object?> get props => [id, origin, targetMode];
}
class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final ThemeRippleRequest? pendingRipple;
  const ThemeState({required this.themeMode, required this.pendingRipple});
  factory ThemeState.initial() {
    return const ThemeState(themeMode: ThemeMode.dark, pendingRipple: null);
  }
  ThemeState copyWith({
    ThemeMode? themeMode,
    ThemeRippleRequest? pendingRipple,
    bool clearPendingRipple = false,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      pendingRipple: clearPendingRipple
          ? null
          : (pendingRipple ?? this.pendingRipple),
    );
  }
  @override
  List<Object?> get props => [themeMode, pendingRipple];
}
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());
  int _nextRippleId = 1;
  void requestToggle({required Offset origin}) {
    if (state.pendingRipple != null) return;
    final targetMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    emit(
      state.copyWith(
        pendingRipple: ThemeRippleRequest(
          id: _nextRippleId++,
          origin: origin,
          targetMode: targetMode,
        ),
      ),
    );
  }
  void commitToggle(int rippleId) {
    final pending = state.pendingRipple;
    if (pending == null) return;
    if (pending.id != rippleId) return;
    emit(
      state.copyWith(themeMode: pending.targetMode, clearPendingRipple: true),
    );
  }
  void cancelRipple(int rippleId) {
    final pending = state.pendingRipple;
    if (pending == null) return;
    if (pending.id != rippleId) return;
    emit(state.copyWith(clearPendingRipple: true));
  }
}

