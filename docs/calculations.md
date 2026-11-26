# Berechnungen

Geld wird als ganze Cent, Gewicht als ganze Gramm gespeichert. Tourmengen
verwenden die Basiseinheit; Kartonmengen werden mit
`kartons × inhalt + einzeln` umgerechnet. Umsatzsteuer und Zeilenwerte werden
kaufmännisch auf ganze Cent gerundet.

Die Live-Anzeige nutzt die reinen Dart-Klassen `Money`, `Quantity`,
`VatRate`, `LoadCalculator`, `SettlementCalculator` und `InvoiceCalculator`.
Bei einer Speicherung ist stets das atomare Datenbankergebnis maßgeblich. Die
zugehörigen Grenzfälle sind durch Unit-Tests abgedeckt.
