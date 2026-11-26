# Release

Vor einem Release müssen `flutter analyze`, `flutter test`,
`make test-backend`, ein Android-Gerätetest und ein iOS-Gerätetest erfolgreich
sein. Produktions-Builds verwenden `config/prod.json`, das nicht versioniert
wird. Build-Ziele: `make build-android` und auf macOS `make build-ios`.

Zusätzlich sind Signierung, finale Icons/Splash-Grafiken, Store-Texte,
Datenschutzangaben, Demo-Zugang und die Pflichtupdate-Konfiguration zu prüfen.
Der aktuelle Funktionsstand ist in `docs/implementation_status.md` vermerkt;
offene Einträge verhindern eine Produktionsfreigabe.
