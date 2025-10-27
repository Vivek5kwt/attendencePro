import 'package:attendancepro/bloc/app_cubit.dart';
import 'package:attendancepro/bloc/attendance_bloc.dart';
import 'package:attendancepro/bloc/auth_cubit.dart';
import 'package:attendancepro/repositories/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_event.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_router.dart';
import '../repositories/auth_repository.dart';
import '../repositories/work_repository.dart';
import '../repositories/reports_repository.dart';
import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../bloc/work_bloc.dart';
import '../utils/responsive.dart';

class AttendanceProApp extends StatelessWidget {
  final AttendanceRepository repository;

  const AttendanceProApp({Key? key, required this.repository})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AttendanceRepository>.value(value: repository),
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
        RepositoryProvider<WorkRepository>(create: (_) => WorkRepository()),
        RepositoryProvider<ReportsRepository>(
          create: (_) => ReportsRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AttendanceBloc>(
            create: (context) => AttendanceBloc(repository: repository),
          ),
          BlocProvider<AppCubit>(create: (context) => AppCubit()),
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              repository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
          BlocProvider<WorkBloc>(
            create: (context) => WorkBloc(
              repository: context.read<WorkRepository>(),
            )..add(const WorkStarted()),
          ),
        ],
        child: Builder(
          builder: (context) {
            final appCubit = context.read<AppCubit>();
            final appRouter = AppRouter(appCubit: appCubit);

            return BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                final localizations = AppLocalizations(locale);
                final baseTheme = ThemeData(
                  primarySwatch: Colors.indigo,
                  useMaterial3: false,
                  fontFamily: AppString.fontFamily,
                );

                final textTheme = _applyFontFamily(baseTheme.textTheme);
                final primaryTextTheme =
                    _applyFontFamily(baseTheme.primaryTextTheme);

                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: AppString.appName,
                  theme: baseTheme.copyWith(
                    textTheme: textTheme,
                    primaryTextTheme: primaryTextTheme,
                    appBarTheme: baseTheme.appBarTheme.copyWith(
                      titleTextStyle: textTheme.titleLarge,
                      toolbarTextStyle: textTheme.bodyMedium,
                    ),
                  ),
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  routerConfig: appRouter.router,
                  builder: (context, child) {
                    final responsive = context.responsive;
                    final media = MediaQuery.of(context);
                    return MediaQuery(
                      data: media.copyWith(
                        textScaleFactor: responsive.textScaleFactor,
                      ),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

TextTheme _applyFontFamily(TextTheme base) {
  return base.copyWith(
    displayLarge:
        base.displayLarge?.copyWith(fontFamily: AppString.fontFamily),
    displayMedium:
        base.displayMedium?.copyWith(fontFamily: AppString.fontFamily),
    displaySmall:
        base.displaySmall?.copyWith(fontFamily: AppString.fontFamily),
    headlineLarge:
        base.headlineLarge?.copyWith(fontFamily: AppString.fontFamily),
    headlineMedium:
        base.headlineMedium?.copyWith(fontFamily: AppString.fontFamily),
    headlineSmall:
        base.headlineSmall?.copyWith(fontFamily: AppString.fontFamily),
    titleLarge: base.titleLarge?.copyWith(fontFamily: AppString.fontFamily),
    titleMedium:
        base.titleMedium?.copyWith(fontFamily: AppString.fontFamily),
    titleSmall: base.titleSmall?.copyWith(fontFamily: AppString.fontFamily),
    bodyLarge: base.bodyLarge?.copyWith(fontFamily: AppString.fontFamily),
    bodyMedium: base.bodyMedium?.copyWith(fontFamily: AppString.fontFamily),
    bodySmall: base.bodySmall?.copyWith(fontFamily: AppString.fontFamily),
    labelLarge: base.labelLarge?.copyWith(fontFamily: AppString.fontFamily),
    labelMedium: base.labelMedium?.copyWith(fontFamily: AppString.fontFamily),
    labelSmall: base.labelSmall?.copyWith(fontFamily: AppString.fontFamily),
  );
}
