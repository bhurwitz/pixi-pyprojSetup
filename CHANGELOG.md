# Changelog for <{package}> package

Author: {author} <{email}>

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
 - Addition boilerplate text can be added through another file (namin TBD)
 - Incorporate the 'semanic-release' package.

### Fixed


### Changed
 - I'd still like to get that string-prepend method working. 

### Deprecated


### Removed


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