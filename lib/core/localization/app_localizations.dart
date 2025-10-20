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
      'addNewWorkLabel': 'Add New Work',
      'attendanceHistoryLabel': 'Attendance History',
      'contractWorkLabel': 'Contract Work',
      'changeLanguageLabel': 'Change Language',
      'helpSupportLabel': 'Help & Support',
      'logoutLabel': 'Logout',
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
      'workNameLabel': 'Work Name',
      'workNameHint': 'Ex Restaurant, Warehouse',
      'hourlySalaryLabel': 'Hourly Salary',
      'hourlySalaryHint': '\$ 0.00',
      'contractWorkHeader': 'Contract Work (if have)',
      'addContractWorkButton': 'Add Contract Work',
      'contractWorkDescription': 'Piece-rate work: Watermelon, Carrot, Ravanello, Orange, etc.',
      'cancelButton': 'Cancel',
      'saveWorkButton': 'Save Work',
      'workNameRequiredMessage': 'Please enter a work name.',
      'workAddedMessage': 'Work added successfully.',
      'invalidHourlyRateMessage': 'Please enter a valid hourly rate.',
      'workSaveFailedMessage': 'Failed to save work. Please try again.',
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
      'verifyCodeDescription': 'We’ve sent a 4-digit code to your email.',
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
      'addNewWorkLabel': 'नया कार्य जोड़ें',
      'attendanceHistoryLabel': 'उपस्थिति इतिहास',
      'contractWorkLabel': 'ठेका कार्य',
      'changeLanguageLabel': 'भाषा बदलें',
      'helpSupportLabel': 'मदद और समर्थन',
      'logoutLabel': 'लॉग आउट',
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
      'workNameLabel': 'कार्य का नाम',
      'workNameHint': 'उदाहरण: रेस्टोरेंट, गोदाम',
      'hourlySalaryLabel': 'घंटे की मजदूरी',
      'hourlySalaryHint': '₹ 0.00',
      'contractWorkHeader': 'ठेका कार्य (यदि हो)',
      'addContractWorkButton': 'ठेका कार्य जोड़ें',
      'contractWorkDescription': 'पीस-रेट कार्य: तरबूज, गाजर, रावनेलो, संतरा आदि।',
      'cancelButton': 'रद्द करें',
      'saveWorkButton': 'कार्य सहेजें',
      'workNameRequiredMessage': 'कृपया कार्य का नाम दर्ज करें।',
      'workAddedMessage': 'कार्य सफलतापूर्वक जोड़ा गया।',
      'invalidHourlyRateMessage': 'कृपया मान्य प्रति घंटा दर दर्ज करें।',
      'workSaveFailedMessage': 'कार्य सहेजा नहीं जा सका। कृपया पुनः प्रयास करें।',
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
      'verifyCodeDescription': 'हमने आपके ईमेल पर 4 अंकों का कोड भेजा है।',
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
      'addNewWorkLabel': 'ਨਵਾਂ ਕੰਮ ਜੋੜੋ',
      'attendanceHistoryLabel': 'ਹਾਜ਼ਰੀ ਇਤਿਹਾਸ',
      'contractWorkLabel': 'ਕਾਂਟ੍ਰੈਕਟ ਕੰਮ',
      'changeLanguageLabel': 'ਭਾਸ਼ਾ ਬਦਲੋ',
      'helpSupportLabel': 'ਸਹਾਇਤਾ ਅਤੇ ਸਮਰਥਨ',
      'logoutLabel': 'ਲੌਗ ਆਉਟ',
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
      'workNameLabel': 'ਕੰਮ ਦਾ ਨਾਮ',
      'workNameHint': 'ਉਦਾਹਰਣ: ਰੈਸਟੋਰੈਂਟ, ਗੋਦਾਮ',
      'hourlySalaryLabel': 'ਘੰਟਾਵਾਰੀ ਮਜ਼ਦੂਰੀ',
      'hourlySalaryHint': '₹ 0.00',
      'contractWorkHeader': 'ਕਾਂਟ੍ਰੈਕਟ ਕੰਮ (ਜੇ ਹੋਵੇ)',
      'addContractWorkButton': 'ਕਾਂਟ੍ਰੈਕਟ ਕੰਮ ਜੋੜੋ',
      'contractWorkDescription': 'ਪੀਸ-ਰੇਟ ਕੰਮ: ਤਰਬੂਜ, ਗਾਜਰ, ਰਾਵੇਨੇਲੋ, ਸੰਤਰਾ ਆਦਿ।',
      'cancelButton': 'ਰੱਦ ਕਰੋ',
      'saveWorkButton': 'ਕੰਮ ਸੰਭਾਲੋ',
      'workNameRequiredMessage': 'ਕਿਰਪਾ ਕਰਕੇ ਕੰਮ ਦਾ ਨਾਮ ਦਰਜ ਕਰੋ।',
      'workAddedMessage': 'ਕੰਮ ਸਫਲਤਾਪੂਰਵਕ ਜੋੜਿਆ ਗਿਆ।',
      'invalidHourlyRateMessage': 'ਕਿਰਪਾ ਕਰਕੇ ਠੀਕ ਘੰਟਾਵਾਰੀ ਦਰ ਦਰਜ ਕਰੋ।',
      'workSaveFailedMessage': 'ਕੰਮ ਸੰਭਾਲਿਆ ਨਹੀਂ ਜਾ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
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
          'ਅਸੀਂ ਤੁਹਾਡੇ ਈਮੇਲ ਉੱਤੇ 4 ਅੰਕਾਂ ਦਾ ਕੋਡ ਭੇਜਿਆ ਹੈ।',
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
      'addNewWorkLabel': 'Aggiungi nuovo lavoro',
      'attendanceHistoryLabel': 'Storico presenze',
      'contractWorkLabel': 'Lavoro a contratto',
      'changeLanguageLabel': 'Cambia lingua',
      'helpSupportLabel': 'Assistenza',
      'logoutLabel': 'Esci',
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
      'workNameLabel': 'Nome del Lavoro',
      'workNameHint': 'Es. Ristorante, Magazzino',
      'hourlySalaryLabel': 'Paga Oraria',
      'hourlySalaryHint': '€ 0,00',
      'contractWorkHeader': 'Lavoro a Contratto (se disponibile)',
      'addContractWorkButton': 'Aggiungi Lavoro a Contratto',
      'contractWorkDescription': 'Lavoro a cottimo: Anguria, Carota, Ravanello, Arancia, ecc.',
      'cancelButton': 'Annulla',
      'saveWorkButton': 'Salva Lavoro',
      'workNameRequiredMessage': 'Inserisci il nome del lavoro.',
      'workAddedMessage': 'Lavoro aggiunto con successo.',
      'invalidHourlyRateMessage': 'Inserisci una tariffa oraria valida.',
      'workSaveFailedMessage': 'Impossibile salvare il lavoro. Riprova.',
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
          'Abbiamo inviato un codice di 4 cifre alla tua email.',
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
  String get addNewWorkLabel => _value('addNewWorkLabel');
  String get attendanceHistoryLabel => _value('attendanceHistoryLabel');
  String get contractWorkLabel => _value('contractWorkLabel');
  String get changeLanguageLabel => _value('changeLanguageLabel');
  String get helpSupportLabel => _value('helpSupportLabel');
  String get logoutLabel => _value('logoutLabel');
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
  String get workNameLabel => _value('workNameLabel');
  String get workNameHint => _value('workNameHint');
  String get hourlySalaryLabel => _value('hourlySalaryLabel');
  String get hourlySalaryHint => _value('hourlySalaryHint');
  String get contractWorkHeader => _value('contractWorkHeader');
  String get addContractWorkButton => _value('addContractWorkButton');
  String get contractWorkDescription => _value('contractWorkDescription');
  String get cancelButton => _value('cancelButton');
  String get saveWorkButton => _value('saveWorkButton');
  String get workNameRequiredMessage => _value('workNameRequiredMessage');
  String get workAddedMessage => _value('workAddedMessage');
  String get invalidHourlyRateMessage => _value('invalidHourlyRateMessage');
  String get workSaveFailedMessage => _value('workSaveFailedMessage');
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
