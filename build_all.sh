#!/bin/bash -e

# NOTE: start with Python 3.6 to get noarch packages built first

export STABLE=true

export PYTHON_VERSION=3.6
./build_packages.sh

export PYTHON_VERSION=3.7
./build_packages.sh

export STABLE=false

export PYTHON_VERSION=3.6
./build_packages.sh

export PYTHON_VERSION=3.7
./build_packages.sh
