#!/bin/bash
if [ "$#" -ne 2 ]
then
  echo "Usage: ./createFile.sh [TESTNAME_STRING] [CIRCUIT_NAME]"
  exit 1
fi
if [ ! -d "./circuits/tmp/$1" ]; then
  mkdir ./circuits/tmp/$1
fi

# cp ./circuits/$2/Nargo.toml ./circuits/tmp/$1/Nargo.toml
# cp ./circuits/$2/Verifier.toml ./circuits/tmp/Verifier.toml
cp -r ./circuits/$2/ ./circuits/tmp/$1/

echo "" > ./circuits/tmp/$1/Prover.toml && echo "" > ./circuits/tmp/$1/proofs/$2.proof
