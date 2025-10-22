import 'package:attendancepro/bloc/app_cubit.dart';
import 'package:attendancepro/bloc/attendance_bloc.dart';
import 'package:attendancepro/bloc/auth_cubit.dart';
import 'package:attendancepro/repositories/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_event.dart';
import '../core/navigation/app_router.dart';
import '../repositories/auth_repository.dart';
import '../repositories/work_repository.dart';
import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../bloc/work_bloc.dart';

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
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: localizations.appTitle,
                  theme: ThemeData(
                    primarySwatch: Colors.indigo,
                    useMaterial3: false,
                    fontFamily: 'Inter',
                  ),
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  routerConfig: appRouter.router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
