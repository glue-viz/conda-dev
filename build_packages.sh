#!/bin/bash -xe

# Switch to root environment to have access to conda-build
source activate root

# Install conda-build and the anaconda client
conda install conda-build anaconda-client

# Install PyQt and jinja2 for the prepare script to work
conda install jinja2 pyqt requests

# Don't auto-upload, instead we upload manually specifying a token.
conda config --set anaconda_upload no

if [[ $STABLE == true ]]; then
  conda config --add channels glueviz
else
  conda config --add channels glueviz/label/dev
fi

packages="glue-core glue-vispy-viewers glueviz glue-wwt glue-geospatial";

for package in $packages; do

  if [[ $STABLE == true ]]; then

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

  conda build --skip-existing --old-build-string --keep-old-work --python $PYTHON_VERSION $package
  output=`conda build --old-build-string --python $PYTHON_VERSION $package --output`

  # If the file does not exist, the build must have skipped because the build
  # already exists in the channel, so we just proceed to the next package
  if [ ! -f $output ]; then
    cd ..
    continue;
  fi

  if [[ $TRAVIS_EVENT_TYPE != pull_request && $TRAVIS_BRANCH == master ]]; then
    if [[ $STABLE == true ]]; then
      anaconda -t $ANACONDA_TOKEN upload $output;
    else
      anaconda -t $ANACONDA_TOKEN upload -l dev $output;
    fi
  fi

  cd ..

done
