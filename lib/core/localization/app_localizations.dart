import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../constants/app_strings.dart';

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

  static Map<String, Map<String, String>> get _localizedValues =>
      AppString.localizedValues;

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
  String get adPlaceholderTitle => _value('adPlaceholderTitle');
  String get adPlaceholderSubtitle => _value('adPlaceholderSubtitle');
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
  String get attendanceHistoryLoadFailedMessage =>
      _value('attendanceHistoryLoadFailedMessage');
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
  String get contractWorkSetupSubtitle =>
      _value('contractWorkSetupSubtitle');
  String get contractWorkContractTypeLabel =>
      _value('contractWorkContractTypeLabel');
  String get contractWorkContractTypeHint =>
      _value('contractWorkContractTypeHint');
  String get contractWorkNameLabel => _value('contractWorkNameLabel');
  String get contractWorkSelectWorkHint =>
      _value('contractWorkSelectWorkHint');
  String get contractWorkCustomOption =>
      _value('contractWorkCustomOption');
  String get contractWorkRateLabel => _value('contractWorkRateLabel');
  String get contractWorkRateHint => _value('contractWorkRateHint');
  String get contractWorkPricePerBinHint =>
      _value('contractWorkPricePerBinHint');
  String get contractWorkPricePerCrateHint =>
      _value('contractWorkPricePerCrateHint');
  String get contractWorkPricePerBunchesHint =>
      _value('contractWorkPricePerBunchesHint');
  String get contractWorkPricePerCrateLabel =>
      _value('contractWorkPricePerCrateLabel');
  String get contractWorkUnitLabel => _value('contractWorkUnitLabel');
  String get contractWorkSubtypeLabel => _value('contractWorkSubtypeLabel');
  String get contractWorkSubtypeHint => _value('contractWorkSubtypeHint');
  String get contractWorkSubtypeCustomOption =>
      _value('contractWorkSubtypeCustomOption');
  String get contractWorkSubtypeCustomLabel =>
      _value('contractWorkSubtypeCustomLabel');
  String get contractWorkSubtypeRequiredMessage =>
      _value('contractWorkSubtypeRequiredMessage');
  String get contractWorkTypeLabel => _value('contractWorkTypeLabel');
  String get contractWorkTypeHint => _value('contractWorkTypeHint');
  String get contractWorkTypeFixedOption =>
      _value('contractWorkTypeFixedOption');
  String get contractWorkTypeBundleOption =>
      _value('contractWorkTypeBundleOption');
  String get contractWorkRoleLabel => _value('contractWorkRoleLabel');
  String get contractWorkRoleHint => _value('contractWorkRoleHint');
  String get contractWorkRoleRequiredMessage =>
      _value('contractWorkRoleRequiredMessage');
  String get contractWorkUnitsLabel => _value('contractWorkUnitsLabel');
  String get contractWorkUnitsHint => _value('contractWorkUnitsHint');
  String get contractWorkRateRequiredMessage =>
      _value('contractWorkRateRequiredMessage');
  String get contractWorkNameRequiredMessage =>
      _value('contractWorkNameRequiredMessage');
  String get contractWorkTypeSavedMessage =>
      _value('contractWorkTypeSavedMessage');
  String get contractWorkSaveAllButton =>
      _value('contractWorkSaveAllButton');
  String get contractWorkDeleteConfirmationTitle =>
      _value('contractWorkDeleteConfirmationTitle');
  String get contractWorkDeleteConfirmationMessage =>
      _value('contractWorkDeleteConfirmationMessage');
  String get contractWorkDeleteButton =>
      _value('contractWorkDeleteButton');
  String get contractWorkTypeDeletedMessage =>
      _value('contractWorkTypeDeletedMessage');
  String get contractWorkTypeDeleteFailedMessage =>
      _value('contractWorkTypeDeleteFailedMessage');
  String get contractWorkNoEntriesLabel =>
      _value('contractWorkNoEntriesLabel');
  String get contractWorkAllTypesAddedMessage =>
      _value('contractWorkAllTypesAddedMessage');
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
  String get contractWorkCloseSheetLabel =>
      _value('contractWorkCloseSheetLabel');
  String get profileLabel => _value('profileLabel');
  String get profileTitle => _value('profileTitle');
  String get profileNameLabel => _value('profileNameLabel');
  String get profileNameHint => _value('profileNameHint');
  String get profileUsernameLabel => _value('profileUsernameLabel');
  String get profileUsernameHint => _value('profileUsernameHint');
  String get profilePhoneLabel => _value('profilePhoneLabel');
  String get profilePhoneHint => _value('profilePhoneHint');
  String get profileCountryCodeLabel => _value('profileCountryCodeLabel');
  String get profileCountryCodeHint => _value('profileCountryCodeHint');
  String get profileLanguageLabel => _value('profileLanguageLabel');
  String get profileSaveButton => _value('profileSaveButton');
  String get profileUpdateSuccess => _value('profileUpdateSuccess');
  String get profileUpdateFailed => _value('profileUpdateFailed');
  String get profileAuthRequired => _value('profileAuthRequired');
  String get profileValidationName => _value('profileValidationName');
  String get profileValidationUsername =>
      _value('profileValidationUsername');
  String get profileValidationPhone => _value('profileValidationPhone');
  String get profileValidationCountryCode =>
      _value('profileValidationCountryCode');
  String get profileValidationLanguage =>
      _value('profileValidationLanguage');
  String get profileLoadingFailed => _value('profileLoadingFailed');
  String get contractWorkCustomTypesTitle =>
      _value('contractWorkCustomTypesTitle');
  String get contractWorkNoCustomTypesLabel =>
      _value('contractWorkNoCustomTypesLabel');
  String get contractWorkLoadError => _value('contractWorkLoadError');
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
  String get deleteAccountLabel => _value('deleteAccountLabel');
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
  String get reportsMonthlySectionTitle =>
      _value('reportsMonthlySectionTitle');
  String get reportsMonthlyTypeHourly =>
      _value('reportsMonthlyTypeHourly');
  String get reportsMonthlyTypeFixed =>
      _value('reportsMonthlyTypeFixed');
  String get reportsMonthlyEmptyMessage =>
      _value('reportsMonthlyEmptyMessage');
  String get reportsGrandTotalLabel => _value('reportsGrandTotalLabel');
  String get reportsLoadingMessage => _value('reportsLoadingMessage');
  String get dashboardSummaryLoadFailedMessage =>
      _value('dashboardSummaryLoadFailedMessage');
  String get reportsLoadFailedMessage => _value('reportsLoadFailedMessage');
  String get logoutConfirmationTitle => _value('logoutConfirmationTitle');
  String get logoutConfirmationMessage =>
      _value('logoutConfirmationMessage');
  String get logoutConfirmButton => _value('logoutConfirmButton');
  String get logoutCancelButton => _value('logoutCancelButton');
  String get logoutSuccessMessage => _value('logoutSuccessMessage');
  String get logoutFailedMessage => _value('logoutFailedMessage');
  String get deleteAccountConfirmationTitle =>
      _value('deleteAccountConfirmationTitle');
  String get deleteAccountConfirmationMessage =>
      _value('deleteAccountConfirmationMessage');
  String get deleteAccountConfirmButton =>
      _value('deleteAccountConfirmButton');
  String get deleteAccountCancelButton =>
      _value('deleteAccountCancelButton');
  String get deleteAccountSuccessMessage =>
      _value('deleteAccountSuccessMessage');
  String get deleteAccountFailedMessage =>
      _value('deleteAccountFailedMessage');
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
  String get selectWorkTitle => _value('selectWorkTitle');
  String get workSelectionSubtitle => _value('workSelectionSubtitle');
  String get confirmSelectionButton => _value('confirmSelectionButton');
  String get workSelectionHourSuffix => _value('workSelectionHourSuffix');
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
  String get attendanceSubmitButton => _value('attendanceSubmitButton');
  String get attendanceStartTimeRequired =>
      _value('attendanceStartTimeRequired');
  String get attendanceEndTimeRequired =>
      _value('attendanceEndTimeRequired');
  String get attendanceInvalidTimeFormat =>
      _value('attendanceInvalidTimeFormat');
  String get attendanceBreakInvalid => _value('attendanceBreakInvalid');
  String get attendanceUnitsRequired => _value('attendanceUnitsRequired');
  String get attendanceUnitsInvalid => _value('attendanceUnitsInvalid');
  String get attendanceRateRequired => _value('attendanceRateRequired');
  String get attendanceRateInvalid => _value('attendanceRateInvalid');
  String get attendanceSubmitSuccess => _value('attendanceSubmitSuccess');
  String get attendanceAlreadyMarkedMessage =>
      _value('attendanceAlreadyMarkedMessage');
  String get attendanceSubmitFailed => _value('attendanceSubmitFailed');
  String get attendanceMissedEntriesTitle =>
      _value('attendanceMissedEntriesTitle');
  String get attendanceMissedEntriesDescription =>
      _value('attendanceMissedEntriesDescription');
  String get attendanceMissedEntriesListLabel =>
      _value('attendanceMissedEntriesListLabel');
  String get attendanceMissedEntriesLoadFailed =>
      _value('attendanceMissedEntriesLoadFailed');
  String get attendanceMissedEntriesResolveButton =>
      _value('attendanceMissedEntriesResolveButton');
  String get attendanceMissedEntriesCompleteSuccess =>
      _value('attendanceMissedEntriesCompleteSuccess');
  String get attendanceMissedEntriesCompleteFailed =>
      _value('attendanceMissedEntriesCompleteFailed');
  String attendanceMissedEntriesReviewButton(String date) {
    return _value('attendanceMissedEntriesReviewButton')
        .replaceFirst('{date}', date);
  }
  String get attendancePreviewTitle => _value('attendancePreviewTitle');
  String get attendancePreviewDescription =>
      _value('attendancePreviewDescription');
  String get attendancePreviewConfirmButton =>
      _value('attendancePreviewConfirmButton');
  String get attendancePreviewCancelButton =>
      _value('attendancePreviewCancelButton');
  String get attendancePreviewHoursLabel =>
      _value('attendancePreviewHoursLabel');
  String get attendancePreviewSalaryLabel =>
      _value('attendancePreviewSalaryLabel');
  String get attendancePreviewValidationPrompt =>
      _value('attendancePreviewValidationPrompt');
  String get attendancePreviewFetchFailed =>
      _value('attendancePreviewFetchFailed');
  String get attendanceDateLabel => _value('attendanceDateLabel');
  String get attendanceEntryTypeLabel =>
      _value('attendanceEntryTypeLabel');
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
  String workActivatedWithName(String workName) =>
      _valueWithArgs('workActivatedWithNameMessage', {
        'workName': workName,
      });
  String get workNameLabel => _value('workNameLabel');
  String get workNameHint => _value('workNameHint');
  String get workNameTooShortValidation =>
      _value('workNameTooShortValidation');
  String get hourlySalaryLabel => _value('hourlySalaryLabel');
  String get hourlySalaryHint => _value('hourlySalaryHint');
  String get hourlyRateNegativeValidation =>
      _value('hourlyRateNegativeValidation');
  String get contractWorkHeader => _value('contractWorkHeader');
  String get contractHistoryButton => _value('contractHistoryButton');
  String get addContractWorkButton => _value('addContractWorkButton');
  String get contractWorkDescription => _value('contractWorkDescription');
  String get cancelButton => _value('cancelButton');
  String get saveButtonLabel => _value('saveButtonLabel');
  String get saveWorkButton => _value('saveWorkButton');
  String get saveChangesButton => _value('saveChangesButton');
  String get deleteWorkButton => _value('deleteWorkButton');
  String get workNameRequiredMessage => _value('workNameRequiredMessage');
  String get workAddedMessage => _value('workAddedMessage');
  String get workUpdatedMessage => _value('workUpdatedMessage');
  String get invalidHourlyRateMessage => _value('invalidHourlyRateMessage');
  String get editWorkTitle => _value('editWorkTitle');
  String get editWorkSubtitle => _value('editWorkSubtitle');
  String get editWorkDetailsTitle => _value('editWorkDetailsTitle');
  String get editWorkDetailsSubtitle =>
      _value('editWorkDetailsSubtitle');
  String get updateWorkButton => _value('updateWorkButton');
  String get editWorkTooltip => _value('editWorkTooltip');
  String get workDeleteConfirmationTitle =>
      _value('workDeleteConfirmationTitle');
  String get workDeleteConfirmationMessage =>
      _value('workDeleteConfirmationMessage');
  String get workDeleteConfirmButton => _value('workDeleteConfirmButton');
  String get workDeleteCancelButton => _value('workDeleteCancelButton');
  String get workDeleteIrreversibleMessage =>
      _value('workDeleteIrreversibleMessage');
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
  String get loginPhoneTab => _value('loginPhoneTab');
  String get loginEmailTab => _value('loginEmailTab');
  String get loginIdentifierLabel => _value('loginIdentifierLabel');
  String get loginIdentifierHint => _value('loginIdentifierHint');
  String get loginPhoneLabel => _value('loginPhoneLabel');
  String get loginPhoneHint => _value('loginPhoneHint');
  String get loginEmailLabel => _value('loginEmailLabel');
  String get loginEmailHint => _value('loginEmailHint');
  String get emailLabel => _value('emailLabel');
  String get emailHint => _value('emailHint');
  String get passwordLabel => _value('passwordLabel');
  String get passwordHint => _value('passwordHint');
  String get loginButton => _value('loginButton');
  String get forgotPassword => _value('forgotPassword');
  String get forgotPasswordSubtitle => _value('forgotPasswordSubtitle');
  String get forgotPasswordFieldLabel => _value('forgotPasswordFieldLabel');
  String get forgotPasswordFieldHint => _value('forgotPasswordFieldHint');
  String get sendOtpButton => _value('sendOtpButton');
  String get backToLogin => _value('backToLogin');
  String get signupPromptPrefix => _value('signupPromptPrefix');
  String get signupPromptAction => _value('signupPromptAction');
  String get changeLanguage => _value('changeLanguage');
  String get snackEnterLoginIdentifier => _value('snackEnterLoginIdentifier');
  String get snackEnterValidLoginIdentifier => _value('snackEnterValidLoginIdentifier');
  String get snackEnterPhone => _value('snackEnterPhone');
  String get snackEnterValidPhone => _value('snackEnterValidPhone');
  String get snackEnterEmail => _value('snackEnterEmail');
  String get snackEnterValidEmail => _value('snackEnterValidEmail');
  String get snackEnterPassword => _value('snackEnterPassword');
  String get snackLoginSuccess => _value('snackLoginSuccess');
  String get snackResetEmail => _value('snackResetEmail');
  String get snackForgotInvalidEmail => _value('snackForgotInvalidEmail');
  String get signupTitle => _value('signupTitle');
  String get fullNameLabel => _value('fullNameLabel');
  String get usernameLabel => _value('usernameLabel');
  String get usernameHint => _value('usernameHint');
  String get usernameRequired => _value('usernameRequired');
  String get usernameInvalid => _value('usernameInvalid');
  String get nameRequired => _value('nameRequired');
  String get emailAddressLabel => _value('emailAddressLabel');
  String get emailRequired => _value('emailRequired');
  String get emailInvalid => _value('emailInvalid');
  String get countryCodeLabel => _value('countryCodeLabel');
  String get phoneNumberLabel => _value('phoneNumberLabel');
  String get phoneNumberHint => _value('phoneNumberHint');
  String get phoneRequired => _value('phoneRequired');
  String get phoneInvalid => _value('phoneInvalid');
  String get languageLabel => _value('languageLabel');
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
  String get searchCountryCodes => _value('searchCountryCodes');
  String get noCountryCodeResults => _value('noCountryCodeResults');
  String get policyLoadFailed => _value('policyLoadFailed');
  String get policyRetryButton => _value('policyRetryButton');
  String get policyLastUpdatedLabel => _value('policyLastUpdatedLabel');
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
  String get resendPromptQuestion => _value('resendPromptQuestion');
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