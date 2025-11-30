PriceFeedMirror Deployed on Reactive Lasna: [0x79b8176184a2eF79502a7b17E5A46B63aC7601f8](https://lasna.reactscan.net/address/0x2d84348941fc1f4303c9cc4839ac16a79f197d1c/contract/0x79b8176184a2eF79502a7b17E5A46B63aC7601f8?screen=subscriptions) <br/>
FeedProxy Deployed on eth sepolia :[0x58341b47d8227c9c40252E76947D8EF0a32bE3C7](https://sepolia.etherscan.io/address/0x58341b47d8227c9c40252E76947D8EF0a32bE3C7#code)

## Main contracts

*PriceFeedMirror.sol*: reactive contract on Lasna. Subscribes (via ISystemContract.subscribe) to the Amoy Chainlink aggregator’s AnswerUpdated event, validates the origin log, decodes answer/round data from topics, builds a payload including feed ID/metadata/domain/version, and emits the Callback event so the Reactive Network forwards updatePriceFeed to the Sepolia proxy. Allows owner to update feedProxyAddress and includes a receive() handler emitting Funded.

*FeedProxy.sol*: destination storage contract on Sepolia implementing AggregatorV3Interface. Authorizes updates from the Reactive VM ID, validates feed/domain/metadata, stores the mirrored round tuple plus metadata, and exposes latestRoundData, getRoundData, decimals, description, version for downstream consumers.

Deploy scripts

*DeployFeedProxy.s.sol*: runs on Sepolia, deploys FeedProxy with the Reactive VM ID (PriceFeedMirror address), Amoy aggregator address, decimals, and description; prints the proxy address.

*DeployPriceFeedMirror.s.sol*: runs on Lasna, deploys PriceFeedMirror with system-contract address, origin/destination chain IDs, Amoy aggregator, and the Sepolia proxy address; wraps subscribe in try/catch so local deployments don’t revert.
## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
# reactive
