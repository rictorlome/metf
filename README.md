1. Install slither
2. Install solc 0.8.3
3. Install echidna-test

Change `block.chainid` to some number to unbreak slither, then:

`slither contracts/ETF.sol --solc /usr/local/bin/solc`

`~/Downloads/echidna-test/echidna-test contracts/test/ETFFuzzing.sol --contract ETFFuzzing --config echinda.config.yaml`
