import { task } from "hardhat/config";

import fs from "fs";
import path from "path";

import { execSync } from "child_process";

task("create-circuit-contract")
  .addParam("circuit", "The name of the circuit to create a contract for")
  .setAction(async (taskArgs, hre) => {
    await generateCircuit(taskArgs, hre);
  });

const generateCircuit = async (taskArgs: any, hre: any) => {
  const { circuit } = taskArgs;

  if (!circuit) throw new Error("Need a circuit name!");

  const circuitsDir = path.join(__dirname, `../circuits/${circuit}`);

  if (!fs.existsSync(circuitsDir))
    throw new Error("Somethings gone wrong with the directory");

  const codegenVerifierCommand = `cd ${circuitsDir} && nargo compile ${circuit} && nargo codegen-verifier`;

  execSync(codegenVerifierCommand);

  // we now have a plonk_vk.sol at circuits/myCircuit/contracts/, we need to rename it
  // to the name of our circuit + Verifier.sol and place it in our contracts/ directory

  const oldPath = `${circuitsDir}/contract/plonk_vk.sol`;
  const contractsDir = path.join(__dirname, "../contracts");

  const capitalisedCircuitName =
    circuit.charAt(0).toUpperCase() + circuit.slice(1);

  const newPath = `${contractsDir}/${capitalisedCircuitName}Verifier.sol`;

  // move the circuit contract from the circuits/ directory to the contracts/ directory
  fs.copyFileSync(oldPath, newPath);
  // delete the circuitName/contract directory (not needed)
  fs.rmdirSync(`${circuitsDir}/contract/`, { recursive: true });

  // now we need to update the contract to have the correct contract name
  // read the file contents
  const fileContents = fs.readFileSync(newPath, "utf8");

  // in keeping with my solidity naming convention, we need to make sure the contracts first letter is capitalised
  // plus we need to update the verify function to not have the _proof param name (throws an unused param error)
  const newFileContents = fileContents
    .replace(
      "contract UltraVerifier is ",
      `contract ${capitalisedCircuitName}Verifier is `
    )
    .replace(
      "* @param _proof - The serialized proof",
      "* bytes calldata - The serialized proof (this isn't named cause accessed with assembly)"
    )
    .replace(
      "function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool) {",
      "function verify(bytes calldata, bytes32[] calldata _publicInputs) external view returns (bool) {"
    );

  fs.writeFileSync(newPath, newFileContents, "utf8");

  console.log(
    `Successfully added ${capitalisedCircuitName} contract to contracts/ directory`
  );
};
