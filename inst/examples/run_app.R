#
# ## Handler manager
#
# The handler manager gives you a place to register handlers (of both http and
# websocket varieties) and provides an httpuv-compatible set of callbacks for
# invoking them.
#
# Create one of these, make zero or more calls to `addHandler` and
# `addWSHandler` methods (order matters--first one wins!), and then pass the
# return value of `createHttpuvApp` to httpuv's `startServer` function.
#
## ------------------------------------------------------------------------
HandlerList <- R6Class("HandlerList",
  portable = FALSE,
  class = FALSE,
  public = list(
    handlers = list(),
    add = function(handler, key, tail = FALSE) {
      if (!is.null(handlers[[key]]))
        stop("Key ", key, " already in use")
      newList <- structure(names=key, list(handler))

      if (length(handlers) == 0)
        handlers <<- newList
      else if (tail)
        handlers <<- c(handlers, newList)
      else
        handlers <<- c(newList, handlers)
    },
    remove = function(key) {
      handlers[key] <<- NULL
    },
    clear = function() {
      handlers <<- list()
    },
    invoke = function(...) {
      for (handler in handlers) {
        result <- handler(...)
        if (!is.null(result))
          return(result)
      }
      return(NULL)
    }
  )
)


HandlerManager <- R6Class("HandlerManager",
  portable = FALSE,
  class = FALSE,
  public = list(
    handlers = "HandlerList",
    wsHandlers = "HandlerList",
    initialize = function() {
      handlers <<- HandlerList$new()
      wsHandlers <<- HandlerList$new()
    },
    addHandler = function(handler, key, tail = FALSE) {
      handlers$add(handler, key, tail)
    },
    removeHandler = function(key) {
      handlers$remove(key)
    },
    addWSHandler = function(wsHandler, key, tail = FALSE) {
      wsHandlers$add(wsHandler, key, tail)
    },
    removeWSHandler = function(key) {
      wsHandlers$remove(key)
    },
    clear = function() {
      handlers$clear()
      wsHandlers$clear()
    },
    createHttpuvApp = function() {
      list(
        onHeaders = function(req) {
          maxSize <- getOption('shiny.maxRequestSize') %||% (5 * 1024 * 1024)
          if (maxSize <= 0)
            return(NULL)

          reqSize <- 0
          if (length(req$CONTENT_LENGTH) > 0)
            reqSize <- as.numeric(req$CONTENT_LENGTH)
          else if (length(req$HTTP_TRANSFER_ENCODING) > 0)
            reqSize <- Inf

          if (reqSize > maxSize) {
            return(list(
              status = 413L,
              headers = list('Content-Type' = 'text/plain'),
              body = 'Maximum upload size exceeded'
            ))
          } else {
            return(NULL)
          }
        },
        call = .httpServer(
          function (req) {
            hybrid_chain(
              hybrid_chain(
                withCallingHandlers(
                  withLogErrors(handlers$invoke(req)),
                  error = function(cond) {
                    sanitizeErrors <- getOption('shiny.sanitize.errors', FALSE)
                    if (inherits(cond, 'shiny.custom.error') || !sanitizeErrors) {
                      stop(cond$message, call. = FALSE)
                    } else {
                      stop(paste("An error has occurred. Check your logs or",
                        "contact the app author for clarification."),
                        call. = FALSE
                      )
                    }
                  }
                ),
                catch = function(err) {
                  httpResponse(status = 500L,
                    content_type = "text/html; charset=UTF-8",
                    content = as.character(htmltools::htmlTemplate(
                      system_file("template", "error.html", package = "shiny"),
                      message = conditionMessage(err)
                    ))
                  )
                }
              ),
              function(resp) {
                maybeInjectAutoreload(resp)
              }
            )
          },
          loadSharedSecret()
        ),
        onWSOpen = function(ws) {
          return(wsHandlers$invoke(ws))
        }
      )
    },
    .httpServer = function(handler, checkSharedSecret) {
      filter <- getOption('shiny.http.response.filter')
      if (is.null(filter))
        filter <- function(req, response) response

      function(req) {
        if (!checkSharedSecret(req$HTTP_SHINY_SHARED_SECRET)) {
          return(list(
            status=403,
            body='<h1>403 Forbidden</h1><p>Shared secret mismatch</p>',
            headers=list('Content-Type' = 'text/html')
          ))
        }

        # Catch HEAD requests. For the purposes of handler functions, they
        # should be treated like GET. The difference is that they shouldn't
        # return a body in the http response.
        head_request <- FALSE
        if (identical(req$REQUEST_METHOD, "HEAD")) {
          head_request <- TRUE
          req$REQUEST_METHOD <- "GET"
        }

        response <- handler(req)

        res <- hybrid_chain(response, function(response) {
          if (is.null(response))
            response <- httpResponse(404, content="<h1>Not Found</h1>")

          if (inherits(response, "httpResponse")) {
            headers <- as.list(response$headers)
            headers$'Content-Type' <- response$content_type

            response <- filter(req, response)
              if (head_request) {

              headers$`Content-Length` <- getResponseContentLength(response, deleteOwnedContent = TRUE)

              return(list(
                status = response$status,
                body = "",
                headers = headers
              ))
            } else {
              return(list(
                status = response$status,
                body = response$content,
                headers = headers
              ))
            }

          } else {
            # Assume it's a Rook-compatible response
            return(response)
          }
        })
      }
    }
  )
)

