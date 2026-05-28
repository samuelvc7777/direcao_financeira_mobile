# UI Contract: Invoice Payment Flow

## Entry points

- Home card section payment button.
- Cards screen payment CTA when the card has a payable invoice.

## Flow

1. User selects a bank account.
2. User selects `total` or `partial`.
3. If `partial`, user informs the amount to pay.
4. System validates the amount.
5. On success, system registers the invoice payment and refreshes the visible state.

## States

- `no_invoice`: the payment action is not offered and the user receives a clear message.
- `select_account`: list of active accounts.
- `select_mode`: total or partial choice.
- `enter_amount`: only for partial payment.
- `processing`: payment request in progress.
- `success`: feedback and refreshed balance/invoice state.
- `error`: message shown, no state committed.

## Validation rules

- Total payment must use the full payable balance.
- Partial payment must be greater than zero and lower than the payable balance.
- Cancel before confirmation must not change the invoice.
