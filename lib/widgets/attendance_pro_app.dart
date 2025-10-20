import 'package:attendancepro/bloc/app_cubit.dart';
import 'package:attendancepro/bloc/attendance_bloc.dart';
import 'package:attendancepro/bloc/auth_cubit.dart';
import 'package:attendancepro/repositories/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/navigation/app_router.dart';
import '../repositories/auth_repository.dart';

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
        ],
        child: Builder(
          builder: (context) {
            final appCubit = context.read<AppCubit>();
            final appRouter = AppRouter(appCubit: appCubit);

            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Attendance Pro',
              theme: ThemeData(
                primarySwatch: Colors.indigo,
                useMaterial3: false,
              ),
              routerConfig: appRouter.router,
            );
          },
        ),
      ),
    );
  }
}
