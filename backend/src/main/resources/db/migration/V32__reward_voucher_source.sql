ALTER TABLE vouchers ADD source_reward_id BIGINT NULL;
ALTER TABLE vouchers ADD CONSTRAINT FK_vouchers_source_reward FOREIGN KEY (source_reward_id) REFERENCES vouchers(id);
CREATE INDEX ix_vouchers_source_reward ON vouchers(source_reward_id, id DESC);
