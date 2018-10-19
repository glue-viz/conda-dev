#!/bin/bash -e

export STABLE=true

export PYTHON_VERSION=2.7
./build_packages.sh

export PYTHON_VERSION=3.5
./build_packages.sh

export PYTHON_VERSION=3.6
./build_packages.sh

export PYTHON_VERSION=3.7
./build_packages.sh

export STABLE=false

export PYTHON_VERSION=2.7
./build_packages.sh

export PYTHON_VERSION=3.5
./build_packages.sh

export PYTHON_VERSION=3.6
./build_packages.sh

export PYTHON_VERSION=3.7
./build_packages.sh
