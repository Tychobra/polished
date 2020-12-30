/*
*
* @param sentry_dsn the Sentry.io DSN for your JavaScript project
* @param app_uid the polished app uid.
* @param user the polished user
* @param r_env the R environment returned from Sys.getenv("R_CONFIG_ACTIVE")
* @param the page of the app that the user is on
*
*/
const sentry_init = (sentry_dsn, app_uid, user = null, r_env = "default", page = null) => {

  Sentry.init({
    dsn: sentry_dsn,
    release: app_uid,
    attachStacktrace: true,
    sendDefaultPii: true,
    autoSessionTracking: true,
    normalizeDepth: 0,
    integrations: [new Sentry.Integrations.BrowserTracing()],

    // We recommend adjusting this value in production, or using tracesSampler
    // for finer control
    tracesSampleRate: 1.0,
    environment: r_env
  });


  if (user !== null) {
    Sentry.setUser(user)
  }

  if (page !== null) {
    Sentry.setTag("page", page)
  }

  $(document).on("shiny:error", function(event) {

      // shiny raises a lot of silent errors that we do not need to track.  Check if error
      // is not a silent error, and send that to sentry
      if (event.error.type === null || event.error.type[0] !== "shiny.silent.error") {
        Sentry.captureException(event.error);
      }

  })
}
