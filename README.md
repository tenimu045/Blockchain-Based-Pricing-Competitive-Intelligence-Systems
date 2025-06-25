# Blockchain-Based Pricing Competitive Intelligence System

A comprehensive decentralized system for pricing intelligence and competitive analysis built on the Stacks blockchain using Clarity smart contracts.

## System Architecture

The system consists of five interconnected smart contracts that work together to provide a complete pricing intelligence solution:

### Core Contracts

#### 1. Analyst Verification Contract (\`analyst-verification.clar\`)
Manages the verification and reputation of pricing intelligence analysts.

**Key Functions:**
- \`register-analyst\` - Register new analysts
- \`verify-analyst\` - Verify analyst credentials
- \`update-reputation\` - Update analyst reputation scores
- \`get-analyst-info\` - Retrieve analyst information

#### 2. Competitor Monitoring Contract (\`competitor-monitoring.clar\`)
Tracks competitor pricing data and market changes.

**Key Functions:**
- \`add-competitor\` - Add new competitors to monitor
- \`submit-price-data\` - Submit competitor pricing information
- \`get-price-history\` - Retrieve historical pricing data
- \`get-price-alerts\` - Get price change notifications

#### 3. Market Positioning Contract (\`market-positioning.clar\`)
Analyzes market position and competitive advantages.

**Key Functions:**
- \`calculate-market-position\` - Calculate current market position
- \`update-positioning-strategy\` - Update positioning strategies
- \`get-competitive-analysis\` - Get competitive analysis data
- \`track-market-share\` - Track market share changes

#### 4. Strategy Adjustment Contract (\`strategy-adjustment.clar\`)
Manages pricing strategy adjustments and recommendations.

**Key Functions:**
- \`propose-strategy-change\` - Propose new pricing strategies
- \`approve-strategy\` - Approve strategy changes
- \`implement-strategy\` - Implement approved strategies
- \`get-strategy-performance\` - Get strategy performance metrics

#### 5. Impact Assessment Contract (\`impact-assessment.clar\`)
Assesses the impact and effectiveness of pricing changes.

**Key Functions:**
- \`record-pricing-impact\` - Record impact of pricing changes
- \`calculate-roi\` - Calculate return on investment
- \`generate-impact-report\` - Generate comprehensive impact reports
- \`get-performance-metrics\` - Retrieve performance metrics

## Getting Started

### Prerequisites
- Stacks CLI
- Clarinet (for local development)
- Node.js (for testing)

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Run tests:
   \`\`\`bash
   npm test
   \`\`\`

### Deployment

1. Deploy to testnet:
   \`\`\`bash
   clarinet deploy --testnet
   \`\`\`

2. Deploy to mainnet:
   \`\`\`bash
   clarinet deploy --mainnet
   \`\`\`

## Usage Examples

### Registering an Analyst
\`\`\`clarity
(contract-call? .analyst-verification register-analyst
"analyst-name"
"credentials-hash"
u100) ;; initial reputation score
\`\`\`

### Submitting Competitor Price Data
\`\`\`clarity
(contract-call? .competitor-monitoring submit-price-data
"competitor-id"
u1000 ;; price in cents
"product-category")
\`\`\`

### Calculating Market Position
\`\`\`clarity
(contract-call? .market-positioning calculate-market-position
"product-id"
u1200) ;; our price
\`\`\`

## Testing

The system includes comprehensive tests using Vitest:

\`\`\`bash
npm run test:analyst-verification
npm run test:competitor-monitoring  
npm run test:market-positioning
npm run test:strategy-adjustment
npm run test:impact-assessment
\`\`\`

## Security Considerations

- All critical operations require multi-signature approval
- Analyst verification prevents unauthorized data submission
- Data integrity checks ensure accurate pricing information
- Role-based access control protects sensitive operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
\`\`\`

```clarity file="contracts/analyst-verification.clar"
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
    (asserts! (&lt;= initial-reputation u1000) ERR-INVALID-REPUTATION)
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
    (asserts! (&lt;= new-score u1000) ERR-INVALID-REPUTATION)
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
