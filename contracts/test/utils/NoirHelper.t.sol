pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {FoundryRandom} from "foundry-random/FoundryRandom.sol";

// this contract is basically a copy of https://github.com/whitenois3/nplate/blob/main/test/utils/NoirHelper.sol
// but written to fit this repository
contract NoirHelper is Test, FoundryRandom {
  struct CircuitInput {
    string name;
    uint256 value;
  }

  CircuitInput[] public inputs;
  string[] public testFiles;
  string public circuitName;

  /// @param _circuitName the path to the circuit folder
  constructor(string memory _circuitName) {
    circuitName = _circuitName;
  }

  /**
   * Appends an input to the array
   *
   * @param name The name of the parameter
   * @param value The value of the parameter
   */
  function withInput(
    string memory name,
    uint256 value
  ) public returns (NoirHelper) {
    inputs.push(CircuitInput(name, value));
    return this;
  }

  /**
   * Ran after each test to clean the inputs array
   */
  function clean(string memory filePath) public {
    delete inputs;

    // delete all files in the /tmp folder
    string[] memory command = new string[](2);
    command[0] = "script/bash/clean.sh";
    command[1] = filePath;
    vm.ffi(command);
  }

  function createNewFileStructure() internal returns (string memory _filePath) {
    uint256 randomNum;
    randomNum = randomNumber(type(uint8).max);
    string[] memory command = new string[](3);
    command[0] = "script/bash/createFiles.sh";
    command[1] = string.concat(circuitName, Strings.toString(randomNum));
    command[2] = circuitName;
    vm.ffi(command);

    return string.concat("./circuits/tmp/", command[1]);
  }

  function generateProof() public returns (bytes memory) {
    // create a tmp/ dir for our circuits to live
    string memory currentWorkingDir = createNewFileStructure();

    console.log(currentWorkingDir);

    // make sure our prover is empty
    vm.writeLine(string.concat(currentWorkingDir, "/Prover.toml"), "");

    // populate our prover.toml with our inputs
    for (uint i; i < inputs.length; i++) {
      vm.writeLine(
        string.concat(currentWorkingDir, "/Prover.toml"),
        string.concat(inputs[i].name, " = ", vm.toString(inputs[i].value))
      );
    }

    // generate proof - this runs the prove.sh command
    string[] memory ffi_prove_cmd = new string[](3);
    ffi_prove_cmd[0] = "script/bash/prove.sh";
    ffi_prove_cmd[1] = currentWorkingDir;
    ffi_prove_cmd[2] = circuitName;

    // execute our proof
    try vm.ffi(ffi_prove_cmd) {} catch {
      // this is normally an OS level throw - but we want to clean up our tmp/ dir
      clean(currentWorkingDir);
    }

    // the path to our proof generate by nargo
    string memory proofOutput = string.concat(
      currentWorkingDir,
      "/proofs/",
      circuitName,
      ".proof"
    );

    bytes memory proofBytes;

    // read output of proof and return it
    try vm.readFile(proofOutput) returns (string memory proof) {
      proofBytes = vm.parseBytes(proof);
    } catch {
      // this is normally an OS level throw - but we want to clean up our tmp/ dir
      clean(currentWorkingDir);
      revert("Error generating proof");
    }

    // wipe our generated test files
    clean(currentWorkingDir);

    // if it's a valid proof - return it, else revert
    if (proofBytes.length == 0) {
      revert("Error generating proof");
    } else {
      return proofBytes;
    }
  }

  // helper function to convert uint256[] to bytes32[]
  function convertToBytes32Array(
    uint256[] memory input
  ) public pure returns (bytes32[] memory) {
    bytes32[] memory output = new bytes32[](input.length);

    for (uint i = 0; i < input.length; i++) {
      output[i] = bytes32(input[i]);
    }

    return output;
  }
}
