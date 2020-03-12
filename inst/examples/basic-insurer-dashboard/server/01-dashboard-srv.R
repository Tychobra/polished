### dashboard tab
dash_filters <- reactive({
  req(input$dash_cutoff)
  
  out <- val_tbl() %>%
    filter(reported >= input$dash_cutoff,
           state %in% input$dash_state)
  
  req(nrow(out) > 0)
  req(length(input$dash_state) > 0)
  
  out
})

dash_metric <- reactive({
  req(dash_filters())
  
  hold <- dash_filters() %>%
            mutate(year = lubridate::year(accident_date))
  
  if (input$dash_metric %in% c("total", "severity")) {
    hold <- hold %>%
              filter(status %in% input$dash_status) %>%
              group_by(year) %>%
              summarise(paid = sum(paid),
                        case = sum(case),
                        reported = sum(reported),
                        n = n())
    if (input$dash_metric == "severity") {
      hold <- hold %>%
        # need to keep totals so that we can calculate weighted avg total
        # severity accurately for value boxes
        mutate(paid_total = paid,
               case_total = case,
               reported_total = reported,
               paid = paid_total / n,
               case = case_total / n,
               reported = reported_total / n)
    }
  } else {
    hold <- hold %>%
      group_by(year, status) %>%
      summarise(n = n()) %>%
      tidyr::spread(key = status, value = n, fill = 0) %>%
      rename(paid = Closed,
             case = Open) %>%
      mutate(reported = paid + case) %>%
      ungroup()
  }
  
  hold
})




dash_metric_boxes <- reactive({
  req(dash_metric())
  
  dat <- dash_metric() 
  
  dash_metric_input <- input$dash_metric
  
  dat <- dat %>%
    summarise(paid = sum(paid),
              case = sum(case),
              reported = sum(reported),
              n = n())
  
  if (dash_metric_input == "severity") {
    dat <- dat %>%
      mutate(paid = paid / n,
             case = case / n,
             reported = reported / n)
  }
  
  titles <- switch(
    dash_metric_input,
    "total" = c("Paid Loss & ALAE", "Case Reserve", "Reported Loss & ALAE"),
    "severity" = c("Paid Severity", "Case Reserve Severity", "Reported Severity"),
    "claims" = c("Closed Claim Counts", "Open Claim Counts", "Reported Claim Counts")
  )
  
  list(
    "dat" = dat,
    "titles" = titles
  )
})

output$paid_box <- renderValueBox({
  req(dash_metric_boxes())
  
  out <- dash_metric_boxes()
  valueBox2(
    format(round(out$dat$paid, 0), big.mark = ","),
    subtitle = out$titles[1],
    icon = icon("money"),
    backgroundColor = "#434348"
  )
})

output$case_box <- renderValueBox({
  req(dash_metric_boxes())
  
  out <- dash_metric_boxes()
  valueBox2(
    format(round(out$dat$case, 0), big.mark = ","),
    subtitle = out$titles[2],
    icon = icon("university"),
    backgroundColor = "#7cb5ec"
  )
})

output$reported_box <- renderValueBox({
  req(dash_metric_boxes())
  
  out <- dash_metric_boxes()
  valueBox2(
    format(round(out$dat$reported, 0), big.mark = ","),
    subtitle = out$titles[3],
    icon = icon("clipboard"),
    backgroundColor = "#f7a35c"
  )
})


ay_plot_prep <- reactive({
  req(dash_metric())
  
  dash_metric_input <- input$dash_metric
  val_date <- input$val_date
  status <- if (length(input$dash_status) == 2) "All" else paste0(input$dash_status, collapse=", ")
  states <- if (length(input$dash_state) == 4) "All" else paste0(input$dash_state, collapse=", ")
  cutoff <- input$dash_cutoff
  
  subtitle <- paste0(
    "Status: ", status, "; States: ", states, "; Excluding Claims Below: ", cutoff
  )
  
  titles <- switch(
    dash_metric_input,
    "total" = list(
      "title" = paste0("Reported Loss & ALAE as of ", val_date),
      "subtitle" = subtitle,
      "series" = c("Paid", "Case Reserve"),
      "y_axis" = "Loss & ALAE"
    ),
    "severity" = list(
      "title" = paste0("Reported Severity as of ", val_date),
      "subtitle" = subtitle,
      "series" = c("Paid Severity", "Case Reserve Severity"),
      "y_axis" = "Loss & ALAE"
    ),
    "claims" = list(
      "title" = paste0("Reported Claims as of ", val_date),
      "subtitle" = paste0("States: ", states, "; Excluding Claims Below: ", cutoff),
      "series" = c("Closed Claims", "Open Claims"),
      "y_axis" = "Claim Counts"
    )
  )
  
  list(
    "dat" = dash_metric(),
    "titles" = titles
  )
})

