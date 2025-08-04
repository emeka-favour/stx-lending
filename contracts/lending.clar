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