autoReloadCallbacks <- shiny:::Callbacks$new()

createAppHandlers <- function(httpHandlers, serverFuncSource) {
  appvars <- new.env()
  appvars$server <- NULL

  sys.www.root <- system_file('www', package='shiny')

  # This value, if non-NULL, must be present on all HTTP and WebSocket
  # requests as the Shiny-Shared-Secret header or else access will be
  # denied (403 response for HTTP, and instant close for websocket).
  checkSharedSecret <- shiny:::loadSharedSecret()

  appHandlers <- list(
    http = joinHandlers(c(
      sessionHandler,
      httpHandlers,
      sys.www.root,
      resourcePathHandler,
      reactLogHandler
    )),
    ws = function(ws) {
      if (!checkSharedSecret(ws$request$HTTP_SHINY_SHARED_SECRET)) {
        ws$close()
        return(TRUE)
      }

      if (identical(ws$request$PATH_INFO, "/autoreload/")) {
        if (!get_devmode_option("shiny.autoreload", FALSE)) {
          ws$close()
          return(TRUE)
        }

        callbackHandle <- autoReloadCallbacks$register(function() {
          ws$send("autoreload")
          ws$close()
        })
        ws$onClose(function() {
          callbackHandle()
        })
        return(TRUE)
      }

      if (!is.null(getOption("shiny.observer.error", NULL))) {
        warning(
          call. = FALSE,
          "options(shiny.observer.error) is no longer supported; please unset it!"
        )
        stopApp()
      }

      shinysession <- shiny:::ShinySession$new(ws)
      appsByToken$set(shinysession$token, shinysession)
      #shinysession$setShowcase(.globals$showcaseDefault)

      messageHandler <- function(binary, msg) {
        withReactiveDomain(shinysession, {
          # To ease transition from websockets-based code. Should remove once we're stable.
          if (is.character(msg))
            msg <- charToRaw(msg)

          traceOption <- getOption('shiny.trace', FALSE)
          if (isTRUE(traceOption) || traceOption == "recv") {
            if (binary)
              message("RECV ", '$$binary data$$')
            else
              message("RECV ", rawToChar(msg))
          }

          if (isEmptyMessage(msg))
            return()

          msg <- shiny:::decodeMessage(msg)

          # Set up a restore context from .clientdata_url_search before
          # handling all the input values, because the restore context may be
          # used by an input handler (like the one for "shiny.file"). This
          # should only happen once, when the app starts.
          if (is.null(shinysession$restoreContext)) {
            #bookmarkStore <- getShinyOption("bookmarkStore", default = "disable")
            #if (bookmarkStore == "disable") {
              # If bookmarking is disabled, use empty context
              shinysession$restoreContext <- RestoreContext$new()
            #} else {
              # If there's bookmarked state, save it on the session object
            #  shinysession$restoreContext <- RestoreContext$new(msg$data$.clientdata_url_search)
            #  shinysession$createBookmarkObservers()
            #}
          }


          msg$data <- applyInputHandlers(msg$data)

          switch(
            msg$method,
            init = {

              serverFunc <- withReactiveDomain(NULL, serverFuncSource())
              if (!identicalFunctionBodies(serverFunc, appvars$server)) {
                appvars$server <- serverFunc
                if (!is.null(appvars$server))
                {
                  # Tag this function as the Shiny server function. A debugger may use this
                  # tag to give this function special treatment.
                  # It's very important that it's appvars$server itself and NOT a copy that
                  # is invoked, otherwise new breakpoints won't be picked up.
                  attr(appvars$server, "shinyServerFunction") <- TRUE
                  registerDebugHook("server", appvars, "Server Function")
                }
              }

              # Check for switching into/out of showcase mode
              #if (.globals$showcaseOverride &&
              #    exists(".clientdata_url_search", where = msg$data)) {
              #  mode <- showcaseModeOfQuerystring(msg$data$.clientdata_url_search)
              #  if (!is.null(mode))
              #    shinysession$setShowcase(mode)
              #}

              # In shinysession$createBookmarkObservers() above, observers may be
              # created, which puts the shiny session in busyCount > 0 state. That
              # prevents the manageInputs here from taking immediate effect, by
              # default. The manageInputs here needs to take effect though, because
              # otherwise the bookmark observers won't find the clientData they are
              # looking for. So use `now = TRUE` to force the changes to be
              # immediate.
              #
              # FIXME: break createBookmarkObservers into two separate steps, one
              # before and one after manageInputs, and put the observer creation
              # in the latter. Then add an assertion that busyCount == 0L when
              # this manageInputs is called.
              shinysession$manageInputs(msg$data, now = TRUE)

              # The client tells us what singletons were rendered into
              # the initial page
              if (!is.null(msg$data$.clientdata_singletons)) {
                shinysession$singletons <- strsplit(
                  msg$data$.clientdata_singletons, ',')[[1]]
              }

              local({
                args <- argsForServerFunc(serverFunc, shinysession)

                withReactiveDomain(shinysession, {
                  do.call(
                    # No corresponding ..stacktraceoff; the server func is pure
                    # user code
                    wrapFunctionLabel(appvars$server, "server",
                                      ..stacktraceon = TRUE
                    ),
                    args
                  )
                })
              })
            },
            update = {
              shinysession$manageInputs(msg$data)
            },
            shinysession$dispatch(msg)
          )
          # The HTTP_GUID, if it exists, is for Shiny Server reporting purposes
          shinysession$startTiming(ws$request$HTTP_GUID)
          shinysession$requestFlush()

          # Make httpuv return control to Shiny quickly, instead of waiting
          # for the usual timeout
          httpuv::interrupt()
        })
      }
      ws$onMessage(function(binary, msg) {
        # If unhandled errors occur, make sure they get properly logged
        withLogErrors(messageHandler(binary, msg))
      })

      ws$onClose(function() {
        shinysession$wsClosed()
        appsByToken$remove(shinysession$token)
        appsNeedingFlush$remove(shinysession$token)
      })

      return(TRUE)
    }
  )
  return(appHandlers)
}

