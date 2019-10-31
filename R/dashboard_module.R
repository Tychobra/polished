#' dashboard_module_ui
#'
#' @param id the module id
#'
#' @importFrom shiny NS fluidRow column
#' @importFrom shinydashboard tabItem box
#' @importFrom apexcharter apexchartOutput
#' @importFrom DT DTOutput
#' @importFrom shinycssloaders withSpinner
#' @importFrom tychobratools value_box_module_ui
#' @importFrom htmlwidgets JS
#'
#' @export
dashboard_module_ui <- function(id) {
  ns <- NS(id)

  tabItem(
    tabName = "dashboard",
    shiny::fluidRow(
      shiny::column(
        width = 9,
        shiny::fluidRow(
          tychobratools::value_box_module_ui(
            ns("dau_box"),
            icon = icon("users"),
            backgroundColor = "#0277BD",
            width = 4
          ),
          tychobratools::value_box_module_ui(
            ns("mau_box"),
            icon = icon("users"),
            backgroundColor = "#2b908f",
            width = 4
          ),
          tychobratools::value_box_module_ui(
            ns("das_box"),
            icon = icon("users"),
            backgroundColor = "#434348",
            width = 4
          )
        ),
        shiny::fluidRow(
          shinydashboard::box(
            width = 12,
            apexcharter::apexchartOutput(ns("daily_users_chart")) %>%
              shinycssloaders::withSpinner(type = 8)
          )
        )
      ),
      shiny::column(
        3,
        fluidRow(
          tychobratools::value_box_module_ui(
            ns("active_users"),
            icon = icon("users"),
            backgroundColor = "#f7a35c",
            width = 12
          ),
          shinydashboard::box(
            width = 12,
            DT::DTOutput(ns("active_users_table")) %>%
              shinycssloaders::withSpinner(type = 8, proxy.height = "341.82px"),
            br()
          )
        )
      )
    )
  )
}

