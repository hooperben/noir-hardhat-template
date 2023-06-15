pragma solidity 0.8.17;

import {TestBase} from "forge-std/Base.sol";
import {console2 as console} from "forge-std/console2.sol";

// this contract is basically a copy of https://github.com/whitenois3/nplate/blob/main/test/utils/NoirHelper.sol
// but written to fit this repository
contract NoirHelper is TestBase {
  struct CircuitInput {
    uint256 value;
    string name;
  }

  CircuitInput[] public inputs;

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
  function clean() public {
    delete inputs;
  }

  /**
   * Reads a proof from a file located in circuits/proofs
   * @param fileName The name of the proof file to read
   */
  function readProof(string memory fileName) public returns (bytes memory) {
    string memory file = vm.readFile(
      string.concat("circuits/proofs/", fileName, ".proof")
    );
    return vm.parseBytes(file);
  }

  /**
   * Generates a proof based on the inputs array and returns it
   *
   * @notice This function will write to Prover.toml and then call the prove.sh script
   * and needs to be called from contracts/test/utils/NoirHelper.t.sol
   *
   * Example usage:
   * withInput("x", 1).withInput("y", 2).withInput("return", 3);
   * bytes memory proof = generateProof();
   */
  function generateProof() public returns (bytes memory) {
    require(inputs.length > 0, "No inputs provided");
    // write to Prover.toml
    string memory proverTOML = "../../../circuits/Prover.toml";
    vm.writeFile(proverTOML, "");

    // write all inputs with their values
    for (uint i; i < inputs.length; i++) {
      vm.writeLine(
        proverTOML,
        string.concat(inputs[i].name, " = ", vm.toString(inputs[i].value))
      );
    }

    // generate proof - this runs the
    string[] memory ffi_cmds = new string[](1);
    ffi_cmds[0] = "../../../prove.sh";
    vm.ffi(ffi_cmds);

    // clean inputs (wipe state)
    clean();

    // read output of proof and return it
    string memory proof = vm.readFile("../../../circuits/proofs/test.proof");
    return vm.parseBytes(proof);
  }
}
