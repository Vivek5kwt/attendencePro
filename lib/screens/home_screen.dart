import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/app_cubit.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../core/constants/app_assets.dart';
import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../models/student.dart';
import '../widgets/student_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(LoadStudents());
  }

  void _add() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      context.read<AttendanceBloc>().add(AddStudent(name));
      _nameController.clear();
    }
  }

  void _showChangeWorkMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(l.workA),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.switchedToWorkA)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.work),
                title: Text(l.workB),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.switchedToWorkB)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onDrawerOptionSelected(String option) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(option)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final languageOptions = {
      'en': l.languageEnglish,
      'hi': l.languageHindi,
      'pa': l.languagePunjabi,
      'it': l.languageItalian,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Colors.transparent,
        elevation: 0,
        // Use a Builder here so the IconButton has a context that is a descendant of the Scaffold.
        // Calling Scaffold.of(context).openDrawer() with the AppBar's own context won't find the Scaffold.
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.grey),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          l.appTitle,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.grey),
            onPressed: () {
              _showLanguageDialog(context, languageOptions, l);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.grey),
            onPressed: () {
              // Share action
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A84FF),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 20,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundImage: AssetImage(AppAssets.profilePlaceholder),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.drawerUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.drawerUserPhone,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _drawerItem(
                      icon: Icons.home_outlined,
                      label: l.dashboardLabel,
                      bgColor: const Color(0xFFE5F6FE),
                      iconColor: const Color(0xFF48A9FF),
                      onTap: () =>
                          _onDrawerOptionSelected(l.dashboardTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.work_outline,
                      label: l.addNewWorkLabel,
                      bgColor: const Color(0xFFE8F8F0),
                      iconColor: const Color(0xFF34C759),
                      onTap: () =>
                          _onDrawerOptionSelected(l.addNewWorkTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.access_time,
                      label: l.attendanceHistoryLabel,
                      bgColor: const Color(0xFFFFF2F2),
                      iconColor: const Color(0xFFFF3B30),
                      onTap: () =>
                          _onDrawerOptionSelected(l.attendanceHistoryTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.assignment_outlined,
                      label: l.contractWorkLabel,
                      bgColor: const Color(0xFFEDEBFF),
                      iconColor: const Color(0xFF5856D6),
                      onTap: () =>
                          _onDrawerOptionSelected(l.contractWorkTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.language,
                      label: l.changeLanguageLabel,
                      bgColor: const Color(0xFFF8E8FA),
                      iconColor: const Color(0xFFAF52DE),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _showLanguageDialog(context, languageOptions, l);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.support_agent_outlined,
                      label: l.helpSupportLabel,
                      bgColor: const Color(0xFFE5F6FE),
                      iconColor: const Color(0xFF007AFF),
                      onTap: () =>
                          _onDrawerOptionSelected(l.helpSupportTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.logout,
                      label: l.logoutLabel,
                      bgColor: const Color(0xFFE5F6FE),
                      iconColor: const Color(0xFF007AFF),
                      onTap: () {
                        Navigator.of(context).pop();

                        // Wait until the drawer animation finishes, then update AppCubit state
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context.read<AppCubit>().logout(); // ✅ This emits AppAuth
                        });
                      },
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Image.asset(AppAssets.homeBanner, width: 330),

          Expanded(
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                if (state is AttendanceLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AttendanceLoaded) {
                  // Fix: show placeholder when the list is empty; show the list when not empty.
                  if (!state.students.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(AppAssets.workPlaceholder, width: 100),
                            const SizedBox(height: 12),
                            Text(
                              l.noWorkAddedYet,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                l.startTrackingAttendance,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007BFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    context
                                        .read<AttendanceBloc>()
                                        .add(AddStudent(l.workA));
                                  },
                                  child: Text(
                                    l.addYourFirstWork,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: state.students.length,
                      itemBuilder: (context, index) {
                        final Student s = state.students[index];
                        return StudentTile(
                          student: s,
                          onToggle: () =>
                              context.read<AttendanceBloc>().add(ToggleAttendance(s.id)),
                        );
                      },
                    );
                  }
                } else if (state is AttendanceError) {
                  return Center(child: Text(state.message));
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(label, style: const TextStyle(fontSize: 16)),
          onTap: onTap,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            color: Color(0xFFE0E0E0),
            thickness: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguageDialog(BuildContext context,
      Map<String, String> options, AppLocalizations l) async {
    final selectedCode = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text(l.selectLanguageTitle),
          children: options.entries
              .map(
                (entry) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, entry.key),
                  child: Text(entry.value),
                ),
              )
              .toList(),
        );
      },
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
      final label = updatedNames[selectedCode] ?? options[selectedCode] ?? selectedCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updatedLocalization.languageSelection(label))),
      );
    }
  }
}
