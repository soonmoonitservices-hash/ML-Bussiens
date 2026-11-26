import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Fehler, die die Oberfläche anzeigt. Eigene Meldungen der App werden über
/// [AppErrorText.localized] übersetzt; Meldungen der Datenbank sind schon
/// deutsch und werden 1:1 angezeigt.
sealed class AppError {
  const AppError(this.message);

  /// Deutscher Text für Logs und als Rückfall.
  final String message;
}

final class NetworkError extends AppError {
  const NetworkError() : super('Keine Internetverbindung');
}

/// Grund eines fehlgeschlagenen Logins.
enum AuthFailureKind { invalidCredentials, codeExpired, codeInvalid, generic }

final class AuthenticationError extends AppError {
  const AuthenticationError(this.kind, super.message);

  final AuthFailureKind kind;
}

final class DatabaseError extends AppError {
  const DatabaseError(super.message);
}

final class ConflictError extends AppError {
  ConflictError(this.changedBy)
    : super(
        changedBy == null
            ? 'Der Datensatz wurde inzwischen geändert. Bitte neu laden.'
            : 'Wurde inzwischen von $changedBy geändert. Bitte neu laden.',
      );

  final String? changedBy;
}

final class ConflictException implements Exception {
  const ConflictException(this.changedBy);

  final String? changedBy;
}

final class UnexpectedError extends AppError {
  /// [detail] ist die technische Meldung (zeigt z. B. die PDF-Vorschau an).
  const UnexpectedError([String? detail])
    : super(detail ?? 'Ein unerwarteter Fehler ist aufgetreten.');
}

/// Text eines Fehlers in der Sprache der App.
extension AppErrorText on AppError {
  String localized(AppLocalizations strings) => switch (this) {
    NetworkError() => strings.noInternet,
    UnexpectedError() => strings.unknownError,
    ConflictError(:final changedBy) =>
      changedBy == null ? strings.conflict : strings.conflictBy(changedBy),
    AuthenticationError(:final kind) => switch (kind) {
      AuthFailureKind.invalidCredentials => strings.invalidCredentials,
      AuthFailureKind.codeExpired => strings.codeExpired,
      AuthFailureKind.codeInvalid => strings.codeInvalid,
      AuthFailureKind.generic => strings.authFailed,
    },
    DatabaseError(:final message) => message,
  };
}
