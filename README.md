###  100daysSolidity_Web3 Challenge projects ###


# 🚀 100 Days of Solidity & Web3 Challenge

Welcome to the **100 Days of Solidity & Web3 Challenge** repository! This project maps out a rigorous, step-by-step developer roadmap designed to take you from writing basic state variables to building production-ready, highly secure, and optimized decentralized applications (DApps).

## 🛠️ Challenge Structure
The roadmap is divided into 7 distinct progressive tiers. Each milestone builds directly on top of the architectural patterns, security mechanisms, and gas optimization strategies learned in the previous sections.

---

## 🟢 Category 1: Absolute Beginner (Syntax & Basics)
* **Focus:** Understanding the EVM state, variable scoping, data types, standard arithmetic, and basic memory allocations (`memory`, `storage`, `calldata`).

- [ ] **Day 01:** Hello World — Store, modify, and read a simple state string.
- [ ] **Day 02:** Simple Counter — Basic arithmetic loops using increment, decrement, and reset functions.
- [ ] **Day 03:** Basic Calculator — Safe math practices utilizing add, subtract, multiply, and divide features.
- [ ] **Day 04:** Number Storer — A simple getter/setter layout emphasizing state visibility (`public`, `private`).
- [ ] **Day 05:** Array Explorer — Appending, modifying, and reading array items inside fixed vs. dynamic arrays.
- [ ] **Day 06:** Even or Odd Checker — Working with conditional branches and boolean outputs.
- [ ] **Day 07:** Basic Struct User — Declaring, organizing, and accessing customized structural records (e.g., User profiles).
- [ ] **Day 08:** Simple Mapping — Key-value database storage using `mapping(address => string)`.
- [ ] **Day 09:** Boolean Toggler — Efficient bit-flipping logic to toggle boolean states.
- [ ] **Day 10:** String Concatenator — Working with dynamic memory compilation using `abi.encodePacked`.
- [ ] **Day 11:** Constant Explorer — Minimizing deployment and runtime gas overhead using `constant` and `immutable`.
- [ ] **Day 12:** Array Summer — Constructing deterministic `for` loops to process array elements.
- [ ] **Day 13:** Simple Enum — Managing contract states using readable tracking states (`Pending`, `Active`, `Closed`).
- [ ] **Day 14:** Local vs State — Deep dive into variable execution scoping and storage persistence rules.
- [ ] **Day 15:** Address Tracker — Interacting with runtime environmental variables using `msg.sender`.

---

## 🟡 Category 2: Control Flow & Access Control
* **Focus:** Security validations, state mutations, exception management via custom errors, and conditional transaction boundaries.

- [ ] **Day 16:** Owner Restricted — Building custom function modifiers (`onlyOwner`) to isolate administrative powers.
- [ ] **Day 17:** Simple Whitelist — Restricting operations to a mapped registry of authorized accounts.
- [ ] **Day 18:** Basic Pausable Contract — Implementing emergency circuit-breakers to halt state operations.
- [ ] **Day 19:** Simple Time-Lock — Using `block.timestamp` constraints to restrict function access until a target date.
- [ ] **Day 20:** Custom Error Logger — Gas-optimized error handling via the `revert CustomError()` pattern over string errors.
- [ ] **Day 21:** Age Gate — Guarding function bodies using standard `require()` assertion statements.
- [ ] **Day 22:** Max Limit Cap - Enforcing strict arrays or value thresholds to mitigate unbounded processing risk.
- [ ] **Day 23:** Fallback Tracker — Overriding default transaction execution using `fallback()` and `receive()` methods.
- [ ] **Day 24:** Blacklist Contract — Introducing logic to programmatically freeze interactions from rogue addresses.
- [ ] **Day 25:** Multi-Owner Modifier — Requiring permissions from an authorized group of static addresses.
- [ ] **Day 26:** Grade Book — Implementing multi-dimensional lookup architectures via nested mappings (`mapping(address => mapping(string => uint))`).
- [ ] **Day 27:** Simple Auth Lookup — Executing secure verification lookups using `keccak256` hashing algorithms.
- [ ] **Day 28:** State Machine Workflow — Managing linear lifecycle progression using validation gates.
- [ ] **Day 29:** Modern Self-Destruct Practice — Writing emergency withdrawal routines avoiding deprecated `selfdestruct` calls.
- [ ] **Day 30:** Fee Collector Modifier — Forcing minimal native execution fees inside transactional methods.

