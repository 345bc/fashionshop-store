-- Keep V25 intact if it was already applied; reuse its receiving-account column for the gateway merchant.
EXEC sp_rename 'orders.payment_account_number', 'payment_merchant_code', 'COLUMN';
