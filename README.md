# Single-byte jumptable EVM function dispatcher in Huff •

Inspired by the latest [article by Degatchi](https://degatchi.com/articles/smart-contract-obfuscation#single-word-jumptable), this is a proof-of-concept implementation of a single-byte jumptable EVM function dispatcher written in [Huff](https://huff.sh/).

## Introduction

Under canonical ABI standards, the first 4 bytes of transaction `calldata` is reserved for the function `selector`. These bytes are matched against the selectors of all the defined functions in the contract. If a match is found, the program jumps to the corresponding function and executes it.

The standard Solidity implementation looks something like this:

```javascript
PUSH1 0x00        // [0x00]
CALLDATALOAD      // [calldata[0:32]]
PUSH1 0xE0        // [0xE0, calldata[0:32]]
SHR               // [selector]

/* dispatcher loop, run n times for n functions */
DUP1              // [selector, selector]
PUSH4 0x12345678  // [0x12345678, selector, selector]
EQ                // [0x12345678 == selector, selector]
PUSH1 0x40        // [0x40, 0x12345678 == selector, selector]
JUMPI             // [selector]
/* end dispatcher loop */
```

The `JUMPI` instruction jumps to the function code (at `PC=0x40` in the example above) if its selector (`0x12345678` in the above example) matches the one provided in the calldata. If no match is found, the program continues to the next function signature.

There is an alternative approach which can be used for optimization: the [binary search dispatching](https://docs.huff.sh/tutorial/function-dispatching/#binary-search-dispatching) method. This method is more gas-efficient in the case of a large number of functions, but the specific savings depend on the number of arbitrary pivot points you choose for the binary search.

This repo implements a third approach, which is **outside of the standard ABI**.

## How it works

The idea is to use a single-byte selector, which is then used to shift into a jump table. The jump table is a 32-bytes word packed with program counter locations corresponding to the function jump destinations program counters. This way, we don't have to iterate over the function selectors and can jump directly to the right function, which saves some gas if the number of functions is large enough.

Please take a look at the source code at [src/CustomDispatcher.huff](./src/CustomDispatcher.huff) for the full details.

## Running the tests

You can get started and run the tests with the following commands (assuming you have Foundry and Huff installed):

```shell
git clone git@github.com:merklefruit/huff-single-byte-dispatcher.git
cd huff-custom-dispatcher
forge test
```

## Limitations and caveats

- Since this implementation breaks the ABI standard, any contract with this setup won't be compatible with all the existing tooling. You will need to specify calldata manually which is not very convenient.
- The jump table is a 32-byte word with 2-bytes program counters. This means that the maximum number of functions that can be dispatched is 16.
- Filling the jumptable with the correct program counters corresponding to the function jump destinations is tricky and error-prone. This is where automated tools could come in handy, until then you will have to do it manually with a debugger like [evm.codes](https://evm.codes) or [forge](https://book.getfoundry.sh/reference/forge/forge-debug).

## Benchmarks

### Standard ABI dispatcher

- Gas cost: **34** for the first function
- Incremental gas cost: **22** for each subsequent function

### Single-byte dispatcher

- Gas cost: **32**
- Incremental gas cost: **0**

### Comparison

Here are the marginal gas savings expressed as a function of the function position _n_:

> _c(n) = ((34 + 22 \* (n - 1)) / 32 - 1) \* 100_

- Savings to reach the n = 1st function: ~6%
- Savings to reach the n = 8th function: ~487%
- Savings to reach the n = 16th function: ~1037%

## Acknowledgements

- [degatchi's article on evm obfuscation](https://degatchi.com/articles/smart-contract-obfuscation#single-word-jumptable)
- [huff-project-template](https://github.com/huff-language/huff-project-template)
- [forge-template](https://github.com/foundry-rs/forge-template)
- [femplate](https://github.com/abigger87/femplate)

## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._
