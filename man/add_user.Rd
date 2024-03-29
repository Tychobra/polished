% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/api_02_users.R
\name{add_user}
\alias{add_user}
\title{Polished API - Add a User}
\usage{
add_user(email, api_key = get_api_key())
}
\arguments{
\item{email}{the new user's email address.}

\item{api_key}{your Polished API key.  Set your polished api key using \code{\link{set_api_key}()}
so that you do not need to supply this argument with each function call.}
}
\value{
an object of class \code{polished_api_res}.  When successful, the \code{content} of the
\code{polished_api_res} is \code{list(message = "success")}.  In the case of an error, the
content is \code{list(error = "<error message>")}.
}
\description{
Polished API - Add a User
}
\seealso{
\code{\link[=get_users]{get_users()}} \code{\link[=update_user]{update_user()}} \code{\link[=delete_user]{delete_user()}}
}
