# src/{package}/__main__.py
# Allows the package to be executed by 'python -m <package>'
# cli.py is required to exist in the 'src' directory.

from {package}.cli import main

if __name__ == "__main__":
    main()