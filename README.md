# Hardhat Noir Template Repository

A hardhat template repository for developing noir (zk) circuits.

## Getting started

Click the `Use this template` button at the top of this repository to create a new repository from this template.

## Installation

You'll need:

- Noir (nargo CLI - Installation steps can be found here https://noir-lang.org/)
- npm or yarn (whatever - so long as you can run `hardhat` on your CLI)

Once you've cloned the repo, run:

```
yarn install // or npm, whatever floats your boat
```

to install all necessary packages.

## Tips and Tricks

Most of this repository contains boilerplate code that can be removed (contents of `circuits/`, `deploy/`, `contracts/` and `test/` primarily).

### Creating and Returning a Testing API for a Circuit

If you want to create a new circuit (zk program), from the `circuits/` directory, run:

```
nargo new <circuit_name>
```

So, say we run `nargo new myCircuit`, we should now have the following files at `circuits/myCircuit/`:

```bash
.
├── src
│   └── main.nr   # the main circuit file
└── Nargo.toml    # the .toml specification for that noir circuit
```

Once you've got this circuit created - you can use the `returnCircuitTestingAPI()` util to get a testing API for your circuit in hardhat, like so:

```ts
const { barretenberg, pedersen, boardCircuit, acir, prover, verifier } =
  await returnCircuitTestingAPI("myCircuit");
```

And you're ready to test this circuit in hardhat.

### Turning your Circuit into a Contract

(I think) It's more efficient to evaluate your proofs firstly using wasm/ts tests first - but once you've done that it's time to turn your circuit into a contract.

You can use this repo's `create-contract` hardhat task to this for you, and rename it to a more specific contract name (e.g. `myCircuitVerifier.sol`) to allow for nicer deployment scripts. To use this task with our above example (our `myCircuit` circuit), you'd run:

```
npx hardhat create-contract --circuit myCircuit
```

This will generate your Circuit contract file for you using nargo - but move it into your `contracts/` directory and rename it to be your circuit name + `Verifier.sol` (e.g. `myCircuitVerifier.sol`), as well as rename the actual contract from `TurboVerifier` (nargo default) to `MyCircuit`.

Alternatively - you can do this using noir by doing the following (using our example `myCircuit` from above):

```
cd circuits/myCircuit
nargo codegen-verifier
```

This will create a `plonk_vk.sol` file at `circuits/myCircuit/contracts/` which you can then use in your hardhat project.
