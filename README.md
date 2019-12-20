# docker-rpi-tasmoadmin

Docker image for manage devices flashed with Tasmota firmware
https://github.com/reloxx13/TasmoAdmin


### Develop and test builds

Just type:

```
docker build . -t tasmoadmin
```

### Create final release and publish to Docker Hub

```
create-publish-release.sh
```


### Run

Given the docker image with name `tasmoadmin`:

```
docker run --name tasmo -p 8080:80 -v $(pwd)/datadir:/data -d jriguera/tasmoadmin
```

You can also use this env variables to automatically define some settings:

```
# Http Basic Auth
TASMOADMIN_AUTH_USER="${TASMOADMIN_AUTH_USER:-}"
TASMOADMIN_AUTH_PASS="${TASMOADMIN_AUTH_PASS:-}"
# TasmoAdmin user
TASMOADMIN_USER="${TASMOADMIN_USER:-}"
TASMOADMIN_PASS="${TASMOADMIN_PASS:-}"
# Enable or disable login
TASMOADMIN_LOGIN="${TASMOADMIN_LOGIN:-1}"
```

To enable TLS (https), just generate the certificate and key in `certs/tasmoadmin.crt`
and `certs/tasmoadmin.key` inside the data folder. You can redefine the environment
variables `TASMOADMIN_TLS_CRT` and `TASMOADMIN_TLS_KEY` to point to a different files.


And use them:

```
docker run --name tasmo -p 8080:80 -v $(pwd)/datadir:/data -e TASMOADMIN_LOGIN=0 -d jriguera/tasmoadmin

```

Make sure `$(pwd)/datadir` is created with uid 1000, otherwise docker will create it automatically
with uid 0 (root) and tasmoadmin will fail complaining about not being able to write files there.


# Author

Jose Riguera `<jriguera@gmail.com>`

