import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/session_manager.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({SessionManager? sessionManager})
      : _sessionManager = sessionManager ?? const SessionManager(),
        super(const Locale('en')) {
    _initialize();
  }

  final SessionManager _sessionManager;

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    emit(locale);
    await _sessionManager.savePreferredLanguage(locale.languageCode);
  }

  void _initialize() {
    unawaited(_loadSavedLocale());
  }

  Future<void> _loadSavedLocale() async {
    final savedLanguage = await _sessionManager.getPreferredLanguage();
    if (savedLanguage == null || savedLanguage.isEmpty) {
      return;
    }
    if (state.languageCode == savedLanguage) {
      return;
    }
    emit(Locale(savedLanguage));
  }
}
