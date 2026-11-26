// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Warenbestand';

  @override
  String get login => 'Anmelden';

  @override
  String get email => 'E-Mail-Adresse';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen';

  @override
  String get forgotEmailHint => 'Wir senden einen Code an diese Adresse.';

  @override
  String get forgotCodeHint => 'Code aus der E-Mail eingeben.';

  @override
  String get forgotPasswordHint => 'Mindestens 8 Zeichen.';

  @override
  String get sendCode => 'Code senden';

  @override
  String get verifyCode => 'Code prüfen';

  @override
  String get verificationCode => '6-stelliger Code';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get savePassword => 'Passwort speichern';

  @override
  String get passwordTooShort => 'Mindestens 8 Zeichen.';

  @override
  String get logout => 'Abmelden';

  @override
  String get backToLogin => 'Zurück zur Anmeldung';

  @override
  String get home => 'Start';

  @override
  String get tours => 'Touren';

  @override
  String get stock => 'Bestand';

  @override
  String get reports => 'Auswertungen';

  @override
  String get more => 'Mehr';

  @override
  String get back => 'Zurück';

  @override
  String greetingMorning(String name) {
    return 'Guten Morgen, $name';
  }

  @override
  String greetingDay(String name) {
    return 'Guten Tag, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Guten Abend, $name';
  }

  @override
  String get areas => 'Bereiche';

  @override
  String get onboardingStockTitle => 'Produkte und Preise';

  @override
  String get onboardingStockText =>
      'Produkte mit Einheit, Kartongröße und Preisen anlegen.';

  @override
  String get onboardingToursTitle => 'Touren abrechnen';

  @override
  String get onboardingToursText =>
      'Ladung eintragen, Rückgabe erfassen, Kasse abgleichen.';

  @override
  String get onboardingDocumentsTitle => 'Belege und Rechnungen';

  @override
  String get onboardingDocumentsText =>
      'Lieferscheine, Rechnungen und Ausgaben als PDF.';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingStart => 'Zur Anmeldung';

  @override
  String onboardingPage(int current, int total) {
    return '$current von $total';
  }

  @override
  String get drivers => 'Fahrer';

  @override
  String get newDriver => 'Fahrer anlegen';

  @override
  String get editDriver => 'Fahrer bearbeiten';

  @override
  String get driverName => 'Name';

  @override
  String get phone => 'Telefon';

  @override
  String get vehicle => 'Fahrzeug / Kennzeichen';

  @override
  String get active => 'Aktiv';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get noDrivers => 'Noch keine Fahrer.';

  @override
  String get noResults => 'Keine Treffer.';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'OK';

  @override
  String get deactivate => 'Deaktivieren';

  @override
  String get reactivate => 'Aktivieren';

  @override
  String get search => 'Suchen';

  @override
  String get requiredField => 'Bitte ausfüllen.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get reload => 'Neu laden';

  @override
  String get loading => 'Lädt';

  @override
  String get conflict =>
      'Der Datensatz wurde inzwischen geändert. Bitte neu laden.';

  @override
  String conflictBy(String name) {
    return 'Wurde inzwischen von $name geändert. Bitte neu laden.';
  }

  @override
  String get noInternet => 'Keine Internetverbindung';

  @override
  String get configurationMissing =>
      'Die App-Konfiguration fehlt oder ist ungültig.';

  @override
  String get accessDenied => 'Nur für die Rolle Chef.';

  @override
  String get featureUnavailable => 'Noch nicht verfügbar.';

  @override
  String get unknownError => 'Ein unerwarteter Fehler ist aufgetreten.';

  @override
  String get invalidCredentials => 'E-Mail-Adresse oder Passwort ist falsch.';

  @override
  String get codeExpired =>
      'Der Code ist abgelaufen. Bitte neuen Code anfordern.';

  @override
  String get codeInvalid => 'Der Code ist ungültig.';

  @override
  String get authFailed => 'Anmeldung fehlgeschlagen.';

  @override
  String get codeSent => 'Der Code wurde per E-Mail gesendet.';

  @override
  String get passwordChanged => 'Das Passwort wurde geändert.';

  @override
  String get cartons => 'Kartons';

  @override
  String get loosePieces => 'Einzeln';

  @override
  String get cashBalanced => 'Kasse stimmt';

  @override
  String shortfall(String amount) {
    return 'Weniger Bargeld $amount. Mindert den Gewinn.';
  }

  @override
  String surplus(String amount) {
    return 'Mehr Bargeld $amount. Zählt zum Gewinn.';
  }

  @override
  String get planTour => 'Tour planen';

  @override
  String get loadTour => 'Tour beladen';

  @override
  String get tourDetails => 'Tour';

  @override
  String get closeTour => 'Tour abschließen';

  @override
  String get stockIntake => 'Wareneingang';

  @override
  String get newProduct => 'Produkt anlegen';

  @override
  String get productDetails => 'Produkt';

  @override
  String get editProduct => 'Produkt bearbeiten';

  @override
  String get correctStock => 'Bestand korrigieren';

  @override
  String get importProducts => 'CSV-Import';

  @override
  String get driverStats => 'Fahrerstatistik';

  @override
  String get newExpense => 'Ausgabe erfassen';

  @override
  String get expenseDetails => 'Ausgabe';

  @override
  String get newDeliveryNote => 'Lieferschein erstellen';

  @override
  String get deliveryNoteDetails => 'Lieferschein';

  @override
  String get signDeliveryNote => 'Unterschreiben';

  @override
  String get newInvoice => 'Rechnung erstellen';

  @override
  String get invoiceDetails => 'Rechnung';

  @override
  String get pdfPreview => 'PDF-Vorschau';

  @override
  String get stockValue => 'Lagerwert';

  @override
  String productCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte',
      one: '1 Produkt',
    );
    return '$_temp0';
  }

  @override
  String belowMinBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte unter Mindestbestand',
      one: '1 Produkt unter Mindestbestand',
    );
    return '$_temp0';
  }

  @override
  String get searchProducts => 'Produktname oder Artikelnummer';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterLow => 'Knapp';

  @override
  String get filterInactive => 'Inaktiv';

  @override
  String get filterCategory => 'Kategorie';

  @override
  String get allCategories => 'Alle Kategorien';

  @override
  String get noProducts => 'Noch keine Produkte.';

  @override
  String get reorderHint =>
      'Produkt lange drücken und ziehen oder auf die Nummer tippen und eine Position eintragen. Die Reihenfolge wird sofort gespeichert und gilt auch in Touren, Lieferscheinen und Rechnungen.';

  @override
  String get reorderStart => 'Reihenfolge ändern';

  @override
  String get reorderSaved => 'Reihenfolge gespeichert';

  @override
  String get reorderPositionTitle => 'Neue Position';

  @override
  String reorderPositionHint(int max) {
    return 'Nummer von 1 bis $max';
  }

  @override
  String get low => 'Knapp';

  @override
  String get menu => 'Menü';

  @override
  String get stockLabel => 'Bestand';

  @override
  String get minStockLabel => 'Mindestbestand';

  @override
  String get pricesSection => 'Preise';

  @override
  String get buyPriceNet => 'Einkauf netto';

  @override
  String get sellPriceNet => 'Verkauf netto';

  @override
  String get margin => 'Marge';

  @override
  String get vatRate => 'USt';

  @override
  String get movementsSection => 'Bewegungen';

  @override
  String get noMovements => 'Noch keine Bewegungen.';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get skuLabel => 'Artikelnummer';

  @override
  String get categoryLabel => 'Kategorie';

  @override
  String get movementIntake => 'Wareneingang';

  @override
  String get movementTourOut => 'Tour';

  @override
  String get movementTourReturn => 'Rückgabe';

  @override
  String get movementTourUndo => 'Tour zurückgenommen';

  @override
  String get movementInvoice => 'Rechnung';

  @override
  String get movementInvoiceCancel => 'Storno';

  @override
  String get movementCorrection => 'Korrektur';

  @override
  String get productName => 'Name';

  @override
  String get unitLabel => 'Einheit';

  @override
  String get unitCarton => 'Karton';

  @override
  String get unitPiece => 'Stück';

  @override
  String get unitJar => 'Glas';

  @override
  String get unitKg => 'Kilogramm';

  @override
  String get unitsPerCarton => 'Stück pro Karton';

  @override
  String get buyPriceField => 'Einkaufspreis netto';

  @override
  String get sellPriceField => 'Verkaufspreis netto';

  @override
  String get priceHint => 'Preis pro Einheit, bei kg pro Kilogramm.';

  @override
  String get initialStock => 'Anfangsbestand';

  @override
  String get invalidAmount => 'Ungültiger Betrag.';

  @override
  String get saved => 'Gespeichert.';

  @override
  String get chooseProduct => 'Produkt wählen';

  @override
  String get quantityLabel => 'Menge';

  @override
  String get noteLabel => 'Notiz';

  @override
  String newStockPreview(String text) {
    return 'Neuer Bestand: $text';
  }

  @override
  String get bookIntake => 'Wareneingang buchen';

  @override
  String get intakeBooked => 'Wareneingang gebucht.';

  @override
  String get quantityMustBePositive => 'Die Menge muss größer als 0 sein.';

  @override
  String get currentStock => 'Aktuell';

  @override
  String get newStockLabel => 'Neuer Bestand';

  @override
  String get differenceLabel => 'Differenz';

  @override
  String get reasonLabel => 'Begründung (optional)';

  @override
  String get reasonBreakage => 'Bruch';

  @override
  String get reasonInventory => 'Inventur';

  @override
  String get reasonOther => 'Sonstiges';

  @override
  String get reasonRequired => 'Bitte eine Begründung angeben.';

  @override
  String get bookCorrection => 'Korrektur buchen';

  @override
  String get correctionBooked => 'Korrektur gebucht.';

  @override
  String cartonsExpression(String text) {
    return '= $text';
  }

  @override
  String get unitCartonOne => 'Karton';

  @override
  String get unitJarOne => 'Glas';

  @override
  String get unitJarMany => 'Gläser';

  @override
  String get unitKgShort => 'kg';

  @override
  String get toursSearch => 'Fahrer oder Tour-Nr.';

  @override
  String get notAvailable => '–';

  @override
  String get tourStatusDraft => 'Geplant';

  @override
  String get tourStatusActive => 'Unterwegs';

  @override
  String get tourStatusClosed => 'Abgeschlossen';

  @override
  String get noTours => 'Noch keine Touren.';

  @override
  String stepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get stepDetails => 'Details';

  @override
  String get stepLoad => 'Beladung';

  @override
  String get driverLabel => 'Fahrer';

  @override
  String get chooseDriver => 'Fahrer wählen';

  @override
  String get plannedAtLabel => 'Datum und Uhrzeit';

  @override
  String get tourNameOptional => 'Tourname (optional)';

  @override
  String get next => 'Weiter';

  @override
  String availableStock(String text) {
    return 'Bestand: $text';
  }

  @override
  String get addProduct => 'Produkt hinzufügen';

  @override
  String get pickPerKilogram => 'Pro Kilogramm';

  @override
  String get remove => 'Entfernen';

  @override
  String get loadValueBuy => 'Warenwert Einkauf';

  @override
  String get loadValueSell => 'Warenwert Verkauf';

  @override
  String get expectedProfit => 'Erwarteter Gewinn';

  @override
  String stockNotEnough(String name) {
    return 'Für $name ist nicht genug Bestand da.';
  }

  @override
  String get startTour => 'Tour starten';

  @override
  String get saveDraft => 'Als Entwurf speichern';

  @override
  String get confirmStartTour => 'Ware wird vom Lager abgebucht.';

  @override
  String get noItemsYet => 'Noch keine Produkte.';

  @override
  String get tourLoad => 'Ladung';

  @override
  String get tourValues => 'Werte';

  @override
  String get expectedRevenue => 'Erwarteter Umsatz';

  @override
  String get tourStarted => 'Tour gestartet.';

  @override
  String get draftSaved => 'Entwurf gespeichert.';

  @override
  String get draftRestored =>
      'Dein angefangener Entwurf ist wieder da. Du kannst genau dort weitermachen.';

  @override
  String get undoStart => 'Start rückgängig';

  @override
  String get confirmUndoStart => 'Die Ware wird wieder ins Lager gebucht.';

  @override
  String get reopenTour => 'Wieder öffnen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirmDeleteDraft => 'Diesen Entwurf löschen?';

  @override
  String get revenue => 'Umsatz';

  @override
  String get expectedCash => 'Soll-Bargeld';

  @override
  String get cashReceived => 'Übergebenes Bargeld';

  @override
  String get costOfGoods => 'Wareneinsatz';

  @override
  String get profit => 'Gewinn';

  @override
  String get startedAtLabel => 'Start';

  @override
  String get closedAtLabel => 'Ende';

  @override
  String get tourNumberLabel => 'Tour-Nr.';

  @override
  String get noDriversAvailable => 'Keine aktiven Fahrer.';

  @override
  String get soldLabel => 'Verkauft';

  @override
  String get returnedLabel => 'Zurück';

  @override
  String get loadedLabel => 'Geladen';

  @override
  String get closeInfo => 'Verkauft = Geladen − Zurück.';

  @override
  String get returnedQty => 'Zurück';

  @override
  String loadedValue(String text) {
    return 'Geladen: $text';
  }

  @override
  String soldValue(String text, String amount) {
    return 'Verkauft: $text · $amount';
  }

  @override
  String get addExpense => 'Ausgabe hinzufügen';

  @override
  String get expenseType => 'Art';

  @override
  String get expenseDiesel => 'Diesel';

  @override
  String get expenseMeal => 'Essen';

  @override
  String get expenseParking => 'Parken';

  @override
  String get expenseOther => 'Sonstiges';

  @override
  String get amountGross => 'Betrag brutto';

  @override
  String get cashFromDriver => 'Bargeld vom Fahrer';

  @override
  String returnTooHigh(String name) {
    return 'Für $name ist mehr zurück als geladen.';
  }

  @override
  String get confirmCloseTour => 'Die Tour wird abgeschlossen und gesperrt.';

  @override
  String get confirmClose => 'Abschluss bestätigen';

  @override
  String get tourClosed => 'Tour abgeschlossen.';

  @override
  String get differenceReasonRequired =>
      'Bei einer Differenz ist eine Begründung nötig.';

  @override
  String get cashRequired => 'Bitte das übergebene Bargeld eintragen.';

  @override
  String get deliveryNotesSearch => 'Empfänger oder Nummer';

  @override
  String get filterSigned => 'Unterschrieben';

  @override
  String get filterOpenNotes => 'Offen';

  @override
  String get statusSigned => 'Unterschrieben';

  @override
  String get statusDraft => 'Entwurf';

  @override
  String get noDeliveryNotes => 'Noch keine Lieferscheine.';

  @override
  String get recipientName => 'Empfänger';

  @override
  String get recipientAddress => 'Adresse';

  @override
  String get dateLabel => 'Datum';

  @override
  String get tourOptional => 'Tour (optional)';

  @override
  String get chooseTour => 'Tour wählen';

  @override
  String get noTour => 'Keine Tour';

  @override
  String get tourItemsTaken => 'Die Produkte der Tour wurden übernommen.';

  @override
  String get showPreview => 'Vorschau';

  @override
  String get showPdf => 'PDF ansehen';

  @override
  String get signAction => 'Unterschreiben';

  @override
  String get signConfirmText => 'Empfang der Ware bestätigt.';

  @override
  String get signerName => 'Name des Unterzeichners';

  @override
  String get clearSignature => 'Löschen';

  @override
  String get takeSignature => 'Unterschrift übernehmen';

  @override
  String get signHere => 'Hier unterschreiben';

  @override
  String get signatureMissing => 'Bitte unterschreiben.';

  @override
  String get signerRequired => 'Bitte den Namen eintragen.';

  @override
  String get signedDone => 'Unterschrieben.';

  @override
  String get createInvoiceFromNote => 'Rechnung daraus erstellen';

  @override
  String get share => 'Teilen';

  @override
  String get print => 'Drucken';

  @override
  String signedBy(String name, String date) {
    return '$name, $date';
  }

  @override
  String get confirmDeleteNote => 'Diesen Lieferschein löschen?';

  @override
  String get itemsRequired =>
      'Bitte mindestens ein Produkt mit Menge eintragen.';

  @override
  String get pdfNotStored =>
      'Unterschrieben, das PDF wurde noch nicht abgelegt.';

  @override
  String expensesSummary(int count, String net) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Belege',
      one: '1 Beleg',
    );
    return '$_temp0 · netto $net';
  }

  @override
  String get filterTourCosts => 'Tourkosten';

  @override
  String get filterOtherExpenses => 'Sonstige';

  @override
  String get withReceipt => 'Beleg';

  @override
  String get withoutReceipt => 'Ohne Beleg';

  @override
  String get exportMonthPdf => 'Monat als PDF exportieren';

  @override
  String get noExpenses => 'Noch keine Ausgaben in diesem Monat.';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get takePhoto => 'Beleg fotografieren';

  @override
  String get pickFromGallery => 'Aus Galerie';

  @override
  String get scanReceipt => 'Beleg scannen';

  @override
  String get removePhoto => 'Foto entfernen';

  @override
  String get expenseTitle => 'Bezeichnung';

  @override
  String netAmount(String amount) {
    return 'Netto: $amount';
  }

  @override
  String get categoryVehicle => 'Fahrzeug & Kraftstoff';

  @override
  String get categoryRent => 'Miete';

  @override
  String get categoryMaintenance => 'Wartung';

  @override
  String get categoryMeals => 'Verpflegung';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get shareAsPdf => 'Als PDF teilen';

  @override
  String get photoFailed => 'Das Foto konnte nicht verarbeitet werden.';

  @override
  String get confirmDeleteExpense => 'Diese Ausgabe löschen?';

  @override
  String get tourCostsLocked => 'Ausgabe einer Tour.';

  @override
  String get viewImage => 'Beleg ansehen';

  @override
  String get netLabel => 'Netto';

  @override
  String get invoicesSearch => 'Empfänger oder Rechnungsnummer';

  @override
  String get filterPaid => 'Bezahlt';

  @override
  String get filterOverdue => 'Überfällig';

  @override
  String get filterDrafts => 'Entwürfe';

  @override
  String get statusOpenInvoice => 'Offen';

  @override
  String get statusPaid => 'Bezahlt';

  @override
  String get statusOverdue => 'Überfällig';

  @override
  String get statusCancelled => 'Storniert';

  @override
  String openSummary(int count) {
    return '$count überfällig';
  }

  @override
  String get noInvoices => 'Noch keine Rechnungen.';

  @override
  String get recipientVatId => 'USt-IdNr. des Empfängers (optional)';

  @override
  String get invoiceDateLabel => 'Rechnungsdatum';

  @override
  String get serviceDateLabel => 'Leistungsdatum';

  @override
  String get dueDateLabel => 'Fällig am';

  @override
  String paymentTermInfo(int days, String date) {
    return 'Zahlungsziel $days Tage, fällig $date';
  }

  @override
  String get positionsSection => 'Positionen';

  @override
  String get addFreeItem => 'Freie Position';

  @override
  String get itemName => 'Bezeichnung';

  @override
  String get itemUnit => 'Einheit';

  @override
  String get unitPriceNetField => 'Preis netto';

  @override
  String lineTotal(String amount) {
    return 'Summe: $amount';
  }

  @override
  String get vat7Row => 'USt 7 %';

  @override
  String get vat19Row => 'USt 19 %';

  @override
  String get grossTotal => 'Gesamt brutto';

  @override
  String get invoiceNote => 'Hinweistext';

  @override
  String get finalizeAction => 'Festschreiben';

  @override
  String get confirmFinalize => 'Nach dem Festschreiben nicht mehr änderbar.';

  @override
  String invoiceFinalized(String number) {
    return 'Rechnung $number festgeschrieben.';
  }

  @override
  String get markPaid => 'Als bezahlt markieren';

  @override
  String get markUnpaid => 'Wieder auf offen setzen';

  @override
  String get cancelInvoiceAction => 'Stornieren';

  @override
  String get confirmCancelInvoice =>
      'Eine Stornorechnung wird erstellt und die Ware zurück ins Lager gebucht.';

  @override
  String get invoiceCancelled => 'Storniert.';

  @override
  String get paidAtLabel => 'Bezahlt am';

  @override
  String get deliveryNoteRefLabel => 'Lieferschein';

  @override
  String get cancellationOfLabel => 'Storno zu';

  @override
  String get invoiceDraftTitle => 'Rechnungsentwurf';

  @override
  String get smallBusinessHint => 'Kleinunternehmer: keine Umsatzsteuer.';

  @override
  String get freeItemName => 'Bezeichnung der Position';

  @override
  String get rangeDay => 'Tag';

  @override
  String get rangeWeek => 'Woche';

  @override
  String get rangeMonth => 'Monat';

  @override
  String get rangeYear => 'Jahr';

  @override
  String get rangeCustom => 'Eigener';

  @override
  String get weekShort => 'KW';

  @override
  String get kpiSection => 'Kennzahlen';

  @override
  String changeToPrevious(String percent) {
    return '$percent % zum Vorzeitraum';
  }

  @override
  String get chartRevenueVsExpenses => 'Umsatz und Ausgaben';

  @override
  String get topProducts => 'Top-Produkte';

  @override
  String get expensesByCategory => 'Ausgaben nach Kategorie';

  @override
  String get reportPdf => 'Bericht als PDF';

  @override
  String get noReportData => 'Keine Daten in diesem Zeitraum.';

  @override
  String get averagePerTour => 'Ø pro Tour';

  @override
  String get returnRate => 'Rücklaufquote';

  @override
  String get differences => 'Kassendifferenzen';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get deliveryNotes => 'Lieferscheine';

  @override
  String get invoices => 'Rechnungen';

  @override
  String get users => 'Benutzer';

  @override
  String get company => 'Firmendaten';

  @override
  String get account => 'Konto';

  @override
  String get help => 'Hilfe';

  @override
  String get products => 'Produkte';

  @override
  String get updateRequired => 'Bitte aktualisieren';

  @override
  String get noConnection => 'Keine Internetverbindung';

  @override
  String get discardChangesTitle => 'Änderungen verwerfen?';

  @override
  String get discardChangesMessage =>
      'Nicht gespeicherte Eingaben gehen verloren.';

  @override
  String get discard => 'Verwerfen';

  @override
  String get checkAmount =>
      'Bitte Betrag prüfen. Die Differenz ist größer als 50 €.';

  @override
  String get onRoadToday => 'Heute unterwegs';

  @override
  String get noTourOnRoad => 'Keine Tour unterwegs';

  @override
  String get monthOverview => 'Monatsübersicht';

  @override
  String get tileToursSub => 'Planen und abrechnen';

  @override
  String get tileStockSub => 'Produkte und Preise';

  @override
  String get tileExpensesSub => 'Belege und Ausgaben';

  @override
  String get tileDeliverySub => 'Erstellen und unterschreiben';

  @override
  String get companyName => 'Firmenname';

  @override
  String get companyAddress => 'Anschrift';

  @override
  String get taxNumber => 'Steuernummer';

  @override
  String get vatId => 'USt-IdNr.';

  @override
  String get iban => 'IBAN';

  @override
  String get bic => 'BIC';

  @override
  String get bankName => 'Bank';

  @override
  String get managingDirector => 'Geschäftsführer';

  @override
  String get paymentTermDays => 'Zahlungsziel in Tagen';

  @override
  String get invoiceFooter => 'Text unter der Rechnung';

  @override
  String get cashIncludesVat => 'Fahrer kassiert Bruttopreise';

  @override
  String get smallBusiness => 'Kleinunternehmer (§ 19 UStG)';

  @override
  String get smallBusinessNote => 'Hinweis auf der Rechnung';

  @override
  String get companySaved => 'Firmendaten gespeichert';

  @override
  String get companyOnlyChef => 'Nur der Chef kann die Firmendaten ändern.';

  @override
  String get accountName => 'Name';

  @override
  String get role => 'Rolle';

  @override
  String get roleChef => 'Chef';

  @override
  String get roleOffice => 'Verwaltung';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountMessage =>
      'Dein Konto und der Zugang werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get nameSaved => 'Name gespeichert';

  @override
  String get usersHint =>
      'Benutzer deiner Firma. Sie sehen dieselben Daten und dürfen alles wie du.';

  @override
  String get makeChef => 'Zum Chef machen';

  @override
  String get makeOffice => 'Zur Verwaltung machen';

  @override
  String get helpTourTitle => 'Tour planen und abrechnen';

  @override
  String get helpTourText =>
      'Fahrer wählen, Produkte und Mengen eintragen, Tour starten. Nach der Rückkehr Rückgaben und Bargeld eintragen, dann Tour abschließen. Verkauft ist Geladen minus Zurück. Soll-Bargeld ist Umsatz minus Ausgaben.';

  @override
  String get helpStockTitle => 'Produkte';

  @override
  String get helpStockText =>
      'Lege Produkte mit Einheit, Kartongröße und Preisen an. Einen Lagerbestand gibt es nicht: Beim Beladen trägst du nur ein, wie viel mitfährt.';

  @override
  String get helpDocsTitle => 'Lieferschein und Rechnung';

  @override
  String get helpDocsText =>
      'Lieferscheine lässt du unterschreiben und teilst sie als PDF. Eine Rechnung kannst du bis zum Festschreiben ändern; die Mehrwertsteuer wählst du je Position. Alles lässt sich löschen, auch Touren und Rechnungen. Bei festgeschriebenen Rechnungen fragt die App vorher nach, weil sie aufbewahrt werden müssen.';

  @override
  String get helpExpensesTitle => 'Belege';

  @override
  String get helpExpensesText =>
      'Beleg fotografieren, Betrag und Kategorie eintragen, speichern. Im Monat siehst du alle Belege und kannst sie als PDF an den Steuerberater schicken.';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get dueToday => 'heute fällig';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fällig in $count Tagen',
      one: 'fällig in 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String overdueSinceDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seit $count Tagen überfällig',
      one: 'seit 1 Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String get language => 'Sprache';

  @override
  String get languageDevice => 'Gerät';

  @override
  String get bundles => 'Mischkartons';

  @override
  String get newBundle => 'Neuer Mischkarton';

  @override
  String get editBundle => 'Mischkarton bearbeiten';

  @override
  String get bundleName => 'Name';

  @override
  String get bundleContents => 'Inhalt';

  @override
  String get noBundles => 'Noch keine Mischkartons.';

  @override
  String get bundleHint =>
      'Ein Mischkarton wird beim Beladen in seine Produkte aufgelöst. Der Bestand dieser Produkte sinkt.';

  @override
  String get bundleNeedsProduct => 'Mindestens ein Produkt hinzufügen.';

  @override
  String get confirmDeleteBundle =>
      'Diesen Mischkarton löschen? Der Bestand ändert sich dadurch nicht.';

  @override
  String get addBundle => 'Mischkarton hinzufügen';

  @override
  String get bundleCountTitle => 'Wie viele Mischkartons?';

  @override
  String get bundleCount => 'Anzahl';

  @override
  String get bundleProductMissing =>
      'Ein Produkt des Mischkartons ist nicht mehr aktiv und wurde nicht hinzugefügt.';

  @override
  String get navReports => 'Berichte';

  @override
  String get gifts => 'Geschenkte Produkte';

  @override
  String get addGift => 'Geschenk hinzufügen';

  @override
  String giftMax(String max) {
    return 'Höchstens $max möglich. Geschenke bringen keinen Umsatz.';
  }

  @override
  String get newUser => 'Neuer Benutzer';

  @override
  String get newUserHint =>
      'Der Benutzer sieht dieselben Daten wie du und darf alles. Gib ihm das Passwort weiter; er kann es später im Konto ändern.';

  @override
  String get createUser => 'Benutzer anlegen';

  @override
  String get userCreated => 'Benutzer angelegt';

  @override
  String get select => 'Auswählen';

  @override
  String get done => 'Fertig';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get deselectAll => 'Auswahl aufheben';

  @override
  String selectionCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get exportSelectionPdf => 'Auswahl als PDF';

  @override
  String get tileProductsSub => 'Produkte und Preise';

  @override
  String get confirmDeleteTour =>
      'Diese Tour wird mit allen Positionen und Ausgaben endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get confirmDeleteSignedNote =>
      'Dieser unterschriebene Lieferschein wird endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get confirmDeleteInvoice =>
      'Achtung: Eine festgeschriebene Rechnung muss in Deutschland 8 Jahre aufbewahrt werden. Wenn du sie löschst, fehlt ihre Nummer und das lässt sich nicht rückgängig machen. Wirklich löschen?';

  @override
  String receiptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Belege',
      one: '1 Beleg',
    );
    return '$_temp0';
  }

  @override
  String get unitCartonHint =>
      'Für Kartons und einzelne Gläser oder Stück: Einheit Glas oder Stück wählen und eintragen, wie viele in einen Karton passen. Beim Beladen und Abschließen gibst du dann Kartons und Stück getrennt ein.';

  @override
  String get companyIncomplete =>
      'Deine Firmendaten sind noch nicht vollständig. Für Rechnungen brauchst du Firmenname, Anschrift und Steuernummer oder USt-IdNr.';

  @override
  String get fillCompany => 'Jetzt ausfüllen';

  @override
  String get platform => 'Firmen verwalten';

  @override
  String get platformHint =>
      'Als Superadmin legst du Chefs mit eigener Firma an, sperrst Firmen oder löschst sie endgültig.';

  @override
  String get userForMyCompany => 'Zu meiner Firma';

  @override
  String get userNewCompany => 'Neue Firma';

  @override
  String get newCompanyUserHint =>
      'Der Benutzer bekommt eine eigene, neue Firma mit allen Funktionen und wird dort Chef. Er sieht nur seine eigenen Daten, du siehst nichts von seiner Firma. Gib ihm das Passwort weiter und bitte ihn, es nach der ersten Anmeldung im Konto zu ändern. Anschrift und Steuernummer seiner Firma trägt er danach selbst ein.';

  @override
  String get companyUserCreated => 'Firma und Chef angelegt';

  @override
  String get noFirms => 'Noch keine Firmen.';

  @override
  String get blockFirm => 'Firma sperren';

  @override
  String get unblockFirm => 'Firma freigeben';

  @override
  String get firmBlocked => 'Gesperrt';

  @override
  String get deleteFirm => 'Firma endgültig löschen';

  @override
  String deleteFirmMessage(String name) {
    return 'Alle Daten, Dateien und Benutzer der Firma „$name“ werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.';
  }

  @override
  String get typeNameToConfirm => 'Zur Bestätigung den Firmennamen eingeben';

  @override
  String get deleteFirmConfirm => 'Endgültig löschen';

  @override
  String get firmDeleted => 'Firma gelöscht';

  @override
  String usersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Benutzer',
      one: '1 Benutzer',
    );
    return '$_temp0';
  }

  @override
  String get accessBlocked =>
      'Dein Zugang ist gesperrt. Bitte wende dich an den Betreiber.';

  @override
  String get nameGerman => 'Name (Deutsch)';

  @override
  String get nameArabic => 'Name (Arabisch)';

  @override
  String get nameRequired => 'Mindestens ein Name ist nötig.';

  @override
  String get nameHint =>
      'Deutsch und Arabisch sind möglich, ein Name genügt. Die App zeigt den Namen in der Sprache der Oberfläche.';

  @override
  String get cartonContents => 'Inhalt des Kartons';

  @override
  String get cartonContentsHint =>
      'Welche Produkte in welcher Menge im Karton stecken. Du kannst Produkte hinzufügen, entfernen und die Mengen ändern.';

  @override
  String get noContents => 'Noch kein Inhalt.';

  @override
  String get cartonRemovalsTitle => 'Einzelne Produkte aus dem Karton';

  @override
  String get cartonRemovalsHint =>
      'Was aus diesem Karton einzeln zurückkommt oder verschenkt wird. Der Umsatz sinkt um den Verkaufspreis dieser Produkte.';

  @override
  String get removedGift => 'Geschenkt';

  @override
  String get removalTooMany =>
      'Es sind mehr einzelne Produkte entfernt, als in den Kartons stecken.';

  @override
  String get soldGoods => 'Verkaufte Ware';

  @override
  String get returnedGoods => 'Zurückgeholte Ware';

  @override
  String get shareGoodsPdf => 'Als PDF teilen';

  @override
  String get noGoods => 'Keine Ware.';

  @override
  String get goodsTotal => 'Gesamtpreis';

  @override
  String removalLabel(String content, String carton) {
    return '$content (aus $carton)';
  }

  @override
  String get tourSummaryPdf => 'Tourabrechnung als PDF';

  @override
  String get navDeliveryNote => 'L-Schein';

  @override
  String get navInvoice => 'Rechnung';

  @override
  String get companySignature => 'Unterschrift der Firma';

  @override
  String signatureSize(int percent) {
    return 'Größe der Unterschrift im PDF: $percent %';
  }

  @override
  String get signatureSmaller => 'Kleiner';

  @override
  String get signatureLarger => 'Größer';

  @override
  String get companySignatureNone => 'Noch keine Unterschrift gespeichert.';

  @override
  String get companySignatureDraw => 'Unterschrift zeichnen';

  @override
  String get companySignatureRedraw => 'Neue Unterschrift zeichnen';

  @override
  String get companySignatureDelete => 'Unterschrift löschen';

  @override
  String get companySignatureSaved => 'Unterschrift gespeichert';

  @override
  String get companySignatureDeleted => 'Unterschrift gelöscht';

  @override
  String get signatureClear => 'Neu beginnen';

  @override
  String get signatureOnDeliveryNote => 'Auf Lieferschein drucken';

  @override
  String get signatureOnInvoice => 'Auf Rechnung drucken';

  @override
  String closeReturnHint(String unit, String max) {
    return 'Zurück in $unit · höchstens $max';
  }

  @override
  String closeGiftHint(String unit, String max) {
    return 'Verschenkt in $unit · höchstens $max';
  }

  @override
  String cartonContains(String items) {
    return '1 Karton enthält: $items';
  }

  @override
  String get soldResult => 'Verkauft';

  @override
  String get closeStepLoad => '1 · Rückgabe der Ware';

  @override
  String get closeStepGifts => '2 · Geschenke';

  @override
  String get closeStepExpenses => '3 · Ausgaben';

  @override
  String get closeStepCash => '4 · Bargeld und Abrechnung';

  @override
  String get closeInfoNew =>
      'Tippe auf „Ware zurücknehmen“ und wähle einen Karton oder ein Produkt. Alles, was nicht zurückkommt, gilt als verkauft.';

  @override
  String get takeOutAdd => 'Ware zurücknehmen';

  @override
  String get takeOutPick => 'Was kommt zurück?';

  @override
  String get takeOutWhole => 'Ganzer Karton';

  @override
  String get takeOutSingles => 'Einzelne Produkte';

  @override
  String get takeOutSinglesHint =>
      'Wie viel von jedem Produkt kommt aus dem Karton zurück oder wird verschenkt?';

  @override
  String get takeOutNone =>
      'Noch nichts zurückgenommen. Alles gilt als verkauft.';

  @override
  String deleteManyTitle(int count) {
    return '$count löschen?';
  }

  @override
  String get confirmDeleteMany =>
      'Die gewählten Einträge werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get confirmDeleteManyInvoices =>
      'Festgeschriebene Rechnungen müssen in Deutschland 8 Jahre aufbewahrt werden. Ihre Nummern fehlen danach.';

  @override
  String deletedMany(int count) {
    return '$count gelöscht';
  }

  @override
  String deleteManyFailed(int count) {
    return '$count konnten nicht gelöscht werden.';
  }

  @override
  String get pdfNothingSelected => 'Wähle zuerst mindestens einen Eintrag.';

  @override
  String get pdfNothingToShow => 'Dafür gibt es noch nichts als PDF.';

  @override
  String get pdfPleaseWait => 'Bitte kurz warten, das PDF wird noch geladen.';

  @override
  String get nothingToShare =>
      'Dazu gibt es kein PDF. Bei Touren nur abgeschlossene.';

  @override
  String get pdfNoPreview =>
      'Die Vorschau konnte nicht angezeigt werden. Teilen und Drucken gehen trotzdem.';
}
