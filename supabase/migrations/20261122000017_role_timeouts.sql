-- Schutz vor Überlastung: Abfragen der App brechen nach 5 Sekunden ab, offene
-- Transaktionen ohne Aktivität nach 10 Sekunden.

alter role authenticated set statement_timeout = '5s';
alter role authenticated set idle_in_transaction_session_timeout = '10s';
