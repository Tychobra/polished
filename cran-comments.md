## Test environments
* local OS X install, R 4.2.2
* Fedora Linux, R-devel, clang, gfortran
* Ubuntu Linux 20.04.1 LTS, R-release, GCC
* Windows Server 2022, R-devel, 64 bit

## R CMD check results

❯ checking CRAN incoming feasibility ... [22s] NOTE
  Maintainer: 'Andy Merlino <andy.merlino@tychobra.com>'

❯ checking package dependencies ... NOTE
  Imports includes 25 non-default packages.
  Importing from so many packages makes the package vulnerable to any of
  them becoming unavailable.  Move as many as possible to Suggests and
  use conditionally.

❯ checking for detritus in the temp directory ... NOTE
  Found the following files/directories:
    'lastMiKTeXException'

0 errors ✔ | 0 warnings ✔ | 3 notes ✖

## Reverse dependencies

There are no reverse dependencies.

## Comments

This is a patch release to fix a UX bug