---

## 🔵 Category 3: Native Ether Transfers & Wallets
* **Focus:** Mastering payment processing, value flows, accounting states, and safe execution transfers (`call` vs. `transfer`/`send`).

- [ ] **Day 31:** Digital Piggy Bank — Escrowing native ETH into a smart contract that can be cracked open by its owner.
- [ ] **Day 32:** Split Pay — Automatically split incoming values 50/50 across hardcoded beneficiary wallets.
- [ ] **Day 33:** Simple Savings Account — Managing distinct ledger allocations inside user balance mappings.
- [ ] **Day 34:** Salary Streamer — Linearly releasing native ETH balances over elapsed block durations.
- [ ] **Day 35:** Tip Jar — Emitting indexable transaction logs alongside native micro-donations.
- [ ] **Day 36:** Event Logger Ledger — Structural audit logging using contract events (`emit`).
- [ ] **Day 37:** Escrow Contract — Mediating value distributions between buyers and sellers via an arbiter.
- [ ] **Day 38:** Multi-Sig Wallet Lite — Enforcing a 2-of-3 multisig scheme before approving transactional execution payloads.
- [ ] **Day 39:** Time-Locked Vault — Enforcing 30-day structural lockups with absolute zero early exit routes.
- [ ] **Day 40:** Shared Expense Pot — Group pooling ledger letting accounts spend allocations up to explicit ceilings.
- [ ] **Day 41:** Allowance Wallet — Setting up hierarchical spend authorizations for authorized sub-wallets.
- [ ] **Day 42:** Auto-Forwarder — Instant, low-overhead transaction proxy routing incoming ETH straight to a cold wallet.
- [ ] **Day 43:** Subscription Receiver — Mapping access control gates against recurring payment timelines.
- [ ] **Day 44:** Merit Bonus Distributor — Distributing custom batches of native token payments across structural work lists.
- [ ] **Day 45:** Gas-Saver Vault — Packing multiple variables into single 256-bit slots to minimize storage write operations.

---

## 🟣 Category 4: Token Standards (ERC-20 & ERC-721 Fundamentals)
* **Focus:** EIP specifications, custom tokenomics, minting limits, metadata architectures, and single/multi-token deployments.

- [ ] **Day 46:** Custom Meme Coin — Building an ERC-20 compliant token contract from scratch.
- [ ] **Day 47:** Capped Token Supply — Hardcoding immutable ceilings onto standard token generation logic.
- [ ] **Day 48:** Burnable Utility Token — Decreasing circulating supplies through verifiable token burning.
- [ ] **Day 49:** Pausable Token Transfer — Enabling globally managed locks to secure tokens during critical events.
- [ ] **Day 50:** Fixed-Rate Token Faucet — Restricting token distributions via time-locked claims per address.
- [ ] **Day 51:** Basic NFT Digital Art — Implementing the fundamental ERC-721 token specification tracking token IDs.
- [ ] **Day 52:** Collectible NFT Minting Cap — Creating hard collection caps (e.g., 10,000 max units) on mint functions.
- [ ] **Day 53:** Dynamic Metadata NFT — Modifying token state variables and URIs based on on-chain triggers.
- [ ] **Day 54:** Whitelisted NFT Mint — Enforcing preferential pricing arrays for designated early wallets.
- [ ] **Day 55:** Soulbound Token (SBT) — Stripping transfer mechanics from tokens to build non-transferable identity badges.
- [ ] **Day 56:** Multi-Token Store — Combining fungible and non-fungible items under a unified ERC-1155 configuration.
- [ ] **Day 57:** Token Air-dropper — Creating optimized batch arrays to distribute tokens across multiple targets in one transaction block.
- [ ] **Day 58:** Dividend Paying Token — Distributing native protocol fee collections proportionally across existing token holders.
- [ ] **Day 59:** Time-Vesting Token Release — Implementing structural vest schedules (e.g., 4-year cliffs) for team allocations.
- [ ] **Day 60:** Buyback Contract — Automatically converting contract fee revenues into target ecosystem tokens.

---

## 🟠 Category 5: Practical DApps & Real-World Apps
* **Focus:** Architectural application state design, lifecycle processing, multi-party logic, and cryptographic verifications.

