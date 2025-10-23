import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('pa'),
    Locale('it'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
  <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'AttendancePro',
      'drawerUserName': 'John Snow',
      'drawerUserPhone': '+39-319-055-5550',
      'dashboardLabel': 'Dashboard',
      'homeBannerTitle': 'Track Attendance Smarter',
      'homeBannerSubtitle':
          'Manage your shifts, track hours, and stay organized every day.',
      'addNewWorkLabel': 'Add New Work',
      'attendanceHistoryLabel': 'Attendance History',
      'attendanceHistoryMonthLabel': 'Select month',
      'attendanceHistorySummaryTitle': 'This month so far',
      'attendanceHistoryWorkedDaysLabel': 'Worked Days',
      'attendanceHistoryLeaveDaysLabel': 'Leaves',
      'attendanceHistoryOvertimeLabel': 'Overtime',
      'attendanceHistoryTimelineTitle': 'Daily timeline',
      'attendanceHistoryNoEntriesLabel': 'No attendance records yet.',
      'attendanceHistoryHourlyEntry': 'Hourly',
      'attendanceHistoryContractEntry': 'Contract',
      'attendanceHistoryLeaveEntry': 'Leave',
      'attendanceHistoryPendingTitle': 'Pending attendance entries',
      'attendanceHistoryPendingDescription':
          'Complete previous days before marking today as present.',
      'attendanceHistoryResolveButton': 'Resolve now',
      'attendanceHistoryAllCaughtUp': 'You are all caught up!',
      'attendanceHistoryAllCaughtUpDescription':
          'All past attendance entries are completed.',
      'attendanceHistoryAllWorks': 'All Works',
      'attendanceHistoryOvertimeEntryLabel': 'Overtime',
      'attendanceHistoryLoggedHoursLabel': 'Logged Hours',
      'attendanceHistoryReasonLabel': 'Reason',
      'contractWorkLabel': 'Contract Work',
      'contractWorkActiveRatesTitle': 'Active contract rates',
      'contractWorkDefaultTypesTitle': 'Available contract types',
      'contractWorkRecentEntriesTitle': 'Recent contract entries',
      'contractWorkRatesNote': 'Rates apply to future entries only.',
      'contractWorkAddTypeTitle': 'Add contract type',
      'contractWorkEditTypeTitle': 'Update contract type',
      'contractWorkNameLabel': 'Contract name',
      'contractWorkRateLabel': 'Rate per unit',
      'contractWorkUnitLabel': 'Unit label',
      'contractWorkUnitsLabel': 'Units',
      'contractWorkRateRequiredMessage': 'Please enter a valid rate.',
      'contractWorkNameRequiredMessage': 'Please enter a contract name.',
      'contractWorkTypeSavedMessage': 'Contract type saved.',
      'contractWorkNoEntriesLabel': 'No contract entries recorded yet.',
      'contractWorkLastUpdatedLabel': 'Last updated',
      'contractWorkEditRateButton': 'Update rate',
      'contractWorkActiveTypesLabel': 'Active types',
      'contractWorkTotalUnitsLabel': 'Total units',
      'contractWorkTotalSalaryLabel': 'Total salary',
      'contractWorkDefaultTag': 'Default',
      'contractWorkUnitFallback': 'per unit',
      'changeLanguageLabel': 'Change Language',
      'helpSupportLabel': 'Help & Support',
      'helpSupportTitle': 'How can we help you today?',
      'helpSupportSubtitle': 'Find quick answers or reach our support team.',
      'helpSupportQuickActionsTitle': 'Quick assistance',
      'helpSupportFaqsLabel': 'FAQs',
      'helpSupportFaqsSubtitle': 'Browse common questions',
      'helpSupportGuidesLabel': 'Getting Started',
      'helpSupportGuidesSubtitle': 'Step-by-step tutorials',
      'helpSupportReportIssueLabel': 'Report an Issue',
      'helpSupportReportIssueSubtitle': 'Let us know what went wrong',
      'helpSupportContactTitle': 'Contact options',
      'helpSupportEmailLabel': 'Email Us',
      'helpSupportEmailValue': 'support@attendancepro.app',
      'helpSupportEmailButton': 'Send email',
      'helpSupportPhoneLabel': 'Call Us',
      'helpSupportPhoneValue': '+1 (800) 555-1234',
      'helpSupportCallButton': 'Call now',
      'helpSupportChatLabel': 'Live Chat',
      'helpSupportChatSubtitle': 'Available Mon-Fri, 9am - 6pm',
      'helpSupportChatButton': 'Start chat',
      'helpSupportHoursLabel': 'Support hours',
      'helpSupportHoursValue': 'Mon - Fri, 9 AM - 6 PM (GMT)',
      'helpSupportResponseTimeLabel': 'Average response time',
      'helpSupportResponseTimeValue': 'Under 24 hours',
      'helpSupportAdditionalInfoTitle': 'Additional information',
      'helpSupportLastUpdatedLabel': 'Last updated',
      'helpSupportLastUpdatedValue': 'October 2025',
      'helpSupportPolicyLabel': 'Support policy',
      'helpSupportPolicyValue': 'We follow the AttendancePro customer care standards.',
      'helpSupportLaunchFailed': 'Unable to open the requested application.',
      'helpSupportComingSoon': 'This section will be available soon.',
      'logoutLabel': 'Logout',
      'reportsSummaryLabel': 'Reports & Summary',
      'reportsSummaryMonth': 'October 2025',
      'reportsCombinedSalaryTitle': 'Total Combined Salary',
      'reportsHoursWorkedSuffix': 'hours worked',
      'reportsUnitsCompletedSuffix': 'units completed',
      'reportsHourlyWorkSummaryTitle': 'Hourly Work Summary',
      'reportsWorkingDaysLabel': 'Working Days',
      'reportsAverageHoursPerDayLabel': 'Average Hours/Day',
      'reportsLastPayoutLabel': 'Last Payout',
      'reportsTotalUnitsLabel': 'Total Units',
      'reportsContractSalaryLabel': 'Contract Salary',
      'reportsBreakdownSuffix': 'Breakdown',
      'reportsGrandTotalLabel': 'Grand Total',
      'logoutConfirmationTitle': 'Confirm Logout',
      'logoutConfirmationMessage': 'Are you sure you want to logout?',
      'logoutConfirmButton': 'Logout',
      'logoutCancelButton': 'Cancel',
      'logoutSuccessMessage': 'User logged out successfully.',
      'logoutFailedMessage': 'Unable to log out. Please try again.',
      'shareAppTitle': 'Share App',
      'shareViaWhatsApp': 'Share Via WhatsApp',
      'copyLink': 'Copy Link',
      'shareCancelButton': 'Cancel',
      'shareLinkCopied': 'Link copied to clipboard.',
      'shareWhatsappUnavailable': 'WhatsApp is not installed on this device.',
      'shareWhatsappFailed': 'Unable to open WhatsApp.',
      'shareMessage': 'Check out AttendancePro: {link}',
      'dashboardTappedMessage': 'Dashboard tapped',
      'addNewWorkTappedMessage': 'Add New Work tapped',
      'attendanceHistoryTappedMessage': 'Attendance History tapped',
      'contractWorkTappedMessage': 'Contract Work tapped',
      'helpSupportTappedMessage': 'Help & Support tapped',
      'workA': 'Work A',
      'workB': 'Work B',
      'switchedToWorkA': 'Switched to Work A',
      'switchedToWorkB': 'Switched to Work B',
      'selectLanguageTitle': 'Select Language',
      'languageEnglish': 'English',
      'languageHindi': 'Hindi',
      'languagePunjabi': 'Punjabi',
      'languageItalian': 'Italian',
      'languageSelection': 'Language: {language}',
      'noWorkAddedYet': 'No Work Added Yet',
      'startTrackingAttendance':
      'Start tracking your attendance \nby adding your first work',
      'addYourFirstWork': 'Add Your First Work',
      'hourlyWorkLabel': 'Hourly Work',
      'changeWorkButton': 'Change Work',
      'todaysAttendanceTitle': "Today's Attendance",
      'startTimeLabel': 'Start Time',
      'endTimeLabel': 'End Time',
      'breakLabel': 'Break',
      'submitButton': 'Submit',
      'markAsWorkOffButton': 'Mark as Work Off',
      'contractWorkSummaryTitle': 'Contract Work Summary',
      'summaryLabel': 'Summary',
      'totalHoursLabel': 'Total Hours',
      'totalSalaryLabel': 'Total Salary',
      'activeWorkLabel': 'Active',
      'setActiveWorkButton': 'Set Active',
      'settingActiveWorkLabel': 'Activating...',
      'workActivatedMessage': 'Work set as active successfully.',
      'workNameLabel': 'Work Name',
      'workNameHint': 'Ex Restaurant, Warehouse',
      'hourlySalaryLabel': 'Hourly Salary',
      'hourlySalaryHint': '\$ 0.00',
      'contractWorkHeader': 'Contract Work (if have)',
      'addContractWorkButton': 'Add Contract Work',
      'contractWorkDescription': 'Piece-rate work: Watermelon, Carrot, Ravanello, Orange, etc.',
      'cancelButton': 'Cancel',
      'saveButtonLabel': 'Save',
      'saveWorkButton': 'Save Work',
      'workNameRequiredMessage': 'Please enter a work name.',
      'workAddedMessage': 'Work added successfully.',
      'workUpdatedMessage': 'Work updated successfully.',
      'invalidHourlyRateMessage': 'Please enter a valid hourly rate.',
      'editWorkTitle': 'Edit Work',
      'editWorkSubtitle': 'Update your work details',
      'updateWorkButton': 'Update Work',
      'editWorkTooltip': 'Edit work',
      'workDeleteConfirmationTitle': 'Delete Work',
      'workDeleteConfirmationMessage':
          'Are you sure you want to delete this work?',
      'workDeleteConfirmButton': 'Delete',
      'workDeleteCancelButton': 'Cancel',
      'workDeleteSuccessMessage': 'Work deleted successfully.',
      'workDeleteFailedMessage': 'Failed to delete work. Please try again.',
      'workSaveFailedMessage': 'Failed to save work. Please try again.',
      'worksLoadFailedTitle': 'Unable to load works',
      'worksLoadFailedMessage':
          'We couldn\'t fetch your works. Pull to refresh or try again.',
      'retryButtonLabel': 'Retry',
      'notAvailableLabel': 'Not available',
      'authenticationRequiredMessage': 'Your session has expired. Please log in again.',
      'walkthroughTitleOne': 'Track Your Work Hours Easily',
      'walkthroughDescOne':
      'Start and end your day with just one tap. Keep your hours accurate and organized.',
      'walkthroughTitleTwo': 'Add Multiple Jobs, One App',
      'walkthroughDescTwo':
      'Switch easily between multiple works and see your earnings instantly. One place for all your shifts.',
      'walkthroughTitleThree': 'Your Language. Your Way.',
      'walkthroughDescThree':
      'Available in English, Hindi, Punjabi, and Italian so you can manage attendance in your own comfort.',
      'skip': 'Skip',
      'splashTitle': 'AttendancePro',
      'loginTitle': 'Login',
      'emailLabel': 'Email',
      'emailHint': 'you@example.com',
      'passwordLabel': 'Password',
      'passwordHint': '********',
      'loginButton': 'Login',
      'forgotPassword': 'Forgot Your Password?',
      'signupPromptPrefix': 'Don’t Have an Account? ',
      'signupPromptAction': 'Sign Up',
      'changeLanguage': 'Change Language',
      'snackEnterEmail': 'Please enter your email.',
      'snackEnterValidEmail': 'Please enter a valid email address.',
      'snackEnterPassword': 'Please enter your password.',
      'snackLoginSuccess': 'Logged in successfully',
      'snackResetEmail': 'Please enter your email to reset.',
      'snackForgotInvalidEmail': 'Please enter a valid email address.',
      'signupTitle': 'Sign Up',
      'fullNameLabel': 'Full Name',
      'nameRequired': 'Name required',
      'emailAddressLabel': 'Email Address',
      'emailRequired': 'Email required',
      'emailInvalid': 'Invalid email',
      'passwordRequired': 'Password required',
      'passwordMinLength': 'Min 6 characters',
      'confirmPasswordLabel': 'Confirm Password',
      'confirmPasswordRequired': 'Please confirm password',
      'confirmPasswordMismatch': 'Passwords do not match',
      'termsAgreement': 'Please agree to the terms to continue.',
      'userAgreementTitle': 'User Agreement & Privacy Policy',
      'userAgreementContent':
      'This is a placeholder for the User Agreement and Privacy Policy. In a real app you would show the full text or open a webview.',
      'close': 'Close',
      'agreeTextPrefix': 'I Have Read and Agree to ',
      'userAgreement': 'User Agreement',
      'and': ' and ',
      'privacyPolicy': 'Privacy Policy',
      'signupButton': 'Sign Up',
      'alreadyAccountPrompt': 'Already Have an Account? ',
      'loginAction': 'Login',
      'createPasswordTitle': 'Create a New Password',
      'newPasswordLabel': 'New Password',
      'newPasswordHint': 'Enter new password',
      'confirmPasswordHint': 'Confirm password',
      'passwordMinEight': 'Password must be at least 8 characters.',
      'passwordsDoNotMatch': 'Passwords do not match.',
      'resetPasswordButton': 'Reset Password',
      'verifyNumberTitle': 'Verify Your Number',
      'verifyCodeDescription': 'We’ve sent a 6-digit code to your email.',
      'enterCodeLabel': 'Enter Code',
      'verifyOtpButton': 'Verify OTP',
      'resendCountdown': 'Didn’t receive code? Resend in 00:{seconds}',
      'resendCode': 'Resend Code',
      'operationSuccessful': 'Operation successful',
    },
    'hi': {
      'appTitle': 'अटेंडेंस प्रो',
      'drawerUserName': 'जॉन स्नो',
      'drawerUserPhone': '+39-319-055-5550',
      'dashboardLabel': 'डैशबोर्ड',
      'homeBannerTitle': 'उपस्थिति को स्मार्ट तरीके से ट्रैक करें',
      'homeBannerSubtitle':
          'अपनी शिफ्ट्स प्रबंधित करें, घंटे ट्रैक करें और हर दिन व्यवस्थित रहें।',
      'addNewWorkLabel': 'नया कार्य जोड़ें',
      'attendanceHistoryLabel': 'उपस्थिति इतिहास',
      'attendanceHistoryMonthLabel': 'माह चुनें',
      'attendanceHistorySummaryTitle': 'इस महीने अब तक',
      'attendanceHistoryWorkedDaysLabel': 'काम किए गए दिन',
      'attendanceHistoryLeaveDaysLabel': 'छुट्टियाँ',
      'attendanceHistoryOvertimeLabel': 'अतिरिक्त समय',
      'attendanceHistoryTimelineTitle': 'दैनिक टाइमलाइन',
      'attendanceHistoryNoEntriesLabel': 'अभी कोई उपस्थिति रिकॉर्ड नहीं है।',
      'attendanceHistoryHourlyEntry': 'घंटेवार',
      'attendanceHistoryContractEntry': 'कॉन्ट्रैक्ट',
      'attendanceHistoryLeaveEntry': 'छुट्टी',
      'attendanceHistoryPendingTitle': 'लंबित उपस्थिति प्रविष्टियाँ',
      'attendanceHistoryPendingDescription':
          'आज उपस्थित चिह्नित करने से पहले पिछले दिनों की प्रविष्टियाँ पूरी करें।',
      'attendanceHistoryResolveButton': 'अभी पूरा करें',
      'attendanceHistoryAllCaughtUp': 'आप पूरी तरह अपडेट हैं!',
      'attendanceHistoryAllCaughtUpDescription':
          'पिछली सभी उपस्थिति प्रविष्टियाँ पूरी हो चुकी हैं।',
      'attendanceHistoryAllWorks': 'सभी कार्य',
      'attendanceHistoryOvertimeEntryLabel': 'अतिरिक्त समय',
      'attendanceHistoryLoggedHoursLabel': 'लॉग किए गए घंटे',
      'attendanceHistoryReasonLabel': 'कारण',
      'contractWorkLabel': 'ठेका कार्य',
      'contractWorkActiveRatesTitle': 'सक्रिय कॉन्ट्रैक्ट दरें',
      'contractWorkDefaultTypesTitle': 'उपलब्ध कॉन्ट्रैक्ट प्रकार',
      'contractWorkRecentEntriesTitle': 'हाल की कॉन्ट्रैक्ट प्रविष्टियाँ',
      'contractWorkRatesNote': 'दरें केवल भविष्य की प्रविष्टियों पर लागू होंगी।',
      'contractWorkAddTypeTitle': 'कॉन्ट्रैक्ट प्रकार जोड़ें',
      'contractWorkEditTypeTitle': 'कॉन्ट्रैक्ट प्रकार अपडेट करें',
      'contractWorkNameLabel': 'कॉन्ट्रैक्ट का नाम',
      'contractWorkRateLabel': 'प्रति इकाई दर',
      'contractWorkUnitLabel': 'इकाई लेबल',
      'contractWorkUnitsLabel': 'इकाइयाँ',
      'contractWorkRateRequiredMessage': 'कृपया मान्य दर दर्ज करें।',
      'contractWorkNameRequiredMessage': 'कृपया कॉन्ट्रैक्ट का नाम दर्ज करें।',
      'contractWorkTypeSavedMessage': 'कॉन्ट्रैक्ट प्रकार सहेजा गया।',
      'contractWorkNoEntriesLabel': 'कोई कॉन्ट्रैक्ट प्रविष्टि दर्ज नहीं है।',
      'contractWorkLastUpdatedLabel': 'आखिरी अपडेट',
      'contractWorkEditRateButton': 'दर अपडेट करें',
      'contractWorkActiveTypesLabel': 'सक्रिय प्रकार',
      'contractWorkTotalUnitsLabel': 'कुल इकाइयाँ',
      'contractWorkTotalSalaryLabel': 'कुल वेतन',
      'contractWorkDefaultTag': 'डिफ़ॉल्ट',
      'contractWorkUnitFallback': 'प्रति इकाई',
      'changeLanguageLabel': 'भाषा बदलें',
      'helpSupportLabel': 'मदद और समर्थन',
      'helpSupportTitle': 'हम आपकी कैसे मदद कर सकते हैं?',
      'helpSupportSubtitle': 'त्वरित उत्तर पाएं या हमारी सपोर्ट टीम से संपर्क करें।',
      'helpSupportQuickActionsTitle': 'त्वरित सहायता',
      'helpSupportFaqsLabel': 'सामान्य प्रश्न',
      'helpSupportFaqsSubtitle': 'अक्सर पूछे गए प्रश्न देखें',
      'helpSupportGuidesLabel': 'शुरू कैसे करें',
      'helpSupportGuidesSubtitle': 'क्रमबद्ध मार्गदर्शिकाएँ',
      'helpSupportReportIssueLabel': 'समस्या रिपोर्ट करें',
      'helpSupportReportIssueSubtitle': 'हमें बताएं क्या गलत हुआ',
      'helpSupportContactTitle': 'संपर्क विकल्प',
      'helpSupportEmailLabel': 'हमें ईमेल करें',
      'helpSupportEmailValue': 'support@attendancepro.app',
      'helpSupportEmailButton': 'ईमेल भेजें',
      'helpSupportPhoneLabel': 'हमें कॉल करें',
      'helpSupportPhoneValue': '+1 (800) 555-1234',
      'helpSupportCallButton': 'अभी कॉल करें',
      'helpSupportChatLabel': 'लाइव चैट',
      'helpSupportChatSubtitle': 'सोम-शुक्र, सुबह 9 से शाम 6 तक उपलब्ध',
      'helpSupportChatButton': 'चैट प्रारंभ करें',
      'helpSupportHoursLabel': 'सपोर्ट समय',
      'helpSupportHoursValue': 'सोम - शुक्र, सुबह 9 से शाम 6 (GMT)',
      'helpSupportResponseTimeLabel': 'औसत प्रतिक्रिया समय',
      'helpSupportResponseTimeValue': '24 घंटे से कम',
      'helpSupportAdditionalInfoTitle': 'अतिरिक्त जानकारी',
      'helpSupportLastUpdatedLabel': 'अंतिम अपडेट',
      'helpSupportLastUpdatedValue': 'अक्टूबर 2025',
      'helpSupportPolicyLabel': 'सपोर्ट नीति',
      'helpSupportPolicyValue': 'हम AttendancePro ग्राहक सेवा मानकों का पालन करते हैं।',
      'helpSupportLaunchFailed': 'अनुरोधित ऐप्लिकेशन नहीं खोल सके।',
      'helpSupportComingSoon': 'यह अनुभाग जल्द ही उपलब्ध होगा।',
      'logoutLabel': 'लॉग आउट',
      'reportsSummaryLabel': 'Reports & Summary',
      'reportsSummaryMonth': 'October 2025',
      'reportsCombinedSalaryTitle': 'Total Combined Salary',
      'reportsHoursWorkedSuffix': 'hours worked',
      'reportsUnitsCompletedSuffix': 'units completed',
      'reportsHourlyWorkSummaryTitle': 'Hourly Work Summary',
      'reportsWorkingDaysLabel': 'Working Days',
      'reportsAverageHoursPerDayLabel': 'Average Hours/Day',
      'reportsLastPayoutLabel': 'Last Payout',
      'reportsTotalUnitsLabel': 'Total Units',
      'reportsContractSalaryLabel': 'Contract Salary',
      'reportsBreakdownSuffix': 'Breakdown',
      'reportsGrandTotalLabel': 'Grand Total',
      'logoutConfirmationTitle': 'लॉग आउट की पुष्टि करें',
      'logoutConfirmationMessage': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',
      'logoutConfirmButton': 'लॉग आउट',
      'logoutCancelButton': 'रद्द करें',
      'logoutSuccessMessage': 'उपयोगकर्ता सफलतापूर्वक लॉग आउट हुआ।',
      'logoutFailedMessage': 'लॉग आउट नहीं हो सका। कृपया पुनः प्रयास करें।',
      'shareAppTitle': 'ऐप साझा करें',
      'shareViaWhatsApp': 'व्हाट्सऐप से साझा करें',
      'copyLink': 'लिंक कॉपी करें',
      'shareCancelButton': 'रद्द करें',
      'shareLinkCopied': 'लिंक कॉपी हो गया है।',
      'shareWhatsappUnavailable': 'इस डिवाइस पर WhatsApp इंस्टॉल नहीं है।',
      'shareWhatsappFailed': 'WhatsApp नहीं खोल सके।',
      'shareMessage': 'AttendancePro देखें: {link}',
      'dashboardTappedMessage': 'डैशबोर्ड चुना गया',
      'addNewWorkTappedMessage': 'नया कार्य चुना गया',
      'attendanceHistoryTappedMessage': 'उपस्थिति इतिहास चुना गया',
      'contractWorkTappedMessage': 'ठेका कार्य चुना गया',
      'helpSupportTappedMessage': 'मदद और समर्थन चुना गया',
      'workA': 'कार्य A',
      'workB': 'कार्य B',
      'switchedToWorkA': 'कार्य A पर स्विच किया गया',
      'switchedToWorkB': 'कार्य B पर स्विच किया गया',
      'selectLanguageTitle': 'भाषा चुनें',
      'languageEnglish': 'अंग्रेज़ी',
      'languageHindi': 'हिंदी',
      'languagePunjabi': 'पंजाबी',
      'languageItalian': 'इतालवी',
      'languageSelection': 'भाषा: {language}',
      'noWorkAddedYet': 'अभी तक कोई कार्य नहीं जोड़ा गया',
      'startTrackingAttendance':
      'अपनी पहली नौकरी जोड़कर\nअपनी उपस्थिति ट्रैक करना शुरू करें',
      'addYourFirstWork': 'अपना पहला कार्य जोड़ें',
      'hourlyWorkLabel': 'घंटे का कार्य',
      'changeWorkButton': 'कार्य बदलें',
      'todaysAttendanceTitle': 'आज की उपस्थिति',
      'startTimeLabel': 'आरंभ समय',
      'endTimeLabel': 'समाप्ति समय',
      'breakLabel': 'विराम',
      'submitButton': 'जमा करें',
      'markAsWorkOffButton': 'कार्य अवकाश चिह्नित करें',
      'contractWorkSummaryTitle': 'ठेका कार्य सारांश',
      'summaryLabel': 'सारांश',
      'totalHoursLabel': 'कुल घंटे',
      'totalSalaryLabel': 'कुल वेतन',
      'activeWorkLabel': 'सक्रिय',
      'setActiveWorkButton': 'सक्रिय करें',
      'settingActiveWorkLabel': 'सक्रिय किया जा रहा है...',
      'workActivatedMessage': 'कार्य सफलतापूर्वक सक्रिय किया गया।',
      'workNameLabel': 'कार्य का नाम',
      'workNameHint': 'उदाहरण: रेस्टोरेंट, गोदाम',
      'hourlySalaryLabel': 'घंटे की मजदूरी',
      'hourlySalaryHint': '₹ 0.00',
      'contractWorkHeader': 'ठेका कार्य (यदि हो)',
      'addContractWorkButton': 'ठेका कार्य जोड़ें',
      'contractWorkDescription': 'पीस-रेट कार्य: तरबूज, गाजर, रावनेलो, संतरा आदि।',
      'cancelButton': 'रद्द करें',
      'saveButtonLabel': 'सहेजें',
      'saveWorkButton': 'कार्य सहेजें',
      'workNameRequiredMessage': 'कृपया कार्य का नाम दर्ज करें।',
      'workAddedMessage': 'कार्य सफलतापूर्वक जोड़ा गया।',
      'workUpdatedMessage': 'कार्य सफलतापूर्वक अपडेट किया गया।',
      'invalidHourlyRateMessage': 'कृपया मान्य प्रति घंटा दर दर्ज करें।',
      'editWorkTitle': 'कार्य संपादित करें',
      'editWorkSubtitle': 'अपने कार्य का विवरण अपडेट करें',
      'updateWorkButton': 'कार्य अपडेट करें',
      'editWorkTooltip': 'कार्य संपादित करें',
      'workDeleteConfirmationTitle': 'काम हटाएं',
      'workDeleteConfirmationMessage':
          'क्या आप वाकई इस काम को हटाना चाहते हैं?',
      'workDeleteConfirmButton': 'हटाएं',
      'workDeleteCancelButton': 'रद्द करें',
      'workDeleteSuccessMessage': 'काम सफलतापूर्वक हटाया गया।',
      'workDeleteFailedMessage': 'काम हटाने में विफल। कृपया पुनः प्रयास करें।',
      'workSaveFailedMessage': 'कार्य सहेजा नहीं जा सका। कृपया पुनः प्रयास करें।',
      'worksLoadFailedTitle': 'कार्य लोड नहीं हो सका',
      'worksLoadFailedMessage':
          'हम आपके कार्य लोड नहीं कर पाए। कृपया नीचे खींचकर रिफ्रेश करें या पुनः प्रयास करें।',
      'retryButtonLabel': 'पुनः प्रयास करें',
      'notAvailableLabel': 'उपलब्ध नहीं',
      'authenticationRequiredMessage': 'आपका सत्र समाप्त हो गया है। कृपया पुनः लॉग इन करें।',
      'walkthroughTitleOne': 'अपने कार्य घंटों को आसानी से ट्रैक करें',
      'walkthroughDescOne':
      'सिर्फ एक टैप में अपना दिन शुरू और खत्म करें। अपने घंटे सटीक और व्यवस्थित रखें।',
      'walkthroughTitleTwo': 'कई नौकरियाँ, एक ऐप',
      'walkthroughDescTwo':
      'आसानी से कई कामों के बीच स्विच करें और अपनी कमाई तुरंत देखें।',
      'walkthroughTitleThree': 'आपकी भाषा, आपका तरीका',
      'walkthroughDescThree':
      'अंग्रेज़ी, हिंदी, पंजाबी और इतालवी में उपलब्ध ताकि आप अपनी सुविधा से उपस्थिति प्रबंधित कर सकें।',
      'skip': 'स्किप करें',
      'splashTitle': 'अटेंडेंस प्रो',
      'loginTitle': 'लॉगिन',
      'emailLabel': 'ईमेल',
      'emailHint': 'you@example.com',
      'passwordLabel': 'पासवर्ड',
      'passwordHint': '********',
      'loginButton': 'लॉगिन',
      'forgotPassword': 'क्या आपने पासवर्ड भूल गए?',
      'signupPromptPrefix': 'खाता नहीं है? ',
      'signupPromptAction': 'साइन अप',
      'changeLanguage': 'भाषा बदलें',
      'snackEnterEmail': 'कृपया अपना ईमेल दर्ज करें।',
      'snackEnterValidEmail': 'कृपया मान्य ईमेल पता दर्ज करें।',
      'snackEnterPassword': 'कृपया अपना पासवर्ड दर्ज करें।',
      'snackLoginSuccess': 'सफलतापूर्वक लॉगिन किया गया',
      'snackResetEmail': 'रीसेट करने के लिए कृपया अपना ईमेल दर्ज करें।',
      'snackForgotInvalidEmail': 'कृपया मान्य ईमेल पता दर्ज करें।',
      'signupTitle': 'साइन अप',
      'fullNameLabel': 'पूरा नाम',
      'nameRequired': 'नाम आवश्यक है',
      'emailAddressLabel': 'ईमेल पता',
      'emailRequired': 'ईमेल आवश्यक है',
      'emailInvalid': 'अमान्य ईमेल',
      'passwordRequired': 'पासवर्ड आवश्यक है',
      'passwordMinLength': 'कम से कम 6 अक्षर',
      'confirmPasswordLabel': 'पासवर्ड की पुष्टि करें',
      'confirmPasswordRequired': 'कृपया पासवर्ड की पुष्टि करें',
      'confirmPasswordMismatch': 'पासवर्ड मेल नहीं खाते',
      'termsAgreement': 'जारी रखने के लिए कृपया शर्तों से सहमत हों।',
      'userAgreementTitle': 'उपयोगकर्ता समझौता और गोपनीयता नीति',
      'userAgreementContent':
      'यह उपयोगकर्ता समझौता और गोपनीयता नीति के लिए प्लेसहोल्डर है। वास्तविक ऐप में आप पूरा पाठ दिखाएंगे या वेबव्यू खोलेंगे।',
      'close': 'बंद करें',
      'agreeTextPrefix': 'मैंने पढ़ा है और सहमत हूँ ',
      'userAgreement': 'उपयोगकर्ता समझौता',
      'and': ' और ',
      'privacyPolicy': 'गोपनीयता नीति',
      'signupButton': 'साइन अप',
      'alreadyAccountPrompt': 'पहले से खाता है? ',
      'loginAction': 'लॉगिन',
      'createPasswordTitle': 'नया पासवर्ड बनाएं',
      'newPasswordLabel': 'नया पासवर्ड',
      'newPasswordHint': 'नया पासवर्ड दर्ज करें',
      'confirmPasswordHint': 'पासवर्ड की पुष्टि करें',
      'passwordMinEight': 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए।',
      'passwordsDoNotMatch': 'पासवर्ड मेल नहीं खाते।',
      'resetPasswordButton': 'पासवर्ड रीसेट करें',
      'verifyNumberTitle': 'अपना नंबर सत्यापित करें',
      'verifyCodeDescription': 'हमने आपके ईमेल पर 6 अंकों का कोड भेजा है।',
      'enterCodeLabel': 'कोड दर्ज करें',
      'verifyOtpButton': 'ओटीपी सत्यापित करें',
      'resendCountdown': 'कोड नहीं मिला? 00:{seconds} में फिर से भेजें',
      'resendCode': 'कोड पुनः भेजें',
      'operationSuccessful': 'कार्रवाई सफल रही',
    },
    'pa': {
      'appTitle': 'ਅਟੈਂਡੈਂਸ ਪ੍ਰੋ',
      'drawerUserName': 'ਜੌਨ ਸਨੋ',
      'drawerUserPhone': '+39-319-055-5550',
      'dashboardLabel': 'ਡੈਸ਼ਬੋਰਡ',
      'homeBannerTitle': 'ਹਾਜ਼ਰੀ ਨੂੰ ਹੋਰ ਸਮਝਦਾਰੀ ਨਾਲ ਟਰੈਕ ਕਰੋ',
      'homeBannerSubtitle':
          'ਆਪਣੀਆਂ ਸ਼ਿਫਟਾਂ ਸੰਭਾਲੋ, ਘੰਟੇ ਟਰੈਕ ਕਰੋ ਅਤੇ ਹਰ ਰੋਜ਼ ਸੁਵਿਧਾਜਨਕ ਰਹੋ।',
      'addNewWorkLabel': 'ਨਵਾਂ ਕੰਮ ਜੋੜੋ',
      'attendanceHistoryLabel': 'ਹਾਜ਼ਰੀ ਇਤਿਹਾਸ',
      'attendanceHistoryMonthLabel': 'ਮਹੀਨਾ ਚੁਣੋ',
      'attendanceHistorySummaryTitle': 'ਇਸ ਮਹੀਨੇ ਤੱਕ',
      'attendanceHistoryWorkedDaysLabel': 'ਕੰਮ ਵਾਲੇ ਦਿਨ',
      'attendanceHistoryLeaveDaysLabel': 'ਛੁੱਟੀਆਂ',
      'attendanceHistoryOvertimeLabel': 'ਵਾਧੂ ਸਮਾਂ',
      'attendanceHistoryTimelineTitle': 'ਰੋਜ਼ਾਨਾ ਟਾਈਮਲਾਈਨ',
      'attendanceHistoryNoEntriesLabel': 'ਹਾਲੇ ਕੋਈ ਹਾਜ਼ਰੀ ਰਿਕਾਰਡ ਨਹੀਂ ਹੈ।',
      'attendanceHistoryHourlyEntry': 'ਘੰਟਾ ਅਧਾਰਿਤ',
      'attendanceHistoryContractEntry': 'ਕਾਂਟ੍ਰੈਕਟ',
      'attendanceHistoryLeaveEntry': 'ਛੁੱਟੀ',
      'attendanceHistoryPendingTitle': 'ਬਕਾਇਆ ਹਾਜ਼ਰੀ ਐਂਟਰੀਆਂ',
      'attendanceHistoryPendingDescription':
          'ਅੱਜ ਹਾਜ਼ਰ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਪਿਛਲੇ ਦਿਨਾਂ ਦੀਆਂ ਐਂਟਰੀਆਂ ਪੂਰੀ ਕਰੋ।',
      'attendanceHistoryResolveButton': 'ਹੁਣ ਪੂਰਾ ਕਰੋ',
      'attendanceHistoryAllCaughtUp': 'ਤੁਸੀਂ ਪੂਰੀ ਤਰ੍ਹਾਂ ਅਪਡੇਟ ਹੋ!',
      'attendanceHistoryAllCaughtUpDescription':
          'ਪਿਛਲੀਆਂ ਸਾਰੀਆਂ ਹਾਜ਼ਰੀ ਐਂਟਰੀਆਂ ਪੂਰੀਆਂ ਹਨ।',
      'attendanceHistoryAllWorks': 'ਸਾਰੇ ਕੰਮ',
      'attendanceHistoryOvertimeEntryLabel': 'ਵਾਧੂ ਸਮਾਂ',
      'attendanceHistoryLoggedHoursLabel': 'ਲਾਗ ਕੀਤੇ ਘੰਟੇ',
      'attendanceHistoryReasonLabel': 'ਕਾਰਨ',
      'contractWorkLabel': 'ਕਾਂਟ੍ਰੈਕਟ ਕੰਮ',
      'contractWorkActiveRatesTitle': 'ਸਰਗਰਮ ਕਾਂਟ੍ਰੈਕਟ ਦਰਾਂ',
      'contractWorkDefaultTypesTitle': 'ਉਪਲਬਧ ਕਾਂਟ੍ਰੈਕਟ ਕਿਸਮਾਂ',
      'contractWorkRecentEntriesTitle': 'ਤਾਜ਼ੀਆਂ ਕਾਂਟ੍ਰੈਕਟ ਐਂਟਰੀਆਂ',
      'contractWorkRatesNote': 'ਦਰਾਂ ਸਿਰਫ਼ ਭਵਿੱਖ ਦੀਆਂ ਐਂਟਰੀਆਂ \'ਤੇ ਲਾਗੂ ਹੁੰਦੀਆਂ ਹਨ।',
      'contractWorkAddTypeTitle': 'ਕਾਂਟ੍ਰੈਕਟ ਕਿਸਮ ਸ਼ਾਮਲ ਕਰੋ',
      'contractWorkEditTypeTitle': 'ਕਾਂਟ੍ਰੈਕਟ ਕਿਸਮ ਅਪਡੇਟ ਕਰੋ',
      'contractWorkNameLabel': 'ਕਾਂਟ੍ਰੈਕਟ ਨਾਮ',
      'contractWorkRateLabel': 'ਪਰ ਯੂਨਿਟ ਦਰ',
      'contractWorkUnitLabel': 'ਯੂਨਿਟ ਲੇਬਲ',
      'contractWorkUnitsLabel': 'ਯੂਨਿਟ',
      'contractWorkRateRequiredMessage': 'ਕਿਰਪਾ ਕਰਕੇ ਵੈਧ ਦਰ ਦਰਜ ਕਰੋ।',
      'contractWorkNameRequiredMessage': 'ਕਿਰਪਾ ਕਰਕੇ ਕਾਂਟ੍ਰੈਕਟ ਨਾਮ ਦਰਜ ਕਰੋ।',
      'contractWorkTypeSavedMessage': 'ਕਾਂਟ੍ਰੈਕਟ ਕਿਸਮ ਸੇਵ ਕੀਤੀ ਗਈ।',
      'contractWorkNoEntriesLabel': 'ਕੋਈ ਕਾਂਟ੍ਰੈਕਟ ਐਂਟਰੀ ਰਿਕਾਰਡ ਨਹੀਂ ਹੈ।',
      'contractWorkLastUpdatedLabel': 'ਆਖਰੀ ਅਪਡੇਟ',
      'contractWorkEditRateButton': 'ਦਰ ਅਪਡੇਟ ਕਰੋ',
      'contractWorkActiveTypesLabel': 'ਸਰਗਰਮ ਕਿਸਮਾਂ',
      'contractWorkTotalUnitsLabel': 'ਕੁੱਲ ਯੂਨਿਟ',
      'contractWorkTotalSalaryLabel': 'ਕੁੱਲ ਤਨਖ਼ਾਹ',
      'contractWorkDefaultTag': 'ਡਿਫਾਲਟ',
      'contractWorkUnitFallback': 'ਪਰ ਯੂਨਿਟ',
      'changeLanguageLabel': 'ਭਾਸ਼ਾ ਬਦਲੋ',
      'helpSupportLabel': 'ਸਹਾਇਤਾ ਅਤੇ ਸਮਰਥਨ',
      'helpSupportTitle': 'ਅਸੀਂ ਤੁਹਾਡੀ ਕਿਵੇਂ ਮਦਦ ਕਰ ਸਕਦੇ ਹਾਂ?',
      'helpSupportSubtitle': 'ਝਟਪਟ ਜਵਾਬ ਲੱਭੋ ਜਾਂ ਸਾਡੀ ਸਹਾਇਤਾ ਟੀਮ ਨਾਲ ਸੰਪਰਕ ਕਰੋ।',
      'helpSupportQuickActionsTitle': 'ਤੁਰੰਤ ਮਦਦ',
      'helpSupportFaqsLabel': 'ਅਕਸਰ ਪੁੱਛੇ ਸਵਾਲ',
      'helpSupportFaqsSubtitle': 'ਆਮ ਸਵਾਲ ਵੇਖੋ',
      'helpSupportGuidesLabel': 'ਸ਼ੁਰੂਆਤ ਲਈ ਗਾਈਡ',
      'helpSupportGuidesSubtitle': 'ਕਦਮ-ਦਰ-ਕਦਮ ਸਿਖਲਾਈ',
      'helpSupportReportIssueLabel': 'ਮੁੱਦਾ ਰਿਪੋਰਟ ਕਰੋ',
      'helpSupportReportIssueSubtitle': 'ਸਾਨੂੰ ਦੱਸੋ ਕਿ ਕੀ ਗਲਤ ਹੋਇਆ',
      'helpSupportContactTitle': 'ਸੰਪਰਕ ਵਿਕਲਪ',
      'helpSupportEmailLabel': 'ਸਾਨੂੰ ਈਮੇਲ ਕਰੋ',
      'helpSupportEmailValue': 'support@attendancepro.com',
      'helpSupportEmailButton': 'ਈਮੇਲ ਭੇਜੋ',
      'helpSupportPhoneLabel': 'ਸਾਨੂੰ ਕਾਲ ਕਰੋ',
      'helpSupportPhoneValue': '+91 9876543210',
      'helpSupportCallButton': 'ਹੁਣੇ ਕਾਲ ਕਰੋ',
      'helpSupportChatLabel': 'ਲਾਈਵ ਚੈਟ',
      'helpSupportChatSubtitle': 'ਸੋਮ-ਸ਼ੁੱਕਰ, ਸਵੇਰੇ 9 ਤੋਂ ਸ਼ਾਮ 6 ਵਜੇ ਤੱਕ',
      'helpSupportChatButton': 'ਚੈਟ ਸ਼ੁਰੂ ਕਰੋ',
      'helpSupportHoursLabel': 'ਸਹਾਇਤਾ ਸਮਾਂ',
      'helpSupportHoursValue': 'ਸੋਮ - ਸ਼ੁੱਕਰ, 9 AM - 6 PM (GMT)',
      'helpSupportResponseTimeLabel': 'ਔਸਤ ਜਵਾਬ ਸਮਾਂ',
      'helpSupportResponseTimeValue': '24 ਘੰਟਿਆਂ ਤੋਂ ਘੱਟ',
      'helpSupportAdditionalInfoTitle': 'ਵਾਧੂ ਜਾਣਕਾਰੀ',
      'helpSupportLastUpdatedLabel': 'ਆਖਰੀ ਅੱਪਡੇਟ',
      'helpSupportLastUpdatedValue': 'ਅਕਤੂਬਰ 2025',
      'helpSupportPolicyLabel': 'ਸਹਾਇਤਾ ਨੀਤੀ',
      'helpSupportPolicyValue': 'ਅਸੀਂ AttendancePro ਗਾਹਕ ਸੇਵਾ ਮਿਆਰਾਂ ਦੀ ਪਾਲਣਾ ਕਰਦੇ ਹਾਂ।',
      'helpSupportLaunchFailed': 'ਅਨੁਰੋਧਿਤ ਐਪ ਖੋਲ੍ਹਣ ਵਿੱਚ ਅਸਮਰੱਥ।',
      'helpSupportComingSoon': 'ਇਹ ਭਾਗ ਜਲਦੀ ਉਪਲਬਧ ਹੋਵੇਗਾ।',
      'logoutLabel': 'ਲੌਗ ਆਉਟ',
      'reportsSummaryLabel': 'Reports & Summary',
      'reportsSummaryMonth': 'October 2025',
      'reportsCombinedSalaryTitle': 'Total Combined Salary',
      'reportsHoursWorkedSuffix': 'hours worked',
      'reportsUnitsCompletedSuffix': 'units completed',
      'reportsHourlyWorkSummaryTitle': 'Hourly Work Summary',
      'reportsWorkingDaysLabel': 'Working Days',
      'reportsAverageHoursPerDayLabel': 'Average Hours/Day',
      'reportsLastPayoutLabel': 'Last Payout',
      'reportsTotalUnitsLabel': 'Total Units',
      'reportsContractSalaryLabel': 'Contract Salary',
      'reportsBreakdownSuffix': 'Breakdown',
      'reportsGrandTotalLabel': 'Grand Total',
      'logoutConfirmationTitle': 'ਲਾਗਆਉਟ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ',
      'logoutConfirmationMessage': 'ਕੀ ਤੁਸੀਂ ਯਕੀਨਨ ਲਾਗਆਉਟ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?',
      'logoutConfirmButton': 'ਲਾਗਆਉਟ',
      'logoutCancelButton': 'ਰੱਦ ਕਰੋ',
      'logoutSuccessMessage': 'ਉਪਭੋਗਤਾ ਸਫਲਤਾਪੂਰਵਕ ਲਾਗਆਉਟ ਹੋ ਗਿਆ।',
      'logoutFailedMessage': 'ਲਾਗਆਉਟ ਨਹੀਂ ਹੋ ਸਕਿਆ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      'shareAppTitle': 'ਐਪ ਸਾਂਝਾ ਕਰੋ',
      'shareViaWhatsApp': 'WhatsApp ਰਾਹੀਂ ਸਾਂਝਾ ਕਰੋ',
      'copyLink': 'ਲਿੰਕ ਕਾਪੀ ਕਰੋ',
      'shareCancelButton': 'ਰੱਦ ਕਰੋ',
      'shareLinkCopied': 'ਲਿੰਕ ਕਲਿੱਪਬੋਰਡ ਵਿੱਚ ਕਾਪੀ ਹੋ ਗਿਆ ਹੈ।',
      'shareWhatsappUnavailable': 'ਇਸ ਡਿਵਾਈਸ ਤੇ WhatsApp ਇੰਸਟਾਲ ਨਹੀਂ ਹੈ।',
      'shareWhatsappFailed': 'WhatsApp ਨਹੀਂ ਖੋਲ੍ਹ ਸਕੇ।',
      'shareMessage': 'AttendancePro ਨੂੰ ਵੇਖੋ: {link}',
      'dashboardTappedMessage': 'ਡੈਸ਼ਬੋਰਡ ਚੁਣਿਆ ਗਿਆ',
      'addNewWorkTappedMessage': 'ਨਵਾਂ ਕੰਮ ਚੁਣਿਆ ਗਿਆ',
      'attendanceHistoryTappedMessage': 'ਹਾਜ਼ਰੀ ਇਤਿਹਾਸ ਚੁਣਿਆ ਗਿਆ',
      'contractWorkTappedMessage': 'ਕਾਂਟ੍ਰੈਕਟ ਕੰਮ ਚੁਣਿਆ ਗਿਆ',
      'helpSupportTappedMessage': 'ਸਹਾਇਤਾ ਅਤੇ ਸਮਰਥਨ ਚੁਣਿਆ ਗਿਆ',
      'workA': 'ਕੰਮ A',
      'workB': 'ਕੰਮ B',
      'switchedToWorkA': 'ਕੰਮ A ਤੇ ਬਦਲਿਆ ਗਿਆ',
      'switchedToWorkB': 'ਕੰਮ B ਤੇ ਬਦਲਿਆ ਗਿਆ',
      'selectLanguageTitle': 'ਭਾਸ਼ਾ ਚੁਣੋ',
      'languageEnglish': 'ਅੰਗਰੇਜ਼ੀ',
      'languageHindi': 'ਹਿੰਦੀ',
      'languagePunjabi': 'ਪੰਜਾਬੀ',
      'languageItalian': 'ਇਤਾਲਵੀ',
      'languageSelection': 'ਭਾਸ਼ਾ: {language}',
      'noWorkAddedYet': 'ਹੁਣ ਤੱਕ ਕੋਈ ਕੰਮ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ',
      'startTrackingAttendance':
      'ਆਪਣਾ ਪਹਿਲਾ ਕੰਮ ਜੋੜ ਕੇ\nਹਾਜ਼ਰੀ ਟ੍ਰੈਕ ਕਰਨੀ ਸ਼ੁਰੂ ਕਰੋ',
      'addYourFirstWork': 'ਆਪਣਾ ਪਹਿਲਾ ਕੰਮ ਜੋੜੋ',
      'hourlyWorkLabel': 'ਘੰਟਾਵਾਰੀ ਕੰਮ',
      'changeWorkButton': 'ਕੰਮ ਬਦਲੋ',
      'todaysAttendanceTitle': 'ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ',
      'startTimeLabel': 'ਸ਼ੁਰੂਆਤੀ ਸਮਾਂ',
      'endTimeLabel': 'ਖਤਮ ਸਮਾਂ',
      'breakLabel': 'ਵਿਰਾਮ',
      'submitButton': 'ਜਮ੍ਹਾਂ ਕਰੋ',
      'markAsWorkOffButton': 'ਕੰਮ ਛੁੱਟੀ ਨਿਸ਼ਾਨ ਲਗਾਓ',
      'contractWorkSummaryTitle': 'ਕਾਨਟ੍ਰੈਕਟ ਕੰਮ ਸੰਖੇਪ',
      'summaryLabel': 'ਸੰਖੇਪ',
      'totalHoursLabel': 'ਕੁੱਲ ਘੰਟੇ',
      'totalSalaryLabel': 'ਕੁੱਲ ਤਨਖ਼ਾਹ',
      'activeWorkLabel': 'ਸਰਗਰਮ',
      'setActiveWorkButton': 'ਸਰਗਰਮ ਕਰੋ',
      'settingActiveWorkLabel': 'ਸਰਗਰਮ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...',
      'workActivatedMessage': 'ਕੰਮ ਨੂੰ ਸਰਗਰਮ ਕੀਤਾ ਗਿਆ ਹੈ।',
      'workNameLabel': 'ਕੰਮ ਦਾ ਨਾਮ',
      'workNameHint': 'ਉਦਾਹਰਣ: ਰੈਸਟੋਰੈਂਟ, ਗੋਦਾਮ',
      'hourlySalaryLabel': 'ਘੰਟਾਵਾਰੀ ਮਜ਼ਦੂਰੀ',
      'hourlySalaryHint': '₹ 0.00',
      'contractWorkHeader': 'ਕਾਂਟ੍ਰੈਕਟ ਕੰਮ (ਜੇ ਹੋਵੇ)',
      'addContractWorkButton': 'ਕਾਂਟ੍ਰੈਕਟ ਕੰਮ ਜੋੜੋ',
      'contractWorkDescription': 'ਪੀਸ-ਰੇਟ ਕੰਮ: ਤਰਬੂਜ, ਗਾਜਰ, ਰਾਵੇਨੇਲੋ, ਸੰਤਰਾ ਆਦਿ।',
      'cancelButton': 'ਰੱਦ ਕਰੋ',
      'saveButtonLabel': 'ਸੇਵ ਕਰੋ',
      'saveWorkButton': 'ਕੰਮ ਸੰਭਾਲੋ',
      'workNameRequiredMessage': 'ਕਿਰਪਾ ਕਰਕੇ ਕੰਮ ਦਾ ਨਾਮ ਦਰਜ ਕਰੋ।',
      'workAddedMessage': 'ਕੰਮ ਸਫਲਤਾਪੂਰਵਕ ਜੋੜਿਆ ਗਿਆ।',
      'workUpdatedMessage': 'ਕੰਮ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਹੋਇਆ।',
      'invalidHourlyRateMessage': 'ਕਿਰਪਾ ਕਰਕੇ ਠੀਕ ਘੰਟਾਵਾਰੀ ਦਰ ਦਰਜ ਕਰੋ।',
      'editWorkTitle': 'ਕੰਮ ਸੰਪਾਦਿਤ ਕਰੋ',
      'editWorkSubtitle': 'ਆਪਣੇ ਕੰਮ ਦੇ ਵੇਰਵੇ ਅੱਪਡੇਟ ਕਰੋ',
      'updateWorkButton': 'ਕੰਮ ਅੱਪਡੇਟ ਕਰੋ',
      'editWorkTooltip': 'ਕੰਮ ਸੰਪਾਦਿਤ ਕਰੋ',
      'workDeleteConfirmationTitle': 'ਕੰਮ ਮਿਟਾਓ',
      'workDeleteConfirmationMessage': 'ਕੀ ਤੁਸੀਂ ਇਹ ਕੰਮ ਮਿਟਾਉਣਾ ਚਾਹੁੰਦੇ ਹੋ?',
      'workDeleteConfirmButton': 'ਮਿਟਾਓ',
      'workDeleteCancelButton': 'ਰੱਦ ਕਰੋ',
      'workDeleteSuccessMessage': 'ਕੰਮ ਸਫਲਤਾਪੂਰਵਕ ਮਿਟਾਇਆ ਗਿਆ।',
      'workDeleteFailedMessage': 'ਕੰਮ ਮਿਟਾਉਣ ਵਿੱਚ ਅਸਫਲ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      'workSaveFailedMessage': 'ਕੰਮ ਸੰਭਾਲਿਆ ਨਹੀਂ ਜਾ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      'worksLoadFailedTitle': 'ਕੰਮ ਲੋਡ ਨਹੀਂ ਹੋ ਸਕੇ',
      'worksLoadFailedMessage':
          'ਅਸੀਂ ਤੁਹਾਡੇ ਕੰਮ ਲੋਡ ਨਹੀਂ ਕਰ ਸਕੇ। ਕਿਰਪਾ ਕਰਕੇ ਹੇਠਾਂ ਖਿੱਚ ਕੇ ਰਿਫ਼ਰੈਸ਼ ਕਰੋ ਜਾਂ ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      'retryButtonLabel': 'ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ',
      'notAvailableLabel': 'ਉਪਲਬਧ ਨਹੀਂ',
      'authenticationRequiredMessage': 'ਤੁਹਾਡਾ ਸੈਸ਼ਨ ਸਮਾਪਤ ਹੋ ਗਿਆ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਲੌਗਇਨ ਕਰੋ।',
      'walkthroughTitleOne':
      'ਆਪਣੇ ਕੰਮ ਦੇ ਘੰਟੇ ਆਸਾਨੀ ਨਾਲ ਟ੍ਰੈਕ ਕਰੋ',
      'walkthroughDescOne':
      'ਕੇਵਲ ਇੱਕ ਟੈਪ ਨਾਲ ਆਪਣਾ ਦਿਨ ਸ਼ੁਰੂ ਅਤੇ ਖਤਮ ਕਰੋ। ਆਪਣੇ ਘੰਟਿਆਂ ਨੂੰ ਸਹੀ ਅਤੇ ਵਿਵਸਥਿਤ ਰੱਖੋ।',
      'walkthroughTitleTwo': 'ਇੱਕ ਐਪ ਵਿੱਚ ਕਈ ਨੌਕਰੀਆਂ',
      'walkthroughDescTwo':
      'ਅਸਾਨੀ ਨਾਲ ਕਈ ਕੰਮਾਂ ਵਿੱਚ ਬਦਲੋ ਅਤੇ ਆਪਣੀ ਕਮਾਈ ਤੁਰੰਤ ਵੇਖੋ।',
      'walkthroughTitleThree': 'ਤੁਹਾਡੀ ਭਾਸ਼ਾ, ਤੁਹਾਡਾ ਢੰਗ',
      'walkthroughDescThree':
      'ਅੰਗਰੇਜ਼ੀ, ਹਿੰਦੀ, ਪੰਜਾਬੀ ਅਤੇ ਇਤਾਲਵੀ ਵਿੱਚ ਉਪਲਬਧ ਤਾਂ ਜੋ ਤੁਸੀਂ ਹਾਜ਼ਰੀ ਆਪਣੇ ਸੁਖ ਨਾਲ ਸੰਭਾਲ ਸਕੋ।',
      'skip': 'ਛੱਡੋ',
      'splashTitle': 'ਅਟੈਂਡੈਂਸ ਪ੍ਰੋ',
      'loginTitle': 'ਲਾਗਇਨ',
      'emailLabel': 'ਈਮੇਲ',
      'emailHint': 'you@example.com',
      'passwordLabel': 'ਪਾਸਵਰਡ',
      'passwordHint': '********',
      'loginButton': 'ਲਾਗਇਨ',
      'forgotPassword': 'ਕੀ ਤੁਸੀਂ ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?',
      'signupPromptPrefix': 'ਖਾਤਾ ਨਹੀਂ ਹੈ? ',
      'signupPromptAction': 'ਸਾਈਨ ਅੱਪ',
      'changeLanguage': 'ਭਾਸ਼ਾ ਬਦਲੋ',
      'snackEnterEmail': 'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਈਮੇਲ ਦਰਜ ਕਰੋ।',
      'snackEnterValidEmail': 'ਕਿਰਪਾ ਕਰਕੇ ਵੈਧ ਈਮੇਲ ਐਡਰੈੱਸ ਦਰਜ ਕਰੋ।',
      'snackEnterPassword': 'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਪਾਸਵਰਡ ਦਰਜ ਕਰੋ।',
      'snackLoginSuccess': 'ਸਫਲਤਾਪੂਰਵਕ ਲਾਗਇਨ ਕੀਤਾ',
      'snackResetEmail': 'ਰੀਸੈਟ ਕਰਨ ਲਈ ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਈਮੇਲ ਦਰਜ ਕਰੋ।',
      'snackForgotInvalidEmail': 'ਕਿਰਪਾ ਕਰਕੇ ਵੈਧ ਈਮੇਲ ਐਡਰੈੱਸ ਦਰਜ ਕਰੋ।',
      'signupTitle': 'ਸਾਈਨ ਅੱਪ',
      'fullNameLabel': 'ਪੂਰਾ ਨਾਮ',
      'nameRequired': 'ਨਾਮ ਲਾਜ਼ਮੀ ਹੈ',
      'emailAddressLabel': 'ਈਮੇਲ ਐਡਰੈੱਸ',
      'emailRequired': 'ਈਮੇਲ ਲਾਜ਼ਮੀ ਹੈ',
      'emailInvalid': 'ਗਲਤ ਈਮੇਲ',
      'passwordRequired': 'ਪਾਸਵਰਡ ਲਾਜ਼ਮੀ ਹੈ',
      'passwordMinLength': 'ਘੱਟੋ-ਘੱਟ 6 ਅੱਖਰ',
      'confirmPasswordLabel': 'ਪਾਸਵਰਡ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ',
      'confirmPasswordRequired': 'ਕਿਰਪਾ ਕਰਕੇ ਪਾਸਵਰਡ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ',
      'confirmPasswordMismatch': 'ਪਾਸਵਰਡ ਮੇਲ ਨਹੀਂ ਖਾਂਦੇ',
      'termsAgreement':
      'ਕਿਰਪਾ ਕਰਕੇ ਜਾਰੀ ਰੱਖਣ ਲਈ ਸ਼ਰਤਾਂ ਨਾਲ ਸਹਿਮਤ ਹੋਵੋ।',
      'userAgreementTitle': 'ਉਪਭੋਗਤਾ ਸਮਝੌਤਾ ਅਤੇ ਗੋਪਨੀਯਤਾ ਨੀਤੀ',
      'userAgreementContent':
      'ਇਹ ਉਪਭੋਗਤਾ ਸਮਝੌਤਾ ਅਤੇ ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਲਈ ਪਲੇਸਹੋਲਡਰ ਹੈ। ਅਸਲੀ ਐਪ ਵਿੱਚ ਤੁਸੀਂ ਪੂਰਾ ਪਾਠ ਦਿਖਾਓਗੇ ਜਾਂ ਵੈੱਬਵਿਊ ਖੋਲ੍ਹੋਗੇ।',
      'close': 'ਬੰਦ ਕਰੋ',
      'agreeTextPrefix': 'ਮੈਂ ਪੜ੍ਹਿਆ ਹੈ ਅਤੇ ਸਹਿਮਤ ਹਾਂ ',
      'userAgreement': 'ਉਪਭੋਗਤਾ ਸਮਝੌਤਾ',
      'and': ' ਅਤੇ ',
      'privacyPolicy': 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ',
      'signupButton': 'ਸਾਈਨ ਅੱਪ',
      'alreadyAccountPrompt': 'ਕੀ ਪਹਿਲਾਂ ਹੀ ਖਾਤਾ ਹੈ? ',
      'loginAction': 'ਲਾਗਇਨ',
      'createPasswordTitle': 'ਨਵਾਂ ਪਾਸਵਰਡ ਬਣਾਓ',
      'newPasswordLabel': 'ਨਵਾਂ ਪਾਸਵਰਡ',
      'newPasswordHint': 'ਨਵਾਂ ਪਾਸਵਰਡ ਦਰਜ ਕਰੋ',
      'confirmPasswordHint': 'ਪਾਸਵਰਡ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ',
      'passwordMinEight':
      'ਪਾਸਵਰਡ ਘੱਟੋ-ਘੱਟ 8 ਅੱਖਰਾਂ ਦਾ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ।',
      'passwordsDoNotMatch': 'ਪਾਸਵਰਡ ਮੇਲ ਨਹੀਂ ਖਾਂਦੇ।',
      'resetPasswordButton': 'ਪਾਸਵਰਡ ਰੀਸੈਟ ਕਰੋ',
      'verifyNumberTitle': 'ਆਪਣਾ ਨੰਬਰ ਤਸਦੀਕ ਕਰੋ',
      'verifyCodeDescription':
      'ਅਸੀਂ ਤੁਹਾਡੇ ਈਮੇਲ ਉੱਤੇ 6 ਅੰਕਾਂ ਦਾ ਕੋਡ ਭੇਜਿਆ ਹੈ।',
      'enterCodeLabel': 'ਕੋਡ ਦਰਜ ਕਰੋ',
      'verifyOtpButton': 'ਓਟੀਪੀ ਦੀ ਤਸਦੀਕ ਕਰੋ',
      'resendCountdown': 'ਕੋਡ ਨਹੀਂ ਮਿਲਿਆ? 00:{seconds} ਵਿੱਚ ਮੁੜ ਭੇਜੋ',
      'resendCode': 'ਕੋਡ ਮੁੜ ਭੇਜੋ',
      'operationSuccessful': 'ਕਾਰਵਾਈ ਸਫਲ ਰਹੀ',
    },
    'it': {
      'appTitle': 'PresenzePro',
      'drawerUserName': 'John Snow',
      'drawerUserPhone': '+39-319-055-5550',
      'dashboardLabel': 'Dashboard',
      'homeBannerTitle': 'Monitora le presenze in modo intelligente',
      'homeBannerSubtitle':
          'Gestisci i tuoi turni, traccia le ore e rimani organizzato ogni giorno.',
      'addNewWorkLabel': 'Aggiungi nuovo lavoro',
      'attendanceHistoryLabel': 'Storico presenze',
      'attendanceHistoryMonthLabel': 'Seleziona mese',
      'attendanceHistorySummaryTitle': 'Questo mese finora',
      'attendanceHistoryWorkedDaysLabel': 'Giorni lavorati',
      'attendanceHistoryLeaveDaysLabel': 'Giorni di permesso',
      'attendanceHistoryOvertimeLabel': 'Straordinari',
      'attendanceHistoryTimelineTitle': 'Cronologia giornaliera',
      'attendanceHistoryNoEntriesLabel': 'Nessuna registrazione di presenza.',
      'attendanceHistoryHourlyEntry': 'Orario',
      'attendanceHistoryContractEntry': 'Contratto',
      'attendanceHistoryLeaveEntry': 'Permesso',
      'attendanceHistoryPendingTitle': 'Registrazioni di presenza in sospeso',
      'attendanceHistoryPendingDescription':
          'Completa i giorni precedenti prima di segnare oggi come presente.',
      'attendanceHistoryResolveButton': 'Completa ora',
      'attendanceHistoryAllCaughtUp': 'Sei completamente aggiornato!',
      'attendanceHistoryAllCaughtUpDescription':
          'Tutte le presenze precedenti sono completate.',
      'attendanceHistoryAllWorks': 'Tutti i lavori',
      'attendanceHistoryOvertimeEntryLabel': 'Straordinari',
      'attendanceHistoryLoggedHoursLabel': 'Ore registrate',
      'attendanceHistoryReasonLabel': 'Motivo',
      'contractWorkLabel': 'Lavoro a contratto',
      'contractWorkActiveRatesTitle': 'Tariffe contratto attive',
      'contractWorkDefaultTypesTitle': 'Tipi di contratto disponibili',
      'contractWorkRecentEntriesTitle': 'Registrazioni contratto recenti',
      'contractWorkRatesNote': 'Le tariffe si applicano solo alle registrazioni future.',
      'contractWorkAddTypeTitle': 'Aggiungi tipo di contratto',
      'contractWorkEditTypeTitle': 'Aggiorna tipo di contratto',
      'contractWorkNameLabel': 'Nome contratto',
      'contractWorkRateLabel': 'Tariffa per unità',
      'contractWorkUnitLabel': 'Etichetta unità',
      'contractWorkUnitsLabel': 'Unità',
      'contractWorkRateRequiredMessage': 'Inserisci una tariffa valida.',
      'contractWorkNameRequiredMessage': 'Inserisci il nome del contratto.',
      'contractWorkTypeSavedMessage': 'Tipo di contratto salvato.',
      'contractWorkNoEntriesLabel': 'Nessuna registrazione contratto.',
      'contractWorkLastUpdatedLabel': 'Ultimo aggiornamento',
      'contractWorkEditRateButton': 'Aggiorna tariffa',
      'contractWorkActiveTypesLabel': 'Tipi attivi',
      'contractWorkTotalUnitsLabel': 'Unità totali',
      'contractWorkTotalSalaryLabel': 'Salario totale',
      'contractWorkDefaultTag': 'Predefinito',
      'contractWorkUnitFallback': 'per unità',
      'changeLanguageLabel': 'Cambia lingua',
      'helpSupportLabel': 'Assistenza',
      'helpSupportTitle': 'Come possiamo aiutarti oggi?',
      'helpSupportSubtitle':
          'Trova risposte rapide o contatta il nostro team di supporto.',
      'helpSupportQuickActionsTitle': 'Assistenza rapida',
      'helpSupportFaqsLabel': 'Domande frequenti',
      'helpSupportFaqsSubtitle': 'Consulta le domande comuni',
      'helpSupportGuidesLabel': 'Guida introduttiva',
      'helpSupportGuidesSubtitle': 'Tutorial passo dopo passo',
      'helpSupportReportIssueLabel': 'Segnala un problema',
      'helpSupportReportIssueSubtitle': 'Facci sapere cosa è successo',
      'helpSupportContactTitle': 'Opzioni di contatto',
      'helpSupportEmailLabel': 'Scrivici',
      'helpSupportEmailValue': 'support@attendancepro.app',
      'helpSupportEmailButton': 'Invia email',
      'helpSupportPhoneLabel': 'Chiamaci',
      'helpSupportPhoneValue': '+1 (800) 555-1234',
      'helpSupportCallButton': 'Chiama ora',
      'helpSupportChatLabel': 'Chat live',
      'helpSupportChatSubtitle': 'Disponibile Lun-Ven, 9:00 - 18:00',
      'helpSupportChatButton': 'Avvia chat',
      'helpSupportHoursLabel': 'Orari di supporto',
      'helpSupportHoursValue': 'Lun - Ven, 9:00 - 18:00 (GMT)',
      'helpSupportResponseTimeLabel': 'Tempo medio di risposta',
      'helpSupportResponseTimeValue': 'Entro 24 ore',
      'helpSupportAdditionalInfoTitle': 'Informazioni aggiuntive',
      'helpSupportLastUpdatedLabel': 'Ultimo aggiornamento',
      'helpSupportLastUpdatedValue': 'Ottobre 2025',
      'helpSupportPolicyLabel': 'Politica di supporto',
      'helpSupportPolicyValue':
          'Seguiamo gli standard di assistenza clienti di AttendancePro.',
      'helpSupportLaunchFailed':
          'Impossibile aprire l\'applicazione richiesta.',
      'helpSupportComingSoon': 'Questa sezione sarà disponibile a breve.',
      'logoutLabel': 'Esci',
      'reportsSummaryLabel': 'Reports & Summary',
      'reportsSummaryMonth': 'October 2025',
      'reportsCombinedSalaryTitle': 'Total Combined Salary',
      'reportsHoursWorkedSuffix': 'hours worked',
      'reportsUnitsCompletedSuffix': 'units completed',
      'reportsHourlyWorkSummaryTitle': 'Hourly Work Summary',
      'reportsWorkingDaysLabel': 'Working Days',
      'reportsAverageHoursPerDayLabel': 'Average Hours/Day',
      'reportsLastPayoutLabel': 'Last Payout',
      'reportsTotalUnitsLabel': 'Total Units',
      'reportsContractSalaryLabel': 'Contract Salary',
      'reportsBreakdownSuffix': 'Breakdown',
      'reportsGrandTotalLabel': 'Grand Total',
      'logoutConfirmationTitle': 'Conferma logout',
      'logoutConfirmationMessage': 'Sei sicuro di voler uscire?',
      'logoutConfirmButton': 'Esci',
      'logoutCancelButton': 'Annulla',
      'logoutSuccessMessage': 'Disconnessione avvenuta con successo.',
      'logoutFailedMessage': 'Impossibile disconnettersi. Riprova.',
      'shareAppTitle': 'Condividi app',
      'shareViaWhatsApp': 'Condividi via WhatsApp',
      'copyLink': 'Copia link',
      'shareCancelButton': 'Annulla',
      'shareLinkCopied': 'Link copiato negli appunti.',
      'shareWhatsappUnavailable': 'WhatsApp non è installato su questo dispositivo.',
      'shareWhatsappFailed': 'Impossibile aprire WhatsApp.',
      'shareMessage': 'Scopri AttendancePro: {link}',
      'dashboardTappedMessage': 'Dashboard selezionata',
      'addNewWorkTappedMessage': 'Nuovo lavoro selezionato',
      'attendanceHistoryTappedMessage': 'Storico presenze selezionato',
      'contractWorkTappedMessage': 'Lavoro a contratto selezionato',
      'helpSupportTappedMessage': 'Assistenza selezionata',
      'workA': 'Lavoro A',
      'workB': 'Lavoro B',
      'switchedToWorkA': 'Passato a Lavoro A',
      'switchedToWorkB': 'Passato a Lavoro B',
      'selectLanguageTitle': 'Seleziona lingua',
      'languageEnglish': 'Inglese',
      'languageHindi': 'Hindi',
      'languagePunjabi': 'Punjabi',
      'languageItalian': 'Italiano',
      'languageSelection': 'Lingua: {language}',
      'noWorkAddedYet': 'Nessun lavoro aggiunto',
      'startTrackingAttendance':
      'Inizia a registrare le presenze\naggiungendo il tuo primo lavoro',
      'addYourFirstWork': 'Aggiungi il tuo primo lavoro',
      'hourlyWorkLabel': 'Lavoro Orario',
      'changeWorkButton': 'Cambia lavoro',
      'todaysAttendanceTitle': 'Presenze di oggi',
      'startTimeLabel': 'Ora di inizio',
      'endTimeLabel': 'Ora di fine',
      'breakLabel': 'Pausa',
      'submitButton': 'Invia',
      'markAsWorkOffButton': 'Segna come riposo',
      'contractWorkSummaryTitle': 'Riepilogo lavoro a contratto',
      'summaryLabel': 'Riepilogo',
      'totalHoursLabel': 'Ore totali',
      'totalSalaryLabel': 'Salario totale',
      'activeWorkLabel': 'Attivo',
      'setActiveWorkButton': 'Imposta come attivo',
      'settingActiveWorkLabel': 'Attivazione...',
      'workActivatedMessage': 'Lavoro impostato come attivo con successo.',
      'workNameLabel': 'Nome del Lavoro',
      'workNameHint': 'Es. Ristorante, Magazzino',
      'hourlySalaryLabel': 'Paga Oraria',
      'hourlySalaryHint': '€ 0,00',
      'contractWorkHeader': 'Lavoro a Contratto (se disponibile)',
      'addContractWorkButton': 'Aggiungi Lavoro a Contratto',
      'contractWorkDescription': 'Lavoro a cottimo: Anguria, Carota, Ravanello, Arancia, ecc.',
      'cancelButton': 'Annulla',
      'saveButtonLabel': 'Salva',
      'saveWorkButton': 'Salva Lavoro',
      'workNameRequiredMessage': 'Inserisci il nome del lavoro.',
      'workAddedMessage': 'Lavoro aggiunto con successo.',
      'workUpdatedMessage': 'Lavoro aggiornato con successo.',
      'invalidHourlyRateMessage': 'Inserisci una tariffa oraria valida.',
      'editWorkTitle': 'Modifica lavoro',
      'editWorkSubtitle': 'Aggiorna i dettagli del lavoro',
      'updateWorkButton': 'Aggiorna lavoro',
      'editWorkTooltip': 'Modifica lavoro',
      'workDeleteConfirmationTitle': 'Elimina lavoro',
      'workDeleteConfirmationMessage':
          'Sei sicuro di voler eliminare questo lavoro?',
      'workDeleteConfirmButton': 'Elimina',
      'workDeleteCancelButton': 'Annulla',
      'workDeleteSuccessMessage': 'Lavoro eliminato con successo.',
      'workDeleteFailedMessage':
          'Impossibile eliminare il lavoro. Riprova.',
      'workSaveFailedMessage': 'Impossibile salvare il lavoro. Riprova.',
      'worksLoadFailedTitle': 'Impossibile caricare i lavori',
      'worksLoadFailedMessage':
          'Non siamo riusciti a recuperare i tuoi lavori. Trascina verso il basso per aggiornare o riprova.',
      'retryButtonLabel': 'Riprova',
      'notAvailableLabel': 'Non disponibile',
      'authenticationRequiredMessage': 'La tua sessione è scaduta. Accedi di nuovo.',
      'walkthroughTitleOne': 'Traccia facilmente le ore di lavoro',
      'walkthroughDescOne':
      'Avvia e termina la giornata con un tocco. Tieni le ore precise e ordinate.',
      'walkthroughTitleTwo': "Più lavori, un'unica app",
      'walkthroughDescTwo':
      'Passa facilmente tra i lavori e vedi subito i tuoi guadagni.',
      'walkthroughTitleThree': 'La tua lingua, a modo tuo',
      'walkthroughDescThree':
      'Disponibile in inglese, hindi, punjabi e italiano così gestisci le presenze come preferisci.',
      'skip': 'Salta',
      'splashTitle': 'PresenzePro',
      'loginTitle': 'Accesso',
      'emailLabel': 'Email',
      'emailHint': 'you@example.com',
      'passwordLabel': 'Password',
      'passwordHint': '********',
      'loginButton': 'Accedi',
      'forgotPassword': 'Password dimenticata?',
      'signupPromptPrefix': 'Non hai un account? ',
      'signupPromptAction': 'Registrati',
      'changeLanguage': 'Cambia lingua',
      'snackEnterEmail': 'Inserisci la tua email.',
      'snackEnterValidEmail': 'Inserisci un indirizzo email valido.',
      'snackEnterPassword': 'Inserisci la tua password.',
      'snackLoginSuccess': 'Accesso eseguito correttamente',
      'snackResetEmail': 'Inserisci la tua email per reimpostare.',
      'snackForgotInvalidEmail': 'Inserisci un indirizzo email valido.',
      'signupTitle': 'Registrati',
      'fullNameLabel': 'Nome completo',
      'nameRequired': 'Nome obbligatorio',
      'emailAddressLabel': 'Indirizzo email',
      'emailRequired': 'Email obbligatoria',
      'emailInvalid': 'Email non valida',
      'passwordRequired': 'Password obbligatoria',
      'passwordMinLength': 'Minimo 6 caratteri',
      'confirmPasswordLabel': 'Conferma password',
      'confirmPasswordRequired': 'Conferma la password',
      'confirmPasswordMismatch': 'Le password non coincidono',
      'termsAgreement': 'Accetta i termini per continuare.',
      'userAgreementTitle': 'Accordo utente e informativa privacy',
      'userAgreementContent':
      "Questo è un testo fittizio per l'accordo utente e l'informativa privacy. Nell'app reale mostreresti il testo completo o apriresti una webview.",
      'close': 'Chiudi',
      'agreeTextPrefix': 'Ho letto e accetto ',
      'userAgreement': "l'Accordo utente",
      'and': ' e ',
      'privacyPolicy': "l'Informativa privacy",
      'signupButton': 'Registrati',
      'alreadyAccountPrompt': 'Hai già un account? ',
      'loginAction': 'Accedi',
      'createPasswordTitle': 'Crea una nuova password',
      'newPasswordLabel': 'Nuova password',
      'newPasswordHint': 'Inserisci nuova password',
      'confirmPasswordHint': 'Conferma password',
      'passwordMinEight':
      'La password deve contenere almeno 8 caratteri.',
      'passwordsDoNotMatch': 'Le password non coincidono.',
      'resetPasswordButton': 'Reimposta password',
      'verifyNumberTitle': 'Verifica il tuo numero',
      'verifyCodeDescription':
      'Abbiamo inviato un codice di 6 cifre alla tua email.',
      'enterCodeLabel': 'Inserisci il codice',
      'verifyOtpButton': 'Verifica codice',
      'resendCountdown':
      'Non hai ricevuto il codice? Invia di nuovo tra 00:{seconds}',
      'resendCode': 'Invia di nuovo',
      'operationSuccessful': 'Operazione riuscita',
    },
  };

  String _value(String key) {
    final String languageCode = locale.languageCode;
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String _valueWithArgs(String key, Map<String, String> args) {
    var value = _value(key);
    args.forEach((placeholder, replacement) {
      value = value.replaceAll('{$placeholder}', replacement);
    });
    return value;
  }

  String get appTitle => _value('appTitle');
  String get drawerUserName => _value('drawerUserName');
  String get drawerUserPhone => _value('drawerUserPhone');
  String get dashboardLabel => _value('dashboardLabel');
  String get homeBannerTitle => _value('homeBannerTitle');
  String get homeBannerSubtitle => _value('homeBannerSubtitle');
  String get addNewWorkLabel => _value('addNewWorkLabel');
  String get attendanceHistoryLabel => _value('attendanceHistoryLabel');
  String get attendanceHistoryMonthLabel =>
      _value('attendanceHistoryMonthLabel');
  String get attendanceHistorySummaryTitle =>
      _value('attendanceHistorySummaryTitle');
  String get attendanceHistoryWorkedDaysLabel =>
      _value('attendanceHistoryWorkedDaysLabel');
  String get attendanceHistoryLeaveDaysLabel =>
      _value('attendanceHistoryLeaveDaysLabel');
  String get attendanceHistoryOvertimeLabel =>
      _value('attendanceHistoryOvertimeLabel');
  String get attendanceHistoryTimelineTitle =>
      _value('attendanceHistoryTimelineTitle');
  String get attendanceHistoryNoEntriesLabel =>
      _value('attendanceHistoryNoEntriesLabel');
  String get attendanceHistoryHourlyEntry =>
      _value('attendanceHistoryHourlyEntry');
  String get attendanceHistoryContractEntry =>
      _value('attendanceHistoryContractEntry');
  String get attendanceHistoryLeaveEntry =>
      _value('attendanceHistoryLeaveEntry');
  String get attendanceHistoryPendingTitle =>
      _value('attendanceHistoryPendingTitle');
  String get attendanceHistoryPendingDescription =>
      _value('attendanceHistoryPendingDescription');
  String get attendanceHistoryResolveButton =>
      _value('attendanceHistoryResolveButton');
  String get attendanceHistoryAllCaughtUp =>
      _value('attendanceHistoryAllCaughtUp');
  String get attendanceHistoryAllCaughtUpDescription =>
      _value('attendanceHistoryAllCaughtUpDescription');
  String get attendanceHistoryAllWorks =>
      _value('attendanceHistoryAllWorks');
  String get attendanceHistoryOvertimeEntryLabel =>
      _value('attendanceHistoryOvertimeEntryLabel');
  String get attendanceHistoryLoggedHoursLabel =>
      _value('attendanceHistoryLoggedHoursLabel');
  String get attendanceHistoryReasonLabel =>
      _value('attendanceHistoryReasonLabel');
  String get contractWorkLabel => _value('contractWorkLabel');
  String get contractWorkActiveRatesTitle =>
      _value('contractWorkActiveRatesTitle');
  String get contractWorkDefaultTypesTitle =>
      _value('contractWorkDefaultTypesTitle');
  String get contractWorkRecentEntriesTitle =>
      _value('contractWorkRecentEntriesTitle');
  String get contractWorkRatesNote => _value('contractWorkRatesNote');
  String get contractWorkAddTypeTitle => _value('contractWorkAddTypeTitle');
  String get contractWorkEditTypeTitle => _value('contractWorkEditTypeTitle');
  String get contractWorkNameLabel => _value('contractWorkNameLabel');
  String get contractWorkRateLabel => _value('contractWorkRateLabel');
  String get contractWorkUnitLabel => _value('contractWorkUnitLabel');
  String get contractWorkUnitsLabel => _value('contractWorkUnitsLabel');
  String get contractWorkRateRequiredMessage =>
      _value('contractWorkRateRequiredMessage');
  String get contractWorkNameRequiredMessage =>
      _value('contractWorkNameRequiredMessage');
  String get contractWorkTypeSavedMessage =>
      _value('contractWorkTypeSavedMessage');
  String get contractWorkNoEntriesLabel =>
      _value('contractWorkNoEntriesLabel');
  String get contractWorkLastUpdatedLabel =>
      _value('contractWorkLastUpdatedLabel');
  String get contractWorkEditRateButton =>
      _value('contractWorkEditRateButton');
  String get contractWorkActiveTypesLabel =>
      _value('contractWorkActiveTypesLabel');
  String get contractWorkTotalUnitsLabel =>
      _value('contractWorkTotalUnitsLabel');
  String get contractWorkTotalSalaryLabel =>
      _value('contractWorkTotalSalaryLabel');
  String get contractWorkDefaultTag => _value('contractWorkDefaultTag');
  String get contractWorkUnitFallback => _value('contractWorkUnitFallback');
  String get changeLanguageLabel => _value('changeLanguageLabel');
  String get helpSupportLabel => _value('helpSupportLabel');
  String get helpSupportTitle => _value('helpSupportTitle');
  String get helpSupportSubtitle => _value('helpSupportSubtitle');
  String get helpSupportQuickActionsTitle =>
      _value('helpSupportQuickActionsTitle');
  String get helpSupportFaqsLabel => _value('helpSupportFaqsLabel');
  String get helpSupportFaqsSubtitle => _value('helpSupportFaqsSubtitle');
  String get helpSupportGuidesLabel => _value('helpSupportGuidesLabel');
  String get helpSupportGuidesSubtitle =>
      _value('helpSupportGuidesSubtitle');
  String get helpSupportReportIssueLabel =>
      _value('helpSupportReportIssueLabel');
  String get helpSupportReportIssueSubtitle =>
      _value('helpSupportReportIssueSubtitle');
  String get helpSupportContactTitle => _value('helpSupportContactTitle');
  String get helpSupportEmailLabel => _value('helpSupportEmailLabel');
  String get helpSupportEmailValue => _value('helpSupportEmailValue');
  String get helpSupportEmailButton => _value('helpSupportEmailButton');
  String get helpSupportPhoneLabel => _value('helpSupportPhoneLabel');
  String get helpSupportPhoneValue => _value('helpSupportPhoneValue');
  String get helpSupportCallButton => _value('helpSupportCallButton');
  String get helpSupportChatLabel => _value('helpSupportChatLabel');
  String get helpSupportChatSubtitle => _value('helpSupportChatSubtitle');
  String get helpSupportChatButton => _value('helpSupportChatButton');
  String get helpSupportHoursLabel => _value('helpSupportHoursLabel');
  String get helpSupportHoursValue => _value('helpSupportHoursValue');
  String get helpSupportResponseTimeLabel =>
      _value('helpSupportResponseTimeLabel');
  String get helpSupportResponseTimeValue =>
      _value('helpSupportResponseTimeValue');
  String get helpSupportAdditionalInfoTitle =>
      _value('helpSupportAdditionalInfoTitle');
  String get helpSupportLastUpdatedLabel =>
      _value('helpSupportLastUpdatedLabel');
  String get helpSupportLastUpdatedValue =>
      _value('helpSupportLastUpdatedValue');
  String get helpSupportPolicyLabel => _value('helpSupportPolicyLabel');
  String get helpSupportPolicyValue => _value('helpSupportPolicyValue');
  String get helpSupportLaunchFailed => _value('helpSupportLaunchFailed');
  String get helpSupportComingSoon => _value('helpSupportComingSoon');
  String get logoutLabel => _value('logoutLabel');
  String get reportsSummaryLabel => _value('reportsSummaryLabel');
  String get reportsSummaryMonth => _value('reportsSummaryMonth');
  String get reportsCombinedSalaryTitle =>
      _value('reportsCombinedSalaryTitle');
  String get reportsHoursWorkedSuffix =>
      _value('reportsHoursWorkedSuffix');
  String get reportsUnitsCompletedSuffix =>
      _value('reportsUnitsCompletedSuffix');
  String get reportsHourlyWorkSummaryTitle =>
      _value('reportsHourlyWorkSummaryTitle');
  String get reportsWorkingDaysLabel =>
      _value('reportsWorkingDaysLabel');
  String get reportsAverageHoursPerDayLabel =>
      _value('reportsAverageHoursPerDayLabel');
  String get reportsLastPayoutLabel => _value('reportsLastPayoutLabel');
  String get reportsTotalUnitsLabel => _value('reportsTotalUnitsLabel');
  String get reportsContractSalaryLabel =>
      _value('reportsContractSalaryLabel');
  String get reportsBreakdownSuffix => _value('reportsBreakdownSuffix');
  String get reportsGrandTotalLabel => _value('reportsGrandTotalLabel');
  String get logoutConfirmationTitle => _value('logoutConfirmationTitle');
  String get logoutConfirmationMessage =>
      _value('logoutConfirmationMessage');
  String get logoutConfirmButton => _value('logoutConfirmButton');
  String get logoutCancelButton => _value('logoutCancelButton');
  String get logoutSuccessMessage => _value('logoutSuccessMessage');
  String get logoutFailedMessage => _value('logoutFailedMessage');
  String get shareAppTitle => _value('shareAppTitle');
  String get shareViaWhatsApp => _value('shareViaWhatsApp');
  String get copyLink => _value('copyLink');
  String get shareCancelButton => _value('shareCancelButton');
  String get shareLinkCopied => _value('shareLinkCopied');
  String get shareWhatsappUnavailable => _value('shareWhatsappUnavailable');
  String get shareWhatsappFailed => _value('shareWhatsappFailed');
  String shareMessage(String link) =>
      _valueWithArgs('shareMessage', {'link': link});
  String get dashboardTappedMessage => _value('dashboardTappedMessage');
  String get addNewWorkTappedMessage => _value('addNewWorkTappedMessage');
  String get attendanceHistoryTappedMessage =>
      _value('attendanceHistoryTappedMessage');
  String get contractWorkTappedMessage =>
      _value('contractWorkTappedMessage');
  String get helpSupportTappedMessage =>
      _value('helpSupportTappedMessage');
  String get workA => _value('workA');
  String get workB => _value('workB');
  String get switchedToWorkA => _value('switchedToWorkA');
  String get switchedToWorkB => _value('switchedToWorkB');
  String get selectLanguageTitle => _value('selectLanguageTitle');
  String get languageEnglish => _value('languageEnglish');
  String get languageHindi => _value('languageHindi');
  String get languagePunjabi => _value('languagePunjabi');
  String get languageItalian => _value('languageItalian');
  String get noWorkAddedYet => _value('noWorkAddedYet');
  String get startTrackingAttendance => _value('startTrackingAttendance');
  String get addYourFirstWork => _value('addYourFirstWork');
  String get hourlyWorkLabel => _value('hourlyWorkLabel');
  String get changeWorkButton => _value('changeWorkButton');
  String get todaysAttendanceTitle => _value('todaysAttendanceTitle');
  String get startTimeLabel => _value('startTimeLabel');
  String get endTimeLabel => _value('endTimeLabel');
  String get breakLabel => _value('breakLabel');
  String get submitButton => _value('submitButton');
  String get markAsWorkOffButton => _value('markAsWorkOffButton');
  String get contractWorkSummaryTitle => _value('contractWorkSummaryTitle');
  String get summaryLabel => _value('summaryLabel');
  String get totalHoursLabel => _value('totalHoursLabel');
  String get totalSalaryLabel => _value('totalSalaryLabel');
  String get activeWorkLabel => _value('activeWorkLabel');
  String get setActiveWorkButton => _value('setActiveWorkButton');
  String get settingActiveWorkLabel => _value('settingActiveWorkLabel');
  String get workActivatedMessage => _value('workActivatedMessage');
  String get workNameLabel => _value('workNameLabel');
  String get workNameHint => _value('workNameHint');
  String get hourlySalaryLabel => _value('hourlySalaryLabel');
  String get hourlySalaryHint => _value('hourlySalaryHint');
  String get contractWorkHeader => _value('contractWorkHeader');
  String get addContractWorkButton => _value('addContractWorkButton');
  String get contractWorkDescription => _value('contractWorkDescription');
  String get cancelButton => _value('cancelButton');
  String get saveButtonLabel => _value('saveButtonLabel');
  String get saveWorkButton => _value('saveWorkButton');
  String get workNameRequiredMessage => _value('workNameRequiredMessage');
  String get workAddedMessage => _value('workAddedMessage');
  String get workUpdatedMessage => _value('workUpdatedMessage');
  String get invalidHourlyRateMessage => _value('invalidHourlyRateMessage');
  String get editWorkTitle => _value('editWorkTitle');
  String get editWorkSubtitle => _value('editWorkSubtitle');
  String get updateWorkButton => _value('updateWorkButton');
  String get editWorkTooltip => _value('editWorkTooltip');
  String get workDeleteConfirmationTitle =>
      _value('workDeleteConfirmationTitle');
  String get workDeleteConfirmationMessage =>
      _value('workDeleteConfirmationMessage');
  String get workDeleteConfirmButton => _value('workDeleteConfirmButton');
  String get workDeleteCancelButton => _value('workDeleteCancelButton');
  String get workDeleteSuccessMessage => _value('workDeleteSuccessMessage');
  String get workDeleteFailedMessage => _value('workDeleteFailedMessage');
  String get workSaveFailedMessage => _value('workSaveFailedMessage');
  String get worksLoadFailedTitle => _value('worksLoadFailedTitle');
  String get worksLoadFailedMessage => _value('worksLoadFailedMessage');
  String get retryButtonLabel => _value('retryButtonLabel');
  String get notAvailableLabel => _value('notAvailableLabel');
  String get authenticationRequiredMessage =>
      _value('authenticationRequiredMessage');
  String get walkthroughTitleOne => _value('walkthroughTitleOne');
  String get walkthroughDescOne => _value('walkthroughDescOne');
  String get walkthroughTitleTwo => _value('walkthroughTitleTwo');
  String get walkthroughDescTwo => _value('walkthroughDescTwo');
  String get walkthroughTitleThree => _value('walkthroughTitleThree');
  String get walkthroughDescThree => _value('walkthroughDescThree');
  String get skip => _value('skip');
  String get splashTitle => _value('splashTitle');
  String get loginTitle => _value('loginTitle');
  String get emailLabel => _value('emailLabel');
  String get emailHint => _value('emailHint');
  String get passwordLabel => _value('passwordLabel');
  String get passwordHint => _value('passwordHint');
  String get loginButton => _value('loginButton');
  String get forgotPassword => _value('forgotPassword');
  String get signupPromptPrefix => _value('signupPromptPrefix');
  String get signupPromptAction => _value('signupPromptAction');
  String get changeLanguage => _value('changeLanguage');
  String get snackEnterEmail => _value('snackEnterEmail');
  String get snackEnterValidEmail => _value('snackEnterValidEmail');
  String get snackEnterPassword => _value('snackEnterPassword');
  String get snackLoginSuccess => _value('snackLoginSuccess');
  String get snackResetEmail => _value('snackResetEmail');
  String get snackForgotInvalidEmail => _value('snackForgotInvalidEmail');
  String get signupTitle => _value('signupTitle');
  String get fullNameLabel => _value('fullNameLabel');
  String get nameRequired => _value('nameRequired');
  String get emailAddressLabel => _value('emailAddressLabel');
  String get emailRequired => _value('emailRequired');
  String get emailInvalid => _value('emailInvalid');
  String get passwordRequired => _value('passwordRequired');
  String get passwordMinLength => _value('passwordMinLength');
  String get confirmPasswordLabel => _value('confirmPasswordLabel');
  String get confirmPasswordRequired =>
      _value('confirmPasswordRequired');
  String get confirmPasswordMismatch =>
      _value('confirmPasswordMismatch');
  String get termsAgreement => _value('termsAgreement');
  String get userAgreementTitle => _value('userAgreementTitle');
  String get userAgreementContent => _value('userAgreementContent');
  String get close => _value('close');
  String get agreeTextPrefix => _value('agreeTextPrefix');
  String get userAgreement => _value('userAgreement');
  String get and => _value('and');
  String get privacyPolicy => _value('privacyPolicy');
  String get signupButton => _value('signupButton');
  String get alreadyAccountPrompt => _value('alreadyAccountPrompt');
  String get loginAction => _value('loginAction');
  String get createPasswordTitle => _value('createPasswordTitle');
  String get newPasswordLabel => _value('newPasswordLabel');
  String get newPasswordHint => _value('newPasswordHint');
  String get confirmPasswordHint => _value('confirmPasswordHint');
  String get passwordMinEight => _value('passwordMinEight');
  String get passwordsDoNotMatch => _value('passwordsDoNotMatch');
  String get resetPasswordButton => _value('resetPasswordButton');
  String get verifyNumberTitle => _value('verifyNumberTitle');
  String get verifyCodeDescription => _value('verifyCodeDescription');
  String get enterCodeLabel => _value('enterCodeLabel');
  String get verifyOtpButton => _value('verifyOtpButton');
  String get resendCode => _value('resendCode');
  String get operationSuccessful => _value('operationSuccessful');

  String languageSelection(String language) {
    return _value('languageSelection').replaceFirst('{language}', language);
  }

  String resendCountdown(int seconds) {
    final String padded = seconds.toString().padLeft(2, '0');
    return _value('resendCountdown').replaceFirst('{seconds}', padded);
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((Locale l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}