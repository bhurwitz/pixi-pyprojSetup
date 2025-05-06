REM =================================================================
REM This is a batch-list of files that are to not have any boilerplate prepended to them when copying. THEY ARE *NOT* ENTIRELY IGNORED.
REM
REM The 'list' is just a space-separate string of file names.
REM
REM Notes: 
REM     - If any filename has a space in it, it will itself need quotes as well. 
REM     - The filenames are case-insensitive.
REM 
REM Usage:
REM     set ignores=""ignore this.txt" skip_me.log dont_touch.exe"
REM =================================================================

@echo off
set ignores=".gitignore changelog.md"