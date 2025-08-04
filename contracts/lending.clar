;; Title: STX Lending Protocol Smart Contract

;; Summary
;; This smart contract implements a secure, decentralized lending protocol
;; on the Stacks blockchain, enabling users to deposit STX tokens as collateral,
;; borrow against their positions, and participate in liquidations.
;; The protocol is designed for Bitcoin L2 compliance and includes
;; safety mechanisms to ensure protocol solvency.

;; Constants and Error Codes
;; Contract Owner
(define-constant CONTRACT-OWNER tx-sender)

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-LOAN-NOT-FOUND (err u103))
(define-constant ERR-LOAN-ACTIVE (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-LIQUIDATION-FAILED (err u106))
(define-constant ERR-INVALID-PARAMETER (err u107))

;; Protocol Parameters
(define-constant MAX-COLLATERAL-RATIO u500) ;; Maximum allowed collateral ratio (500%)
(define-constant MIN-COLLATERAL-RATIO u110) ;; Minimum required collateral ratio (110%)
(define-constant MAX-PROTOCOL-FEE u10) ;; Maximum protocol fee (10%)

;; Data Variables
(define-data-var minimum-collateral-ratio uint u150) ;; Default: 150%
(define-data-var liquidation-threshold uint u130) ;; Default: 130%
(define-data-var protocol-fee uint u1) ;; Default: 1%
(define-data-var total-deposits uint u0)
(define-data-var total-borrows uint u0)

;; Data Maps
;; Loan Data Structure
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    borrowed-amount: uint,
    interest-rate: uint,
    start-height: uint,
    last-interest-update: uint,
    active: bool,
  }
)

;; User Position Tracking
(define-map user-positions
  { user: principal }
  {
    total-collateral: uint,
    total-borrowed: uint,
    loan-count: uint,
  }
)

;; Private Functions
;; Calculate Interest
(define-private (calculate-interest
    (principal uint)
    (rate uint)
    (blocks uint)
  )
  (let (
      (interest-per-block (/ (* principal rate) u10000))
      (total-interest (* interest-per-block blocks))
    )
    total-interest
  )
)

;; Calculate Collateral Ratio
(define-private (get-collateral-ratio
    (collateral uint)
    (debt uint)
  )
  (if (is-eq debt u0)
    u0
    (/ (* collateral u100) debt)
  )
)

;; Update User Position
(define-private (update-user-position
    (user principal)
    (collateral-delta uint)
    (is-collateral-increase bool)
    (borrow-delta uint)
    (is-borrow-increase bool)
  )
  (let (
      (current-position (default-to {
        total-collateral: u0,
        total-borrowed: u0,
        loan-count: u0,
      }
        (map-get? user-positions { user: user })
      ))
      (new-collateral (if is-collateral-increase
        (+ (get total-collateral current-position) collateral-delta)
        (- (get total-collateral current-position) collateral-delta)
      ))
      (new-borrowed (if is-borrow-increase
        (+ (get total-borrowed current-position) borrow-delta)
        (- (get total-borrowed current-position) borrow-delta)
      ))
    )
    (map-set user-positions { user: user } {
      total-collateral: new-collateral,
      total-borrowed: new-borrowed,
      loan-count: (get loan-count current-position),
    })
  )
)

;; Public Functions - Core Protocol Operations
;; Deposit STX as Collateral
(define-public (deposit)
  (let ((amount (stx-get-balance tx-sender)))
    (if (> amount u0)
      (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set total-deposits (+ (var-get total-deposits) amount))
        (update-user-position tx-sender amount true u0 true)
        (ok amount)
      )
      ERR-INVALID-AMOUNT
    )
  )
)

;; Borrow STX Against Collateral
(define-public (borrow (amount uint))
  (let (
      (user-pos (default-to {
        total-collateral: u0,
        total-borrowed: u0,
        loan-count: u0,
      }
        (map-get? user-positions { user: tx-sender })
      ))
      (collateral (get total-collateral user-pos))
      (current-borrowed (get total-borrowed user-pos))
    )
    (if (and
        (> amount u0)
        (>= (get-collateral-ratio collateral (+ current-borrowed amount))
          (var-get minimum-collateral-ratio)
        )
      )
      (begin
        (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
        (var-set total-borrows (+ (var-get total-borrows) amount))
        (update-user-position tx-sender u0 true amount true)
        (ok amount)
      )
      ERR-INSUFFICIENT-COLLATERAL
    )
  )
)

;; Repay Borrowed STX
(define-public (repay (amount uint))
  (let (
      (user-pos (default-to {
        total-collateral: u0,
        total-borrowed: u0,
        loan-count: u0,
      }
        (map-get? user-positions { user: tx-sender })
      ))
      (current-borrowed (get total-borrowed user-pos))
    )
    (if (<= amount current-borrowed)
      (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set total-borrows (- (var-get total-borrows) amount))
        (update-user-position tx-sender u0 true amount false)
        (ok amount)
      )
      ERR-INVALID-AMOUNT
    )
  )
)

;; Withdraw Collateral
(define-public (withdraw (amount uint))
  (let (
      (user-pos (default-to {
        total-collateral: u0,
        total-borrowed: u0,
        loan-count: u0,
      }
        (map-get? user-positions { user: tx-sender })
      ))
      (collateral (get total-collateral user-pos))
      (borrowed (get total-borrowed user-pos))
    )
    (if (and
        (<= amount collateral)
        (>= (get-collateral-ratio (- collateral amount) borrowed)
          (var-get minimum-collateral-ratio)
        )
      )
      (begin
        (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
        (var-set total-deposits (- (var-get total-deposits) amount))
        (update-user-position tx-sender amount false u0 true)
        (ok amount)
      )
      ERR-INSUFFICIENT-COLLATERAL
    )
  )
)

;; Public Functions - Liquidation
(define-public (liquidate (user principal))
  (let (
      (user-pos (unwrap! (map-get? user-positions { user: user }) ERR-LOAN-NOT-FOUND))
      (collateral (get total-collateral user-pos))
      (borrowed (get total-borrowed user-pos))
      (ratio (get-collateral-ratio collateral borrowed))
    )
    (asserts! (not (is-eq user tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> borrowed u0) ERR-INVALID-AMOUNT)
    (if (< ratio (var-get liquidation-threshold))
      (begin
        (try! (as-contract (stx-transfer? collateral (as-contract tx-sender) tx-sender)))
        (map-delete user-positions { user: user })
        (var-set total-deposits (- (var-get total-deposits) collateral))
        (var-set total-borrows (- (var-get total-borrows) borrowed))
        (ok true)
      )
      ERR-LIQUIDATION-FAILED
    )
  )
)

;; Read-Only Functions
(define-read-only (get-user-position (user principal))
  (default-to {
    total-collateral: u0,
    total-borrowed: u0,
    loan-count: u0,
  }
    (map-get? user-positions { user: user })
  )
)