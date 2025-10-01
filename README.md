# DRO Whale Dump Detector

A Drosera trap that monitors top DRO token holders on Hoodi testnet and triggers alerts when any whale dumps more than 20% of their holdings in a single transaction.

## Live Deployment

- **Network:** Hoodi Testnet (Chain ID: 560048)
- **Trap Address:** `0xf67A565f1A747E2bC83D55Bc4FeB8dBeea8c27a2`
- **Monitoring Token:** $DRO (`0x499b095Ed02f76E56444c242EC43A05F9c2A3ac8`)
- **Threshold:** 20% balance drop

## What This Does

This Drosera trap:
- Monitors 3 whale addresses holding large amounts of DRO tokens
- Collects their balances every block
- Compares current balance to previous block
- Triggers a response if any whale's balance drops by 20% or more
- Can be customized to track any ERC-20 token and any threshold

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Bun](https://bun.sh/) (for dependencies)
- [Drosera CLI](https://app.drosera.io/install)
- Hoodi testnet ETH for deployment gas

## Quick Start

### 1. Clone and Install

```bash
git clone https://github.com/chiefmmorgs/whale-dump-detector.git
cd whale-dump-detector

# Install dependencies
bun install

# Install Drosera CLI
curl -L https://app.drosera.io/install | bash
droseraup
```

### 2. Configure Your Whale Addresses

Edit `src/WhaleDumpDetector.sol` and replace the whale addresses with your target addresses:

```solidity
// Find top holders at your token's block explorer
address public constant WHALE_1 = 0xYourWhaleAddress1;
address public constant WHALE_2 = 0xYourWhaleAddress2;
address public constant WHALE_3 = 0xYourWhaleAddress3;
```

### 3. Optional: Change Token or Threshold

To monitor a different token:
```solidity
address public constant TOKEN = 0xYourTokenAddress;
```

To change the dump threshold (default 20%):
```solidity
// 10% = 100000000000000000
// 20% = 200000000000000000
// 30% = 300000000000000000
uint256 public constant THRESHOLD_PCT = 200000000000000000;
```

### 4. Create Environment File

```bash
cp .env.example .env
nano .env
```

Add your private key:
```bash
DROSERA_PRIVATE_KEY=0xYourPrivateKeyHere
```

### 5. Build and Deploy

```bash
# Compile the contract
forge build

# Deploy to Hoodi testnet
source .env
DROSERA_PRIVATE_KEY=$DROSERA_PRIVATE_KEY drosera apply
```

Type `ofc` when prompted to confirm deployment.

### 6. Get Your Trap Address

After successful deployment, your trap address will be added to `drosera.toml`:

```toml
[traps.whale_dump_dro]
address = "0xYourTrapAddress"  # <-- This gets added automatically
```

## How It Works

The trap uses Drosera's `collect` and `shouldRespond` pattern:

1. **collect()** - Called every block to gather whale balances
2. **shouldRespond()** - Analyzes last 2 blocks of data:
   - Compares each whale's current balance to previous balance
   - Calculates percentage drop: `(oldBalance - newBalance) / oldBalance`
   - Returns `true` if drop >= threshold
   - Encodes dump details in response data

## Finding Whale Addresses

To find top token holders:

1. Go to Hoodi testnet block explorer
2. Search for your target token address
3. Click "Holders" tab
4. Copy the top 3-10 addresses with largest balances
5. Update them in `src/WhaleDumpDetector.sol`

For DRO token specifically:
- Token: `0x499b095Ed02f76E56444c242EC43A05F9c2A3ac8`
- Explorer: https://hoodi.etherscan.io/token/0x499b095Ed02f76E56444c242EC43A05F9c2A3ac8

## Configuration

### drosera.toml Settings

```toml
[traps.whale_dump_dro]
path = "out/WhaleDumpDetector.sol/WhaleDumpDetector.json"
response_contract = "0x183D78491555cb69B68d2354F7373cc2632508C7"
response_function = "helloworld(string)"
cooldown_period_blocks = 33
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size = 2
private_trap = true
whitelist = []
```

Key settings:
- **cooldown_period_blocks**: Minimum blocks between responses
- **block_sample_size**: Number of historical blocks to analyze (2 minimum)
- **private_trap**: If true, only whitelisted operators can run
- **whitelist**: Array of operator addresses allowed to run your trap

## Getting Testnet Funds

You need Hoodi testnet ETH to deploy (~0.006 ETH for gas).

Get testnet tokens from:
- Drosera Discord faucet channel: https://discord.gg/drosera
- Hoodi testnet faucet (check Hoodi documentation)

Check your balance:
```bash
cast balance YOUR_ADDRESS --rpc-url https://ethereum-hoodi-rpc.publicnode.com
```

Visit https://app.drosera.io/ and connect your wallet to see:
- Trap status
- Operator activity
- Response history
- Hydration level

## Customization Examples

### Monitor Different Token

```solidity
// USDC on Hoodi
address public constant TOKEN = 0xUSDCAddress;
```

### More Sensitive Detection

```solidity
// Trigger on 10% dumps instead of 20%
uint256 public constant THRESHOLD_PCT = 100000000000000000;
```

### Track More Whales

Add more whale constants and update the CollectOutput struct:

```solidity
address public constant WHALE_4 = 0x...;
address public constant WHALE_5 = 0x...;

struct CollectOutput {
    address whale1;
    address whale2;
    address whale3;
    address whale4;  // Add new whales
    address whale5;
    uint256 balance1;
    uint256 balance2;
    uint256 balance3;
    uint256 balance4;
    uint256 balance5;
    uint256 blockNumber;
}
```

Then update the `collect()` and `shouldRespond()` functions accordingly.


## Project Structure

```
whale-dump-detector/
├── src/
│   ├── WhaleDumpDetector.sol    # Main trap contract
│   ├── HelloWorldTrap.sol        # Example trap
│   ├── ResponseTrap.sol          # Example trap
│   └── TransferEventTrap.sol     # Example trap
├── test/
│   └── *.t.sol                   # Test files
├── drosera.toml                  # Drosera configuration
├── foundry.toml                  # Foundry configuration
└── .env.example                  # Environment template
```

## Troubleshooting

### "insufficient funds for gas"
- Get Hoodi testnet ETH from faucet
- Check balance with `cast balance YOUR_ADDRESS --rpc-url https://ethereum-hoodi-rpc.publicnode.com`

### "Failed to get block" errors
- RPC might be rate limiting
- Try using Alchemy or QuickNode RPC
- Reduce `block_sample_size` to 2 in drosera.toml


## Resources

- [Drosera Documentation](https://dev.drosera.io/)
- [Drosera Discord](https://discord.gg/drosera)
- [Trap Examples](https://github.com/drosera-network/examples)

## License

MIT

## Contributing

Pull requests welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with `forge test`
5. Submit a pull request

## Acknowledgments

Built using the [Drosera Trap Foundry Template](https://github.com/drosera-network/trap-foundry-template)
```
