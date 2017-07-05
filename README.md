[![Build Status](https://travis-ci.org/glue-viz/conda-dev.svg?branch=master)](https://travis-ci.org/glue-viz/conda-dev)

### About

This repository is used to build nightly 'developer' versions of the various glue packages for conda. To install these versions, you can install glueviz from the ``glueviz/label/dev`` channel:

    $ conda install -c glueviz/label/dev glueviz
    Fetching package metadata .............
    Solving package specifications: .

    Package plan for installation in environment /Users/tom/miniconda3/envs/dev:

    The following NEW packages will be INSTALLED:

        glue-core:          0.11.0.dev20170705102151.3ea9531-py36_0 glueviz/label/dev
        glue-vispy-viewers: 0.8.dev20170602171439.7533769-py36_0    glueviz/label/dev
        glueviz:            0.10.4.dev20170523215155.bd41d10-0      glueviz/label/dev
