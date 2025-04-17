# src/{package}/cli.py
import argparse
from {package}.{module-name} import {main-function-name}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--{arg-name}", required=True) # EDIT THIS LINE
    args = parser.parse_args()
    print({main-function-name}(args.{arg-name}))
