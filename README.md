# STX Lending Protocol

A secure, decentralized lending protocol built on the Stacks blockchain, enabling users to deposit STX tokens as collateral, borrow against their positions, and participate in liquidations. This protocol is designed for Bitcoin Layer 2 compliance and includes comprehensive safety mechanisms to ensure protocol solvency.

## 🚀 Features

- **Collateralized Lending**: Deposit STX tokens as collateral to borrow against your position
- **Dynamic Collateral Ratios**: Configurable minimum collateral requirements with safety bounds
- **Liquidation System**: Automated liquidation mechanism to maintain protocol health
- **Interest Calculations**: Block-based interest accrual system
- **Admin Controls**: Governance functions for protocol parameter adjustments
- **Position Tracking**: Comprehensive user position management
- **Bitcoin L2 Compliance**: Built specifically for Stacks blockchain integration

## 📋 Protocol Parameters

| Parameter | Default Value | Range | Description |
|-----------|---------------|-------|-------------|
| Minimum Collateral Ratio | 150% | 110% - 500% | Required overcollateralization |
| Liquidation Threshold | 130% | 110% - MCR | Liquidation trigger point |
| Protocol Fee | 1% | 0% - 10% | Protocol service fee |

## 🏗️ Architecture

### Core Components

#### Data Structures

**Loan Management**

```clarity
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
```

**User Positions**

```clarity
(define-map user-positions
  { user: principal }
  {
    total-collateral: uint,
    total-borrowed: uint,
    loan-count: uint,
  }
)
```

#### Core Functions

- `deposit()` - Deposit STX as collateral
- `borrow(amount)` - Borrow STX against collateral
- `repay(amount)` - Repay borrowed STX
- `withdraw(amount)` - Withdraw excess collateral
- `liquidate(user)` - Liquidate undercollateralized positions

## 🛠️ Installation & Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### Quick Start

1. **Clone the repository**

   ```bash
   git clone https://github.com/emeka-favour/stx-lending.git
   cd stx-lending
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Check contract syntax**

   ```bash
   clarinet check
   ```

4. **Run tests**

   ```bash
   npm test
   ```

5. **Deploy locally**

   ```bash
   clarinet integrate
   ```

## 🧪 Testing

The project includes comprehensive test suites using Vitest and Clarinet SDK:

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Structure

- **Unit Tests**: Individual function testing
- **Integration Tests**: End-to-end protocol scenarios
- **Edge Cases**: Boundary condition testing
- **Security Tests**: Attack vector validation

## 📊 Usage Examples

### Basic Lending Flow

```clarity
;; 1. Deposit collateral
(contract-call? .lending deposit)

;; 2. Borrow against collateral (max 66% of collateral value at 150% ratio)
(contract-call? .lending borrow u1000000) ;; 1 STX

;; 3. Repay loan
(contract-call? .lending repay u1000000)

;; 4. Withdraw collateral
(contract-call? .lending withdraw u500000) ;; 0.5 STX
```

### Reading Protocol State

```clarity
;; Get user position
(contract-call? .lending get-user-position 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Get protocol statistics
(contract-call? .lending get-protocol-stats)
```

### Admin Operations

```clarity
;; Update collateral ratio (admin only)
(contract-call? .lending set-minimum-collateral-ratio u200) ;; 200%

;; Update liquidation threshold (admin only)
(contract-call? .lending set-liquidation-threshold u140) ;; 140%
```

## 🔒 Security Features

### Collateral Management

- **Overcollateralization**: Minimum 110% collateral ratio requirement
- **Dynamic Ratios**: Adjustable parameters within safe bounds
- **Position Validation**: Real-time collateral ratio checks

### Liquidation Protection

- **Threshold Monitoring**: Automated liquidation triggers
- **Incentive Alignment**: Liquidation rewards for protocol participants
- **Solvency Maintenance**: Automatic bad debt prevention

### Access Control

- **Owner-Only Functions**: Critical parameter changes restricted
- **Self-Liquidation Prevention**: Users cannot liquidate themselves
- **Input Validation**: Comprehensive parameter checking

## 🌐 Network Deployment

### Testnet Deployment

```bash
# Deploy to testnet
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

```bash
# Deploy to mainnet (requires configuration)
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## 📈 Protocol Economics

### Interest Model

- **Block-based Accrual**: Interest calculated per Stacks block
- **Fixed Rates**: Stable interest rate model
- **Compound Interest**: Automatic interest compounding

### Fee Structure

- **Protocol Fee**: Configurable fee on borrowing operations
- **Liquidation Bonus**: Incentive for liquidation participants

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`npm test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Standards

- Follow Clarity best practices
- Maintain comprehensive test coverage
- Document all public functions
- Use descriptive variable names
- Include error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/stacks/clarinet-js-sdk)
- [Stacks Explorer](https://explorer.stacks.co/)
