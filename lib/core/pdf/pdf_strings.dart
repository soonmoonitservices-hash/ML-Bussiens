import 'package:warenbestand/core/formatting/quantity_formatter.dart';

/// Alle Texte der PDFs (Deutsch). Für eine weitere Sprache diese Klasse
/// ableiten und die Getter überschreiben; im Layout stehen keine festen Texte.
class PdfStrings {
  /// Deutsche Texte.
  const PdfStrings();

  // Allgemein
  String pageOf(int page, int total) => 'Seite $page von $total';
  String get position => 'Pos.';
  String get article => 'Artikel';
  String get quantity => 'Menge';
  String get unit => 'Einheit';
  String get number => 'Nummer';
  String get date => 'Datum';
  String get category => 'Kategorie';
  String get vatPercent => 'USt %';
  String get net => 'Netto';
  String get gross => 'Brutto';
  String get vat => 'USt';
  String get bank => 'Bank';
  String get taxNumber => 'Steuernr.';
  String get vatId => 'USt-IdNr.';
  String get managingDirector => 'Geschäftsführer';
  String get phone => 'Tel.';
  String get email => 'E-Mail';
  String get draftWatermark => 'ENTWURF';
  String get notAvailable => '–';
  QuantityLabels get quantityLabels => QuantityLabels.de;

  // Lieferschein
  String get deliveryNote => 'Lieferschein';
  String get deliveryDate => 'Lieferdatum';
  String get tour => 'Tour';
  String get deliveryReceived => 'Ware vollständig und unbeschädigt erhalten.';
  String get recipientSignature => 'Unterschrift Fahrer';
  String ownerSignature(String name) => 'Inhaber: $name';
  String signedAt(String name, String dateTime) => '$name, $dateTime';

  // Rechnung
  String get invoice => 'Rechnung';
  String get cancellationInvoice => 'Stornorechnung';
  String get invoiceNumber => 'Rechnungsnr.';
  String get invoiceDate => 'Rechnungsdatum';
  String get serviceDate => 'Leistungsdatum';
  String get dueDate => 'Fällig am';
  String get deliveryNoteRef => 'Lieferschein';
  String get unitPriceNet => 'Einzelpreis netto';
  String get lineTotalNet => 'Gesamt netto';
  String get totalNet => 'Nettobetrag';
  String vatAmount(int percent) => 'USt $percent %';
  String get totalGross => 'Gesamtbetrag';
  String get invoiceDraftWatermark => 'ENTWURF – keine gültige Rechnung';
  String cancellationOf(String number) => 'Storno zu Rechnung $number';
  String paymentRequest(String amount, String dueDate) =>
      'Bitte überweisen Sie $amount bis zum $dueDate auf folgendes Konto:';
  String paymentReference(String number) => 'Verwendungszweck: $number';
  String get iban => 'IBAN';
  String get bic => 'BIC';

  // Tourabrechnung
  String get soldGoods => 'Verkaufte Ware';
  String get returnedGoods => 'Zurückgeholte Ware';
  String get unitPrice => 'Einzelpreis';
  String get totalPrice => 'Gesamtpreis';
  String get tourSummary => 'Tourabrechnung';
  String get tourNumber => 'Tour-Nr.';
  String get driver => 'Fahrer';
  String get startedAt => 'Start';
  String get closedAt => 'Ende';
  String get loaded => 'Geladen';
  String get returned => 'Zurück';
  String get sold => 'Verkauft';
  String get price => 'Preis';
  String get revenue => 'Umsatz';
  String get expenses => 'Ausgaben';
  String get expectedCash => 'Soll-Bargeld';
  String get cashReceived => 'Übergebenes Bargeld';
  String get difference => 'Differenz';
  String get shortfall => 'Weniger Bargeld';
  String get surplus => 'Mehr Bargeld';
  String get cashBalanced => 'Kasse stimmt';
  String get differenceReason => 'Begründung';
  String get cost => 'Wareneinsatz';
  String get profit => 'Tourgewinn';
  String get checked => 'Geprüft';
  String get type => 'Art';
  String get amount => 'Betrag';

  // Monatsbelege
  String expensesTitle(String month) => 'Ausgabenbelege $month';
  String get receiptCount => 'Anzahl Belege';
  String get byCategory => 'Aufteilung nach Kategorie';
  String get receipt => 'Beleg';
  String get title => 'Bezeichnung';
  String get noPhoto => 'Kein Foto vorhanden';
  String get receiptNumberShort => 'Nr.';

  // Auswertung
  String get report => 'Auswertung';
  String get period => 'Zeitraum';
  String get kpis => 'Kennzahlen';
  String get changeToPrevious => 'zum Vorzeitraum';
  String get topProducts => 'Top-Produkte';
  String get expensesByCategory => 'Ausgaben nach Kategorie';
  String get driverStats => 'Fahrerstatistik';
  String get tours => 'Touren';
  String get averagePerTour => 'Ø pro Tour';
  String get returnRate => 'Rücklaufquote';
  String get differences => 'Differenzen';
}
