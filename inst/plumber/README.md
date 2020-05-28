
```
# terminal

docker build -t polished_api .
# docker build --no-cache -t polished_api .

docker run --rm -p 8080:8080 polished_api
```

Now go to "localhost:8000/hello" in your browser to see your running Docker container

```
# terminal

# cleanup running containers
docker stop $(docker ps -q)
```


Deploy to Google Cloud Run

```
docker tag polished_api gcr.io/postgres-db-189513/polished_api

docker push gcr.io/postgres-db-189513/polished_api
```

Open bach shell inside running docker container.  This is useful for debugging.

```
docker exec -it $(docker ps -q) /bin/bash
```


Notes on running locally.  You can run the API directly from your local computer with the following
commands, but it is better to run with docker.

The following commands should allow you to run the plumber API directly from your computer.

```
# terminal

# remove old plumber API
sudo rm -r /plumber
# copy new plumber API to location to server plumber from
sudo cp -r ./api /plumber

# run plumber
Rscript plumber_server.R
```

```
# $ R

# create a new R session in your terminal.  By creating the R session in a separate
# terminal, you can still use your default R console for interactive use to manually
# test API requests.

library(plumber)
pr <- plumb("/plumber/plumber.R")

# register an exit handler to close the database connection when the plumber
# API closes
pr$registerHook("exit", function() {
  DBI::dbDisconnect(conn)
})

pr$run(port=8080)
```
