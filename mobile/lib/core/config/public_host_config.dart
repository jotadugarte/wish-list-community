// Staging/public host for deep links + legal URLs (O8A/O9B).
// Swap to production host before App Store / Play submit.
class PublicHostConfig {
  static const String stagingHost = String.fromEnvironment(
    'PUBLIC_WEB_HOST',
    defaultValue: 'staging.wishlist.local',
  );

  static Uri termsUri({String locale = 'es'}) =>
      Uri.https(stagingHost, '/terms', {'locale': locale});

  static Uri privacyUri({String locale = 'es'}) =>
      Uri.https(stagingHost, '/privacy', {'locale': locale});

  static Set<String> get allowedDeepLinkHosts => {
        stagingHost,
        'localhost',
        '127.0.0.1',
      };
}
