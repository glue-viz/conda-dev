import os
import sys
import shutil
import subprocess
from datetime import datetime

import requests
from jinja2 import Template


SOURCE_DEV = """
source:
  path: ../../{{package}}
"""

SOURCE_STABLE = """
source:
  fn: {{filename}}
  url: {{url}}
  md5: {{md5_digest}}
"""

SOURCE_STABLE_GIT = """
source:
    git_tag: {{version}}
    git_url: https://github.com/spacetelescope/{{package}}.git
"""


def prepare_recipe_dev(package):

    with open(os.path.join('recipes', package, 'meta.yaml')) as f:
        content = f.read()

    if os.path.exists(package):
        os.chdir(package)
        package_dir = package
    elif os.path.exists(package + '.git'):
        os.chdir(package + '.git')
        package_dir = package + '.git'
    else:
        print('Package {0} not cloned'.format(package))
        sys.exit(1)

    overall_version = subprocess.check_output('python setup.py --version', shell=True).decode('ascii')
    utime = subprocess.check_output('git log -1 --pretty=format:%ct', shell=True).decode('ascii')
    chash = subprocess.check_output('git log -1 --pretty=format:%h', shell=True).decode('ascii')
    os.chdir('..')

    stamp = datetime.fromtimestamp(int(utime)).strftime('%Y%m%d%H%M%S')

    overall_version = overall_version.strip().split('.dev')[0]

    version = overall_version + '.dev' + stamp + '.' + chash

    source = Template(SOURCE_DEV).render(package=package_dir)

    recipe = Template(content).render(version=version, source=source)

    if not os.path.exists('generated'):
        os.mkdir('generated')

    if not os.path.exists(os.path.join('generated', package)):
        os.mkdir(os.path.join('generated', package))

    with open(os.path.join('generated', package, 'meta.yaml'), 'w') as f:
        f.write(recipe)

    for filename in os.listdir(os.path.join('recipes', package)):
        if filename != 'meta.yaml':
            shutil.copyfile(os.path.join('recipes', package, filename),
                            os.path.join('generated', package, filename))


def prepare_recipe_stable(package):

    with open(os.path.join('recipes', package, 'meta.yaml')) as f:
        content = f.read()

    # Find latest stable version from PyPI
    package_json = requests.get('https://pypi.python.org/pypi/{package}/json'.format(package=package)).json()
    version = sorted(package_json['releases'], key=lambda s: tuple(map(int, s.split('.'))))[-1]
    releases = package_json['releases'][version]
    for release in releases:
        if release['python_version'] == 'source':
            break
    else:
        raise Exception("Cannot find source package for {0}".format(package))

    source = Template(SOURCE_STABLE).render(**release)

    recipe = Template(content).render(version=version, source=source)

    if not os.path.exists('generated'):
        os.mkdir('generated')

    if not os.path.exists(os.path.join('generated', package)):
        os.mkdir(os.path.join('generated', package))

    with open(os.path.join('generated', package, 'meta.yaml'), 'w') as f:
        f.write(recipe)

    for filename in os.listdir(os.path.join('recipes', package)):
        if filename != 'meta.yaml':
            shutil.copyfile(os.path.join('recipes', package, filename),
                            os.path.join('generated', package, filename))


def prepare_recipe_stable_git(package):

    with open(os.path.join('recipes', package, 'meta.yaml')) as f:
        content = f.read()

    # Find latest stable version from PyPI
    package_json = requests.get('https://api.github.com/repos/spacetelescope/{package}/tags'.format(package=package)).json()
    version = package_json[0]['name']

    source = Template(SOURCE_STABLE_GIT).render(version=version, package=package)

    recipe = Template(content).render(version=version, source=source)

    if not os.path.exists('generated'):
        os.mkdir('generated')

    if not os.path.exists(os.path.join('generated', package)):
        os.mkdir(os.path.join('generated', package))

    with open(os.path.join('generated', package, 'meta.yaml'), 'w') as f:
        f.write(recipe)

    for filename in os.listdir(os.path.join('recipes', package)):
        if filename != 'meta.yaml':
            shutil.copyfile(os.path.join('recipes', package, filename),
                            os.path.join('generated', package, filename))


def main_stable(*packages):
    for package in packages:
        prepare_recipe_stable(package)


def main_stable_git(*packages):
    for package in packages:
        prepare_recipe_stable_git(package)


def main_dev(*packages):
    for package in packages:
        prepare_recipe_dev(package)


if __name__ == "__main__":
    if '--stable' in sys.argv:
        sys.argv.remove('--stable')
        main_stable(*sys.argv[1:])
    elif '--stable-git' in sys.argv:
        sys.argv.remove('--stable-git')
        main_stable_git(*sys.argv[1:])
    else:
        main_dev(*sys.argv[1:])
