import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Warenbestand'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get login;

  /// No description provided for @email.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get email;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen'**
  String get forgotPassword;

  /// No description provided for @forgotEmailHint.
  ///
  /// In de, this message translates to:
  /// **'Wir senden einen Code an diese Adresse.'**
  String get forgotEmailHint;

  /// No description provided for @forgotCodeHint.
  ///
  /// In de, this message translates to:
  /// **'Code aus der E-Mail eingeben.'**
  String get forgotCodeHint;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen.'**
  String get forgotPasswordHint;

  /// No description provided for @sendCode.
  ///
  /// In de, this message translates to:
  /// **'Code senden'**
  String get sendCode;

  /// No description provided for @verifyCode.
  ///
  /// In de, this message translates to:
  /// **'Code prüfen'**
  String get verifyCode;

  /// No description provided for @verificationCode.
  ///
  /// In de, this message translates to:
  /// **'6-stelliger Code'**
  String get verificationCode;

  /// No description provided for @newPassword.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort'**
  String get newPassword;

  /// No description provided for @savePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort speichern'**
  String get savePassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen.'**
  String get passwordTooShort;

  /// No description provided for @logout.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get logout;

  /// No description provided for @backToLogin.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Anmeldung'**
  String get backToLogin;

  /// No description provided for @home.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get home;

  /// No description provided for @tours.
  ///
  /// In de, this message translates to:
  /// **'Touren'**
  String get tours;

  /// No description provided for @stock.
  ///
  /// In de, this message translates to:
  /// **'Bestand'**
  String get stock;

  /// No description provided for @reports.
  ///
  /// In de, this message translates to:
  /// **'Auswertungen'**
  String get reports;

  /// No description provided for @more.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get more;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @greetingMorning.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingDay.
  ///
  /// In de, this message translates to:
  /// **'Guten Tag, {name}'**
  String greetingDay(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend, {name}'**
  String greetingEvening(String name);

  /// No description provided for @areas.
  ///
  /// In de, this message translates to:
  /// **'Bereiche'**
  String get areas;

  /// No description provided for @onboardingStockTitle.
  ///
  /// In de, this message translates to:
  /// **'Produkte und Preise'**
  String get onboardingStockTitle;

  /// No description provided for @onboardingStockText.
  ///
  /// In de, this message translates to:
  /// **'Produkte mit Einheit, Kartongröße und Preisen anlegen.'**
  String get onboardingStockText;

  /// No description provided for @onboardingToursTitle.
  ///
  /// In de, this message translates to:
  /// **'Touren abrechnen'**
  String get onboardingToursTitle;

  /// No description provided for @onboardingToursText.
  ///
  /// In de, this message translates to:
  /// **'Ladung eintragen, Rückgabe erfassen, Kasse abgleichen.'**
  String get onboardingToursText;

  /// No description provided for @onboardingDocumentsTitle.
  ///
  /// In de, this message translates to:
  /// **'Belege und Rechnungen'**
  String get onboardingDocumentsTitle;

  /// No description provided for @onboardingDocumentsText.
  ///
  /// In de, this message translates to:
  /// **'Lieferscheine, Rechnungen und Ausgaben als PDF.'**
  String get onboardingDocumentsText;

  /// No description provided for @onboardingNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In de, this message translates to:
  /// **'Zur Anmeldung'**
  String get onboardingStart;

  /// No description provided for @onboardingPage.
  ///
  /// In de, this message translates to:
  /// **'{current} von {total}'**
  String onboardingPage(int current, int total);

  /// No description provided for @drivers.
  ///
  /// In de, this message translates to:
  /// **'Fahrer'**
  String get drivers;

  /// No description provided for @newDriver.
  ///
  /// In de, this message translates to:
  /// **'Fahrer anlegen'**
  String get newDriver;

  /// No description provided for @editDriver.
  ///
  /// In de, this message translates to:
  /// **'Fahrer bearbeiten'**
  String get editDriver;

  /// No description provided for @driverName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get driverName;

  /// No description provided for @phone.
  ///
  /// In de, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @vehicle.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug / Kennzeichen'**
  String get vehicle;

  /// No description provided for @active.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In de, this message translates to:
  /// **'Inaktiv'**
  String get inactive;

  /// No description provided for @noDrivers.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Fahrer.'**
  String get noDrivers;

  /// No description provided for @noResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer.'**
  String get noResults;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @deactivate.
  ///
  /// In de, this message translates to:
  /// **'Deaktivieren'**
  String get deactivate;

  /// No description provided for @reactivate.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren'**
  String get reactivate;

  /// No description provided for @search.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get search;

  /// No description provided for @requiredField.
  ///
  /// In de, this message translates to:
  /// **'Bitte ausfüllen.'**
  String get requiredField;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @reload.
  ///
  /// In de, this message translates to:
  /// **'Neu laden'**
  String get reload;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Lädt'**
  String get loading;

  /// No description provided for @conflict.
  ///
  /// In de, this message translates to:
  /// **'Der Datensatz wurde inzwischen geändert. Bitte neu laden.'**
  String get conflict;

  /// No description provided for @conflictBy.
  ///
  /// In de, this message translates to:
  /// **'Wurde inzwischen von {name} geändert. Bitte neu laden.'**
  String conflictBy(String name);

  /// No description provided for @noInternet.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung'**
  String get noInternet;

  /// No description provided for @configurationMissing.
  ///
  /// In de, this message translates to:
  /// **'Die App-Konfiguration fehlt oder ist ungültig.'**
  String get configurationMissing;

  /// No description provided for @accessDenied.
  ///
  /// In de, this message translates to:
  /// **'Nur für die Rolle Chef.'**
  String get accessDenied;

  /// No description provided for @featureUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht verfügbar.'**
  String get featureUnavailable;

  /// No description provided for @unknownError.
  ///
  /// In de, this message translates to:
  /// **'Ein unerwarteter Fehler ist aufgetreten.'**
  String get unknownError;

  /// No description provided for @invalidCredentials.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse oder Passwort ist falsch.'**
  String get invalidCredentials;

  /// No description provided for @codeExpired.
  ///
  /// In de, this message translates to:
  /// **'Der Code ist abgelaufen. Bitte neuen Code anfordern.'**
  String get codeExpired;

  /// No description provided for @codeInvalid.
  ///
  /// In de, this message translates to:
  /// **'Der Code ist ungültig.'**
  String get codeInvalid;

  /// No description provided for @authFailed.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung fehlgeschlagen.'**
  String get authFailed;

  /// No description provided for @codeSent.
  ///
  /// In de, this message translates to:
  /// **'Der Code wurde per E-Mail gesendet.'**
  String get codeSent;

  /// No description provided for @passwordChanged.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort wurde geändert.'**
  String get passwordChanged;

  /// No description provided for @cartons.
  ///
  /// In de, this message translates to:
  /// **'Kartons'**
  String get cartons;

  /// No description provided for @loosePieces.
  ///
  /// In de, this message translates to:
  /// **'Einzeln'**
  String get loosePieces;

  /// No description provided for @cashBalanced.
  ///
  /// In de, this message translates to:
  /// **'Kasse stimmt'**
  String get cashBalanced;

  /// No description provided for @shortfall.
  ///
  /// In de, this message translates to:
  /// **'Weniger Bargeld {amount}. Mindert den Gewinn.'**
  String shortfall(String amount);

  /// No description provided for @surplus.
  ///
  /// In de, this message translates to:
  /// **'Mehr Bargeld {amount}. Zählt zum Gewinn.'**
  String surplus(String amount);

  /// No description provided for @planTour.
  ///
  /// In de, this message translates to:
  /// **'Tour planen'**
  String get planTour;

  /// No description provided for @loadTour.
  ///
  /// In de, this message translates to:
  /// **'Tour beladen'**
  String get loadTour;

  /// No description provided for @tourDetails.
  ///
  /// In de, this message translates to:
  /// **'Tour'**
  String get tourDetails;

  /// No description provided for @closeTour.
  ///
  /// In de, this message translates to:
  /// **'Tour abschließen'**
  String get closeTour;

  /// No description provided for @stockIntake.
  ///
  /// In de, this message translates to:
  /// **'Wareneingang'**
  String get stockIntake;

  /// No description provided for @newProduct.
  ///
  /// In de, this message translates to:
  /// **'Produkt anlegen'**
  String get newProduct;

  /// No description provided for @productDetails.
  ///
  /// In de, this message translates to:
  /// **'Produkt'**
  String get productDetails;

  /// No description provided for @editProduct.
  ///
  /// In de, this message translates to:
  /// **'Produkt bearbeiten'**
  String get editProduct;

  /// No description provided for @correctStock.
  ///
  /// In de, this message translates to:
  /// **'Bestand korrigieren'**
  String get correctStock;

  /// No description provided for @importProducts.
  ///
  /// In de, this message translates to:
  /// **'CSV-Import'**
  String get importProducts;

  /// No description provided for @driverStats.
  ///
  /// In de, this message translates to:
  /// **'Fahrerstatistik'**
  String get driverStats;

  /// No description provided for @newExpense.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe erfassen'**
  String get newExpense;

  /// No description provided for @expenseDetails.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe'**
  String get expenseDetails;

  /// No description provided for @newDeliveryNote.
  ///
  /// In de, this message translates to:
  /// **'Lieferschein erstellen'**
  String get newDeliveryNote;

  /// No description provided for @deliveryNoteDetails.
  ///
  /// In de, this message translates to:
  /// **'Lieferschein'**
  String get deliveryNoteDetails;

  /// No description provided for @signDeliveryNote.
  ///
  /// In de, this message translates to:
  /// **'Unterschreiben'**
  String get signDeliveryNote;

  /// No description provided for @newInvoice.
  ///
  /// In de, this message translates to:
  /// **'Rechnung erstellen'**
  String get newInvoice;

  /// No description provided for @invoiceDetails.
  ///
  /// In de, this message translates to:
  /// **'Rechnung'**
  String get invoiceDetails;

  /// No description provided for @pdfPreview.
  ///
  /// In de, this message translates to:
  /// **'PDF-Vorschau'**
  String get pdfPreview;

  /// No description provided for @stockValue.
  ///
  /// In de, this message translates to:
  /// **'Lagerwert'**
  String get stockValue;

  /// No description provided for @productCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Produkt} other{{count} Produkte}}'**
  String productCount(int count);

  /// No description provided for @belowMinBanner.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Produkt unter Mindestbestand} other{{count} Produkte unter Mindestbestand}}'**
  String belowMinBanner(int count);

  /// No description provided for @searchProducts.
  ///
  /// In de, this message translates to:
  /// **'Produktname oder Artikelnummer'**
  String get searchProducts;

  /// No description provided for @filterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterAll;

  /// No description provided for @filterLow.
  ///
  /// In de, this message translates to:
  /// **'Knapp'**
  String get filterLow;

  /// No description provided for @filterInactive.
  ///
  /// In de, this message translates to:
  /// **'Inaktiv'**
  String get filterInactive;

  /// No description provided for @filterCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get filterCategory;

  /// No description provided for @allCategories.
  ///
  /// In de, this message translates to:
  /// **'Alle Kategorien'**
  String get allCategories;

  /// No description provided for @noProducts.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Produkte.'**
  String get noProducts;

  /// No description provided for @reorderHint.
  ///
  /// In de, this message translates to:
  /// **'Produkt lange drücken und ziehen oder auf die Nummer tippen und eine Position eintragen. Die Reihenfolge wird sofort gespeichert und gilt auch in Touren, Lieferscheinen und Rechnungen.'**
  String get reorderHint;

  /// No description provided for @reorderStart.
  ///
  /// In de, this message translates to:
  /// **'Reihenfolge ändern'**
  String get reorderStart;

  /// No description provided for @reorderSaved.
  ///
  /// In de, this message translates to:
  /// **'Reihenfolge gespeichert'**
  String get reorderSaved;

  /// No description provided for @reorderPositionTitle.
  ///
  /// In de, this message translates to:
  /// **'Neue Position'**
  String get reorderPositionTitle;

  /// No description provided for @reorderPositionHint.
  ///
  /// In de, this message translates to:
  /// **'Nummer von 1 bis {max}'**
  String reorderPositionHint(int max);

  /// No description provided for @low.
  ///
  /// In de, this message translates to:
  /// **'Knapp'**
  String get low;

  /// No description provided for @menu.
  ///
  /// In de, this message translates to:
  /// **'Menü'**
  String get menu;

  /// No description provided for @stockLabel.
  ///
  /// In de, this message translates to:
  /// **'Bestand'**
  String get stockLabel;

  /// No description provided for @minStockLabel.
  ///
  /// In de, this message translates to:
  /// **'Mindestbestand'**
  String get minStockLabel;

  /// No description provided for @pricesSection.
  ///
  /// In de, this message translates to:
  /// **'Preise'**
  String get pricesSection;

  /// No description provided for @buyPriceNet.
  ///
  /// In de, this message translates to:
  /// **'Einkauf netto'**
  String get buyPriceNet;

  /// No description provided for @sellPriceNet.
  ///
  /// In de, this message translates to:
  /// **'Verkauf netto'**
  String get sellPriceNet;

  /// No description provided for @margin.
  ///
  /// In de, this message translates to:
  /// **'Marge'**
  String get margin;

  /// No description provided for @vatRate.
  ///
  /// In de, this message translates to:
  /// **'USt'**
  String get vatRate;

  /// No description provided for @movementsSection.
  ///
  /// In de, this message translates to:
  /// **'Bewegungen'**
  String get movementsSection;

  /// No description provided for @noMovements.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bewegungen.'**
  String get noMovements;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @skuLabel.
  ///
  /// In de, this message translates to:
  /// **'Artikelnummer'**
  String get skuLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get categoryLabel;

  /// No description provided for @movementIntake.
  ///
  /// In de, this message translates to:
  /// **'Wareneingang'**
  String get movementIntake;

  /// No description provided for @movementTourOut.
  ///
  /// In de, this message translates to:
  /// **'Tour'**
  String get movementTourOut;

  /// No description provided for @movementTourReturn.
  ///
  /// In de, this message translates to:
  /// **'Rückgabe'**
  String get movementTourReturn;

  /// No description provided for @movementTourUndo.
  ///
  /// In de, this message translates to:
  /// **'Tour zurückgenommen'**
  String get movementTourUndo;

  /// No description provided for @movementInvoice.
  ///
  /// In de, this message translates to:
  /// **'Rechnung'**
  String get movementInvoice;

  /// No description provided for @movementInvoiceCancel.
  ///
  /// In de, this message translates to:
  /// **'Storno'**
  String get movementInvoiceCancel;

  /// No description provided for @movementCorrection.
  ///
  /// In de, this message translates to:
  /// **'Korrektur'**
  String get movementCorrection;

  /// No description provided for @productName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get productName;

  /// No description provided for @unitLabel.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get unitLabel;

  /// No description provided for @unitCarton.
  ///
  /// In de, this message translates to:
  /// **'Karton'**
  String get unitCarton;

  /// No description provided for @unitPiece.
  ///
  /// In de, this message translates to:
  /// **'Stück'**
  String get unitPiece;

  /// No description provided for @unitJar.
  ///
  /// In de, this message translates to:
  /// **'Glas'**
  String get unitJar;

  /// No description provided for @unitKg.
  ///
  /// In de, this message translates to:
  /// **'Kilogramm'**
  String get unitKg;

  /// No description provided for @unitsPerCarton.
  ///
  /// In de, this message translates to:
  /// **'Stück pro Karton'**
  String get unitsPerCarton;

  /// No description provided for @buyPriceField.
  ///
  /// In de, this message translates to:
  /// **'Einkaufspreis netto'**
  String get buyPriceField;

  /// No description provided for @sellPriceField.
  ///
  /// In de, this message translates to:
  /// **'Verkaufspreis netto'**
  String get sellPriceField;

  /// No description provided for @priceHint.
  ///
  /// In de, this message translates to:
  /// **'Preis pro Einheit, bei kg pro Kilogramm.'**
  String get priceHint;

  /// No description provided for @initialStock.
  ///
  /// In de, this message translates to:
  /// **'Anfangsbestand'**
  String get initialStock;

  /// No description provided for @invalidAmount.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger Betrag.'**
  String get invalidAmount;

  /// No description provided for @saved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert.'**
  String get saved;

  /// No description provided for @chooseProduct.
  ///
  /// In de, this message translates to:
  /// **'Produkt wählen'**
  String get chooseProduct;

  /// No description provided for @quantityLabel.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get quantityLabel;

  /// No description provided for @noteLabel.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get noteLabel;

  /// No description provided for @newStockPreview.
  ///
  /// In de, this message translates to:
  /// **'Neuer Bestand: {text}'**
  String newStockPreview(String text);

  /// No description provided for @bookIntake.
  ///
  /// In de, this message translates to:
  /// **'Wareneingang buchen'**
  String get bookIntake;

  /// No description provided for @intakeBooked.
  ///
  /// In de, this message translates to:
  /// **'Wareneingang gebucht.'**
  String get intakeBooked;

  /// No description provided for @quantityMustBePositive.
  ///
  /// In de, this message translates to:
  /// **'Die Menge muss größer als 0 sein.'**
  String get quantityMustBePositive;

  /// No description provided for @currentStock.
  ///
  /// In de, this message translates to:
  /// **'Aktuell'**
  String get currentStock;

  /// No description provided for @newStockLabel.
  ///
  /// In de, this message translates to:
  /// **'Neuer Bestand'**
  String get newStockLabel;

  /// No description provided for @differenceLabel.
  ///
  /// In de, this message translates to:
  /// **'Differenz'**
  String get differenceLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In de, this message translates to:
  /// **'Begründung (optional)'**
  String get reasonLabel;

  /// No description provided for @reasonBreakage.
  ///
  /// In de, this message translates to:
  /// **'Bruch'**
  String get reasonBreakage;

  /// No description provided for @reasonInventory.
  ///
  /// In de, this message translates to:
  /// **'Inventur'**
  String get reasonInventory;

  /// No description provided for @reasonOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get reasonOther;

  /// No description provided for @reasonRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Begründung angeben.'**
  String get reasonRequired;

  /// No description provided for @bookCorrection.
  ///
  /// In de, this message translates to:
  /// **'Korrektur buchen'**
  String get bookCorrection;

  /// No description provided for @correctionBooked.
  ///
  /// In de, this message translates to:
  /// **'Korrektur gebucht.'**
  String get correctionBooked;

  /// No description provided for @cartonsExpression.
  ///
  /// In de, this message translates to:
  /// **'= {text}'**
  String cartonsExpression(String text);

  /// No description provided for @unitCartonOne.
  ///
  /// In de, this message translates to:
  /// **'Karton'**
  String get unitCartonOne;

  /// No description provided for @unitJarOne.
  ///
  /// In de, this message translates to:
  /// **'Glas'**
  String get unitJarOne;

  /// No description provided for @unitJarMany.
  ///
  /// In de, this message translates to:
  /// **'Gläser'**
  String get unitJarMany;

  /// No description provided for @unitKgShort.
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get unitKgShort;

  /// No description provided for @toursSearch.
  ///
  /// In de, this message translates to:
  /// **'Fahrer oder Tour-Nr.'**
  String get toursSearch;

  /// No description provided for @notAvailable.
  ///
  /// In de, this message translates to:
  /// **'–'**
  String get notAvailable;

  /// No description provided for @tourStatusDraft.
  ///
  /// In de, this message translates to:
  /// **'Geplant'**
  String get tourStatusDraft;

  /// No description provided for @tourStatusActive.
  ///
  /// In de, this message translates to:
  /// **'Unterwegs'**
  String get tourStatusActive;

  /// No description provided for @tourStatusClosed.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get tourStatusClosed;

  /// No description provided for @noTours.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Touren.'**
  String get noTours;

  /// No description provided for @stepOf.
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total}'**
  String stepOf(int current, int total);

  /// No description provided for @stepDetails.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get stepDetails;

  /// No description provided for @stepLoad.
  ///
  /// In de, this message translates to:
  /// **'Beladung'**
  String get stepLoad;

  /// No description provided for @driverLabel.
  ///
  /// In de, this message translates to:
  /// **'Fahrer'**
  String get driverLabel;

  /// No description provided for @chooseDriver.
  ///
  /// In de, this message translates to:
  /// **'Fahrer wählen'**
  String get chooseDriver;

  /// No description provided for @plannedAtLabel.
  ///
  /// In de, this message translates to:
  /// **'Datum und Uhrzeit'**
  String get plannedAtLabel;

  /// No description provided for @tourNameOptional.
  ///
  /// In de, this message translates to:
  /// **'Tourname (optional)'**
  String get tourNameOptional;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @availableStock.
  ///
  /// In de, this message translates to:
  /// **'Bestand: {text}'**
  String availableStock(String text);

  /// No description provided for @addProduct.
  ///
  /// In de, this message translates to:
  /// **'Produkt hinzufügen'**
  String get addProduct;

  /// No description provided for @pickPerKilogram.
  ///
  /// In de, this message translates to:
  /// **'Pro Kilogramm'**
  String get pickPerKilogram;

  /// No description provided for @remove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get remove;

  /// No description provided for @loadValueBuy.
  ///
  /// In de, this message translates to:
  /// **'Warenwert Einkauf'**
  String get loadValueBuy;

  /// No description provided for @loadValueSell.
  ///
  /// In de, this message translates to:
  /// **'Warenwert Verkauf'**
  String get loadValueSell;

  /// No description provided for @expectedProfit.
  ///
  /// In de, this message translates to:
  /// **'Erwarteter Gewinn'**
  String get expectedProfit;

  /// No description provided for @stockNotEnough.
  ///
  /// In de, this message translates to:
  /// **'Für {name} ist nicht genug Bestand da.'**
  String stockNotEnough(String name);

  /// No description provided for @startTour.
  ///
  /// In de, this message translates to:
  /// **'Tour starten'**
  String get startTour;

  /// No description provided for @saveDraft.
  ///
  /// In de, this message translates to:
  /// **'Als Entwurf speichern'**
  String get saveDraft;

  /// No description provided for @confirmStartTour.
  ///
  /// In de, this message translates to:
  /// **'Ware wird vom Lager abgebucht.'**
  String get confirmStartTour;

  /// No description provided for @noItemsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Produkte.'**
  String get noItemsYet;

  /// No description provided for @tourLoad.
  ///
  /// In de, this message translates to:
  /// **'Ladung'**
  String get tourLoad;

  /// No description provided for @tourValues.
  ///
  /// In de, this message translates to:
  /// **'Werte'**
  String get tourValues;

  /// No description provided for @expectedRevenue.
  ///
  /// In de, this message translates to:
  /// **'Erwarteter Umsatz'**
  String get expectedRevenue;

  /// No description provided for @tourStarted.
  ///
  /// In de, this message translates to:
  /// **'Tour gestartet.'**
  String get tourStarted;

  /// No description provided for @draftSaved.
  ///
  /// In de, this message translates to:
  /// **'Entwurf gespeichert.'**
  String get draftSaved;

  /// No description provided for @draftRestored.
  ///
  /// In de, this message translates to:
  /// **'Dein angefangener Entwurf ist wieder da. Du kannst genau dort weitermachen.'**
  String get draftRestored;

  /// No description provided for @undoStart.
  ///
  /// In de, this message translates to:
  /// **'Start rückgängig'**
  String get undoStart;

  /// No description provided for @confirmUndoStart.
  ///
  /// In de, this message translates to:
  /// **'Die Ware wird wieder ins Lager gebucht.'**
  String get confirmUndoStart;

  /// No description provided for @reopenTour.
  ///
  /// In de, this message translates to:
  /// **'Wieder öffnen'**
  String get reopenTour;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @confirmDeleteDraft.
  ///
  /// In de, this message translates to:
  /// **'Diesen Entwurf löschen?'**
  String get confirmDeleteDraft;

  /// No description provided for @revenue.
  ///
  /// In de, this message translates to:
  /// **'Umsatz'**
  String get revenue;

  /// No description provided for @expectedCash.
  ///
  /// In de, this message translates to:
  /// **'Soll-Bargeld'**
  String get expectedCash;

  /// No description provided for @cashReceived.
  ///
  /// In de, this message translates to:
  /// **'Übergebenes Bargeld'**
  String get cashReceived;

  /// No description provided for @costOfGoods.
  ///
  /// In de, this message translates to:
  /// **'Wareneinsatz'**
  String get costOfGoods;

  /// No description provided for @profit.
  ///
  /// In de, this message translates to:
  /// **'Gewinn'**
  String get profit;

  /// No description provided for @startedAtLabel.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get startedAtLabel;

  /// No description provided for @closedAtLabel.
  ///
  /// In de, this message translates to:
  /// **'Ende'**
  String get closedAtLabel;

  /// No description provided for @tourNumberLabel.
  ///
  /// In de, this message translates to:
  /// **'Tour-Nr.'**
  String get tourNumberLabel;

  /// No description provided for @noDriversAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine aktiven Fahrer.'**
  String get noDriversAvailable;

  /// No description provided for @soldLabel.
  ///
  /// In de, this message translates to:
  /// **'Verkauft'**
  String get soldLabel;

  /// No description provided for @returnedLabel.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get returnedLabel;

  /// No description provided for @loadedLabel.
  ///
  /// In de, this message translates to:
  /// **'Geladen'**
  String get loadedLabel;

  /// No description provided for @closeInfo.
  ///
  /// In de, this message translates to:
  /// **'Verkauft = Geladen − Zurück.'**
  String get closeInfo;

  /// No description provided for @returnedQty.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get returnedQty;

  /// No description provided for @loadedValue.
  ///
  /// In de, this message translates to:
  /// **'Geladen: {text}'**
  String loadedValue(String text);

  /// No description provided for @soldValue.
  ///
  /// In de, this message translates to:
  /// **'Verkauft: {text} · {amount}'**
  String soldValue(String text, String amount);

  /// No description provided for @addExpense.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe hinzufügen'**
  String get addExpense;

  /// No description provided for @expenseType.
  ///
  /// In de, this message translates to:
  /// **'Art'**
  String get expenseType;

  /// No description provided for @expenseDiesel.
  ///
  /// In de, this message translates to:
  /// **'Diesel'**
  String get expenseDiesel;

  /// No description provided for @expenseMeal.
  ///
  /// In de, this message translates to:
  /// **'Essen'**
  String get expenseMeal;

  /// No description provided for @expenseParking.
  ///
  /// In de, this message translates to:
  /// **'Parken'**
  String get expenseParking;

  /// No description provided for @expenseOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get expenseOther;

  /// No description provided for @amountGross.
  ///
  /// In de, this message translates to:
  /// **'Betrag brutto'**
  String get amountGross;

  /// No description provided for @cashFromDriver.
  ///
  /// In de, this message translates to:
  /// **'Bargeld vom Fahrer'**
  String get cashFromDriver;

  /// No description provided for @returnTooHigh.
  ///
  /// In de, this message translates to:
  /// **'Für {name} ist mehr zurück als geladen.'**
  String returnTooHigh(String name);

  /// No description provided for @confirmCloseTour.
  ///
  /// In de, this message translates to:
  /// **'Die Tour wird abgeschlossen und gesperrt.'**
  String get confirmCloseTour;

  /// No description provided for @confirmClose.
  ///
  /// In de, this message translates to:
  /// **'Abschluss bestätigen'**
  String get confirmClose;

  /// No description provided for @tourClosed.
  ///
  /// In de, this message translates to:
  /// **'Tour abgeschlossen.'**
  String get tourClosed;

  /// No description provided for @differenceReasonRequired.
  ///
  /// In de, this message translates to:
  /// **'Bei einer Differenz ist eine Begründung nötig.'**
  String get differenceReasonRequired;

  /// No description provided for @cashRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte das übergebene Bargeld eintragen.'**
  String get cashRequired;

  /// No description provided for @deliveryNotesSearch.
  ///
  /// In de, this message translates to:
  /// **'Empfänger oder Nummer'**
  String get deliveryNotesSearch;

  /// No description provided for @filterSigned.
  ///
  /// In de, this message translates to:
  /// **'Unterschrieben'**
  String get filterSigned;

  /// No description provided for @filterOpenNotes.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get filterOpenNotes;

  /// No description provided for @statusSigned.
  ///
  /// In de, this message translates to:
  /// **'Unterschrieben'**
  String get statusSigned;

  /// No description provided for @statusDraft.
  ///
  /// In de, this message translates to:
  /// **'Entwurf'**
  String get statusDraft;

  /// No description provided for @noDeliveryNotes.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Lieferscheine.'**
  String get noDeliveryNotes;

  /// No description provided for @recipientName.
  ///
  /// In de, this message translates to:
  /// **'Empfänger'**
  String get recipientName;

  /// No description provided for @recipientAddress.
  ///
  /// In de, this message translates to:
  /// **'Adresse'**
  String get recipientAddress;

  /// No description provided for @dateLabel.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get dateLabel;

  /// No description provided for @tourOptional.
  ///
  /// In de, this message translates to:
  /// **'Tour (optional)'**
  String get tourOptional;

  /// No description provided for @chooseTour.
  ///
  /// In de, this message translates to:
  /// **'Tour wählen'**
  String get chooseTour;

  /// No description provided for @noTour.
  ///
  /// In de, this message translates to:
  /// **'Keine Tour'**
  String get noTour;

  /// No description provided for @tourItemsTaken.
  ///
  /// In de, this message translates to:
  /// **'Die Produkte der Tour wurden übernommen.'**
  String get tourItemsTaken;

  /// No description provided for @showPreview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get showPreview;

  /// No description provided for @showPdf.
  ///
  /// In de, this message translates to:
  /// **'PDF ansehen'**
  String get showPdf;

  /// No description provided for @signAction.
  ///
  /// In de, this message translates to:
  /// **'Unterschreiben'**
  String get signAction;

  /// No description provided for @signConfirmText.
  ///
  /// In de, this message translates to:
  /// **'Empfang der Ware bestätigt.'**
  String get signConfirmText;

  /// No description provided for @signerName.
  ///
  /// In de, this message translates to:
  /// **'Name des Unterzeichners'**
  String get signerName;

  /// No description provided for @clearSignature.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get clearSignature;

  /// No description provided for @takeSignature.
  ///
  /// In de, this message translates to:
  /// **'Unterschrift übernehmen'**
  String get takeSignature;

  /// No description provided for @signHere.
  ///
  /// In de, this message translates to:
  /// **'Hier unterschreiben'**
  String get signHere;

  /// No description provided for @signatureMissing.
  ///
  /// In de, this message translates to:
  /// **'Bitte unterschreiben.'**
  String get signatureMissing;

  /// No description provided for @signerRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte den Namen eintragen.'**
  String get signerRequired;

  /// No description provided for @signedDone.
  ///
  /// In de, this message translates to:
  /// **'Unterschrieben.'**
  String get signedDone;

  /// No description provided for @createInvoiceFromNote.
  ///
  /// In de, this message translates to:
  /// **'Rechnung daraus erstellen'**
  String get createInvoiceFromNote;

  /// No description provided for @share.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get share;

  /// No description provided for @print.
  ///
  /// In de, this message translates to:
  /// **'Drucken'**
  String get print;

  /// No description provided for @signedBy.
  ///
  /// In de, this message translates to:
  /// **'{name}, {date}'**
  String signedBy(String name, String date);

  /// No description provided for @confirmDeleteNote.
  ///
  /// In de, this message translates to:
  /// **'Diesen Lieferschein löschen?'**
  String get confirmDeleteNote;

  /// No description provided for @itemsRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte mindestens ein Produkt mit Menge eintragen.'**
  String get itemsRequired;

  /// No description provided for @pdfNotStored.
  ///
  /// In de, this message translates to:
  /// **'Unterschrieben, das PDF wurde noch nicht abgelegt.'**
  String get pdfNotStored;

  /// No description provided for @expensesSummary.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Beleg} other{{count} Belege}} · netto {net}'**
  String expensesSummary(int count, String net);

  /// No description provided for @filterTourCosts.
  ///
  /// In de, this message translates to:
  /// **'Tourkosten'**
  String get filterTourCosts;

  /// No description provided for @filterOtherExpenses.
  ///
  /// In de, this message translates to:
  /// **'Sonstige'**
  String get filterOtherExpenses;

  /// No description provided for @withReceipt.
  ///
  /// In de, this message translates to:
  /// **'Beleg'**
  String get withReceipt;

  /// No description provided for @withoutReceipt.
  ///
  /// In de, this message translates to:
  /// **'Ohne Beleg'**
  String get withoutReceipt;

  /// No description provided for @exportMonthPdf.
  ///
  /// In de, this message translates to:
  /// **'Monat als PDF exportieren'**
  String get exportMonthPdf;

  /// No description provided for @noExpenses.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausgaben in diesem Monat.'**
  String get noExpenses;

  /// No description provided for @previousMonth.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Monat'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In de, this message translates to:
  /// **'Nächster Monat'**
  String get nextMonth;

  /// No description provided for @takePhoto.
  ///
  /// In de, this message translates to:
  /// **'Beleg fotografieren'**
  String get takePhoto;

  /// No description provided for @pickFromGallery.
  ///
  /// In de, this message translates to:
  /// **'Aus Galerie'**
  String get pickFromGallery;

  /// No description provided for @scanReceipt.
  ///
  /// In de, this message translates to:
  /// **'Beleg scannen'**
  String get scanReceipt;

  /// No description provided for @removePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto entfernen'**
  String get removePhoto;

  /// No description provided for @expenseTitle.
  ///
  /// In de, this message translates to:
  /// **'Bezeichnung'**
  String get expenseTitle;

  /// No description provided for @netAmount.
  ///
  /// In de, this message translates to:
  /// **'Netto: {amount}'**
  String netAmount(String amount);

  /// No description provided for @categoryVehicle.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug & Kraftstoff'**
  String get categoryVehicle;

  /// No description provided for @categoryRent.
  ///
  /// In de, this message translates to:
  /// **'Miete'**
  String get categoryRent;

  /// No description provided for @categoryMaintenance.
  ///
  /// In de, this message translates to:
  /// **'Wartung'**
  String get categoryMaintenance;

  /// No description provided for @categoryMeals.
  ///
  /// In de, this message translates to:
  /// **'Verpflegung'**
  String get categoryMeals;

  /// No description provided for @categoryOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get categoryOther;

  /// No description provided for @shareAsPdf.
  ///
  /// In de, this message translates to:
  /// **'Als PDF teilen'**
  String get shareAsPdf;

  /// No description provided for @photoFailed.
  ///
  /// In de, this message translates to:
  /// **'Das Foto konnte nicht verarbeitet werden.'**
  String get photoFailed;

  /// No description provided for @confirmDeleteExpense.
  ///
  /// In de, this message translates to:
  /// **'Diese Ausgabe löschen?'**
  String get confirmDeleteExpense;

  /// No description provided for @tourCostsLocked.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe einer Tour.'**
  String get tourCostsLocked;

  /// No description provided for @viewImage.
  ///
  /// In de, this message translates to:
  /// **'Beleg ansehen'**
  String get viewImage;

  /// No description provided for @netLabel.
  ///
  /// In de, this message translates to:
  /// **'Netto'**
  String get netLabel;

  /// No description provided for @invoicesSearch.
  ///
  /// In de, this message translates to:
  /// **'Empfänger oder Rechnungsnummer'**
  String get invoicesSearch;

  /// No description provided for @filterPaid.
  ///
  /// In de, this message translates to:
  /// **'Bezahlt'**
  String get filterPaid;

  /// No description provided for @filterOverdue.
  ///
  /// In de, this message translates to:
  /// **'Überfällig'**
  String get filterOverdue;

  /// No description provided for @filterDrafts.
  ///
  /// In de, this message translates to:
  /// **'Entwürfe'**
  String get filterDrafts;

  /// No description provided for @statusOpenInvoice.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get statusOpenInvoice;

  /// No description provided for @statusPaid.
  ///
  /// In de, this message translates to:
  /// **'Bezahlt'**
  String get statusPaid;

  /// No description provided for @statusOverdue.
  ///
  /// In de, this message translates to:
  /// **'Überfällig'**
  String get statusOverdue;

  /// No description provided for @statusCancelled.
  ///
  /// In de, this message translates to:
  /// **'Storniert'**
  String get statusCancelled;

  /// No description provided for @openSummary.
  ///
  /// In de, this message translates to:
  /// **'{count} überfällig'**
  String openSummary(int count);

  /// No description provided for @noInvoices.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Rechnungen.'**
  String get noInvoices;

  /// No description provided for @recipientVatId.
  ///
  /// In de, this message translates to:
  /// **'USt-IdNr. des Empfängers (optional)'**
  String get recipientVatId;

  /// No description provided for @invoiceDateLabel.
  ///
  /// In de, this message translates to:
  /// **'Rechnungsdatum'**
  String get invoiceDateLabel;

  /// No description provided for @serviceDateLabel.
  ///
  /// In de, this message translates to:
  /// **'Leistungsdatum'**
  String get serviceDateLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In de, this message translates to:
  /// **'Fällig am'**
  String get dueDateLabel;

  /// No description provided for @paymentTermInfo.
  ///
  /// In de, this message translates to:
  /// **'Zahlungsziel {days} Tage, fällig {date}'**
  String paymentTermInfo(int days, String date);

  /// No description provided for @positionsSection.
  ///
  /// In de, this message translates to:
  /// **'Positionen'**
  String get positionsSection;

  /// No description provided for @addFreeItem.
  ///
  /// In de, this message translates to:
  /// **'Freie Position'**
  String get addFreeItem;

  /// No description provided for @itemName.
  ///
  /// In de, this message translates to:
  /// **'Bezeichnung'**
  String get itemName;

  /// No description provided for @itemUnit.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get itemUnit;

  /// No description provided for @unitPriceNetField.
  ///
  /// In de, this message translates to:
  /// **'Preis netto'**
  String get unitPriceNetField;

  /// No description provided for @lineTotal.
  ///
  /// In de, this message translates to:
  /// **'Summe: {amount}'**
  String lineTotal(String amount);

  /// No description provided for @vat7Row.
  ///
  /// In de, this message translates to:
  /// **'USt 7 %'**
  String get vat7Row;

  /// No description provided for @vat19Row.
  ///
  /// In de, this message translates to:
  /// **'USt 19 %'**
  String get vat19Row;

  /// No description provided for @grossTotal.
  ///
  /// In de, this message translates to:
  /// **'Gesamt brutto'**
  String get grossTotal;

  /// No description provided for @invoiceNote.
  ///
  /// In de, this message translates to:
  /// **'Hinweistext'**
  String get invoiceNote;

  /// No description provided for @finalizeAction.
  ///
  /// In de, this message translates to:
  /// **'Festschreiben'**
  String get finalizeAction;

  /// No description provided for @confirmFinalize.
  ///
  /// In de, this message translates to:
  /// **'Nach dem Festschreiben nicht mehr änderbar.'**
  String get confirmFinalize;

  /// No description provided for @invoiceFinalized.
  ///
  /// In de, this message translates to:
  /// **'Rechnung {number} festgeschrieben.'**
  String invoiceFinalized(String number);

  /// No description provided for @markPaid.
  ///
  /// In de, this message translates to:
  /// **'Als bezahlt markieren'**
  String get markPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In de, this message translates to:
  /// **'Wieder auf offen setzen'**
  String get markUnpaid;

  /// No description provided for @cancelInvoiceAction.
  ///
  /// In de, this message translates to:
  /// **'Stornieren'**
  String get cancelInvoiceAction;

  /// No description provided for @confirmCancelInvoice.
  ///
  /// In de, this message translates to:
  /// **'Eine Stornorechnung wird erstellt und die Ware zurück ins Lager gebucht.'**
  String get confirmCancelInvoice;

  /// No description provided for @invoiceCancelled.
  ///
  /// In de, this message translates to:
  /// **'Storniert.'**
  String get invoiceCancelled;

  /// No description provided for @paidAtLabel.
  ///
  /// In de, this message translates to:
  /// **'Bezahlt am'**
  String get paidAtLabel;

  /// No description provided for @deliveryNoteRefLabel.
  ///
  /// In de, this message translates to:
  /// **'Lieferschein'**
  String get deliveryNoteRefLabel;

  /// No description provided for @cancellationOfLabel.
  ///
  /// In de, this message translates to:
  /// **'Storno zu'**
  String get cancellationOfLabel;

  /// No description provided for @invoiceDraftTitle.
  ///
  /// In de, this message translates to:
  /// **'Rechnungsentwurf'**
  String get invoiceDraftTitle;

  /// No description provided for @smallBusinessHint.
  ///
  /// In de, this message translates to:
  /// **'Kleinunternehmer: keine Umsatzsteuer.'**
  String get smallBusinessHint;

  /// No description provided for @freeItemName.
  ///
  /// In de, this message translates to:
  /// **'Bezeichnung der Position'**
  String get freeItemName;

  /// No description provided for @rangeDay.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get rangeDay;

  /// No description provided for @rangeWeek.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get rangeMonth;

  /// No description provided for @rangeYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get rangeYear;

  /// No description provided for @rangeCustom.
  ///
  /// In de, this message translates to:
  /// **'Eigener'**
  String get rangeCustom;

  /// No description provided for @weekShort.
  ///
  /// In de, this message translates to:
  /// **'KW'**
  String get weekShort;

  /// No description provided for @kpiSection.
  ///
  /// In de, this message translates to:
  /// **'Kennzahlen'**
  String get kpiSection;

  /// No description provided for @changeToPrevious.
  ///
  /// In de, this message translates to:
  /// **'{percent} % zum Vorzeitraum'**
  String changeToPrevious(String percent);

  /// No description provided for @chartRevenueVsExpenses.
  ///
  /// In de, this message translates to:
  /// **'Umsatz und Ausgaben'**
  String get chartRevenueVsExpenses;

  /// No description provided for @topProducts.
  ///
  /// In de, this message translates to:
  /// **'Top-Produkte'**
  String get topProducts;

  /// No description provided for @expensesByCategory.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben nach Kategorie'**
  String get expensesByCategory;

  /// No description provided for @reportPdf.
  ///
  /// In de, this message translates to:
  /// **'Bericht als PDF'**
  String get reportPdf;

  /// No description provided for @noReportData.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten in diesem Zeitraum.'**
  String get noReportData;

  /// No description provided for @averagePerTour.
  ///
  /// In de, this message translates to:
  /// **'Ø pro Tour'**
  String get averagePerTour;

  /// No description provided for @returnRate.
  ///
  /// In de, this message translates to:
  /// **'Rücklaufquote'**
  String get returnRate;

  /// No description provided for @differences.
  ///
  /// In de, this message translates to:
  /// **'Kassendifferenzen'**
  String get differences;

  /// No description provided for @expenses.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get expenses;

  /// No description provided for @deliveryNotes.
  ///
  /// In de, this message translates to:
  /// **'Lieferscheine'**
  String get deliveryNotes;

  /// No description provided for @invoices.
  ///
  /// In de, this message translates to:
  /// **'Rechnungen'**
  String get invoices;

  /// No description provided for @users.
  ///
  /// In de, this message translates to:
  /// **'Benutzer'**
  String get users;

  /// No description provided for @company.
  ///
  /// In de, this message translates to:
  /// **'Firmendaten'**
  String get company;

  /// No description provided for @account.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get account;

  /// No description provided for @help.
  ///
  /// In de, this message translates to:
  /// **'Hilfe'**
  String get help;

  /// No description provided for @products.
  ///
  /// In de, this message translates to:
  /// **'Produkte'**
  String get products;

  /// No description provided for @updateRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte aktualisieren'**
  String get updateRequired;

  /// No description provided for @noConnection.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung'**
  String get noConnection;

  /// No description provided for @discardChangesTitle.
  ///
  /// In de, this message translates to:
  /// **'Änderungen verwerfen?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In de, this message translates to:
  /// **'Nicht gespeicherte Eingaben gehen verloren.'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discard;

  /// No description provided for @checkAmount.
  ///
  /// In de, this message translates to:
  /// **'Bitte Betrag prüfen. Die Differenz ist größer als 50 €.'**
  String get checkAmount;

  /// No description provided for @onRoadToday.
  ///
  /// In de, this message translates to:
  /// **'Heute unterwegs'**
  String get onRoadToday;

  /// No description provided for @noTourOnRoad.
  ///
  /// In de, this message translates to:
  /// **'Keine Tour unterwegs'**
  String get noTourOnRoad;

  /// No description provided for @monthOverview.
  ///
  /// In de, this message translates to:
  /// **'Monatsübersicht'**
  String get monthOverview;

  /// No description provided for @tileToursSub.
  ///
  /// In de, this message translates to:
  /// **'Planen und abrechnen'**
  String get tileToursSub;

  /// No description provided for @tileStockSub.
  ///
  /// In de, this message translates to:
  /// **'Produkte und Preise'**
  String get tileStockSub;

  /// No description provided for @tileExpensesSub.
  ///
  /// In de, this message translates to:
  /// **'Belege und Ausgaben'**
  String get tileExpensesSub;

  /// No description provided for @tileDeliverySub.
  ///
  /// In de, this message translates to:
  /// **'Erstellen und unterschreiben'**
  String get tileDeliverySub;

  /// No description provided for @companyName.
  ///
  /// In de, this message translates to:
  /// **'Firmenname'**
  String get companyName;

  /// No description provided for @companyAddress.
  ///
  /// In de, this message translates to:
  /// **'Anschrift'**
  String get companyAddress;

  /// No description provided for @taxNumber.
  ///
  /// In de, this message translates to:
  /// **'Steuernummer'**
  String get taxNumber;

  /// No description provided for @vatId.
  ///
  /// In de, this message translates to:
  /// **'USt-IdNr.'**
  String get vatId;

  /// No description provided for @iban.
  ///
  /// In de, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @bic.
  ///
  /// In de, this message translates to:
  /// **'BIC'**
  String get bic;

  /// No description provided for @bankName.
  ///
  /// In de, this message translates to:
  /// **'Bank'**
  String get bankName;

  /// No description provided for @managingDirector.
  ///
  /// In de, this message translates to:
  /// **'Geschäftsführer'**
  String get managingDirector;

  /// No description provided for @paymentTermDays.
  ///
  /// In de, this message translates to:
  /// **'Zahlungsziel in Tagen'**
  String get paymentTermDays;

  /// No description provided for @invoiceFooter.
  ///
  /// In de, this message translates to:
  /// **'Text unter der Rechnung'**
  String get invoiceFooter;

  /// No description provided for @cashIncludesVat.
  ///
  /// In de, this message translates to:
  /// **'Fahrer kassiert Bruttopreise'**
  String get cashIncludesVat;

  /// No description provided for @smallBusiness.
  ///
  /// In de, this message translates to:
  /// **'Kleinunternehmer (§ 19 UStG)'**
  String get smallBusiness;

  /// No description provided for @smallBusinessNote.
  ///
  /// In de, this message translates to:
  /// **'Hinweis auf der Rechnung'**
  String get smallBusinessNote;

  /// No description provided for @companySaved.
  ///
  /// In de, this message translates to:
  /// **'Firmendaten gespeichert'**
  String get companySaved;

  /// No description provided for @companyOnlyChef.
  ///
  /// In de, this message translates to:
  /// **'Nur der Chef kann die Firmendaten ändern.'**
  String get companyOnlyChef;

  /// No description provided for @accountName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get accountName;

  /// No description provided for @role.
  ///
  /// In de, this message translates to:
  /// **'Rolle'**
  String get role;

  /// No description provided for @roleChef.
  ///
  /// In de, this message translates to:
  /// **'Chef'**
  String get roleChef;

  /// No description provided for @roleOffice.
  ///
  /// In de, this message translates to:
  /// **'Verwaltung'**
  String get roleOffice;

  /// No description provided for @changePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort ändern'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto und der Zugang werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get deleteAccountMessage;

  /// No description provided for @nameSaved.
  ///
  /// In de, this message translates to:
  /// **'Name gespeichert'**
  String get nameSaved;

  /// No description provided for @usersHint.
  ///
  /// In de, this message translates to:
  /// **'Benutzer deiner Firma. Sie sehen dieselben Daten und dürfen alles wie du.'**
  String get usersHint;

  /// No description provided for @makeChef.
  ///
  /// In de, this message translates to:
  /// **'Zum Chef machen'**
  String get makeChef;

  /// No description provided for @makeOffice.
  ///
  /// In de, this message translates to:
  /// **'Zur Verwaltung machen'**
  String get makeOffice;

  /// No description provided for @helpTourTitle.
  ///
  /// In de, this message translates to:
  /// **'Tour planen und abrechnen'**
  String get helpTourTitle;

  /// No description provided for @helpTourText.
  ///
  /// In de, this message translates to:
  /// **'Fahrer wählen, Produkte und Mengen eintragen, Tour starten. Nach der Rückkehr Rückgaben und Bargeld eintragen, dann Tour abschließen. Verkauft ist Geladen minus Zurück. Soll-Bargeld ist Umsatz minus Ausgaben.'**
  String get helpTourText;

  /// No description provided for @helpStockTitle.
  ///
  /// In de, this message translates to:
  /// **'Produkte'**
  String get helpStockTitle;

  /// No description provided for @helpStockText.
  ///
  /// In de, this message translates to:
  /// **'Lege Produkte mit Einheit, Kartongröße und Preisen an. Einen Lagerbestand gibt es nicht: Beim Beladen trägst du nur ein, wie viel mitfährt.'**
  String get helpStockText;

  /// No description provided for @helpDocsTitle.
  ///
  /// In de, this message translates to:
  /// **'Lieferschein und Rechnung'**
  String get helpDocsTitle;

  /// No description provided for @helpDocsText.
  ///
  /// In de, this message translates to:
  /// **'Lieferscheine lässt du unterschreiben und teilst sie als PDF. Eine Rechnung kannst du bis zum Festschreiben ändern; die Mehrwertsteuer wählst du je Position. Alles lässt sich löschen, auch Touren und Rechnungen. Bei festgeschriebenen Rechnungen fragt die App vorher nach, weil sie aufbewahrt werden müssen.'**
  String get helpDocsText;

  /// No description provided for @helpExpensesTitle.
  ///
  /// In de, this message translates to:
  /// **'Belege'**
  String get helpExpensesTitle;

  /// No description provided for @helpExpensesText.
  ///
  /// In de, this message translates to:
  /// **'Beleg fotografieren, Betrag und Kategorie eintragen, speichern. Im Monat siehst du alle Belege und kannst sie als PDF an den Steuerberater schicken.'**
  String get helpExpensesText;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get yesterday;

  /// No description provided for @dueToday.
  ///
  /// In de, this message translates to:
  /// **'heute fällig'**
  String get dueToday;

  /// No description provided for @dueInDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{fällig in 1 Tag} other{fällig in {count} Tagen}}'**
  String dueInDays(int count);

  /// No description provided for @overdueSinceDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{seit 1 Tag überfällig} other{seit {count} Tagen überfällig}}'**
  String overdueSinceDays(int count);

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @languageDevice.
  ///
  /// In de, this message translates to:
  /// **'Gerät'**
  String get languageDevice;

  /// No description provided for @bundles.
  ///
  /// In de, this message translates to:
  /// **'Mischkartons'**
  String get bundles;

  /// No description provided for @newBundle.
  ///
  /// In de, this message translates to:
  /// **'Neuer Mischkarton'**
  String get newBundle;

  /// No description provided for @editBundle.
  ///
  /// In de, this message translates to:
  /// **'Mischkarton bearbeiten'**
  String get editBundle;

  /// No description provided for @bundleName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get bundleName;

  /// No description provided for @bundleContents.
  ///
  /// In de, this message translates to:
  /// **'Inhalt'**
  String get bundleContents;

  /// No description provided for @noBundles.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Mischkartons.'**
  String get noBundles;

  /// No description provided for @bundleHint.
  ///
  /// In de, this message translates to:
  /// **'Ein Mischkarton wird beim Beladen in seine Produkte aufgelöst. Der Bestand dieser Produkte sinkt.'**
  String get bundleHint;

  /// No description provided for @bundleNeedsProduct.
  ///
  /// In de, this message translates to:
  /// **'Mindestens ein Produkt hinzufügen.'**
  String get bundleNeedsProduct;

  /// No description provided for @confirmDeleteBundle.
  ///
  /// In de, this message translates to:
  /// **'Diesen Mischkarton löschen? Der Bestand ändert sich dadurch nicht.'**
  String get confirmDeleteBundle;

  /// No description provided for @addBundle.
  ///
  /// In de, this message translates to:
  /// **'Mischkarton hinzufügen'**
  String get addBundle;

  /// No description provided for @bundleCountTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie viele Mischkartons?'**
  String get bundleCountTitle;

  /// No description provided for @bundleCount.
  ///
  /// In de, this message translates to:
  /// **'Anzahl'**
  String get bundleCount;

  /// No description provided for @bundleProductMissing.
  ///
  /// In de, this message translates to:
  /// **'Ein Produkt des Mischkartons ist nicht mehr aktiv und wurde nicht hinzugefügt.'**
  String get bundleProductMissing;

  /// No description provided for @navReports.
  ///
  /// In de, this message translates to:
  /// **'Berichte'**
  String get navReports;

  /// No description provided for @gifts.
  ///
  /// In de, this message translates to:
  /// **'Geschenkte Produkte'**
  String get gifts;

  /// No description provided for @addGift.
  ///
  /// In de, this message translates to:
  /// **'Geschenk hinzufügen'**
  String get addGift;

  /// No description provided for @giftMax.
  ///
  /// In de, this message translates to:
  /// **'Höchstens {max} möglich. Geschenke bringen keinen Umsatz.'**
  String giftMax(String max);

  /// No description provided for @newUser.
  ///
  /// In de, this message translates to:
  /// **'Neuer Benutzer'**
  String get newUser;

  /// No description provided for @newUserHint.
  ///
  /// In de, this message translates to:
  /// **'Der Benutzer sieht dieselben Daten wie du und darf alles. Gib ihm das Passwort weiter; er kann es später im Konto ändern.'**
  String get newUserHint;

  /// No description provided for @createUser.
  ///
  /// In de, this message translates to:
  /// **'Benutzer anlegen'**
  String get createUser;

  /// No description provided for @userCreated.
  ///
  /// In de, this message translates to:
  /// **'Benutzer angelegt'**
  String get userCreated;

  /// No description provided for @select.
  ///
  /// In de, this message translates to:
  /// **'Auswählen'**
  String get select;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @selectAll.
  ///
  /// In de, this message translates to:
  /// **'Alle auswählen'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In de, this message translates to:
  /// **'Auswahl aufheben'**
  String get deselectAll;

  /// No description provided for @selectionCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String selectionCount(int count);

  /// No description provided for @exportSelectionPdf.
  ///
  /// In de, this message translates to:
  /// **'Auswahl als PDF'**
  String get exportSelectionPdf;

  /// No description provided for @tileProductsSub.
  ///
  /// In de, this message translates to:
  /// **'Produkte und Preise'**
  String get tileProductsSub;

  /// No description provided for @confirmDeleteTour.
  ///
  /// In de, this message translates to:
  /// **'Diese Tour wird mit allen Positionen und Ausgaben endgültig gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get confirmDeleteTour;

  /// No description provided for @confirmDeleteSignedNote.
  ///
  /// In de, this message translates to:
  /// **'Dieser unterschriebene Lieferschein wird endgültig gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get confirmDeleteSignedNote;

  /// No description provided for @confirmDeleteInvoice.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Eine festgeschriebene Rechnung muss in Deutschland 8 Jahre aufbewahrt werden. Wenn du sie löschst, fehlt ihre Nummer und das lässt sich nicht rückgängig machen. Wirklich löschen?'**
  String get confirmDeleteInvoice;

  /// No description provided for @receiptCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Beleg} other{{count} Belege}}'**
  String receiptCount(int count);

  /// No description provided for @unitCartonHint.
  ///
  /// In de, this message translates to:
  /// **'Für Kartons und einzelne Gläser oder Stück: Einheit Glas oder Stück wählen und eintragen, wie viele in einen Karton passen. Beim Beladen und Abschließen gibst du dann Kartons und Stück getrennt ein.'**
  String get unitCartonHint;

  /// No description provided for @companyIncomplete.
  ///
  /// In de, this message translates to:
  /// **'Deine Firmendaten sind noch nicht vollständig. Für Rechnungen brauchst du Firmenname, Anschrift und Steuernummer oder USt-IdNr.'**
  String get companyIncomplete;

  /// No description provided for @fillCompany.
  ///
  /// In de, this message translates to:
  /// **'Jetzt ausfüllen'**
  String get fillCompany;

  /// No description provided for @platform.
  ///
  /// In de, this message translates to:
  /// **'Firmen verwalten'**
  String get platform;

  /// No description provided for @platformHint.
  ///
  /// In de, this message translates to:
  /// **'Als Superadmin legst du Chefs mit eigener Firma an, sperrst Firmen oder löschst sie endgültig.'**
  String get platformHint;

  /// No description provided for @userForMyCompany.
  ///
  /// In de, this message translates to:
  /// **'Zu meiner Firma'**
  String get userForMyCompany;

  /// No description provided for @userNewCompany.
  ///
  /// In de, this message translates to:
  /// **'Neue Firma'**
  String get userNewCompany;

  /// No description provided for @newCompanyUserHint.
  ///
  /// In de, this message translates to:
  /// **'Der Benutzer bekommt eine eigene, neue Firma mit allen Funktionen und wird dort Chef. Er sieht nur seine eigenen Daten, du siehst nichts von seiner Firma. Gib ihm das Passwort weiter und bitte ihn, es nach der ersten Anmeldung im Konto zu ändern. Anschrift und Steuernummer seiner Firma trägt er danach selbst ein.'**
  String get newCompanyUserHint;

  /// No description provided for @companyUserCreated.
  ///
  /// In de, this message translates to:
  /// **'Firma und Chef angelegt'**
  String get companyUserCreated;

  /// No description provided for @noFirms.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Firmen.'**
  String get noFirms;

  /// No description provided for @blockFirm.
  ///
  /// In de, this message translates to:
  /// **'Firma sperren'**
  String get blockFirm;

  /// No description provided for @unblockFirm.
  ///
  /// In de, this message translates to:
  /// **'Firma freigeben'**
  String get unblockFirm;

  /// No description provided for @firmBlocked.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get firmBlocked;

  /// No description provided for @deleteFirm.
  ///
  /// In de, this message translates to:
  /// **'Firma endgültig löschen'**
  String get deleteFirm;

  /// No description provided for @deleteFirmMessage.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten, Dateien und Benutzer der Firma „{name}“ werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.'**
  String deleteFirmMessage(String name);

  /// No description provided for @typeNameToConfirm.
  ///
  /// In de, this message translates to:
  /// **'Zur Bestätigung den Firmennamen eingeben'**
  String get typeNameToConfirm;

  /// No description provided for @deleteFirmConfirm.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteFirmConfirm;

  /// No description provided for @firmDeleted.
  ///
  /// In de, this message translates to:
  /// **'Firma gelöscht'**
  String get firmDeleted;

  /// No description provided for @usersCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Benutzer} other{{count} Benutzer}}'**
  String usersCount(int count);

  /// No description provided for @accessBlocked.
  ///
  /// In de, this message translates to:
  /// **'Dein Zugang ist gesperrt. Bitte wende dich an den Betreiber.'**
  String get accessBlocked;

  /// No description provided for @nameGerman.
  ///
  /// In de, this message translates to:
  /// **'Name (Deutsch)'**
  String get nameGerman;

  /// No description provided for @nameArabic.
  ///
  /// In de, this message translates to:
  /// **'Name (Arabisch)'**
  String get nameArabic;

  /// No description provided for @nameRequired.
  ///
  /// In de, this message translates to:
  /// **'Mindestens ein Name ist nötig.'**
  String get nameRequired;

  /// No description provided for @nameHint.
  ///
  /// In de, this message translates to:
  /// **'Deutsch und Arabisch sind möglich, ein Name genügt. Die App zeigt den Namen in der Sprache der Oberfläche.'**
  String get nameHint;

  /// No description provided for @cartonContents.
  ///
  /// In de, this message translates to:
  /// **'Inhalt des Kartons'**
  String get cartonContents;

  /// No description provided for @cartonContentsHint.
  ///
  /// In de, this message translates to:
  /// **'Welche Produkte in welcher Menge im Karton stecken. Du kannst Produkte hinzufügen, entfernen und die Mengen ändern.'**
  String get cartonContentsHint;

  /// No description provided for @noContents.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Inhalt.'**
  String get noContents;

  /// No description provided for @cartonRemovalsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einzelne Produkte aus dem Karton'**
  String get cartonRemovalsTitle;

  /// No description provided for @cartonRemovalsHint.
  ///
  /// In de, this message translates to:
  /// **'Was aus diesem Karton einzeln zurückkommt oder verschenkt wird. Der Umsatz sinkt um den Verkaufspreis dieser Produkte.'**
  String get cartonRemovalsHint;

  /// No description provided for @removedGift.
  ///
  /// In de, this message translates to:
  /// **'Geschenkt'**
  String get removedGift;

  /// No description provided for @removalTooMany.
  ///
  /// In de, this message translates to:
  /// **'Es sind mehr einzelne Produkte entfernt, als in den Kartons stecken.'**
  String get removalTooMany;

  /// No description provided for @soldGoods.
  ///
  /// In de, this message translates to:
  /// **'Verkaufte Ware'**
  String get soldGoods;

  /// No description provided for @returnedGoods.
  ///
  /// In de, this message translates to:
  /// **'Zurückgeholte Ware'**
  String get returnedGoods;

  /// No description provided for @shareGoodsPdf.
  ///
  /// In de, this message translates to:
  /// **'Als PDF teilen'**
  String get shareGoodsPdf;

  /// No description provided for @noGoods.
  ///
  /// In de, this message translates to:
  /// **'Keine Ware.'**
  String get noGoods;

  /// No description provided for @goodsTotal.
  ///
  /// In de, this message translates to:
  /// **'Gesamtpreis'**
  String get goodsTotal;

  /// No description provided for @removalLabel.
  ///
  /// In de, this message translates to:
  /// **'{content} (aus {carton})'**
  String removalLabel(String content, String carton);

  /// No description provided for @tourSummaryPdf.
  ///
  /// In de, this message translates to:
  /// **'Tourabrechnung als PDF'**
  String get tourSummaryPdf;

  /// No description provided for @navDeliveryNote.
  ///
  /// In de, this message translates to:
  /// **'L-Schein'**
  String get navDeliveryNote;

  /// No description provided for @navInvoice.
  ///
  /// In de, this message translates to:
  /// **'Rechnung'**
  String get navInvoice;

  /// No description provided for @companySignature.
  ///
  /// In de, this message translates to:
  /// **'Unterschrift der Firma'**
  String get companySignature;

  /// No description provided for @signatureSize.
  ///
  /// In de, this message translates to:
  /// **'Größe der Unterschrift im PDF: {percent} %'**
  String signatureSize(int percent);

  /// No description provided for @signatureSmaller.
  ///
  /// In de, this message translates to:
  /// **'Kleiner'**
  String get signatureSmaller;

  /// No description provided for @signatureLarger.
  ///
  /// In de, this message translates to:
  /// **'Größer'**
  String get signatureLarger;

  /// No description provided for @companySignatureNone.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Unterschrift gespeichert.'**
  String get companySignatureNone;

  /// No description provided for @companySignatureDraw.
  ///
  /// In de, this message translates to:
  /// **'Unterschrift zeichnen'**
  String get companySignatureDraw;

  /// No description provided for @companySignatureRedraw.
  ///
  /// In de, this message translates to:
  /// **'Neue Unterschrift zeichnen'**
  String get companySignatureRedraw;

  /// No description provided for @companySignatureDelete.
  ///
  /// In de, this message translates to:
  /// **'Unterschrift löschen'**
  String get companySignatureDelete;

  /// No description provided for @companySignatureSaved.
  ///
  /// In de, this message translates to:
  /// **'Unterschrift gespeichert'**
  String get companySignatureSaved;

  /// No description provided for @companySignatureDeleted.
  ///
  /// In de, this message translates to:
  /// **'Unterschrift gelöscht'**
  String get companySignatureDeleted;

  /// No description provided for @signatureClear.
  ///
  /// In de, this message translates to:
  /// **'Neu beginnen'**
  String get signatureClear;

  /// No description provided for @signatureOnDeliveryNote.
  ///
  /// In de, this message translates to:
  /// **'Auf Lieferschein drucken'**
  String get signatureOnDeliveryNote;

  /// No description provided for @signatureOnInvoice.
  ///
  /// In de, this message translates to:
  /// **'Auf Rechnung drucken'**
  String get signatureOnInvoice;

  /// No description provided for @closeReturnHint.
  ///
  /// In de, this message translates to:
  /// **'Zurück in {unit} · höchstens {max}'**
  String closeReturnHint(String unit, String max);

  /// No description provided for @closeGiftHint.
  ///
  /// In de, this message translates to:
  /// **'Verschenkt in {unit} · höchstens {max}'**
  String closeGiftHint(String unit, String max);

  /// No description provided for @cartonContains.
  ///
  /// In de, this message translates to:
  /// **'1 Karton enthält: {items}'**
  String cartonContains(String items);

  /// No description provided for @soldResult.
  ///
  /// In de, this message translates to:
  /// **'Verkauft'**
  String get soldResult;

  /// No description provided for @closeStepLoad.
  ///
  /// In de, this message translates to:
  /// **'1 · Rückgabe der Ware'**
  String get closeStepLoad;

  /// No description provided for @closeStepGifts.
  ///
  /// In de, this message translates to:
  /// **'2 · Geschenke'**
  String get closeStepGifts;

  /// No description provided for @closeStepExpenses.
  ///
  /// In de, this message translates to:
  /// **'3 · Ausgaben'**
  String get closeStepExpenses;

  /// No description provided for @closeStepCash.
  ///
  /// In de, this message translates to:
  /// **'4 · Bargeld und Abrechnung'**
  String get closeStepCash;

  /// No description provided for @closeInfoNew.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf „Ware zurücknehmen“ und wähle einen Karton oder ein Produkt. Alles, was nicht zurückkommt, gilt als verkauft.'**
  String get closeInfoNew;

  /// No description provided for @takeOutAdd.
  ///
  /// In de, this message translates to:
  /// **'Ware zurücknehmen'**
  String get takeOutAdd;

  /// No description provided for @takeOutPick.
  ///
  /// In de, this message translates to:
  /// **'Was kommt zurück?'**
  String get takeOutPick;

  /// No description provided for @takeOutWhole.
  ///
  /// In de, this message translates to:
  /// **'Ganzer Karton'**
  String get takeOutWhole;

  /// No description provided for @takeOutSingles.
  ///
  /// In de, this message translates to:
  /// **'Einzelne Produkte'**
  String get takeOutSingles;

  /// No description provided for @takeOutSinglesHint.
  ///
  /// In de, this message translates to:
  /// **'Wie viel von jedem Produkt kommt aus dem Karton zurück oder wird verschenkt?'**
  String get takeOutSinglesHint;

  /// No description provided for @takeOutNone.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts zurückgenommen. Alles gilt als verkauft.'**
  String get takeOutNone;

  /// No description provided for @deleteManyTitle.
  ///
  /// In de, this message translates to:
  /// **'{count} löschen?'**
  String deleteManyTitle(int count);

  /// No description provided for @confirmDeleteMany.
  ///
  /// In de, this message translates to:
  /// **'Die gewählten Einträge werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get confirmDeleteMany;

  /// No description provided for @confirmDeleteManyInvoices.
  ///
  /// In de, this message translates to:
  /// **'Festgeschriebene Rechnungen müssen in Deutschland 8 Jahre aufbewahrt werden. Ihre Nummern fehlen danach.'**
  String get confirmDeleteManyInvoices;

  /// No description provided for @deletedMany.
  ///
  /// In de, this message translates to:
  /// **'{count} gelöscht'**
  String deletedMany(int count);

  /// No description provided for @deleteManyFailed.
  ///
  /// In de, this message translates to:
  /// **'{count} konnten nicht gelöscht werden.'**
  String deleteManyFailed(int count);

  /// No description provided for @pdfNothingSelected.
  ///
  /// In de, this message translates to:
  /// **'Wähle zuerst mindestens einen Eintrag.'**
  String get pdfNothingSelected;

  /// No description provided for @pdfNothingToShow.
  ///
  /// In de, this message translates to:
  /// **'Dafür gibt es noch nichts als PDF.'**
  String get pdfNothingToShow;

  /// No description provided for @pdfPleaseWait.
  ///
  /// In de, this message translates to:
  /// **'Bitte kurz warten, das PDF wird noch geladen.'**
  String get pdfPleaseWait;

  /// No description provided for @nothingToShare.
  ///
  /// In de, this message translates to:
  /// **'Dazu gibt es kein PDF. Bei Touren nur abgeschlossene.'**
  String get nothingToShare;

  /// No description provided for @pdfNoPreview.
  ///
  /// In de, this message translates to:
  /// **'Die Vorschau konnte nicht angezeigt werden. Teilen und Drucken gehen trotzdem.'**
  String get pdfNoPreview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
