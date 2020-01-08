#!/bin/bash -xe

# Determine whether build products should be uploaded
if [[ $TRAVIS == true && $TRAVIS_EVENT_TYPE != pull_request && $TRAVIS_BRANCH == master ]]; then
  UPLOAD=true;
elif [[ $CIRCLECI == true && $CIRCLE_BRANCH == master ]]; then
  UPLOAD=true;
else
  UPLOAD=false;
fi

# Switch to root environment to have access to conda-build
source activate root

# Install conda-build and the anaconda client
conda install conda-build anaconda-client

# Install PyQt and jinja2 for the prepare script to work
conda install jinja2 pyqt requests=2.18.4

# For now, we also need to install Numpy because it is included in some of the setup_requires
conda install numpy

# Don't auto-upload, instead we upload manually specifying a token.
conda config --set anaconda_upload no

# We add glueviz in all cases since it also contains e.g. rasterio and other packages
conda config --add channels glueviz

if [[ $STABLE == false ]]; then
  conda config --add channels glueviz/label/dev
fi

# Packages that need to be build per Python version and architecture

packages="glue-core";

if [[ $PYTHON_VERSION != "3.7" ]]; then
  packages+=" glue-medical";
fi

# noarch packages are only build on Python 3.6 on CircleCI

if [[ $PYTHON_VERSION == "3.6" && $CIRCLE_SHA1 != "" ]]; then
  packages+=" glue-jupyter glue-plotly specviz mosviz glue-geospatial glue-samp glue-vispy-viewers glue-wwt";
fi

if [[ $PYTHON_VERSION == "3.6" && $CIRCLE_SHA1 != "" && $STABLE == false ]]; then
  packages+=" glue-openspace bqplot ipymaterialui glue-regions glue-exp cubeviz";
fi

# This needs to be built after glue-vispy-viewers
packages+=" glueviz"

for package in $packages; do

  if [[ $STABLE == true ]]; then

    # The following puts the correct version number and md5 in the recipes
    python prepare_recipe.py $package --stable;

  else

    if [[ $package == glue-core ]]; then
      git clone git://github.com/glue-viz/glue.git glue-core;
    elif [[ $package == py-expression-eval ]]; then
      git clone "git://github.com/Axiacore/"$package".git"
    elif [[ $package == ipymaterialui ]]; then
      # For ipymaterialui we use a pre-release to avoid requiring npm
      pip download ipymaterialui --pre --no-binary :all: --no-deps
      mkdir ipymaterialui
      tar --strip 1 --directory ipymaterialui -xvzf ipymaterialui*gz
    elif [[ $package == bqplot ]]; then
      # For bqplot we use a pre-release to avoid requiring npm
      pip download bqplot --pre --no-binary :all: --no-deps
      mkdir bqplot
      tar --strip 1 --directory bqplot -xvzf bqplot*gz
    elif [[ $package == specviz || $package == cubeviz || $package == mosviz ]]; then
      git clone "git://github.com/spacetelescope/"$package".git"
    else
      git clone "git://github.com/glue-viz/"$package".git"
    fi

    # The following puts the correct version number in the recipes
    python prepare_recipe.py $package;

  fi

  cd generated

  # Print out the recipe
  echo "-----------------------------------------------------"
  cat $package/meta.yaml
  echo "-----------------------------------------------------"

  # If we are processing a pull request, we shouldn't skip builds even if they
  # exist already otherwise some builds might not get tested
  if [[ $TRAVIS_EVENT_TYPE != pull_request ]]; then
    skip="--skip-existing"
  else
    skip="";
  fi

  conda build $skip --old-build-string --keep-old-work --python $PYTHON_VERSION $package
  output=`conda build --old-build-string --python $PYTHON_VERSION $package --output`

  cd ..

  # Remove git repository
  if [[ $STABLE == false ]]; then
    rm -rf $package
  fi

  # If the file does not exist, the build must have skipped because the build
  # already exists in the channel, so we just proceed to the next package
  if [ ! -f $output ]; then
    continue;
  fi

  if [[ $UPLOAD == true ]]; then
    if [[ $STABLE == true ]]; then
      anaconda -t $ANACONDA_TOKEN upload $output;
    else
      anaconda -t $ANACONDA_TOKEN upload -l dev $output;
    fi
  fi

  rm $output

done
