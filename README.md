PriceFeedMirror Deployed on Reactive Lasna: [0xaffd76b978b9F48F3EEbEB20cB1B43C699855Ee3](https://lasna.reactscan.net/address/0x2d84348941fc1f4303c9cc4839ac16a79f197d1c/contract/0xaffd76b978b9F48F3EEbEB20cB1B43C699855Ee3?screen=subscriptions) <br/>
FeedProxy Deployed on eth sepolia :[0x1b0bA94B1F01590E4aeCDa2363A839e99d57fF5b](https://sepolia.etherscan.io/address/0x1b0bA94B1F01590E4aeCDa2363A839e99d57fF5b#code)
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
