#' dashboard_module_ui
#'
#' @param id the module id
#'
#' @importFrom shiny NS fluidRow column
#' @importFrom shinydashboard tabItem box
#' @importFrom apexcharter apexchartOutput
#' @importFrom DT DTOutput
#' @importFrom shinycssloaders withSpinner
#' @importFrom shinyFeedback valueBoxModuleUI
#' @importFrom htmlwidgets JS
#'
#' @export
dashboard_module_ui <- function(id) {
  ns <- NS(id)

  tabItem(
    tabName = "dashboard",
    shiny::tags$head(
      shiny::tags$style(
        paste0(
          "#", ns('daily_users_chart'), " {
            overflow: hidden;
          }"
        )
      )
    ),
    shiny::fluidRow(
      shiny::column(
        width = 9,
        shiny::fluidRow(
          shinyFeedback::valueBoxModuleUI(
            ns("dau_box"),
            subtitle = "Average Daily Users",
            icon = icon("users"),
            backgroundColor = "#0277BD",
            width = 4
          ),
          shinyFeedback::valueBoxModuleUI(
            ns("mau_box"),
            subtitle = "Average Monthly Users",
            icon = icon("users"),
            backgroundColor = "#2b908f",
            width = 4
          ),
          shinyFeedback::valueBoxModuleUI(
            ns("das_box"),
            subtitle = "Average Daily Sessions",
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
          shinyFeedback::valueBoxModuleUI(
            ns("active_users"),
            subtitle = "Current Active Users",
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
#' @importFrom shiny reactive callModule reactivePoll reactiveVal observe req
#' @importFrom lubridate days today month
#' @importFrom dplyr tbl select collect mutate group_by summarize ungroup left_join %>% bind_rows distinct .data n
#' @importFrom tibble tibble
#' @importFrom apexcharter apexchart ax_title ax_chart ax_tooltip ax_xaxis ax_stroke ax_dataLabels ax_fill ax_series ax_yaxis
#' @importFrom DT renderDT datatable dataTableProxy replaceData
#' @importFrom shinyFeedback valueBoxModule
#'
#' @export
dashboard_module <- function(input, output, session) {
  ns <- session$ns

  #  Returns a data frame with 3 columns:
  # - "date" in the "America/New_York" time zone
  # - "daily_sessions" the daily number of sessions
  # - "daily_users" the daily number of users
  #
  daily_user_sessions <- shiny::reactive({
    hold_app_uid = .global_sessions$app_name

    start_date <- lubridate::today(tzone = "America/New_York") - lubridate::days(30)


    out <- list()
    tryCatch({
      res <- httr::GET(
        url = paste0(.global_sessions$hosted_url, "/daily-sessions"),
        query = list(
          app_uid = hold_app_uid
        ),
        httr::authenticate(
          user = .global_sessions$api_key,
          password = ""
        )
      )

      httr::stop_for_status(res)

      out <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )
    })

    if (length(out) == 0) {
      out <- tibble::tibble(
        date = as.Date(character(0)),
        daily_sessions = integer(0),
        daily_users = integer(0)
      )
    } else {
      out <- out %>%
        mutate(date = as.Date(date))
    }

    out
  })

  # returns a data frame with 2 columns
  # - "date" the date in "America/New_York" time zone
  # - "n" the number of unique daily users
  daily_users <- reactive({

    daily_user_sessions() %>%
      select(date, n = daily_users)

  })



  # calculate an format Daily Average Users for the value box
  dau_box_prep <- shiny::reactive({
    out <- mean(daily_users()$n) %>%
      round(1) %>%
      format(big.mark = ",")

    if (out == "NaN") {
      out <- 0
    }

    out
  })

  shiny::callModule(
    shinyFeedback::valueBoxModule,
    "dau_box",
    dau_box_prep
  )

  # calculate and format the Monthly Average Users for the value box
  mau_box_prep <- shiny::reactive({
    by_month <- daily_user_sessions() %>%
      dplyr::mutate(month_ = lubridate::month(.data$date)) %>%
      dplyr::group_by(.data$month_) %>%
      dplyr::summarize(n = sum(daily_users)) %>%
      dplyr::ungroup()

    out <- mean(by_month$n) %>%
      round(1) %>%
      format(big.mark = ",")

    if (out == "NaN") {
      out <- 0
    }

    out
  })

  shiny::callModule(
    shinyFeedback::valueBoxModule,
    "mau_box",
    mau_box_prep
  )

  # calculate and format the Daily Average Sessions for the value box
  das_box_prep <- shiny::reactive({
    out <- daily_user_sessions() %>%
      pull("daily_sessions") %>%
      mean() %>%
      round(1) %>%
      format(big.mark = ",")

    if (out == "NaN") {
      out <- 0
    }

    out
  })

  shiny::callModule(
    shinyFeedback::valueBoxModule,
    "das_box",
    das_box_prep
  )

  # poll the active sessions from the `.global_sessions` object
  poll_global_users <- shiny::reactivePoll(
    # trigger once every 30 seconds
    intervalMillis = 30000,
    session = session,
    # invalidate every 30 second interval
    checkFun = function() {
      Sys.time()
    },
    valueFunc = function() {
      hold_app_uid = .global_sessions$app_name

      res <- httr::GET(
        url = paste0(.global_sessions$hosted_url, "/active-users"),
        query = list(
          app_uid = hold_app_uid
        ),
        httr::authenticate(
          user = .global_sessions$api_key,
          password = ""
        )
      )

      httr::stop_for_status(res)

      out <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      ) %>%
        tibble::as_tibble()

      out
  })


  # calculate the unique active users from the active sessions.  Note: a user
  # can have more than 1 active session
  active_users_number_prep <- reactive({
    active_user_emails <- poll_global_users()

    nrow(active_user_emails) %>%
      format(big.mark = ",")
  })

  shiny::callModule(
    shinyFeedback::valueBoxModule,
    "active_users",
    active_users_number_prep
  )


  # prepare daily average users for the chart.
  daily_users_chart_prep <- reactive({
    daily_users <- daily_users()
    days <- nrow(daily_users)

    if (days < 7) {
      current_date <- lubridate::today(tzone = "America/New_York")
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
        type = 'datetime',
        categories = dat$date
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
          style = "font-size: 18px; font-weight: 500; text-align: center;",
          "Active Users"
        )
      )
    )
  )
  
  active_users_table_prep <- shiny::reactiveVal()
  
  shiny::observe({
    shiny::req(length(poll_global_users()) > 0)
    out <- poll_global_users()
    
    if (is.null(active_users_table_prep())) {
      active_users_table_prep(out)
    } else {
      DT::replaceData(active_users_table_proxy, out, rownames = FALSE)
    }
  })
  

  output$active_users_table <- DT::renderDT({
    shiny::req(active_users_table_prep())
    out <- active_users_table_prep()

    DT::datatable(
      out,
      rownames = FALSE,
      container = container,
      selection = "none",
      callback = JS("$( table.table().container() ).addClass( 'table-responsive' ); return table;"),
      options = list(
        dom = "tp",
        language = list(
          emptyTable = "No Active Users"
        )
      )
    )
  })
  
  active_users_table_proxy <- DT::dataTableProxy("active_users_table")
}

