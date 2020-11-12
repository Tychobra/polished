/*
*
* @param sentry_dsn the Sentry.io DSN for your JavaScript project
* @param app_uid the polished app uid.
* @param r_env the R environment returned from Sys.getenv("R_CONFIG_ACTIVE")
*
*/
const sentry_init = (sentry_dsn, app_uid, user = null, r_env = "default") => {

  Sentry.init({
    dsn: sentry_dsn,
    release: app_uid,
    integrations: [new Sentry.Integrations.BrowserTracing()],

    // We recommend adjusting this value in production, or using tracesSampler
    // for finer control
    tracesSampleRate: 1.0,
    environment: r_env
  })


  if (user !== null) {
    Sentry.setUser(user)
  }


  $(document).on("shiny:error", function(event) {

    // shiny raises a lot of silent errors that we do not need to track.  Check if error
    // is not a silent error, and send that to sentry
    if (event.error.type[0] !== "shiny.silent.error") {
      Sentry.captureException(event.error)
    }
  })
}
