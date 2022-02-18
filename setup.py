try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

long_description = """
panda3d-rest provides a panda native solution to performing RESTful HTTP GET/POST requests using non-blocking io.
"""

setup(
    name='panda3d_rest',
    description='panda3d-rest provides a panda native solution to performing RESTful HTTP GET/POST requests using non-blocking io.',
    long_description=long_description,
    license='MIT',
    version='1.0.3',
    author='Jordan Maxwell',
    maintainer='Jordan Maxwell',
    url='https://github.com/NxtStudios/p3d-rest',
    packages=['panda3d_rest'],
    classifiers=[
        'Programming Language :: Python :: 3',
    ])
