Ben Hurwitz <bchurwitz+pixi_newPyProject@gmail.com>, 2025

This script generates a set of files and folder for the PyPI-style project (i.e. src-layout) with Pixi, the package and dependency manager, creates a git repository locally, and then pushes the repo to GitHub. 

Note: the script is kept within the 'pixi_pyprojSetup' directory so that it is tracked by git, and I have a shortcut externally that allows me to run it without worrying about directories. Just run it with '.lnk' at the end of the file name, i.e. 'pixi_pyprojSetup.bat.lnk'.


 - If you want to adjust the boilerplate text, delete all the BP files for that license EXCEPT for the .txt one. Adjust that one, and then let the script re-generate the rest.
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% File: README.md
%
% Description: An overview of this project: what it is, how to use it, and who to thank.
%
% Note from GitHub: The README "should contain only the necessary information for developers to get started using and contributing to your project. Longer documentation is best suited for wikis."
%
% -----------------------------------------------------------------------------

# Package: {package}

{description}

## Badges
% Shields for things like version, license, build status, Python version, etc. 


# Table of Contents
[Features](#Features)
[Installation](#Installation)
[Usage](#Usage)
[Configuration](#Configuration)
[Development](#Development)
[License](#License)
[Credits](#Credits)


# Features
% A bulleted list of key functionality or highlights. 


# Installation
% Instructions for installing the package or dependencies. Include pip, Pixi, conda, etc.


# Usage
% How to run it. Examples of CLI commands or imports with expected output.


# Configuration
% If your tool has settings, config files, or environment variables.


# Development
% How others can set up the dev environment, run tests, contribute. 


# License
This project is licensed under the {license_spdx} license - see the LICENSE.txt for details.

Copyright (c) {year} by {author} <{email}>.


# Credits
% Acknowledgments