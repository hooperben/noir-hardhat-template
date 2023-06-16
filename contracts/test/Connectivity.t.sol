// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "./utils/Noirhelper.t.sol";

import "../Connectivity.sol";
import "../ConnectivityVerifier.sol";

contract ConnectivityTest is Test {
  // initialise our noir helper instance
  NoirHelper public noirhelper;

  // our Noir verifier contract
  ConnectivityVerifier public verifier;

  // our connectivity contract (where we use our verifier contract)
  Connectivity public connectivity;

  // set up our unit tests
  function setUp() public {
    // we want to test the circuit at circuits/connectivity
    noirhelper = new NoirHelper("connectivity");

    // deploy our verifier contract
    verifier = new ConnectivityVerifier();

    // deploy our connectivity contract and pass in the address of the verifier contract
    connectivity = new Connectivity(address(verifier));
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

  // evaluate valid proof with our verifier contract
  function testValidProof() public {
    // load up inputs
    // 7 + 8 == 15 - this is a valid input
    noirhelper.withInput("x", 7).withInput("y", 8);
    bytes memory proof = noirhelper.generateProof();

    uint256[] memory inputs = new uint256[](1);
    inputs[0] = 8;

    // submit the proof to our contract (this tx won't revert)
    connectivity.submitProof(proof, convertToBytes32Array(inputs));

    assertEq(connectivity.isProofUsed(keccak256(proof)), true);
  }

  // an invalid proof will revert
  function testInvalidProof() public {
    // 7 + 9 != 15 - this is a valid input
    noirhelper.withInput("x", 7).withInput("y", 9);

    // our expected error message
    vm.expectRevert("not today, bozo");
    noirhelper.generateProof(); // this will revert with the above
  }
}
