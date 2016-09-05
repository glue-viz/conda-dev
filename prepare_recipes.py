import importlib
from jinja2 import Template


def prepare_recipe(package):

    with open('recipes/{0}/meta.yaml'.format(package)) as f:
        content = f.read()

    mod = importlib.import_module(package)

    recipe = Template(content).render(version=mod.__version__)

    with open('recipes/{0}/meta.yaml'.format(package), 'w') as f:
        f.write(recipe)


if __name__ == "__main__":
    prepare_recipe('glue')
    prepare_recipe('glue-vispy-viewers')
    prepare_recipe('glue-medical')
    prepare_recipe('glue-geospatial')