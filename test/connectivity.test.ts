/* eslint-disable camelcase -- few factories and libaries that use camel case */
import { expect } from "chai";
import returnCircuitTestingAPI from "../utils/returnCircuitTestingAPI";
import {
  create_proof,
  verify_proof,
  StandardExampleProver,
  StandardExampleVerifier,
} from "@noir-lang/barretenberg/dest/client_proofs";
import { BarretenbergWasm } from "@noir-lang/barretenberg/dest/wasm";
import { SinglePedersen } from "@noir-lang/barretenberg/dest/crypto";

import { deployments, ethers } from "hardhat";

import { Connectivity } from "../typechain";

// A unit test that ensures that all dependencies are working correctly (can be deleted once ran once successfully)
describe("Connectivity Testing", async () => {
  let barretenberg: BarretenbergWasm;
  let pedersen: SinglePedersen;
  let boardCircuit: any;
  let acir: any;
  let prover: StandardExampleProver;
  let verifier: StandardExampleVerifier;

  let connectivityContract: Connectivity;

  before(async () => {
    // our example 'connectivity' circuit takes to numbers as inputs that cannot be the same,
    // and checks that the sum of these numbers is equal to 15
    const circuitName = "connectivity";

    // these are our core objects needed to run a proof in TS using the noir wasm package
    ({ barretenberg, pedersen, boardCircuit, acir, prover, verifier } =
      await returnCircuitTestingAPI(circuitName));

    // next we need to get our deployed contracts
    await deployments.fixture(["testbed"]);

    // get our connectivity contract
    connectivityContract = (await ethers.getContract(
      "Connectivity"
    )) as Connectivity;
  });

  describe("testing our proofs locally (not with smart contracts)", async () => {
    it("should evaluate the circuit successfully with valid inputs", async () => {
      // as 1 + 14 == 15 && 1 != 45, this is a valid proof
      const inputs = {
        x: 1,
        y: 14,
      };

      // generate the proof
      const proof = await create_proof(prover, acir, inputs);

      // verify it
      const verify = await verify_proof(verifier, proof);

      // tada!
      expect(verify).equal(true);
    });

    it("should not evaluate the circuit successfully with invalid inputs (!= 15)", async () => {
      // as 1 + 14 == 24 && 24 != 15, this is an invalid proof
      const inputs = {
        x: 8,
        y: 16,
      };

      try {
        const proof = await create_proof(prover, acir, inputs);
        const verified = await verify_proof(verifier, proof);
        expect(verified).equal(false);
        // sorry for the any 🤮
      } catch (err: any) {
        expect(err.name).to.include("RuntimeError");
      }
    });

    it("should not evaluate the circuit successfully with invalid inputs (x == y)", async () => {
      // as 8 + 8 == 24 && 16 != 15, this is an invalid proof
      const inputs = {
        x: 8,
        y: 8,
      };

      try {
        const proof = await create_proof(prover, acir, inputs);
        const verified = await verify_proof(verifier, proof);
        expect(verified).equal(false);

        // sorry for the any 🤮
      } catch (err: any) {
        expect(err.name).to.include("RuntimeError");
      }
    });
  });

  describe("testing our proofs with verifier contracts", async () => {
    const input = {
      x: 4, // private (by default)
      y: 11, // public (explicitly defined)
    };

    const publicInputs = [ethers.utils.hexZeroPad(input.y.toString(), 32)];

    it("the smart contract should accept a valid proof", async () => {
      // generate our proof
      const proof = (await create_proof(prover, acir, input)) as Buffer;

      // verify it locally (in wasm)
      const verified = await verify_proof(verifier, proof);
      expect(verified).equal(true);

      // need a keccak of the proof to submit it to the contract
      const keccakProof = ethers.utils.keccak256(proof);

      // proof should not exists on the contract
      let proofExists = await connectivityContract.isProofUsed(keccakProof);
      expect(proofExists).equal(false);

      // we also have to submit the public inputs to the contract as a bytes32[]
      // y is our only public input in this example
      // should go throw (not revert)
      await connectivityContract.submitProof(proof, publicInputs);

      // once we submit a proof we can check the state of the contract to ensure it's been written
      proofExists = await connectivityContract.isProofUsed(keccakProof);
      expect(proofExists).equal(true);
    });

    // generate our proof
    const proof = (await create_proof(prover, acir, input)) as Buffer;

    // verify it locally (in wasm)
    const verified = await verify_proof(verifier, proof);
    expect(verified).equal(true);

    // need a keccak of the proof to submit it to the contract
    const keccakProof = ethers.utils.keccak256(proof);

    // proof should not exists on the contract
    let proofExists = await connectivityContract.isProofUsed(keccakProof);
    expect(proofExists).equal(true);

    // should go throw (not revert)
    try {
      await connectivityContract.submitProof(proof, publicInputs);
    } catch (err: any) {
      // sorry for the any 🤮
      expect(err.message).to.include("proof already used");
    }
  });
});
