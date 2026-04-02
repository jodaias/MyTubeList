class AppConstants {
  AppConstants._();

  // Animações & Durações
  static const Duration splashAnimationDuration = Duration(seconds: 2);
  static const Duration splashRedirectDelay = Duration(seconds: 3);
  static const Duration gestureFeedbackAnimation = Duration(milliseconds: 90);
  static const Duration gestureFeedbackHide = Duration(milliseconds: 600);
  static const Duration lockButtonAnimation = Duration(milliseconds: 220);
  static const Duration unlockButtonTimeout = Duration(seconds: 5);
  static const Duration scrollAnimation = Duration(milliseconds: 300);
  static const Duration scrollEnsureVisible = Duration(milliseconds: 200);
  static const Duration skipFeedbackDuration = Duration(seconds: 1);
  static const Duration playerControlsTimeout = Duration(seconds: 5);
  static const Duration landscapeListAnimation = Duration(milliseconds: 500);
  static const Duration videoListSyncDelay = Duration(milliseconds: 500);
  static const Duration scrollPostFrameDelay = Duration(milliseconds: 100);

  // Limites
  static const int maxSearchHistory = 5;
  static const int maxYoutubeResults = 50;
  static const int mathQuestionMin = 2;
  static const int mathQuestionRange = 8;

  // Validações
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 20;
  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 25;
  static const int profileNameMinLength = 2;
  static const int profileNameMaxLength = 30;

  // Grid Layout
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 1.1;
  static const double homeGridChildAspectRatio = 1.2;
  static const double gridSpacing = 8.0;

  // Player UI
  static const double gestureFeedbackBarHeight = 92.0;
  static const double lockButtonSize = 42.0;
  static const double percentTextWidth = 34.0;
  static const double percentTextHeight = 16.0;
  static const double skipIconSize = 80.0;
  static const double portraitListItemHeight = 76.0;
  static const double fullscreenListItemHeight = 116.0;
  static const double landscapeListWidthFraction = 0.25;
  static const double dragThresholdFraction = 0.8;

  // Splash UI
  static const double splashLogoWidth = 120.0;
  static const double splashTitleFontSize = 28.0;

  // Home UI
  static const double playlistIconSize = 48.0;
  static const double listNameFontSize = 16.0;

  // VideoCard UI
  static const double playButtonContainerSize = 50.0;
  static const double playButtonIconSize = 30.0;
  static const double selectionIconSize = 28.0;
  static const double videoTitleFontSize = 12.0;
  static const double addedTextFontSize = 10.0;
}
