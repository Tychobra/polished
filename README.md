# polished <img src="inst/assets/images/polished_logo_transparent.png" align="right" width="120" />

[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing) [![Travis-CI Build Status](https://travis-ci.org/Tychobra/polished.svg?branch=master)](https://travis-ci.org/tychobra/polished)

Authentication and user administration for Shiny apps.  `polished` provides a way to secure your Shiny application behind an authentication layer.  It also provides a UI for controlling user access. 

### Live Demo

Register and sign in to a [live Shiny app using polished](https://tychobra.shinyapps.io/polished_example_01).

### Polished API

polished requires the [polishedapi](https://github.com/Tychobra/polishedapi).  There are two ways to use the `polishedapi`.

1. [polished.tech](https://polished.tech): polished.tech is our hosted offering of the `polishedapi`.  It is the easiest way to use `polished`.  It does not require database setup or API hosting.  

2. On Premise: Deploy the `polishedapi` on your own servers.  This naturally requires you to set up and maintain a database and API hosting server.  

If you want to use [polished.tech](https://polished.tech), go to the polished.tech website and follow the [Get Started](https://polished.tech/docs/get-started) instructions.  If you want to deploy the polishedapi on premise, check out the [polishedapi README](https://github.com/Tychobra/polishedapi/blob/master/README.md).
