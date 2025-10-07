# ⛓️ TimestampX

**Bitcoin-Anchored Document Authentication Protocol**
A secure and censorship-resistant protocol for proving document existence via Bitcoin, built on the Stacks blockchain.

---

## 🧠 Overview

**TimestampX** is a Clarity-based smart contract system that enables individuals and organizations to create cryptographic attestations of document integrity without disclosing content. Each attestation anchors a document’s SHA-256 hash to the Bitcoin blockchain through the Stacks layer, providing **verifiable proof-of-existence**, immutably timestamped and linked to the issuer and recipient.

Common use cases include:

* Intellectual property protection
* Regulatory and compliance documentation
* Digital signature audit trails
* Contract timestamping

---

## 🔐 Features

* ✅ **Content Privacy**: Only document hashes are recorded—no content is exposed on-chain.
* ⛓️ **Bitcoin Security**: Proof-of-existence records inherit Bitcoin’s finality via Stacks anchoring.
* 🧾 **Traceability**: Each attestation includes issuer, recipient, and timestamp.
* 📊 **User Analytics**: Tracks attestation activity per user.
* 🔍 **Verification**: Verifies submitted content hashes against recorded entries.
* 🛡️ **Permissioned Versioning**: Protocol version control restricted to contract owner.

---

## 🏗 Contract Architecture

```text
+---------------------+          +------------------+
|    Contract Owner   |<-------->|  Protocol State  |
+---------------------+          | (version, etc.)  |
                                 +------------------+
                                         |
                                         v
+------------------+        +--------------------+
|  Users (issuers) | -----> |  create-attestation|
+------------------+        +--------------------+
                                         |
                +------------------------+-------------------------+
                |                        |                         |
                v                        v                         v
       +----------------+       +----------------+        +------------------+
       |  attestations  |<----->|  hash-index    |<------>|  verify-attest.  |
       +----------------+       +----------------+        +------------------+
                |
                v
       +----------------+
       |  user-stats    |
       +----------------+
```

---

## 🧩 Key Components

### 🗃️ Data Structures

* **`attestations` (map)**
  Stores attestation records, each keyed by a unique ID.

* **`hash-index` (map)**
  Enables hash-based lookup of attestations and tracks verification count.

* **`user-stats` (map)**
  Records how many attestations each principal has created.

* **`attestation-counter` (var)**
  Global counter for attestation ID generation.

* **`protocol-version` (var)**
  Maintains the current version of the contract protocol.

---

## 🔁 Data Flow

### 1. **Creating an Attestation**

* The issuer calls `create-attestation(subject, content-hash)`
* The system:

  * Validates input
  * Increments the attestation counter
  * Stores record in `attestations`
  * Indexes the hash in `hash-index`
  * Updates `user-stats`

### 2. **Verifying an Attestation**

* Any user calls `verify-attestation(attestation-id, provided-hash)`
* The contract:

  * Validates input and existence
  * Compares hash with stored content-hash
  * If matched, marks the attestation as verified and increments `verification-count`

---

## 🧪 Public Interface

### 📄 Attestation Functions

| Function                 | Description                                    |
| ------------------------ | ---------------------------------------------- |
| `create-attestation`     | Registers a new document hash                  |
| `verify-attestation`     | Verifies a document hash against stored record |
| `get-attestation`        | Fetches full attestation by ID                 |
| `hash-exists`            | Checks if a hash has been registered           |
| `get-verification-count` | Returns number of successful verifications     |

### 👤 User and Protocol Queries

| Function                 | Description                              |
| ------------------------ | ---------------------------------------- |
| `get-user-stats`         | Number of attestations submitted by user |
| `get-total-attestations` | Global counter of attestations           |
| `get-protocol-version`   | Current protocol version                 |

### 🔐 Admin Function

| Function                  | Description                              |
| ------------------------- | ---------------------------------------- |
| `update-protocol-version` | Increments protocol version (owner only) |

---

## ⚠️ Error Codes

| Constant                     | Code  | Description                          |
| ---------------------------- | ----- | ------------------------------------ |
| `ERR_UNAUTHORIZED`           | `100` | Caller is not contract owner         |
| `ERR_INVALID_ATTESTATION_ID` | `101` | Invalid or zero attestation ID       |
| `ERR_ATTESTATION_NOT_FOUND`  | `102` | No attestation found for given ID    |
| `ERR_INVALID_HASH`           | `103` | Hash length is invalid               |
| `ERR_INVALID_PRINCIPAL`      | `104` | Subject or caller is invalid address |
| `ERR_INVALID_VERSION`        | `105` | Protocol version downgrade attempted |
| `ERR_SELF_REFERENCE`         | `106` | Issuer cannot attest to self         |

---

## 🔧 Deployment & Integration Notes

* This contract assumes Clarity language v2 and is compatible with the latest Stacks blockchain.
* Content hashes must be **SHA-256** and **exactly 32 bytes** in length.
* All addresses must be valid **non-burn principals** (`SP...`), excluding the designated burn address (`SP000000000000000000002Q6VF78`).

---

## ✅ Future Enhancements

Planned roadmap features include:

* Decentralized attestation revocation/expiration
* Multi-signature attestation approvals
* Integration with IPFS or Arweave for optional off-chain content storage
* Event emissions for improved indexing and traceability

---

## 📜 License

MIT License. Use freely with attribution.
