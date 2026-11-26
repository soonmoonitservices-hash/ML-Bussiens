/// Firmendaten und Abrechnungseinstellungen (genau eine Zeile in der
/// Datenbank).
final class CompanySettings {
  const CompanySettings({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.taxNumber,
    required this.vatId,
    required this.iban,
    required this.bic,
    required this.bankName,
    required this.managingDirector,
    required this.paymentTermDays,
    required this.invoiceFooter,
    required this.cashIncludesVat,
    required this.isSmallBusiness,
    required this.smallBusinessNote,
    required this.signaturePath,
    required this.signatureOnDeliveryNote,
    required this.signatureOnInvoice,
    required this.signatureScale,
    required this.updatedAt,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) =>
      CompanySettings(
        name: json['name'] as String,
        address: json['address'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        taxNumber: json['tax_number'] as String,
        vatId: json['vat_id'] as String,
        iban: json['iban'] as String,
        bic: json['bic'] as String,
        bankName: json['bank_name'] as String,
        managingDirector: json['managing_director'] as String,
        paymentTermDays: json['payment_term_days'] as int,
        invoiceFooter: json['invoice_footer'] as String,
        cashIncludesVat: json['cash_includes_vat'] as bool,
        isSmallBusiness: json['is_small_business'] as bool,
        smallBusinessNote: json['small_business_note'] as String,
        signaturePath: json['signature_path'] as String?,
        signatureOnDeliveryNote: json['signature_on_delivery_note'] as bool,
        signatureOnInvoice: json['signature_on_invoice'] as bool,
        signatureScale: json['signature_scale'] as int,
        updatedAt: json['updated_at'] as String,
      );

  static const columns =
      'name,address,phone,email,tax_number,vat_id,iban,bic,bank_name,'
      'managing_director,payment_term_days,invoice_footer,cash_includes_vat,'
      'is_small_business,small_business_note,signature_path,signature_on_delivery_note,signature_on_invoice,signature_scale,updated_at';

  final String name;
  final String address;
  final String phone;
  final String email;
  final String taxNumber;
  final String vatId;
  final String iban;
  final String bic;
  final String bankName;
  final String managingDirector;
  final int paymentTermDays;
  final String invoiceFooter;
  final bool cashIncludesVat;
  final bool isSmallBusiness;
  final String smallBusinessNote;
  final String? signaturePath;
  final bool signatureOnDeliveryNote;
  final bool signatureOnInvoice;

  /// Größe der Unterschrift im PDF in Prozent (50 bis 200, 100 = Standard).
  final int signatureScale;
  final String updatedAt;

  Map<String, Object?> toJson() => {
    'name': name.trim(),
    'address': address.trim(),
    'phone': phone.trim(),
    'email': email.trim(),
    'tax_number': taxNumber.trim(),
    'vat_id': vatId.trim(),
    'iban': iban.trim(),
    'bic': bic.trim(),
    'bank_name': bankName.trim(),
    'managing_director': managingDirector.trim(),
    'payment_term_days': paymentTermDays,
    'invoice_footer': invoiceFooter.trim(),
    'cash_includes_vat': cashIncludesVat,
    'is_small_business': isSmallBusiness,
    'small_business_note': smallBusinessNote.trim(),
    'signature_on_delivery_note': signatureOnDeliveryNote,
    'signature_on_invoice': signatureOnInvoice,
    'signature_scale': signatureScale,
  };
}
