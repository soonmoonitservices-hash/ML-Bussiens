final class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.privacyUrl,
    required this.imprintUrl,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    flavor: String.fromEnvironment('FLAVOR'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    privacyUrl: String.fromEnvironment('PRIVACY_URL'),
    imprintUrl: String.fromEnvironment('IMPRINT_URL'),
  );

  final String flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String privacyUrl;
  final String imprintUrl;

  bool get isValid {
    final uri = Uri.tryParse(supabaseUrl);
    return (flavor == 'dev' || flavor == 'prod') &&
        uri != null &&
        uri.hasScheme &&
        supabaseAnonKey.isNotEmpty;
  }
}
