-- Survives successful email deletion from email_outbox so repeated sends cannot spam recipients.
CREATE TABLE voucher_email_recipients (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    voucher_id BIGINT NOT NULL REFERENCES vouchers(id),
    email VARCHAR(254) NOT NULL,
    membership_tier VARCHAR(20) NOT NULL,
    queued_at DATETIME2 NOT NULL,
    CONSTRAINT uq_voucher_email_recipient UNIQUE (voucher_id, email)
);
