from distutils.core import setup
import py2exe

setup(
    version = "1.0",
    description = "Logger",
    name = "Logger",

    # targets to build
    windows = ["logger.py"],
    )
