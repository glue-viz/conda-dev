# Show which commands are being run
Set-PSDebug -Trace 1

if ($env:ANACONDA_TOKEN -eq $null) {
  echo "WARNING: ANACONDA_TOKEN is not set"
}

# Switch to root environment to have access to conda-build
activate root

# Install conda-build and the anaconda client
conda install -n root conda-build anaconda-client

# Install PyQt and jinja2 for the prepare script to work
conda install jinja2 pyqt requests

# Don't auto-upload, instead we upload manually specifying a token.
conda config --set anaconda_upload no

if ($env:STABLE -match "true") {
  conda config --add channels glueviz
} else {
  conda config --add channels glueviz/label/dev
}

$packages = @("glue-core", "glue-vispy-viewers", "glueviz", "glue-wwt", "glue-geospatial")

foreach ($package in $packages) {

  if ($env:STABLE -match "true") {

    # The following puts the correct version number and md5 in the recipes
    python prepare_recipe.py $package --stable

  } else {

    if ($package -match "glue-core") {
      git clone git://github.com/glue-viz/glue.git glue-core
    } else {
      git clone "git://github.com/glue-viz/"$package".git"
    }

    # The following puts the correct version number in the recipes
    python prepare_recipe.py $package

  }

  cd recipes

  conda build --skip-existing --old-build-string --keep-old-work --python $env:PYTHON_VERSION $package
  $BUILD_OUTPUT = cmd /c conda build --old-build-string --python $env:PYTHON_VERSION $package --output 2>&1
  echo $BUILD_OUTPUT

  # If the file does not exist, the build must have skipped because the build
  # already exists in the channel, so we just proceed to the next package
  if (-not ($BUILD_OUTPUT | Test-Path)) {
    cd ..
    continue
  }

  if ($env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null -and $env:APPVEYOR_REPO_BRANCH -eq "master") {
    if ($env:STABLE -match "true") {
      anaconda -t $env:ANACONDA_TOKEN upload $BUILD_OUTPUT;
    } else {
      anaconda -t $env:ANACONDA_TOKEN upload -l dev $BUILD_OUTPUT;
    }
  }

  cd ..

}
