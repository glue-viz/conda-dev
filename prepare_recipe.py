import os
import sys
import subprocess
from datetime import datetime

import requests
from yaml import load, dump
from jinja2 import Template


def prepare_recipe_dev(package):

    with open('recipes/{0}/meta.yaml'.format(package)) as f:
        content = f.read()

    os.chdir(package)
    overall_version = subprocess.check_output('python setup.py --version', shell=True).decode('ascii')
    utime = subprocess.check_output('git log -1 --pretty=format:%ct', shell=True).decode('ascii')
    chash = subprocess.check_output('git log -1 --pretty=format:%h', shell=True).decode('ascii')
    os.chdir('..')

    stamp = datetime.fromtimestamp(int(utime)).strftime('%Y%m%d%H%M%S')

    overall_version = overall_version.strip().split('.dev')[0]

    version = overall_version + '.dev' + stamp + '.' + chash

    recipe = Template(content).render(version=version)

    with open('recipes/{0}/meta.yaml'.format(package), 'w') as f:
        f.write(recipe)


def prepare_recipe_stable(package):

    with open('recipes/{0}/meta.yaml'.format(package)) as f:
        content = f.read()

    # Find latest stable version from PyPI
    package_json = requests.get('https://pypi.python.org/pypi/glue-core/json').json()
    version = sorted(package_json['releases'])[-1]
    releases = package_json['releases'][version]
    for release in releases:
        if release['python_version'] == 'source':
            break
    else:
        raise Exception("Cannot find source package for {0}".format(package))

    recipe = Template(content).render(version=version)

    # Parse YAML
    recipe_yaml = load(recipe)
    recipe_yaml['source'].pop('path')
    recipe_yaml['source']['fn'] = release['filename']
    recipe_yaml['source']['url'] = release['url']
    recipe_yaml['source']['md5'] = release['md5_digest']

    with open('recipes/{0}/meta.yaml'.format(package), 'w') as f:
        f.write(dump(recipe_yaml, default_flow_style=False))


def main_stable(*packages):
    for package in packages:
        prepare_recipe_stable(package)


def main_dev(*packages):
    for package in packages:
        prepare_recipe_dev(package)


if __name__ == "__main__":

    if '--stable' in sys.argv:
        sys.argv.remove('--stable')
        main_stable(*sys.argv[1:])
    else:
        main_dev(*sys.argv[1:])
