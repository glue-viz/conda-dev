# We use the following function to exit the script after any failing command
function checkLastExitCode {
  if ($lastExitCode) {
    echo "ERROR: the last command returned the following exit code: $lastExitCode"
    Exit $lastExitCode
  }
}

# Show which commands are being run
Set-PSDebug -Trace 1

# Print out environment variables
Get-ChildItem Env:

if ($env:ANACONDA_TOKEN -eq $null) {
  echo "WARNING: ANACONDA_TOKEN is not set"
}

# Switch to root environment to have access to conda-build
activate root
checkLastExitCode

# Install conda-build and the anaconda client
conda install -n root conda-build=3.8 anaconda-client
checkLastExitCode

# Install PyQt and jinja2 for the prepare script to work
conda install jinja2 pyqt requests=2.18.4 git
checkLastExitCode

# Don't auto-upload, instead we upload manually specifying a token.
conda config --set anaconda_upload no
checkLastExitCode

# We add glueviz in all cases since it also contains e.g. rasterio and other packages
conda config --add channels glueviz
checkLastExitCode

if ($env:STABLE -match "false") {
  conda config --add channels glueviz/label/dev
  checkLastExitCode
}

# $packages = @("glue-core", "glue-medical", "glue-vispy-viewers", "glueviz", "glue-wwt", "glue-geospatial", "glue-samp", "glue-exp")
$packages = @("glue-medical", "glue-vispy-viewers", "glueviz", "glue-wwt", "glue-geospatial")

# Don't build specviz dev for now as it's being refactored
if ($env:PYTHON_VERSION -notmatch "2.7" -And $env:STABLE -match "true") {
  $packages += @("py-expression-eval", "specviz")
}

if ($env:PYTHON_VERSION -notmatch "2.7") {
  $packages += @("cubeviz")
}

# For now, only build dev builds of glue-core since the recipe will only
# work with that version.
if ($env:STABLE -match "false") {
  $packages += @("glue-core")
}

foreach ($package in $packages) {

  if ($env:STABLE -match "true") {

    # The following puts the correct version number and md5 in the recipes
    if ($package -match "specviz" -Or $package -match "cubeviz") {
      python prepare_recipe.py $package --stable-git
      checkLastExitCode
    } else {
      python prepare_recipe.py $package --stable
      checkLastExitCode
    }

  } else {

    if ($package -match "glue-core") {
      git clone git://github.com/glue-viz/glue.git glue-core
      checkLastExitCode
    } elseif ($package -match "py-expression-eval") {
      git clone "git://github.com/Axiacore/$package"
      checkLastExitCode
    } elseif ($package -match "specviz" -Or $package -match "cubeviz") {
      git clone "git://github.com/spacetelescope/$package"
      checkLastExitCode
    } else {
      git clone "git://github.com/glue-viz/$package"
      checkLastExitCode
    }

    # The following puts the correct version number in the recipes
    python prepare_recipe.py $package
    checkLastExitCode

  }

  cd generated
  checkLastExitCode

  # If we are processing a pull request, we shouldn't skip builds even if they
  # exist already otherwise some builds might not get tested
  if ($env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null) {
    $skip = "--skip-existing"
    checkLastExitCode
  } else {
    $skip = ""
    checkLastExitCode
  }

  conda build $skip --old-build-string --keep-old-work --python $env:PYTHON_VERSION $package
  checkLastExitCode

  $BUILD_OUTPUT = cmd /c conda build --old-build-string --python $env:PYTHON_VERSION $package --output 2>&1
  checkLastExitCode

  echo $BUILD_OUTPUT

  cd ..

  # Remove git repository
  if ($env:STABLE -match "false") {
    Remove-Item $package -Force -Recurse
  }

  # If the file does not exist, the build must have skipped because the build
  # already exists in the channel, so we just proceed to the next package
  if (-not ($BUILD_OUTPUT | Test-Path)) {
    continue
  }

  if ($env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null -and $env:APPVEYOR_REPO_BRANCH -eq "master") {
    if ($env:STABLE -match "true") {
      anaconda -t $env:ANACONDA_TOKEN upload $BUILD_OUTPUT;
      checkLastExitCode
    } else {
      anaconda -t $env:ANACONDA_TOKEN upload -l dev $BUILD_OUTPUT;
      checkLastExitCode
    }
  }

}
