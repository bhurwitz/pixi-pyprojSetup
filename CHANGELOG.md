# Changelog for <pixi-pyprojectSetup> package

Author: Ben Hurwitz <bchurwitz+pixi_pyprojectSetup@gmail.com>

Copyright (c) 2025 under GNU GPL v3.0 (see LICENSE.txt for full details)

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project tries to adhere to [Semantic Versioning](https://semver.org/).


Versioning:

    Versions are always <Major.Minor.Patch>.
    - Major versions: When you introduce significant, breaking changes.
    - Minor versions: When you add functionality in a backward-compatible manner.
    - Patch versions: For backward-compatible fixes and improvements.
    
Changelog formatting:

    Guiding Principles:
     - Changelogs are for humans, not machines.
     - There should be an entry for every single version.
     - The same types of changes should be grouped.
     - Versions and sections should be linkable.
     - The latest version comes first.
     - The release date of each version is displayed.

    Types of changes:
     - [Added] for new features.
     - [Fixed] for any bug fixes.
     - [Changed] for changes in existing functionality.
     - [Deprecated] for soon-to-be removed features.
     - [Removed] for now removed features.
     - [Security] in case of vulnerabilities.

###############################################################################
###############################################################################

## [Unreleased]

### Added
 - Incorporate the 'semanic-release' package.
 - Many/all of the templates should have better preambles with placeholders. 
 - Some thought as to whether Pixi should be automatically updated within the script, or perhaps the user should be asked if they want to update it. 
 - A fleshed out template for the run script that has additional optional flags.
 - Optional multi-module setup
 - Optional (probably with flags) to setup things like nox/tox, different optional directories, use certain packages (e.g. typer vs argparse), and the like. 
 - Flexible positional CLI arguments (rather than fixed position)
 - A CLI flag that forces a version of Powershell (do versions before 5.1 also have the same path?). I'm not sure this matters since the script will run with 7 and 5.1.
 - Ask for packages to incorporate (with a list of options, likely, and probably a config file for each with a set of commands that need running to load them properly, and probably other settings like things to add to the gitignore), and then run the config commands.
 - Some way to deal with the fact that my 'comment-boilerplate' method offers three different commenting options, but only one can be saved for future use (because of the way I deal with BPs right now).
 - Passing pixi tasks, somehow, possibly with a config file. 
 - Should dates that are explicitly passed as parameters be verified to be a certain format?
 - There's probably a nice way to print messages around a function. I thought about using 'log' with a new severity level and 'call %~3' to call the subroutine as a passed paramter, but I didn't want to dedicate time to testing that.
 - "Need" some error testing in the PS scripts and then error catching the main function. 
 - Should the placeholders be required to used braces to be replaced? Perhaps that character should be adjustable, or the exact placeholder string should be replaced without expectation of characters, e.g. if 'package' is the key, instead of replacing '{package}' it should replaced just 'package', so if you wanted to replace '{package}', the key in the placeholders file should be just that: '{package}'.
 - The boilerplate situation seems kinda dumb.
 
### Fixed


### Changed
 - I'd still like to get that string-prepend method working. 

### Deprecated


### Removed


### Security


###############################################################################
###############################################################################

## [0.7.0] - 2025-04-18

### Added
 - Debugging levels added (1, 2, 3, and 4). Debugging level can be set either globally (e.g. 'set DEBUG_LEVEL=2' in the CLI before running the script) or as a CLI parameter (e.g. '--debug=2'). 
 - New CLI parameters:
     - 'debug=<level>' sets the debugging level; 0 for off, 4 for too much debugging.
     - 'validate=<path-to-baseline-root>' sets the validation baseline root directory; if set, the generated directory tree will be compared to this directory tree using 'Compare-FolderTreesAdvanced.ps1' for validation.
     - '<placeholder>=<replacement>': any placeholder-replacement mapping, even unknown ones, can be set here.
 - CLI parameters MUST be quoted, otherwise they won't be read properly. This is due to how Batch processes the arguments.
 - The 'placeholders' framework was completely revamped.
     - Default placeholders and their replacement values are defined in 'config\placeholders.DEFAULT'.
     - Users can overwrite the defaults and add their own in 'config\placeholders.USER'
     - Those, in turn, can be overwritten through the CLI by passing '<placeholder>=<replacement>' for a given placeholder and replacement pair. These do not need to be pre-defined in one of the 'placeholder' files, either.
     - Any placeholder in braces, e.g. {package}, in a template file will be replaced with the mapped replacement value.
     - The finalized project-specific placeholders file lives in '<package>\config\placeholders.config'
     - Placeholders can be nested within each other up to ten deep.
     - A number of new default placeholders have been defined.
     - The 'project_name' placeholder is automatically set to the package name.
 - Placeholder priority: defaults (from 'placeholders.DEFAULT') are overwritten by 'placeholders.USER' with are overwritten by CLI parameters.
     - Three parameters ('package', 'repo_name', and 'description') has special requirements: they must be set via CLI or they will be prompted for. Because these are package-specific, setting them in the 'placeholders.USER' file won't be sufficient.
 - The templates directory has been expanded
     - Files within the 'templates\src' subdirectory will be copied into the '<package>\src\<package>' automatically.
     - Files and folders within the 'templates' directory tree that are in the 'excluded' lists in 'config\pixi-pyprojectSetup_config.cmd' ('CFG_excludeFiles' and 'CFG_excludeFolders', respectively) will not be copied over.
     - All other files and folders will be copied as located in the tree, e.g. files in the 'templates\config' directory will be copied into '<package>\config'. 
 - Licenses and boilerplates
     - License files now live in 'templates\_licenses' with nomeclature defined by the license's SPDX code: 'license_<spdx-code>.txt'
     - Boilerplate files now live in 'templates\_licenses\boilerplates' and are named as '<spdx-code>_boilerplate.<ext>.TEMPLATE', where the <ext> defines the commenting character. There is no need to make these manually; the script will generate them if needed based on the '<spdx-code>_boilerplate.txt.TEMPLATE' file. If that doesn't exist, the script will generate a basic one first (though you can absolutely make your own). 
 - New configuration files in the 'config' subdirectory:
     - 'pixi-pyprojectSetup_config.cmd': stores lists of files and folders to be excluded from copying operations, a list of files to NOT add boilerplate text to, and a number of relative paths to scripts.
     - 'placeholders.DEFAULT': the default placeholder-replacement mapping file.
     - 'placeholders.USER.SAMPLE': the user-set placeholder-replacement mapping file. The '.SAMPLE' extension should be removed prior to running the script.
     - 'toml_insert.config': a JSON file that defines parameters for insertion into the 'pyproject.toml' file.
     - 'toml-replace.config': a JSON file that defines parameters for replacement within the 'pyproject.toml' file.
 - PowerShell scripts are located in the 'scripts' subdirectory:
     - 'Comment-File.ps1': Comments out an entire file; used for creating new boilerplate files.
     - 'Compare-FolderTreesAdvanced.ps1': Compares two directory trees; used for validation of the generated tree, if desired.
     - 'Convert-JsonWithErrorMapping.ps1': Wraps the 'Convert-Json' PowerShell method in a try/catch block with some useful escaping information on errors.
     - 'PrependToTarget.ps1': Prepends an arbitrary number of strings and/or text from files to a given file; used to prepending boilerplate text.
     - 'ReplacePlaceholders.ps1': Replaces curly-brace-wrapped placeholders from a given file based on a placeholder-mapping file.
     - 'Insert-Toml.ps1': Inserts lines into a .TOML file; used to insert the license filename, readme filename, and the description into the 'pyproject.toml' file.
     - 'Replace-Toml.ps1': Replaces lines within a .TOML file; used to update the 'authors' parameter from the Pixi-defined one to the user-passed ones.
 - Pixi is checked for upon startup.
 - Git output is suppressed, including warnings surrounding 'CRLF' and 'LF'.
 - A '.gitattributes' template file (in the 'templates' subdirectory) is used to define line-ending expectations.
 - Git 'safecrlf' is disabled.
 - The 'authors' line in 'pyproject.toml', which is originally set via Pixi at the system level, is replaced automatically by the passed author name and email, which allows the user to adjust their name or email per package.
 - A directory tree comparison PowerShell method is implemented, lives in the scripts directory, activates when the 'validate' flag is passed with a path to a root to compare the generated directory tree with.
 - Double checks the given parent\package path for viability before writing.
 - A new input confirmation loop subroutine is implemented.
 - Updated nearly all the templates:
     - A '.gitignore' template is provided.
     - New directories (config and scripts) are available
     - The '__init__.py' template now has the version and author variables defined within the template with placeholders, rather than being appended to the files via 'echo'. 
     - README.md got sections
     - CHANGELOG now follows the 'Keep A Changelog v.1.1' structure with semantic versioning
     - cli.py, __main__.py, __init__.py, and main.py got preambles with a clear description
     - 'runPythonScript.bat' added a run argument '--run-as-script' that can be passed to run 'main.py' instead of '__main__.py', a second run argument called '--src-dir' that defines what the 'src' directory is called (defaults to 'src', should be a relative path from the root directory). It also got a preamble. 
 - Directories and files may be freely added by the user and will be copyied and processed into the new package directory.


### Fixed


### Changed
 - Most of the underlying methods were reworked for clarity and flow. Many were converted to PowerShell scripts, including the TOML insertion, TOML replacements, placeholder replacements, commenting, and prepending.
 - Print and debug statements are made much clearer and more useful (hopefully)
 - The placeholder system was revamped using an external 'placeholders.env' file coupled with a PS script 'replacePlaceholders.ps1' to enable adding new placeholders without adjusting code. All the old placeholders still function as before. 
 - Reworked the copying methodology for easier understanding.
 - Added additional debugging functionality.
 - Moved the .toml file insertions and replacements to external scripts that allow for user adjustments through their associated config files.
 - Boilerplate commeting method is now a PS script and can be called with an arbitrary number of files and/or strings to prepend (in order).
 - The 'ReplacePlaceholders.ps1' now takes in the full file path to the output file and writes that. Avoids some chicanery around renaming, temp files, and deletions that was causing confusion.

### Deprecated

 
### Removed
 - 'tool.pytest.ini_options' removed from the .toml file, as I'm not using pytest and wanted to retain flexibility (and not confuse anything). 
 - Removed the 'repo-sameAs-package' flag. It was silly. 
  - {absPath} is no longer available as a placeholder for the project root directory; it's now {projRoot_dir}.
 
 
### Security



###############################################################################
###############################################################################


## [0.6.0] - 2025-04-17

### Added
 - README.md template file, instead of writing out to the file.
 - CHANGELOG.md template file (used for this file as well)
 - This CHANGELOG.md file
 - More status print-outs
 - {date} is now a replaceable string from the template (replaced with today's date in YYYY-MM-DD format).
 - Template files are now all named "<file_name>.<ext>.TEMPLATE", where <file_name> is the name that the file will be, e.g. '__init__' would be '__init__.py.TEMPLATE'. 
 
### Fixed


### Changed
 - Functionalized the useage of templates for file creation for cleaner code, including wrapping the "prepending" methods (non-working string version and the file version) into a larger function, a new copy function with status commentary, and then wrapping those with the string-replacement method into a full 'copy_fromTemplate' method.
 - Prepending a copyright string (which includes multiple special characters) proved to be quite challenging. I originally wanted to do that using a similar method as the file-prepending method (which uses powershell to basically create a new file and overwrite the old one), but I could not figure out how to handle it, so instead I just used the method to write the string out to a temp file and used the prepend-file method to write it. Then I tried to wrap the file and string methods under a single roof, but that turned out to be far more complicated than expected because testing if a string is a path is devilishly tricky when special characters are involved and I could not figure it out for the life of me. So instead I adjusted the 'copy_fromTemplate' method to take a file AND a string (and a flag, explained in a second) and then write the file if that existed and then the string if that existed (or, if the flag was set, the string first then the file). Overall, very frustrating sequence, and while it works, it's not really what I wanted. 


### Deprecated


### Removed


### Security