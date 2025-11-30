PriceFeedMirror Deployed on Reactive Lasna: [0x984E73D5F27859b05118205A9C73A3B5e0816B4B](https://lasna.reactscan.net/address/0x2d84348941fc1f4303c9cc4839ac16a79f197d1c/contract/0x984E73D5F27859b05118205A9C73A3B5e0816B4B?screen=subscriptions) <br/>
FeedProxy Deployed on eth sepolia :[0x8dca148Fc929cD40722405FdCA958221F4155d66](https://sepolia.etherscan.io/address/0x8dca148Fc929cD40722405FdCA958221F4155d66#code)
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
