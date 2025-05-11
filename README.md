<!--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
<!-- File: README.md   -->
<!--   -->
<!-- Description: An overview of this project: what it is, how to use it, and who to thank.  --> 
<!--   -->
<!-- Note from GitHub: The README "should contain only the necessary information for developers to get started using and contributing to your project. Longer documentation is best suited for wikis."   -->
<!--   -->
<!--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --> 

# Package: pixi_pyprojSetup

A Batch script that generates a src-layout Python package directory structure with Pixi package management and a 'pyproject.toml' manifest file.

## Badges
<!--Shields for things like version, license, build status, Python version, etc. -->


# Table of Contents
[Features](#Features)
[Installation](#Installation)
[Usage](#Usage)
[Configuration](#Configuration)
[Development](#Development)
[License](#License)
[Credits](#Credits)


# Features
 - Fully capabale of setting up basic Python project structures, including directory structure and basic files.
 - Git- and GitHub-integrated. Automatically.
 - Flexible structuring and file definition
 - A 'placeholder' framework enables user-customized and package-specific files.
 - User-selected licensing with automatic boilerplate added to all file.


# Installation
This doesn't really need installation apart downloading/cloning the repo and running the main Batch file ('pixi_pyprojSetup.bat'). 

Functionality does require a Batch processing interface (the built-in Windows command line works) and an installation of PowerShell (v5.1 or v7 work for sure, prior versions may also work.) 


# Usage
The simiplest invocation of this script is just to call the main 'pixi_pyprojSetup.bat' from from a CLI and follow the prompts. 

Verbosity may be set via the "debug=<level>" CLI parameter, where "<level>" is a number between 1 and 4; passing a 0 will disable debugging/extra verbosity. Note that the full argument must be double-quoted for proper parsing. 

There are a few different parameters that may be passed via CLI, and a number of configuration options for those wanting more control or less interaction. See the [Configuration](#Configuration) section for that. 


# Configuration
There are a number of configuration options available to the user.


## Templates 
The directory structure, and files within, of the newly-generated package directory tree is near-mirrored within the 'pixi_pyprojSetup\templates' subdirectory. Any files  within this directory (with exceptions defined shortly) will be copied into the new-package directoy within the same relative path as they exist within the 'templates' directory except for the 'src' directory; those will be copied into the 'src\<newPackage>' relative path. 

The only exceptions to this copying are files that are within explicitly excluded folders or are named explicitly as an excluded file; these settings are contained within the configuration file (see below). By default, the folders-to-exclude list includes the '_licenses' and '_miscNotCopied' subdirectories.


## Placeholders Framework
"Placeholders" are strings within the various templates that are replaced during the copying/processing sequence with a specifically mapped alternative string. So, for example, the string '{package}' (no quotes) would be replaced with 'MyPackage' (also no quotes), assuming your new package is called 'MyPackage'. These placeholdes must be wrapped in curly braces '{ }' within the template to be replaced. 

Most of these placeholder-replacement mappings are assigned via a three-level hierarchy: 
1. The defaults are saved within the 'pixi_pyprojSetup\config\placeholders.DEFAULT' file and should be left alone;
2. These are initially overridden by mappings defined in the 'pixi_pyprojSetup\config\placeholders.USER' file; and finally
3. The priority assignment is given via CLI parameters as double-quoted "key=value" pairs.
The exception here is the package name, the repo name, and the short description, which will be prompted for if not set via CLI arguments.

The user should set placeholders and their replacements within the 'placeholders.USER' file with a single mapping per line; care should be taken to no include extraneous whitespace. Note that they do not to be defined with the curly braces; those are used to identify the placeholders within the template files. Arbitrary placeholders may be defined within this folder and used within the templates, and users may pass any placeholder-replacement mapping via the CLI as well.


## Configuration file ('pixi_pyprojSetup_config.cmd')
Located in the 'pixi_pyprojSetup\config', this file stores both user-adjustable configuration settings and ones that perhaps should not be changed. In the user-adjustable section lives the list of folders to exclude from copying ('CFG_excludeFolders'), the filenames to exclude from copying ('CFG_excludeFiles'), and filenames to exclude from prepending boilerplate licensing text ('CFG_noBoilerplate'). 



## TOML config files
There are two TOML-related JSON-styled configuration files within the 'pixi_pyprojSetup\config' subdirectory. 

1. 'Insert-Toml.config' passes parameters to the PowerShell script for insertion into the 'pyproject.toml' file. 
    - "File": The target .toml file. This is, by default, given as a relative path because the script cd's into the new-package directory automatically, which is where the manifest file lives.
    - "Insertions": A list of inserted lines. These are given in this file in the JSON syntax, but will be inserted with the proper TOML syntax. Each pair will be inserted on a single line in the order provided.
    - "Anchor": The location within the TOML file above which the insertions will occur.
    - "Debug": An integer to define the verbosity of any output; allowable values are 0 (no extraneous output) to 4 (so much output), with most output starting at level '2'.

2. 'Replace-Toml.config' passes parameters to the PowerShell script for replacement of lines within the 'pyproject.toml' manifest file.
    - "File": The target .toml file. This is, by default, given as a relative path because the script cd's into the new-package directory automatically, which is where the manifest file lives.
    - "Replacements": A JSON-list. The script will locate the key in the target TOML file and replace that line with the line provided here, assuming the key exists. (The script will only look for keys to the left of the equals sign on a given TOML-file line.)
    - "Debug": An integer to define the verbosity of any output; allowable values are 0 (no extraneous output) to 4 (so much output), with most output starting at level '2'.

        
## Licenses and Boilerplates
All license and boilerplate files live within the 'templates\_licenses' and 'templates\_licenses\boilerplates' subdirectories; these files are identified by their SPDX license identifier (<https://spdx.org/licenses/>). 

1. License files should be plain-text files named with the following structure: 'license_<SPDX-identifier>.txt'. Any license file added within the '_licenses' subdirectory will be available for adoption by the new package. By default, the user will be prompted for one of the available options, though an SPDX identifier can be passed with the 'license' CLI parameter to override this prompt, or be set within the user's 'placeholder' file.

2. A boilerplate file, in the context of this project, are license-identification text-files that are prepended to the top of most of the template files after copying. Generally they simply note that the file is under the license of the project and gives a copyright, though the GNU GPL v3.0 goes a bit further. Boilerplate files should be named according to the following structure: '<SPDX-identifier>_boilerplate.<ext>.TEMPLATE', where the <ext> identifies the character marking that comments out the boilerplate text. For example, "MIT_boilerplate.py.TEMPLATE" is commented out using the hashtag character ('#'), as that's how lines are commented in '.py' files.

If you would like to adjust the boilerplate text for a given licensing schema, adjust the '<SPDX-identifier>.txt.TEMPLATE' file as you'd like for the license SPDX in question, and then delete all the other boilerplate files for that license. The script will call 'Comment-File.ps1' to generate the correctly-commented boilerplate file for each template being processed, so there's no need for you to comment or generate anything beyond the '.txt' variant (without any comment characters). 


# Development
Feel free to clone this repo and work on it to your hearts content; it's licensed under the GNU GPL v3.0, which allows basically any kind of work to be done _except_ distributing closed-source versions. 

I encourage forking your own version if you'd like to add or extend this so that it's available to the community, or submit pull requests to contribute. I'm no Batch or PowerShell expert - much of this was written with the help of ChatGPT and Microsoft Copilot - so I'm open to alternative approaches and strategies. 

If you run into bugs or would like additional features added, please either email me (Ben) at 'bchurwitz+pixi_pyprojSetup@gmail.com' or submit an Issue above.


# License
This project is licensed under the GNU GPL v3.0 license - see the LICENSE.txt for details.

Copyright (c) 2025 by Ben Hurwitz <bchurwitz+pixi_pyprojSetup@gmail.com>


# Credits
Credit to ChatGPT and Microsoft Copilot LLMs for "how to code in Batch and PowerShell" questions, structural questions, and debugging help.