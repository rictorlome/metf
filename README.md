docker run -it -v `pwd`:/src echidna echidna-test /src/contracts/ETF.sol --contract /src/contracts/ETF.sol --config /src/contracts/fuzzing/config.yaml

`slither contracts/ETF.sol --solc /usr/local/bin/solc`
