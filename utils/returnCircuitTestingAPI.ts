/* eslint-disable camelcase */
import path from "path";
import fs from "fs";

import { BarretenbergWasm } from "@noir-lang/barretenberg/dest/wasm";
import { SinglePedersen } from "@noir-lang/barretenberg/dest/crypto";

import { compile } from "@noir-lang/noir_wasm";
import { setup_generic_prover_and_verifier } from "@noir-lang/barretenberg/dest/client_proofs";

const returnCircuitTestingAPI = async (circuitName: string) => {
  const barretenberg = await BarretenbergWasm.new();
  const pedersen = new SinglePedersen(barretenberg);

  // check that circuit exists
  const circuitsDir = path.join(__dirname, "../circuits");

  const circuitPath = `${circuitsDir}/${circuitName}/src/main.nr`;

  if (!fs.existsSync(circuitPath)) {
    throw new Error(`Can't find circuit at ${circuitPath}, check your files!`);
  }

  const boardCircuit = compile(circuitPath);
  const acir = boardCircuit.circuit;

  const [prover, verifier] = await setup_generic_prover_and_verifier(acir);

  return {
    barretenberg,
    pedersen,
    boardCircuit,
    acir,
    prover,
    verifier,
  };
};

export default returnCircuitTestingAPI;
