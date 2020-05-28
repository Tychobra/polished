FROM rocker/r-base:4.0.0
MAINTAINER Andy Merlino <andy.merlino@tychobra.com>

RUN apt-get update -qq && apt-get install -y \
  git-core \
  libssl-dev \
  libcurl4-gnutls-dev \
  libxml2-dev \
  libpq-dev

# install R packages
RUN R -e "install.packages('remotes')"
RUN R -e "remotes::install_version('plumber', version = '0.4.6')"
RUN R -e "remotes::install_version('config', version = '0.3')"
RUN R -e "remotes::install_version('digest', version = '0.6.25')"
RUN R -e "remotes::install_version('base64enc', version = '0.1-3')"
RUN R -e "remotes::install_version('RPostgres', version = '1.2.0')"
RUN R -e "remotes::install_version('jsonlite', version = '1.6.1')"
RUN R -e "remotes::install_version('dplyr', version = '0.8.5')"
RUN R -e "remotes::install_version('dbplyr', version = '1.4.4')"
RUN R -e "remotes::install_version('DBI', version = '1.1.0')"

RUN R -e "remotes::install_github('tychobra/polished', ref = '86fcd349d0a0ba57519335bf028e3f67186c2e0a')"

# remove R packages that are not used at run time
#RUN R -e "remove.packages('remotes')"

VOLUME /plumber

COPY ./api /plumber

#EXPOSE 8080
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(commandArgs()[4]); pr$run(host='0.0.0.0', port=8080)"]
CMD ["plumber/plumber.R"]
