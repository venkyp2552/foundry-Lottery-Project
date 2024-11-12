## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**
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

## Tests !
1.Write Deploy Scripts
    1.Note, these will not work i zksync
2.Write tests
    1.Local Chain
    2.Forked testnet
    3.Forked mainnet