class AppStrings {
  AppStrings._();

  static const appTitle = 'AttendancePro';

  // Drawer user details
  static const drawerUserName = 'John Snow';
  static const drawerUserPhone = '+39-319-055-5550';

  // Drawer labels
  static const dashboardLabel = 'Dashboard';
  static const addNewWorkLabel = 'Add New Work';
  static const attendanceHistoryLabel = 'Attendance History';
  static const contractWorkLabel = 'Contract Work';
  static const changeLanguageLabel = 'Change Language';
  static const helpSupportLabel = 'Help & Support';
  static const logoutLabel = 'Logout';

  // Drawer snack bar messages
  static const dashboardTappedMessage = 'Dashboard tapped';
  static const addNewWorkTappedMessage = 'Add New Work tapped';
  static const attendanceHistoryTappedMessage = 'Attendance History tapped';
  static const contractWorkTappedMessage = 'Contract Work tapped';
  static const helpSupportTappedMessage = 'Help & Support tapped';

  // Change work modal
  static const workA = 'Work A';
  static const workB = 'Work B';
  static const switchedToWorkA = 'Switched to Work A';
  static const switchedToWorkB = 'Switched to Work B';

  // Language selection
  static const selectLanguageTitle = 'Select Language';
  static const english = 'English';
  static const spanish = 'Spanish';
  static const french = 'French';

  static String languageSelection(String language) => 'Language: ' + language;

  // Empty state messages
  static const noWorkAddedYet = 'No Work Added Yet';
  static const startTrackingAttendance =
      'Start tracking your attendance \nby adding your first work';
  static const addYourFirstWork = 'Add Your First Work';

  // Walkthrough text
  static const walkthroughTitleOne = 'Track Your Work Hours Easily';
  static const walkthroughDescOne =
      'Start and end your day with just one tap. Keep your hours accurate and organized.';
  static const walkthroughTitleTwo = 'Add Multiple Jobs, One App';
  static const walkthroughDescTwo =
      'Switch easily between multiple works and see your earnings instantly. One place for all your shifts.';
  static const walkthroughTitleThree = 'Your Language. Your Way.';
  static const walkthroughDescThree =
      'Available in English, Hindi, Punjabi, and Italian so you can manage attendance in your own comfort.';
  static const skip = 'Skip';

  // Splash
  static const splashTitle = 'AttendancePro';
}
