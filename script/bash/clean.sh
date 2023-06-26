#!/bin/bash

# Check if the string value is provided as an argument
if [ $# -eq 0 ]; then
  echo "Please provide a string value as an argument."
  exit 1
fi

rm -rf "$1"