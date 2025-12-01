/// Test helpers and configurations for integration tests
/// This file provides utilities to make the app more testable
// Flag to skip loading screens during testing
bool skipLoadingScreens = false;

// Flag to skip onboarding screen during testing
bool skipOnboardingScreen = false;

/// Call this at the start of integration tests to optimize for testing
void configureForTesting() {
  skipLoadingScreens = true;
  skipOnboardingScreen = true;
}

/// Call this to reset configuration after tests
void resetTestConfiguration() {
  skipLoadingScreens = false;
  skipOnboardingScreen = false;
}