- [ ] **Day 61:** Decentralized To-Do List — Structuring basic CRUD state allocations on-chain.
- [ ] **Day 62:** Secure Ballot Voting — Creating Sybil-resistant voting mechanisms with double-vote protection.
- [ ] **Day 63:** Decentralized Kickstarter — Managing crowd-backed escrow structures with dynamic conditional refunds.
- [ ] **Day 64:** Blind Bid Auction — Designing secure two-phase commit-reveal schemes using hashed secret profiles.
- [ ] **Day 65:** Transparent Lottery — Creating pseudo-random outcome systems using historical block metrics.
- [ ] **Day 66:** Peer-to-Peer Car Rental — Managing physical time-slot calendar allocations across shared assets.
- [ ] **Day 67:** On-Chain Resumé Store — Publishing permanent, unalterable academic or career records on-chain.
- [ ] **Day 68:** Real Estate Title Deeds — Tracking physical ownership models by mapping deeds to unique non-fungible indices.
- [ ] **Day 69:** Supply Chain Tracker — Recording multi-party logistics data as goods pass through checkpoints.
- [ ] **Day 70:** Decentralized Freelance Board — Escrowing milestones between clients and independent workers.
- [ ] **Day 71:** Fake Product Identifier — Verifying manufacturer production records using cryptographic provenance.
- [ ] **Day 72:** Medical Record Permissions — Giving patients ownership over clinical data access rights.
- [ ] **Day 73:** Digital Wills & Inheritance — Building decentralized dead-man's switches to transfer assets to beneficiaries.
- [ ] **Day 74:** Hotel Room Booking Engine — Structuring secure room check-in and checkout variables.
- [ ] **Day 75:** Intellectual Copyright Vault — Generating tamper-proof timestamp proofs for creative works.

---

## 🔴 Category 6: DeFi & Web3 Ecosystem Connectors
* **Focus:** Cross-contract composition, mathematical design models, external oracles, and building protocols.

- [ ] **Day 76:** Simple Staking Yield Pool — Calculating and distributing continuous programmatic block rewards.
- [ ] **Day 77:** Flash Loan Practice Simulation — Executing single-transaction atomic borrow and repayment structures.
- [ ] **Day 78:** Chainlink Price Aggregator Feed — Integrating production-grade external oracle feeds for asset evaluation.
- [ ] **Day 79:** Oracle-Driven Weather Insurance — Executing conditional payouts triggered by external weather oracle readings.
- [ ] **Day 80:** Constant Product AMM Lite — Implementing automated market maker swap mechanics using $x \cdot y = k$.
- [ ] **Day 81:** DeFi Crypto Index Fund — Combining and balancing multi-asset allocations inside a smart contract.
- [ ] **Day 82:** Collateralized Loan — Minting algorithmic synthetic tokens against over-collateralized assets.
- [ ] **Day 83:** Yield Aggregator Re-balancer — Dynamically moving capital across contracts depending on yield rates.
- [ ] **Day 84:** Automated Trading Bot Trigger — Opening programmatic access interfaces for authorized keepers.
- [ ] **Day 85:** Token Swapper — Interfacing directly with Uniswap swap routers from your own contract.
- [ ] **Day 86:** Decentralized Stablecoin System — Managing systematic adjustments to defend stablecoin pegs.
- [ ] **Day 87:** EIP-712 Meta-Transactions — Implementing off-chain cryptographic signatures to support gasless user interactions.
- [ ] **Day 88:** Prediction Market Pool — Resolving binary prediction markets based on verifiable external events.
- [ ] **Day 89:** Liquid Staking Derivative — Minting liquid wrapped token representations of locked staked assets.
- [ ] **Day 90:** Merkle Tree Airdrop System — Using Merkle proofs for ultra-low-gas verification across thousands of users.

---

## 🟣 Category 7: DAOs & Web3 Social Games
* **Focus:** Governance game-theory mechanics, multi-user mechanics, coordinate mapping, and shared treasury architectures.

