#!/bin/bash

# Check if the circuit directory, name, and filepath are provided as arguments
if [ $# -lt 2 ]; then
  echo "Please provide the circuit directory and name as arguments."
  exit 1
fi

# Enable the 'set -e' option
set -e

# Store the arguments passed
circuitsDir="$1"
name="$2"

# Change to the circuit directory
cd "$circuitsDir"

# Run the `nargo prove` command with the provided name
nargo prove "$name" || true
