;; Title: TimestampX
;; Summary: Bitcoin-anchored document authentication protocol
;; Description: A cryptographic timestamping system that leverages Bitcoin's immutability 
;; through Stacks to create verifiable proof-of-existence records. Enables organizations 
;; and individuals to register document fingerprints on-chain without exposing sensitive 
;; content, establishing irrefutable chronological evidence for IP claims, contracts, 
;; and compliance documentation.

;; ERROR CODES

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_ATTESTATION_ID (err u101))
(define-constant ERR_ATTESTATION_NOT_FOUND (err u102))
(define-constant ERR_INVALID_HASH (err u103))
(define-constant ERR_INVALID_PRINCIPAL (err u104))
(define-constant ERR_INVALID_VERSION (err u105))
(define-constant ERR_SELF_REFERENCE (err u106))

;; PROTOCOL CONSTANTS

(define-constant CONTRACT_OWNER tx-sender)
(define-constant BURN_ADDRESS 'SP000000000000000000002Q6VF78)

;; STATE VARIABLES

(define-data-var attestation-counter uint u0)
(define-data-var protocol-version uint u1)

;; DATA STORAGE

;; Core attestation records
(define-map attestations
  { attestation-id: uint }
  {
    issuer: principal,
    subject: principal,
    content-hash: (buff 32),
    created-at: uint,
    block-height: uint,
    is-verified: bool
  }
)

;; User activity tracking
(define-map user-stats
  { user: principal }
  { total-attestations: uint }
)

;; Hash-based lookup index
(define-map hash-index
  { content-hash: (buff 32) }
  { 
    attestation-id: uint,
    verification-count: uint
  }
)

;; PRIVATE HELPERS

(define-private (valid-hash? (hash (buff 32)))
  (is-eq (len hash) u32)
)

(define-private (valid-principal? (addr principal))
  (not (is-eq addr BURN_ADDRESS))
)

(define-private (update-user-stats (user principal))
  (let 
    (
      (current (default-to u0 
        (get total-attestations (map-get? user-stats { user: user }))
      ))
    )
    (map-set user-stats 
      { user: user }
      { total-attestations: (+ current u1) }
    )
  )
)

;; PUBLIC FUNCTIONS

;; Create Attestation
;; Registers a document hash with recipient designation, anchoring proof to Bitcoin
;; @param subject: Principal receiving the attestation
;; @param content-hash: SHA-256 hash of the document (32 bytes)
;; @returns: Unique attestation identifier
(define-public (create-attestation 
  (subject principal) 
  (content-hash (buff 32))
)
  (let 
    (
      (new-id (+ (var-get attestation-counter) u1))
      (current-height stacks-block-height)
    )
    ;; Input validation
    (asserts! (valid-principal? subject) ERR_INVALID_PRINCIPAL)
    (asserts! (valid-hash? content-hash) ERR_INVALID_HASH)
    (asserts! (not (is-eq tx-sender subject)) ERR_SELF_REFERENCE)
    
    ;; Create attestation record
    (map-set attestations
      { attestation-id: new-id }
      {
        issuer: tx-sender,
        subject: subject,
        content-hash: content-hash,
        created-at: current-height,
        block-height: current-height,
        is-verified: false
      }
    )
    
    ;; Create hash index entry
    (map-set hash-index
      { content-hash: content-hash }
      {
        attestation-id: new-id,
        verification-count: u0
      }
    )
    
    ;; Update protocol state
    (var-set attestation-counter new-id)
    (update-user-stats tx-sender)
    
    (ok new-id)
  )
)

;; Verify Attestation
;; Validates document integrity by comparing hash against stored record
;; @param attestation-id: Target attestation to verify
;; @param provided-hash: Hash to check against record
;; @returns: Boolean indicating verification result
(define-public (verify-attestation 
  (attestation-id uint) 
  (provided-hash (buff 32))
)
  (let 
    (
      (record (unwrap! 
        (map-get? attestations { attestation-id: attestation-id }) 
        ERR_ATTESTATION_NOT_FOUND
      ))
      (stored-hash (get content-hash record))
      (hash-match (is-eq stored-hash provided-hash))
    )
    ;; Input validation
    (asserts! (> attestation-id u0) ERR_INVALID_ATTESTATION_ID)
    (asserts! (valid-hash? provided-hash) ERR_INVALID_HASH)
    
    ;; Process verification
    (if hash-match
      (begin
        ;; Mark as verified
        (map-set attestations
          { attestation-id: attestation-id }
          (merge record { is-verified: true })
        )
        
        ;; Increment verification counter
        (let 
          (
            (index-entry (default-to 
              { attestation-id: u0, verification-count: u0 } 
              (map-get? hash-index { content-hash: provided-hash })
            ))
          )
          (map-set hash-index
            { content-hash: provided-hash }
            {
              attestation-id: attestation-id,
              verification-count: (+ (get verification-count index-entry) u1)
            }
          )
        )
        (ok true)
      )
      (ok false)
    )
  )
)

;; Update Protocol Version
;; Admin function to increment protocol version
;; @param new-version: New version number (must be greater than current)
;; @returns: Success boolean
(define-public (update-protocol-version (new-version uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> new-version (var-get protocol-version)) ERR_INVALID_VERSION)
    (var-set protocol-version new-version)
    (ok true)
  )
)

;; READ-ONLY FUNCTIONS

;; Get Attestation Details
;; Retrieves complete attestation record by ID
;; @param attestation-id: Attestation identifier
;; @returns: Optional attestation record
(define-read-only (get-attestation (attestation-id uint))
  (begin
    (asserts! (> attestation-id u0) ERR_INVALID_ATTESTATION_ID)
    (ok (map-get? attestations { attestation-id: attestation-id }))
  )
)

;; Get User Statistics
;; Returns total attestations created by user
;; @param user: Principal address to query
;; @returns: Attestation count
(define-read-only (get-user-stats (user principal))
  (begin
    (asserts! (valid-principal? user) ERR_INVALID_PRINCIPAL)
    (ok (default-to u0 
      (get total-attestations (map-get? user-stats { user: user }))
    ))
  )
)

;; Get Total Attestations
;; Returns global attestation counter
;; @returns: Total number of attestations
(define-read-only (get-total-attestations)
  (ok (var-get attestation-counter))
)

;; Get Protocol Version
;; Returns current protocol version
;; @returns: Version number
(define-read-only (get-protocol-version)
  (ok (var-get protocol-version))
)

;; Check Hash Exists
;; Verifies if hash has been registered
;; @param hash: Content hash to check
;; @returns: Boolean existence status
(define-read-only (hash-exists (hash (buff 32)))
  (begin
    (asserts! (valid-hash? hash) ERR_INVALID_HASH)
    (ok (is-some (map-get? hash-index { content-hash: hash })))
  )
)

;; Get Verification Count
;; Returns number of verification attempts for hash
;; @param hash: Content hash to query
;; @returns: Verification attempt count
(define-read-only (get-verification-count (hash (buff 32)))
  (begin
    (asserts! (valid-hash? hash) ERR_INVALID_HASH)
    (ok (default-to u0 
      (get verification-count 
        (map-get? hash-index { content-hash: hash })
      )
    ))
  )
)