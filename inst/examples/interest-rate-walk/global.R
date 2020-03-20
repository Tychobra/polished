library(shiny)
library(tychobratools)
library(apexcharter)
library(DT)
library(shinythemes)
library(sde)
library(readr)
library(xts)
library(dplyr)
library(lubridate)
library(tibble)

# daily treasury bills
#library(quantmod)
#t_bill_10 <- quantmod::getSymbols('DGS10', src='FRED', auto.assign = FALSE)

# annual treasury bills
t_bills <- readr::read_csv("t-bills.csv")
t_bills$date <- as.Date(t_bills$date, format = "%m/%d/%Y")

t_bill_1 <- xts(x = t_bills[, "t_1"], order.by = t_bills$date)
t_bill_1_new <- as.data.frame(t_bill_1) %>% rownames_to_column("Date")
t_bill_5 <- xts(x = t_bills[, "t_5"], order.by = t_bills$date)
t_bill_5_new <- as.data.frame(t_bill_5) %>% rownames_to_column("Date")
t_bill_10 <- xts(x = t_bills[, "t_10"], order.by = t_bills$date)
t_bill_10_new <- as.data.frame(t_bill_10) %>% rownames_to_column("Date")
t_bill_20 <- xts(x = t_bills[, "t_20"], order.by = t_bills$date)
t_bill_20_new <- as.data.frame(t_bill_20) %>% rownames_to_column("Date")
t_bill_30 <- xts(x = t_bills[, "t_30"], order.by = t_bills$date)
t_bill_30_new <- as.data.frame(t_bill_30) %>% rownames_to_column("Date")


year_min <- min(year(t_bills$date))
year_max <- max(year(t_bills$date))
