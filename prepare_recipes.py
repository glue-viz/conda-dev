import os
import subprocess
from datetime import datetime

from jinja2 import Template


def prepare_recipe(package):

    with open('recipes/{0}/meta.yaml'.format(package)) as f:
        content = f.read()

    os.chdir(package)
    utime = subprocess.check_output('git log -1 --pretty=format:%ct', shell=True).decode('ascii')
    chash = subprocess.check_output('git log -1 --pretty=format:%h', shell=True).decode('ascii')
    os.chdir('..')

    stamp = datetime.fromtimestamp(int(utime)).strftime('%Y%m%d%H%M%S')

    recipe = Template(content).render(version='dev.' + stamp + '.' + chash)

    print(recipe)

    with open('recipes/{0}/meta.yaml'.format(package), 'w') as f:
        f.write(recipe)


if __name__ == "__main__":
    prepare_recipe('glue-core')
    prepare_recipe('glue-vispy-viewers')
    #prepare_recipe('glue-medical')
    #prepare_recipe('glue-geospatial')