output$ay_plot <- renderApexchart({
  req(ay_plot_prep())
  
  dat <- ay_plot_prep()$dat
  titles <- ay_plot_prep()$titles
  
  apexchart() %>% 
    ax_chart(
      type = 'bar', 
      stacked = TRUE,
      animations = list(
        enabled = TRUE
      )
    ) %>%
    ax_series(
      list(
        name = titles$series[1],
        data = round(dat$paid, 0)
      ),
      list(
        name = titles$series[2],
        data = round(dat$case, 0)
      )
    ) %>%
    ax_colors(
      colors = list('#434348', '#7cb5ec')
    ) %>%
    ax_xaxis(
      categories = dat$year,
      title = list(text = "Accident Year")
    ) %>%
    ax_yaxis(
      title = list(text = titles$y_axis)#,
      # labels = list(
      #   formatter = JS(
      #     "function (val) {
      #       debugger;
      #       if (val > 1000 && val < 1000000) {
      #         return val / 1000 + 'k';
      #       } else if (val > 1000000) {
      #         return val / 1000000 + 'M';
      #       }
      #     }"
      #   )
      # )
    ) %>%
    ax_title(
      text = titles$title,
      align = 'center',
      style = list(
        fontSize = '18px'
      )
    ) %>%
    ax_subtitle(
      text = titles$subtitle,
      align = 'center'
    ) %>%
    ax_dataLabels(
      enabled = TRUE,
      offsetY = -20,
      style = list(
        colors = list("#F7A35C")
      ),
      formatter = JS(
        "function (val, { seriesIndex, dataPointIndex, w}) {

          function formatNumber(num) {
            return num.toString().replace(/(\\d)(?=(\\d{3})+(?!\\d))/g, '$1,');
          };

          let indices = w.config.series.map(function (item, i) {
            return i;
          })
          indices = indices.filter(function (i) {
            return !w.globals.collapsedSeriesIndices.includes(i) && _.get(w.config.series, `${i}.data.${dataPointIndex}`) > 0;
          });

          var out = '';
          if (seriesIndex == _.max(indices)) {
            out = w.globals.stackedSeriesTotals[dataPointIndex];
          }
          return formatNumber(out);
        }"
      )
    ) %>%
    ax_plotOptions(
      bar = bar_opts(
        dataLabels = list(
          position = 'top',
          hideOverflowingLabels = FALSE
        )
      )
    )
  
})

observe({
  dat <- ay_plot_prep()$dat
  titles <- ay_plot_prep()$titles
  
  # browser()
  
  apexchartProxy('ay_plot') %>%
    ax_proxy_options(
      list(
        title = list(text = titles$title),
        subtitle = list(text = titles$subtitle),
        xaxis = list(
          categories = dat$year
        ),
        yaxis = list(
          title = list(text = titles$y_axis)#,
          # labels = list(
          #   formatter = JS(
          #     "function (val) {
          #       debugger;
          #       if (val > 1000 && val < 1000000) {
          #         return val / 1000 + 'k';
          #       } else if (val > 1000000) {
          #         return val / 1000000 + 'M';
          #       }
          #     }"
          #   )
          # )
        )
      )
    )
})


# output$ay_plot <- renderHighchart({
#   req(ay_plot_prep())
#   
#   dat <- ay_plot_prep()$dat
#   titles <- ay_plot_prep()$titles
#   
#   browser()
#   
#   highchart() %>%
#     hc_chart(type = "column") %>%
#     hc_exporting(
#       enabled = TRUE,
#       buttons = tychobratools::hc_btn_options()
#     ) %>%
#     hc_legend(
#       reversed = TRUE
#     ) %>%
#     hc_title(text = titles$title) %>%
#     hc_subtitle(text = titles$subtitle) %>%
#     hc_xAxis(
#       categories = dat$year,
#       title = list(text = "Accident Year")
#     ) %>%
#     hc_yAxis(
#       title = list(text = titles$y_axis),
#       stackLabels = list(
#         enabled = TRUE,
#         style = list(
#           fontWeight = "bold",
#           color = "#f7a35c",
#           textOutline = NULL
#         ),
#         format = "{total:,.0f}"
#       )
#     ) %>%
#     hc_plotOptions(
#       column = list(stacking = 'normal')
#     ) %>%
#     hc_add_series(
#       data = round(dat$case, 0),
#       name = titles$series[2]
#     ) %>%
#     hc_add_series(
#       data = round(dat$paid, 0),
#       name = titles$series[1]
#     ) 
# })
