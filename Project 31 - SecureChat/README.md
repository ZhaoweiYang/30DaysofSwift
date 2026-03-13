# Project 31 - SecureChat

An end-to-end encrypted chat platform built with SwiftUI. Features a WeChat-inspired UI with crypto-wallet-style mnemonic phrase account creation.

## Architecture

```
用户A → 本地创建加密密钥 → 本地加密消息 → 平台转发密文 → 用户B输入密钥 → 本地解密
```

The platform **never** has access to plaintext messages or encryption keys.

## Features

- **Mnemonic Account Creation**: 12-word seed phrase generates your identity (like crypto wallets)
- **AES-256-GCM Encryption**: Messages are encrypted locally before sending
- **Key Exchange**: Users share encryption keys out-of-band for each conversation
- **WeChat-style UI**: Familiar chat interface with conversation list, contacts, and profile tabs
- **Local Storage**: All data stored locally; keys never leave the device

## Encryption Flow

1. User A generates a conversation key for User B
2. User A encrypts plaintext with AES-256-GCM locally
3. Platform relays only the ciphertext (cannot decrypt)
4. User B receives User A's key (shared out-of-band)
5. User B decrypts the ciphertext locally

## Tech Stack

- SwiftUI + Combine
- CryptoKit (AES-256-GCM)
- iOS 16+
