# Hardhat Noir Template Repository (with Foundry Support)

A hardhat template repository for developing noir (zk) circuits.

## Getting started

Click the `Use this template` button at the top of this repository to create a new repository from this template.

## Installation

You'll need:

- Noir (nargo CLI - Installation steps can be found [here](https://noir-lang.org/getting_started/nargo/nargo_installation)).
- Node Package Manager (npm, yarn, pnpm, etc. - whatever suits - so long as you can run `hardhat` on your CLI).
- _Optional_ Foundry (Forge CLI) - Installation steps can be found [here](https://getfoundry.sh/)

Once you've cloned the repo, run:

```bash
# using yarn - or use npm or pnpm
yarn install
```

to install all necessary packages.

## What's Inside

I made this repository as I was having trouble getting a hardhat project to work with noir - so I thought I'd make a template repository to help others get started. The connectivity circuit example within this template is an example of how to write a very basic circuit, compile and test it using BarretenbergWasm from within hardhat, and have the ability to turn it into a contract that can be tested as part of a hardhat project.

## Tips and Tricks

Most of this repository contains boilerplate code that can be removed (contents of `circuits/`, `deploy/`, `contracts/` and `test/` primarily).

### Creating and Returning a Testing API for a Circuit

If you want to create a new circuit (zk program), from the `circuits/` directory, run:

```bash
nargo new <circuit_name>
```

where `<circuit_name>` is the name of your circuit.

So, say we run `nargo new myCircuit`, we should now have the following files at `circuits/myCircuit/`:

```bash
.
├── src
│   └── main.nr   # the main circuit file
└── Nargo.toml    # the .toml specification for that noir circuit
```

You can then write your circuit in `src/main.nr` - and once you're done, you can compile it using:

```bash
nargo check
```

This will add 2 new files, `Prover.toml` and `Verifier.toml` to your `circuits/myCircuit/` directory, like so:

```bash
.
├── src
│   └── main.nr      # the main circuit file
├── Nargo.toml       # the .toml specification for that noir circuit
├── Prover.toml      # where the inputs to generate a proof for your circuit go
└── Verifier.toml    # where the output of a proof goes to be used in a verification
```

As the default `Prover.toml` and `Verifier.toml` files are empty, you'll need to add some example inputs to get them working. The default `main.nr` circuit generated by `nargo new` just accepts 2 inputs, x and y, and ensures that `x != y`. If this condition is met - it outputs a verification proof, and if it's not met - nargo will throw an error. You can try this by setting the contents of `Prover.toml` like so:

```
x = "1"
y = "2"
```

and then to generate a proof - run:

```bash
nargo prove p
```

This will generate a proof `target` directory for your circuit, as well as output a proof to `Verifier.toml` - which you can then use to verify your proof using:

```bash
nargo verify p
```

If all goes well, the CLI won't output anything. If it output something - something has gone wrong.

This is a very simple example of a proof - but this should be enough to demonstrate the general proof/verification process. To read more on noir's commands - check out the [nargo CLI docs](https://noir-lang.org/getting_started/nargo/commands).

### Working in Hardhat

Once you've got this circuit created - you can use this templates `returnCircuitTestingAPI()` util to get a testing API for your circuit in hardhat, like so:

```ts
const { barretenberg, pedersen, boardCircuit, acir, prover, verifier } =
  await returnCircuitTestingAPI("myCircuit");
```

And you're ready to test this circuit in hardhat. See the `test/connectivity.test.ts` file for an example of how to use both this function and these variables in hardhat, evaluating the simple `circuits/connectivity/src/main.nr` circuit included in this template.

### Turning your Circuit into a Contract

It's more efficient to evaluate your proofs firstly using wasm/ts tests first - but once you've done that it's time to turn your circuit into a contract.

You can use this repo's `create-circuit-contract` hardhat task to this for you, and rename it to a more specific contract name (e.g. `myCircuitVerifier.sol`) to allow for nicer deployment scripts. To use this task with our above example (our `myCircuit` circuit), you'd run:

```
npx hardhat create-circuit-contract --circuit myCircuit
```

This will generate your Circuit contract file for you using nargo - but move it into your `contracts/` directory and rename it to be your circuit name + `Verifier.sol` (e.g. `MyCircuitVerifier.sol`), as well as rename the actual contract from `TurboVerifier` (nargo default) to `MyCircuitVerifier`.

Alternatively - you can just use nargo to generate a `plonk_vk.sol` contract instead (using our example `myCircuit` from above):

```
cd circuits/myCircuit
nargo codegen-verifier
```

This will create a `plonk_vk.sol` file at `circuits/myCircuit/contracts/` which you can then use in your hardhat project.

## Working in Foundry

Once you've got your verifier contract - you can use it to verify and test your proof contract in foundry.

Once you've tested and evaluated your circuit - you can run:

```bash
npx hardhat create-circuit-contract --circuit myCircuit

# to test your circuit in foundry
forge test --ffi

# or

yarn foundry
```

The current way to generate proofs in foundry is just an abstracted bash script that runs a CLI script to generate a proof for your circuit. My bashing isn't the best, so this may be prone to a few irregularities at first.

## General House Keeping

- all .proof and ACIR files are gitignored by default - you can change this if you want to keep them in your repo.

## Issues/Feature Requests

Any issues or features you'd like, hit [me](https://github.com/hooperben) up, otherwise, happy hacking :)
