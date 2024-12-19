# AMM DEX Implementation

A simplified Automated Market Maker (AMM) implementation for the Internet Computer, focusing on core DEX functionality:

- Add/remove liquidity
- Token swaps using constant product formula (x * y = k)
- Pool state management
- Input validation

## Key Features

- Constant product market maker formula
- 0.3% swap fee
- Slippage protection (1%)
- Minimum liquidity requirement
- No external token integration (see Note below)

## Note

For this challenge, implementation focuses on core AMM functionality without token ledger integration. A production AMM would integrate with:
- TokenA Ledger Canister (balances/transfers)
- TokenB Ledger Canister (balances/transfers) 
- LP Token Ledger Canister (ownership tracking)

## Quick Start

```bash
dfx start --clean --background
dfx canister create amm_dex_backend
dfx build
dfx deploy