#' dashboard_module
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny reactive callModule reactivePoll
#' @importFrom lubridate days today month
#' @importFrom dplyr tbl filter select collect mutate group_by summarize ungroup left_join %>% bind_rows distinct .data n
#' @importFrom tibble tibble
#' @importFrom apexcharter apexchart ax_title ax_chart ax_tooltip ax_xaxis ax_stroke ax_dataLabels ax_fill ax_series ax_yaxis
#' @importFrom DT renderDT datatable
#' @importFrom tychobratools value_box_module
#'
#' @export
dashboard_module <- function(input, output, session) {
  ns <- session$ns

  #  Returns a data frame with 3 columns:
  # - "date" in the "America/New_York" time zone
  # - "user_uid"
  # - "n" the number of sessions
  #
  daily_user_sessions <- shiny::reactive({

    hold_app_name = .global_sessions$app_name

    dat <- .global_sessions$conn %>%
      dplyr::tbl(dbplyr::in_schema("polished", "sessions")) %>%
      dplyr::filter(.data$app_name == hold_app_name) %>%
      dplyr::select(.data$user_uid, .data$created_at) %>%
      dplyr::collect() %>%
      dplyr::mutate(date = as.Date(.data$created_at, tz = "America/New_York")) %>%
      dplyr::group_by(.data$date, .data$user_uid) %>%
      dplyr::summarize(n = dplyr::n()) %>%
      dplyr::ungroup()



    # make sure all days are included even if zero sessions in a day
    first_day <- min(dat$date)

    out <- tibble::tibble(
      date = seq.Date(
        from = first_day,
        to = lubridate::today(tzone = "America/New_York"),
        by = "day"
      )
    )

    out %>%
      dplyr::left_join(dat, by = "date") %>%
      mutate(n = ifelse(is.na(n), 0, n))
  })

  # returns a data frame with 2 columns
  # - "date" the date in "America/New_York" time zone
  # - "n" the number of unique daily users
  daily_users <- reactive({

    daily_user_sessions() %>%
      dplyr::distinct(.data$date, .data$user_uid) %>%
      dplyr::group_by(.data$date) %>%
      dplyr::summarize(n = dplyr::n()) %>%
      dplyr::ungroup() %>%
      dplyr::filter(.data$date >= lubridate::today(tzone = "America/New_York") - lubridate::days(30))

  })



  # calculate an format Daily Average Users for the value box
  dau_box_prep <- shiny::reactive({
    mean(daily_users()$n) %>%
      round(1) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "dau_box",
    dau_box_prep,
    reactive("Average Daily Users")
  )

  # calculate and format the Monthly Average Users for the value box
  mau_box_prep <- shiny::reactive({
    by_month <- daily_user_sessions() %>%
      dplyr::mutate(month_ = lubridate::month(.data$date)) %>%
      dplyr::distinct(.data$month_, .data$user_uid) %>%
      dplyr::group_by(.data$month_) %>%
      dplyr::summarize(n = dplyr::n()) %>%
      dplyr::ungroup()

    mean(by_month$n) %>%
      round(1) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "mau_box",
    mau_box_prep,
    shiny::reactive("Average Monthly Users")
  )

  # calculate and format the Monthly Average Sessions for the value box
  das_box_prep <- shiny::reactive({
    daily_user_sessions() %>%
      dplyr::group_by(.data$date) %>%
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
    shiny::reactive("Average Daily Sessions")
  )

  # poll the active sessions from the `.global_sessions` object
  poll_global_users <- shiny::reactivePoll(
    intervalMillis = 1000 * 10, # check every 10 seconds,
    session = session,
    checkFunc = function() {
      length(.global_sessions$list())
    },
    valueFunc = function() {

      out <- .global_sessions$list()

      out_emails <- lapply(out, function(sesh) {
        tibble::tibble(
          email = sesh$email
        )
      })

      dplyr::bind_rows(out_emails) %>%
        dplyr::distinct(.data$email)
    }
  )




  # calculate the unique active users from the active sessions.  Note: a user
  # can have more than 1 active session
  active_users_number_prep <- reactive({
    active_user_emails <- poll_global_users()

    nrow(active_user_emails) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "active_users",
    active_users_number_prep,
    reactive("Current Active Users")
  )


  # prepare daily average users for the chart.
  daily_users_chart_prep <- reactive({
    daily_users <- daily_users()
    days <- nrow(daily_users)

    if (days < 7) {
      current_date <- daily_users$date[[days]]
      past_week <- dplyr::tibble(
        date = current_date - c(6, 5, 4, 3, 2, 1, 0)
      )

      daily_users <- past_week %>%
        left_join(daily_users, by = "date") %>%
        mutate(n = ifelse(is.na(n), 0, n))
    }

    daily_users %>%
      dplyr::mutate(
        month_ = as.character(lubridate::month(.data$date, label = TRUE)),
        day_ = lubridate::day(.data$date),
        date_out = paste0(.data$month_, " ", .data$day_)
      )
  })


  output$daily_users_chart <- apexcharter::renderApexchart({
    dat <- daily_users_chart_prep()

    ax_out <- apexcharter::apexchart() %>%
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
            pan = FALSE,
            reset = FALSE,
            zoom = FALSE
          )
        )
      ) %>%
      apexcharter::ax_tooltip(
        enabled = TRUE,
        y = list(
          formatter = htmlwidgets::JS("function (val) {return val.toFixed(0)}")
        )
      ) %>%
      apexcharter::ax_xaxis(
        categories = dat$date_out
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


    if (max(dat$n) <= 10) {
      ax_out <- ax_out %>%
        apexcharter::ax_yaxis(
          min = 0,
          tickAmount = max(dat$n),
          labels = list(
            formatter = htmlwidgets::JS("function (val) {return val.toFixed(0)}")
          )
        )
    } else {
      ax_out <- ax_out %>%
        apexcharter::ax_yaxis(
          min = 0
        )
    }

    ax_out
  })


  container <- htmltools::tags$table(
    htmltools::tags$thead(
      htmltools::tags$tr(
        htmltools::tags$th(
          style = "font-size: 18px; font-weight: 500;",
          "Active Users"
        )
      )
    )
  )

  output$active_users_table <- DT::renderDT({
    out <- poll_global_users()

    DT::datatable(
      out,
      rownames = FALSE,
      container = container,
      selection = "none",
      options = list(
        dom = "t",
        scrollX = TRUE
      )
    )
  })
}