startApp <- function(appObj, port, host, quiet) {
  appHandlers <- createAppHandlers(appObj$httpHandler, appObj$serverFuncSource)
  handlerManager$addHandler(appHandlers$http, "/", tail = TRUE)
  handlerManager$addWSHandler(appHandlers$ws, "/", tail = TRUE)

  httpuvApp <- handlerManager$createHttpuvApp()
  httpuvApp$staticPaths <- c(
    appObj$staticPaths,
    list(
      # Always handle /session URLs dynamically, even if / is a static path.
      "session" = excludeStaticPath(),
      "shared" = system_file(package = "shiny", "www", "shared")
    ),
    .globals$resourcePaths
  )

  # throw an informative warning if a subdirectory of the
  # app's www dir conflicts with another resource prefix
  wwwDir <- httpuvApp$staticPaths[["/"]]$path
  if (length(wwwDir)) {
    # although httpuv allows for resource prefixes like 'foo/bar',
    # we won't worry about conflicts in sub-sub directories since
    # addResourcePath() currently doesn't allow it
    wwwSubDirs <- list.dirs(wwwDir, recursive = FALSE, full.names = FALSE)
    resourceConflicts <- intersect(wwwSubDirs, names(httpuvApp$staticPaths))
    if (length(resourceConflicts)) {
      warning(
        "Found subdirectories of your app's www/ directory that ",
        "conflict with other resource URL prefixes. ",
        "Consider renaming these directories: '",
        paste0("www/", resourceConflicts, collapse = "', '"), "'",
        call. = FALSE
      )
    }
  }

  # check for conflicts in each pairwise combinations of resource mappings
  checkResourceConflict <- function(paths) {
    if (length(paths) < 2) return(NULL)
    # ensure paths is a named character vector: c(resource_path = local_path)
    paths <- vapply(paths, function(x) if (inherits(x, "staticPath")) x$path else x, character(1))
    # get all possible pairwise combinations of paths
    pair_indices <- utils::combn(length(paths), 2, simplify = FALSE)
    lapply(pair_indices, function(x) {
      p1 <- paths[x[1]]
      p2 <- paths[x[2]]
      if (identical(names(p1), names(p2)) && (p1 != p2)) {
        warning(
          "Found multiple local file paths pointing the same resource prefix: ", names(p1), ". ",
          "If you run into resource-related issues (e.g. 404 requests), consider ",
          "using `addResourcePath()` and/or `removeResourcePath()` to manage resource mappings.",
          call. = FALSE
        )
      }
    })
  }
  checkResourceConflict(httpuvApp$staticPaths)

  httpuvApp$staticPathOptions <- httpuv::staticPathOptions(
    html_charset = "utf-8",
    headers = list("X-UA-Compatible" = "IE=edge,chrome=1"),
    validation =
      if (!is.null(getOption("shiny.sharedSecret"))) {
        sprintf('"Shiny-Shared-Secret" == "%s"', getOption("shiny.sharedSecret"))
      } else {
        character(0)
      }
  )

  if (is.numeric(port) || is.integer(port)) {
    if (!quiet) {
      hostString <- host
      if (httpuv::ipFamily(host) == 6L)
        hostString <- paste0("[", hostString, "]")
      message('\n', 'Listening on http://', hostString, ':', port)
    }
    return(startServer(host, port, httpuvApp))
  } else if (is.character(port)) {
    if (!quiet) {
      message('\n', 'Listening on domain socket ', port)
    }
    mask <- attr(port, 'mask')
    if (is.null(mask)) {
      stop("`port` is not a valid domain socket (missing `mask` attribute). ",
           "Note that if you're using the default `host` + `port` ",
           "configuration (and not domain sockets), then `port` must ",
           "be numeric, not a string.")
    }
    return(startPipeServer(port, mask, httpuvApp))
  }
}
