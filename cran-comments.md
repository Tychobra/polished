## Test environments
* local OS X install, R 4.1.2
* Fedora Linux, R-devel, clang, gfortran
* Ubuntu Linux 20.04.1 LTS, R-release, GCC
* win-builder, R Under development (unstable) (2022-02-10 r81713 ucrt)

## R CMD check results

> checking package dependencies ... NOTE
  Imports includes 24 non-default packages.
  Importing from so many packages makes the package vulnerable to any of
  them becoming unavailable.  Move as many as possible to Suggests and
  use conditionally.

> checking dependencies in R code ... NOTE
  Unexported objects imported by ':::' calls:
    'rmarkdown:::rmarkdown_shiny_server' 'rmarkdown:::rmarkdown_shiny_ui'
    See the note in ?`:::` about the use of this operator.

0 errors ✓ | 0 warnings ✓ | 2 note x

## Reverse dependencies

There are no reverse dependencies.
