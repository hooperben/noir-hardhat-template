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

  // an invalid proof will revert
  function testInvalidProof() public {
    // 7 + 9 != 15 - this is an invalid input
    noirhelper.withInput("x", 7).withInput("y", 9);

    // we expect the following tx to revert
    vm.expectRevert();
    noirhelper.generateProof(); // this will revert with the above input parameters
  }

  // evaluate valid proof with our verifier contract
  function testValidProof() public {
    // load up inputs
    // 7 + 8 == 15 - this is a valid input
    noirhelper.withInput("x", 7).withInput("y", 8);
    bytes memory proof = noirhelper.generateProof();

    // as part of the new ultra verifier, we need to pass in public inputs
    // to the proof verification function as bytes32
    uint256[] memory inputs = new uint256[](1);
    inputs[0] = 8;

    // submit the proof to our contract (this tx won't revert)
    connectivity.submitProof(proof, noirhelper.convertToBytes32Array(inputs));

    // check that the (hash) of the proof is marked as been used
    assertEq(connectivity.isProofUsed(keccak256(proof)), true);
  }
}
