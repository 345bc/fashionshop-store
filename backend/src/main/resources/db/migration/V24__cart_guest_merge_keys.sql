-- Keep guest imports idempotent even when a response is lost or the browser reloads.
ALTER TABLE carts ADD merged_guest_keys NVARCHAR(MAX) NOT NULL CONSTRAINT df_cart_merged_guest_keys DEFAULT '';

-- Reuse the existing token hash to prevent duplicate checkout requests.
CREATE UNIQUE INDEX ux_orders_checkout_token_hash ON orders(checkout_token_hash) WHERE checkout_token_hash IS NOT NULL;
