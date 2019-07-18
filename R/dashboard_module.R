#' dashboard_module_ui
#'
#' @param id the module id
#'
#' @import shiny shinydashboard apexcharter xts dplyr DT shinycssloaders lubridate
#'
#' @export
dashboard_module_ui <- function(id) {
  ns <- NS(id)

  tabItem(
    tabName = "dashboard",
    shiny::fluidRow(
      tychobratools::value_box_module_ui(
        ns("dau_box"),
        icon = icon("users"),
        backgroundColor = "#0277BD",
        width = 3
      ),
      tychobratools::value_box_module_ui(
        ns("mau_box"),
        icon = icon("users"),
        backgroundColor = "#2b908f",
        width = 3
      ),
      tychobratools::value_box_module_ui(
        ns("das_box"),
        icon = icon("users"),
        backgroundColor = "#434348",
        width = 3
      ),
      tychobratools::value_box_module_ui(
        ns("active_users"),
        icon = icon("users"),
        backgroundColor = "#f7a35c",
        width = 3
      )
    ),
    shiny::fluidRow(
      shinydashboard::box(
        width = 9,
        apexcharter::apexchartOutput(ns("daily_users_chart")) %>%
          shinycssloaders::withSpinner(type = 8)
      ),
      shinydashboard::box(
        width = 3,
        DT::DTOutput(ns("active_users_table")) %>%
          shinycssloaders::withSpinner(type = 8, proxy.height = "341.82px"),
        br()
      )
    ),
    tags$script(src = "polish/js/admin_dashboard.js"),
    tags$script(paste0("dashboard_js('", ns(''), "')"))
  )
}

#' dashboard_module
#'
#' @import shiny
#'
#' @export
dashboard_module <- function(input, output, session) {
  ns <- session$ns

  # get a data frame of user sessions from Firestore and count the
  # sessions per user per day.  Returns a data frame with 3 columns:
  # - "date" in the "America/New_York" time zone
  # - "email"
  # - "n" the number of sessions
  #
  # If any days have 0 sessions, a row is added with an "email" of NA and
  # and "n" of 0. This helps for calculating daily averages.
  daily_user_sessions <- eventReactive(input$polish__user_sessions, {
    dat <- input$polish__user_sessions %>%
      dplyr::mutate(
        time_created = convert_timestamp(time_created),
        date = as.Date(time_created, tz = "America/New_York")
      ) %>%
      dplyr::group_by(date, email) %>%
      dplyr::summarize(n = n()) %>%
      dplyr::ungroup()

    # make sure all days are included even if zero sessions in a day
    first_day <- min(dat$date)

    out <- tibble(
      date = seq.Date(
        from = first_day,
        to = lubridate::today(tzone = "America/New_York"),
        by = "day"
      )
    )

    out %>%
      left_join(dat, by = "date") %>%
      mutate(n = ifelse(is.na(n), 0, n))
  })

  # returns a data frame with 2 columns
  # - "date" the date in "America/New_York" time zone
  # - "n" the number of unique daily users
  daily_users <- reactive({

    daily_user_sessions() %>%
      distinct(date, email) %>%
      group_by(date) %>%
      summarize(n = n()) %>%
      ungroup()

  })

  # calculate an format Daily Average Users for the value box
  dau_box_prep <- reactive({
    mean(daily_users()$n) %>%
      round(1) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "dau_box",
    dau_box_prep,
    reactive("Daily Average Users (DAU)")
  )

  # calculate and format the Monthly Average Users for the value box
  mau_box_prep <- reactive({
    by_month <- daily_user_sessions() %>%
      mutate(month_ = lubridate::month(date)) %>%
      distinct(month_, email) %>%
      group_by(month_) %>%
      summarize(n = n()) %>%
      ungroup()

    mean(by_month$n) %>%
      round(1) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "mau_box",
    mau_box_prep,
    reactive("Monthly Average Users (MAU)")
  )

  # calculate and format the Monthly Average Sessions for the value box
  das_box_prep <- reactive({
    daily_user_sessions() %>%
      group_by(date) %>%
      summarize(n_sessions = sum(n)) %>%
      ungroup() %>%
      pull("n_sessions") %>%
      mean() %>%
      round(1) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "das_box",
    das_box_prep,
    reactive("Daily Average Sessions (DAS)")
  )

  # poll the active sessions from the `.global_users` object
  poll_global_users <- shiny::reactivePoll(
    intervalMillis = 1000 * 10, # check every 10 seconds,
    session = session,
    checkFunc = function() {
      .global_users$users
    },
    valueFunc = function() {
      .global_users$users
    }
  )

  # calculate the unique active users from the active sessions.  Note: a user
  # can have more than 1 active session
  active_users_number_prep <- reactive({
    users_list <- poll_global_users()
    users <- unique(lapply(users_list, function(user) user$get_email()))

    length(users) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "active_users",
    active_users_number_prep,
    reactive("Active Users")
  )


  # prepare daily average users for the chart.
  daily_users_chart_prep <- reactive({
    daily_users() %>%
      mutate(
        month_ = as.character(lubridate::month(date, label = TRUE)),
        day_ = lubridate::day(date),
        date_out = paste0(month_, " ", day_)
      )
  })


  output$daily_users_chart <- apexcharter::renderApexchart({
    dat <- daily_users_chart_prep()

    apexcharter::apexchart() %>%
      apexcharter::ax_title(
        "Unique Daily Users",
        align = "center",
        style = list(
          fontSize = 18
        )
      ) %>%
      apexcharter::ax_chart(
        type = "area",
        zoom = list(
          type = "x",
          enabled = TRUE,
          autoScaleYaxis = TRUE
        ),
        toolbar = list(
          tools = list(
            selection = FALSE,
            zoomin = FALSE,
            zoomout = FALSE,
            pan = FALSE
          )
        )
      ) %>%
      apexcharter::ax_xaxis(
        categories = dat$date_out
      ) %>%
      apexcharter::ax_yaxis(
        min = 0
      ) %>%
      apexcharter::ax_stroke(show = TRUE, curve = "straight") %>%
      apexcharter::ax_dataLabels(enabled = FALSE) %>%
      apexcharter::ax_fill(
        type = "gradient",
        gradient = list(
          shadeIntensity = 1,
          opacityFrom = 0.7,
          opacityTo = 0.9,
          stops = list(0, 100)
        )
      ) %>%
      apexcharter::ax_series(list(
        data = dat$n,
        name = "Unique Users"
      ))
  })


  active_users_table_prep <- reactive({
    users_list <- poll_global_users()

    user_emails <- unlist(lapply(users_list, function(user) user$get_email()))

    dplyr::tibble(
      email = unique(user_emails)
    )
  })

  output$active_users_table <- DT::renderDataTable({
    out <- active_users_table_prep()

    DT::datatable(
      out,
      rownames = FALSE,
      colnames = c("Active Users"),
      options = list(
        dom = "t",
        scrollX = TRUE
      )
    )
  })
}

