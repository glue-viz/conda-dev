#!/bin/bash -xe

# Switch to root environment to have access to conda-build
source activate root

# Install conda-build and the anaconda client
conda install conda-build=2 anaconda-client

# Install PyQt and jinja2 for the prepare script to work
conda install jinja2 pyqt

# Don't auto-upload, instead we upload manually specifying a token.
conda config --set anaconda_upload no

if [[ $TRAVIS_BRANCH == stable ]]; then
  packages="glue-core glue-vispy-viewers glueviz";
else
  packages="glue-core glue-vispy-viewers glueviz glue-wwt glue-geospatial";
fi

for package in $packages; do

  if [[ $TRAVIS_BRANCH == stable ]]; then

    # The following puts the correct version number and md5 in the recipes
    python prepare_recipe.py $package --stable;

  else

    if [[ $package == glue-core ]]; then
      git clone git://github.com/glue-viz/glue.git glue-core;
    else
      git clone "git://github.com/glue-viz/"$package".git"
    fi

    # The following puts the correct version number in the recipes
    python prepare_recipe.py $package;

  fi

  cd recipes

  conda build --python $PYTHON_VERSION $package
  output=`conda build --python $PYTHON_VERSION $package --output`
  test -e $output

  if [[ $TRAVIS_EVENT_TYPE != pull_request && $TRAVIS_BRANCH == master ]]; then
    anaconda -t $ANACONDA_TOKEN upload --force -l dev $output;
  fi

  if [[ $TRAVIS_EVENT_TYPE != pull_request && $TRAVIS_BRANCH == stable ]]; then
    anaconda -t $ANACONDA_TOKEN upload $output;
  fi

  cd ..

done