- [ ] **Day 91:** Basic DAO Governance — Building proposal workflows, voting metrics, and auto-executing code blocks.
- [ ] **Day 92:** Quadratic Voting Registry — Structuring balanced, cost-squared governance distributions.
- [ ] **Day 93:** Decentralized Forum Board — Mitigating social spam by putting micro-token weights on creation and upvotes.
- [ ] **Day 94:** Web3 Domain Name Registrar — Mapping, managing, and trading human-readable aliases to crypto addresses.
- [ ] **Day 95:** On-Chain Tic-Tac-Toe — Managing game coordinates and turns inside state matrices.
- [ ] **Day 96:** CryptoZombies-Style Fighter — Handling asset states, levels, and battle calculations.
- [ ] **Day 97:** Decentralized Casino Roulette — Managing multi-choice bets against secure outcome verifications.
- [ ] **Day 98:** Web3 Chess Match Staking — Handling multi-party fund escrows settled by match outcomes.
- [ ] **Day 99:** Guild Multi-Signature Vault — Shared inventory management models built for collaborative groups.
- [ ] **Day 100:** Decentralized Ad Space Board — Dynamically leasing digital pixel layout grids via continuous token auctions.

---

## 🚀 How to Use This Repo
1. **Clone the Repo:** `git clone https://github.com/Ashfaque965/100daysSolidity_Web3-Challenge-projects.git`
2. **Setup Environment:** Install [Hardhat](https://hardhat.org/) or [Foundry](https://book.getfoundry.sh/).
3. **Log Progress:** Update the checkboxes in this `README.md` file as you complete each daily challenge!



---

## 🛠️ Development & Testing Workflow

To streamline development through this 100-day journey, we utilize **Foundry** for blazing-fast testing and advanced gas profiling, and **Hardhat** for historical mainnet forking exercises (useful in Category 6 & 7).

### 📋 Prerequisites

Ensure you have the following installed on your machine:
* [Node.js](https://nodejs.org/) (v18 or higher)
* [Git](https://git-scm.com/)
* [Foundry / Forge](https://book.getfoundry.sh/getting-started/installation)

### 🏗️ Getting Started with Foundry

1. **Initialize the workspace (if starting fresh):**
   ```bash
   forge init



   Compile your smart contracts:

Bash
forge build
Run tests with high verbosity:

Bash
forge test -vvvv
Analyze gas consumption snapshots:

Bash
forge snapshot
🔒 Security Best Practices Checklist
As you move from Category 1 into intermediate protocols, treat security as a first-class citizen. Every production-ready contract should adhere to these core rules:

[ ] Reentrancy Protection: Always apply the Checks-Effects-Interactions pattern or use OpenZeppelin's ReentrancyGuard (nonReentrant modifier) when shifting native Ether or interacting with untrusted addresses.

[ ] Safe Transfers: Never use transfer() or send() for native ETH movements. Always opt for the low-level .call{value: amount}("") combined with a reentrancy check.

[ ] Integer Overflows: Rely on Solidity 0.8.x native panic errors for arithmetic, and explicitly use unchecked {} blocks only when wrapping is mathematically impossible or gas profiling demands it.

[ ] Visibility Hygiene: Default your functions to external or internal where applicable to save jump destination gas. Explicitly label variables as private or public.

[ ] Upgradeability & Deletions: Avoid selfdestruct. Use structural factory patterns or modern proxy architectures if lifecycle component replacements are needed.

📊 Progress Dashboard
Track your mastery milestones as you transition through the smart contract hierarchy:

Category	Focus Area	Status	Difficulty
🟢 Category 1	Syntax, Basic Storage & EVM Memory Types	0 / 15	Fundamental
🟡 Category 2	Control Flow, Mappings & Access Restraints	0 / 15	Easy
🔵 Category 3	Value Transfers, Native Escrows & Accounting Ledgering	0 / 14	Medium
🟣 Category 4	Standard Architectures (ERC-20, 721, 1155)	0 / 15	Medium
🟠 Category 5	Complete Standalone Applied Architectural Systems	0 / 15	Intermediate
🔴 Category 6	External Composition, DeFI Integrations & Oracles	0 / 15	Advanced Intermediate
🟣 Category 7	Complex On-Chain Governance & Game States	0 / 10	Advanced Intermediate
🤝 Contributing & Community
Are you following along with this challenge or looking to optimize an implementation?

Fork this repository to track your own versions of the code!

Open a Pull Request if you spot an opportunity for gas optimization (e.g., custom errors over string reverts, tighter variable packing).

Drop a ⭐️ on this repository if it helps your Web3 engineering journey!

📄 License
This repository is open-source software licensed under the MIT License.

“The best way to understand the Ethereum Virtual Machine is to build it out block by block. Happy hacking!”#   3 0 0 - D a y s - o f - S o l i d i t y - W e b 3 - D e v e l o p m e n t - C h a l l e n g e - p r o j e c t s  
 