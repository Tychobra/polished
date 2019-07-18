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
        title = "Placeholder Chart",
        apexcharter::apexchartOutput(ns("daily_users_chart")) %>%
          shinycssloaders::withSpinner(type = 8)
      ),
      shinydashboard::box(
        width = 3,
        title = "Active Users",
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

  global_users_prep <- shiny::reactivePoll(
    intervalMillis = 1000 * 10, # check every 10 seconds,
    session = session,
    checkFunc = function() {
      .global_users$users
    },
    valueFunc = function() {
      .global_users$users
    }
  )

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

  daily_users <- eventReactive(input$polish__user_sessions, {
    daily_user_sessions() %>%
      distinct(date, email) %>%
      group_by(date) %>%
      summarize(n = n()) %>%
      ungroup()

  })

  das_box_prep <- reactive({
    daily_user_sessions() %>%
      print() %>%
      group_by(date) %>%
      summarize(n_sessions = sum(n)) %>%
      ungroup() %>%
      pull("n_sessions") %>%
      mean()
  })


  shiny::callModule(
    tychobratools::value_box_module,
    "das_box",
    das_box_prep,
    reactive("Daily Average Sessions (DAS)")
  )

  active_users_number_prep <- reactive({
    users_list <- global_users_prep()
    users <- unique(lapply(users_list, function(user) user$get_email()))

    length(users)
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "active_users",
    active_users_number_prep,
    reactive("Active Users")
  )

  dau_box_prep <- reactive({
    mean(daily_users()$n)
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "dau_box",
    dau_box_prep,
    reactive("Daily Average Users (DAU)")
  )

  mau_box_prep <- reactive({
    by_month <- daily_users() %>%
      mutate(month_ = lubridate::month(date)) %>%
      group_by(month_) %>%
      summarize(n = n()) %>%
      ungroup()

    mean(by_month$n)
  })

  shiny::callModule(
    tychobratools::value_box_module,
    "mau_box",
    mau_box_prep,
    reactive("Monthly Average Users (MAU)")
  )



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


  active_users_prep <- reactive({
    users_list <- global_users_prep()

    user_emails <- unlist(lapply(users_list, function(user) user$get_email()))

    dplyr::tibble(
      email = unique(user_emails),
      time = "13:09:00"
    )
  })

  output$active_users_table <- DT::renderDataTable({
    out <- active_users_prep()

    DT::datatable(
      out,
      rownames = FALSE,
      colnames = c("Email", "Signed In"),
      options = list(
        dom = "t",
        scrollX = TRUE
      )
    )
  })
}

