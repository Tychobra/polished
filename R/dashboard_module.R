#' dashboard_module_ui
#'
#' @param id the module id
#'
#' @import shiny shinydashboard apexcharter xts dplyr DT shinycssloaders
#'
#' @export
dashboard_module_ui <- function(id) {
  ns <- NS(id)

  tabItem(
    tabName = "dashboard",
    shiny::fluidRow(
      shinydashboard::valueBox(
        value = NA,
        subtitle = "Total Users",
        icon = icon("users"),
        color = "blue",
        width = 3
      ),
      tychobratools::value_box_module_ui(
        ns("active_users"),
        icon = icon("users"),
        backgroundColor = "#81aef7",
        width = 3
      ),
      shinydashboard::valueBox(
        value = NA,
        subtitle = "DAU",
        icon = icon("users"),
        color = "teal",
        width = 3
      ),
      shinydashboard::valueBox(
        value = NA,
        subtitle = "MAU",
        icon = icon("users"),
        color = "green",
        width = 3
      )
    ),
    shiny::fluidRow(
      shinydashboard::box(
        width = 9,
        title = "Placeholder Chart",
        apexcharter::apexchartOutput(ns("dau_chart")) %>%
          shinycssloaders::withSpinner(type = 8)
      ),
      shinydashboard::box(
        width = 3,
        title = "Active Users",
        DT::DTOutput(ns("active_users_table")) %>%
          shinycssloaders::withSpinner(type = 8, proxy.height = "341.82px"),
        br()
      )
    )
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


  active_users_number_prep <- reactive({
    users_list <- global_users_prep()
    users <- unique(lapply(users_list, function(user) user$get_email()))

    length(users)
  })

  callModule(
    tychobratools::value_box_module,
    "active_users",
    active_users_number_prep,
    reactive("Active Users")
  )


  dau_chart_prep <- reactive({
    date_strings <- c("2019-07-01", "2019-07-02", "2019-07-03", "2019-07-04", "2019-07-05",
                      "2019-07-06", "2019-07-07", "2019-07-08", "2019-07-09", "2019-07-10",
                      "2019-07-11", "2019-07-12", "2019-07-13", "2019-07-14")

    dates <- as.POSIXct(date_strings)

    dplyr::tibble(
      input = c(3,2,2,3,1,4,2,5,7,6,9,15,16,16),
      date = dates
    )
  })

  output$dau_chart <- apexcharter::renderApexchart({
    dat <- dau_chart_prep()

    apexcharter::apexchart() %>%
      apexcharter::ax_title(
        "Daily Active Users",
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
            zoomout = FALSE
          )
        )
      ) %>%
      apexcharter::ax_xaxis(
        type = "datetime",
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
      apexcharter::ax_series(list(data = dat$input, name = "DAU"))
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

