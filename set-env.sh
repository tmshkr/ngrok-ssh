#!/bin/bash -e

if [[ -e .env ]]; then
  echo "Loading environment variables from .env"
  env $(grep -v '^#' .env | xargs) $@
else
  echo "No .env file found"
  exit 1
fi
