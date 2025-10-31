import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../widgets/app_dialogs.dart';

Future<void> showLanguageSelectionDialog({
  required BuildContext context,
  required Map<String, String> options,
  required AppLocalizations localization,
}) async {
  final currentCode = context.read<LocaleCubit>().state.languageCode;
  final selectedCode = await showCreativeLanguageDialog(
    context,
    options: options,
    currentSelection: currentCode,
    localizations: localization,
  );

  if (selectedCode != null && options.containsKey(selectedCode)) {
    context.read<LocaleCubit>().setLocale(Locale(selectedCode));
    final updatedLocalization = AppLocalizations(Locale(selectedCode));
    final updatedNames = {
      'en': updatedLocalization.languageEnglish,
      'hi': updatedLocalization.languageHindi,
      'pa': updatedLocalization.languagePunjabi,
      'it': updatedLocalization.languageItalian,
    };
    final label =
        updatedNames[selectedCode] ?? options[selectedCode] ?? selectedCode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updatedLocalization.languageSelection(label))),
    );
  }
}
