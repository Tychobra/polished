
This directory contains the JS front end code and npm packages to transpile the JS code for use with polished.  Newer ES5+ JS is located in "srcjs/src".  We edit this code during development.  This code is transpiled from ES5+ into ES3 and placed in the "inst/assets/js" directory.  The transpiled code is what runs with polished.  It is compatible with older browsers than the ES5+ JS.  It is not edited directly by hand.

To transpile the code run the following:

```
# terminal

npm run build
```
