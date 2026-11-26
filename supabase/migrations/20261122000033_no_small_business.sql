-- Die Kleinunternehmer-Regelung (§ 19 UStG) gibt es nicht mehr: Rechnungen weisen immer
-- Mehrwertsteuer aus (Satz je Position). Die Einstellung wird überall ausgeschaltet und
-- lässt sich nicht mehr einschalten.

update company_settings set is_small_business = false where is_small_business;

alter table company_settings
  add constraint company_settings_no_small_business check (not is_small_business);
