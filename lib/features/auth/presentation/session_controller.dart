import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/features/auth/data/auth_repository.dart';
import 'package:warenbestand/features/auth/domain/app_profile.dart';

final class SessionController extends ChangeNotifier {
  SessionController(this._repository) {
    _subscription = _repository.authChanges.listen((_) => refresh());
  }

  final AuthRepository _repository;
  StreamSubscription<Object?>? _subscription;
  AppProfile? profile;
  bool profileLoaded = false;
  bool isSuperadmin = false;

  /// Die Firma ist gesperrt: der Benutzer wurde abgemeldet (Hinweis im Login).
  bool blockedNotice = false;

  bool get isAuthenticated => _repository.currentSession != null;
  bool get isChef => profile?.isChef ?? false;

  /// Darf alles verwalten (Firmendaten, Benutzer, Touren wieder öffnen, Stornos):
  /// Chef und Verwaltung haben gleiche Rechte.
  bool get canManage => profile != null;

  Future<void> refresh() async {
    profileLoaded = false;
    if (!isAuthenticated) {
      profile = null;
      isSuperadmin = false;
      profileLoaded = true;
      notifyListeners();
      return;
    }
    final result = await _repository.loadProfile();
    switch (result) {
      case Success(value: final loadedProfile):
        if (!loadedProfile.active) {
          await _repository.signOut();
          profile = null;
        } else {
          profile = loadedProfile;
          blockedNotice = false;
          final superResult = await _repository.isSuperadmin();
          isSuperadmin = superResult is Success<bool> && superResult.value;
        }
      case Failure(:final error):
        profile = null;
        isSuperadmin = false;
        // Ohne Verbindung bleibt der Benutzer angemeldet. Sonst findet die Datenbank
        // kein Profil: die Firma ist gesperrt.
        if (error is! NetworkError) {
          blockedNotice = true;
          await _repository.signOut();
        }
    }
    profileLoaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
