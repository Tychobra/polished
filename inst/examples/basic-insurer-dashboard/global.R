library(shiny)
library(shinydashboard)
library(tibble)
library(dplyr)
library(apexcharter)
library(DT)
library(lubridate)
library(shinyWidgets)
library(tychobratools)

trans <- readRDS("./data/trans.RDS")

state_choices <- unique(trans$state)
ay_choices <- trans %>%
                mutate(year = year(accident_date)) %>%
                pull("year") %>%
                unique() %>%
                sort()

my_colors <- c("#434348", "#7cb5ec")

hcoptslang <- getOption("highcharter.lang")
hcoptslang$thousandsSep <- ","
options(highcharter.lang = hcoptslang)

valueBox2 <- function (value, subtitle, icon = NULL, backgroundColor = "#7cb5ec", textColor = "#FFF", width = 4, href = NULL)
{
  
  boxContent <- div(
    class = paste0("small-box"),
    style = paste0("background-color: ", backgroundColor, "; color: ", textColor, ";"),
    div(
      class = "inner",
      h3(value),
      p(subtitle)
    ),
    if (!is.null(icon)) {
      div(class = "icon-large", icon)
    }
  )
  if (!is.null(href)) {
    boxContent <- a(href = href, boxContent)
  }
  div(
    class = if (!is.null(width)) paste0("col-sm-", width),
    boxContent
  )
}

display_names <- tribble(
  ~data_name, ~display_name,
  "claim_num", "Claim Number",
  "accident_date", "Accident Date",
  "state", "State",
  "claimant", "Claimant Name",
  "report_date", "Report Date",
  "status", "Status",
  "payment", "Payment",
  "case", "Case Reserve",
  "transaction_date", "Transaction Date",
  "trans_num", "Transcation Number",
  "paid", "Paid Loss",
  "reported", "Reported Loss"
)

#' show_names
#' 
#' @param nms character vector of names from the data
#' 
#' @examples 
#' show_names(names(trans))
#'
show_names <- function(nms) {
  nms_tbl <- tibble(data_name = nms)
  
  nms_tbl <- left_join(nms_tbl, display_names, by = "data_name") %>%
               mutate(display_name = ifelse(is.na(display_name), data_name, display_name))
  nms_tbl$display_name
}

#' loss_run
#' 
#' view losses as of a specific date
#' 
#' @param val_date date the valuation date of the loss run.  Claim values from `trans`
#' will be values as of the `val_date`
#' @param trans data frame of claims transactions
#' 
#' @importFrom dplyr `%>%` filter group_by top_n ungroup mutate arrange
#' 
#' @return data frame of claims (1 claim per row) valued as of the `val_date`
#' 
loss_run <- function(val_date, trans_ = trans) {
  trans_ %>%
    filter(transaction_date <= val_date) %>%
    group_by(claim_num) %>%
    top_n(1, wt = trans_num) %>%
    ungroup() %>%
    mutate(reported = paid + case) %>%
    arrange(desc(transaction_date))
}
