# Deployment Guide

## Local Development

1. Start a local blockchain:
```bash
make anvil
```
This will start Anvil (local Ethereum node) in the background

2. Deploy to local network:
```bash
make deploy-local
```

3. Stop the local blockchain when done:
```bash
make stop-anvil
```

Note: Local deployment uses Anvil's default private key for convenience. Never use this key in production.

## Setting up Secure Deployment Keys

1. Generate a new wallet: 

```bash
make new-wallet
```

2. Import the private key to an encrypted keystore:

```bash
make import-wallet
```

Follow the prompts to:
- Enter your private key
- Set a strong password (20+ characters)

3. List available keystores:

```bash
make list-wallets
```

4. Set up your environment:
- Copy `.env.example` to `.env`
- Fill in your RPC URLs and API keys
- Set your `KEYSTORE_NAME` and `KEYSTORE_PASSWORD`

## Deploying

1. To deploy to Mumbai testnet:

```bash
make deploy-mumbai
```

2. To deploy to Polygon mainnet:

```bash
make deploy-polygon
```

## Security Best Practices

1. **Keystore Password**:
   - Use a strong password (20+ characters)
   - Never store the password in plaintext
   - Consider using a password manager

2. **Environment Security**:
   - Never commit `.env` file
   - Use different keys for testnet and mainnet
   - Clear environment variables after use
