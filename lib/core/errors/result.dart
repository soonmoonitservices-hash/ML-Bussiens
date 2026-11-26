import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/app_error.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppError error;
}

Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } on PostgrestException catch (error) {
    return Failure(DatabaseError(error.message));
  } on AuthException catch (error) {
    return Failure(_authError(error.message));
  } on SocketException {
    return const Failure(NetworkError());
  } on TimeoutException {
    return const Failure(NetworkError());
  } on ConflictException catch (error) {
    return Failure(ConflictError(error.changedBy));
  } on Object catch (error) {
    return Failure(UnexpectedError('$error'));
  }
}

AuthenticationError _authError(String message) {
  final normalized = message.toLowerCase();
  if (normalized.contains('invalid login') ||
      normalized.contains('invalid credentials')) {
    return AuthenticationError(AuthFailureKind.invalidCredentials, message);
  }
  if (normalized.contains('expired')) {
    return AuthenticationError(AuthFailureKind.codeExpired, message);
  }
  if (normalized.contains('token')) {
    return AuthenticationError(AuthFailureKind.codeInvalid, message);
  }
  return AuthenticationError(AuthFailureKind.generic, message);
}
