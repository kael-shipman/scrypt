# Scrypt

*A very simple bash file encryption tool*

## Purpose

Scrypt was written as a simple front-end for OpenSSL's reversible encryption algorithms. It takes files and/or directories as arguments and encrypts/decrypts each file individually using the password entered. (In the case of directories, it simply iterates through all files in the directory and encrypts (or decrypts) each one, optionally recursing through subdirectories.)

## Usage

Type `scrypt.sh -h` for usage.

## Caveats

**Don't forget your password!!**

Scrypt does not enforce password continuity, so it's possible to encrypt multiple files with different passwords. There are no hints as to which password you used for which file, so it's recommended that you always use the same password. And of course, if you forget the password, your file is lost.


