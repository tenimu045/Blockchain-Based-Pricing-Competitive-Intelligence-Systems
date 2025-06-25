;; Analyst Verification Contract
;; Manages verification and reputation of pricing intelligence analysts

;; Data structures
(define-map analysts
  { analyst-id: principal }
  {
    name: (string-ascii 50),
    credentials-hash: (string-ascii 64),
    reputation-score: uint,
    verified: bool,
    registration-block: uint
  }
)

(define-map analyst-submissions
  { analyst-id: principal, submission-id: uint }
  {
    timestamp: uint,
    accuracy-score: uint,
    verified: bool
  }
)

;; Data variables
(define-data-var next-submission-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ANALYST-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-REGISTERED (err u102))
(define-constant ERR-INVALID-REPUTATION (err u103))

;; Register new analyst
(define-public (register-analyst (name (string-ascii 50)) (credentials-hash (string-ascii 64)) (initial-reputation uint))
  (let ((analyst-id tx-sender))
    (asserts! (is-none (map-get? analysts { analyst-id: analyst-id })) ERR-ALREADY-REGISTERED)
    (asserts! (<= initial-reputation u1000) ERR-INVALID-REPUTATION)
    (map-set analysts
      { analyst-id: analyst-id }
      {
        name: name,
        credentials-hash: credentials-hash,
        reputation-score: initial-reputation,
        verified: false,
        registration-block: block-height
      }
    )
    (ok analyst-id)
  )
)

;; Verify analyst (only contract owner)
(define-public (verify-analyst (analyst-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (match (map-get? analysts { analyst-id: analyst-id })
      analyst-data (begin
        (map-set analysts
          { analyst-id: analyst-id }
          (merge analyst-data { verified: true })
        )
        (ok true)
      )
      ERR-ANALYST-NOT-FOUND
    )
  )
)

;; Update analyst reputation
(define-public (update-reputation (analyst-id principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-score u1000) ERR-INVALID-REPUTATION)
    (match (map-get? analysts { analyst-id: analyst-id })
      analyst-data (begin
        (map-set analysts
          { analyst-id: analyst-id }
          (merge analyst-data { reputation-score: new-score })
        )
        (ok new-score)
      )
      ERR-ANALYST-NOT-FOUND
    )
  )
)

;; Record analyst submission
(define-public (record-submission (analyst-id principal) (accuracy-score uint))
  (let ((submission-id (var-get next-submission-id)))
    (asserts! (is-some (map-get? analysts { analyst-id: analyst-id })) ERR-ANALYST-NOT-FOUND)
    (asserts! (<= accuracy-score u100) ERR-INVALID-REPUTATION)
    (map-set analyst-submissions
      { analyst-id: analyst-id, submission-id: submission-id }
      {
        timestamp: block-height,
        accuracy-score: accuracy-score,
        verified: true
      }
    )
    (var-set next-submission-id (+ submission-id u1))
    (ok submission-id)
  )
)

;; Get analyst information
(define-read-only (get-analyst-info (analyst-id principal))
  (map-get? analysts { analyst-id: analyst-id })
)

;; Check if analyst is verified
(define-read-only (is-analyst-verified (analyst-id principal))
  (match (map-get? analysts { analyst-id: analyst-id })
    analyst-data (get verified analyst-data)
    false
  )
)

;; Get analyst reputation
(define-read-only (get-analyst-reputation (analyst-id principal))
  (match (map-get? analysts { analyst-id: analyst-id })
    analyst-data (some (get reputation-score analyst-data))
    none
  )
)

;; Get submission info
(define-read-only (get-submission-info (analyst-id principal) (submission-id uint))
  (map-get? analyst-submissions { analyst-id: analyst-id, submission-id: submission-id })
)
