import importlib
from jinja2 import Template

def prepare_recipe(package):

    with open('recipes/{0}/meta.yaml') as f:
        content = f.read()

    mod = importlib.import_module(package)

    recipe = Template(content).render(version=mod.__version__)

    with open('recipes/{0}/meta.yaml', 'w') as f:
        f.write(recipe)