# mc-server-compose

Builds a [Spigot](https://www.spigotmc.org/) Minecraft server from source using `BuildTools.jar` and runs it in Docker.

## Requirements

- A Linux server with Docker Engine and the Docker Compose plugin installed.
  ```bash
  curl -fsSL https://get.docker.com | sh
  sudo apt install docker-compose-plugin   # if not already included
  ```
- At least 2 CPU cores and 3 GB free RAM (the build step compiles Spigot from source and the JVM is set to use 2 GB heap by default).
- Ports open on the host firewall: see [Ports](#ports) below.

## Getting the project onto the server

```bash
git clone <this-repo-url> mc-server-compose
cd mc-server-compose
```

## Configuration

Build-time options are set as `args` in `docker-compose.yaml`:

```yaml
services:
  server:
    build:
      context: .
      args:
        - MC_VERSION=1.20.4                        # Minecraft/Spigot version to build
        - JDK_VERSION=25                            # eclipse-temurin JDK tag used for all stages
        - EULA=true                                 # must be "true" to build the image
        - JAVA_ARGS=-Xms2G -Xmx2G -XX:+UseG1GC       # JVM flags for the running server
```

- **MC_VERSION** — version passed to `BuildTools.jar --rev`.
- **JDK_VERSION** — tag suffix for the `eclipse-temurin` base image (e.g. `21`, `25`). Must be a JDK version compatible with the Spigot version you're building.
- **EULA** — you must set this to `true`, confirming agreement with the [Minecraft EULA](https://www.minecraft.net/en-us/eula). The build fails if it's anything else.
- **JAVA_ARGS** — JVM flags such as heap size. Adjust `-Xms`/`-Xmx` to match the RAM available on your server.

Edit these values in `docker-compose.yaml` before building if you want a different Minecraft version or memory allocation.

## Build and run

```bash
docker compose build
docker compose up -d
```

The first build compiles Spigot from source via BuildTools and can take several minutes. Watch startup logs with:

```bash
docker compose logs -f server
```

The server is ready once you see `Done (...)! For help, type "help"`.

## Ports

| Port  | Protocol | Purpose                          | Required |
|-------|----------|-----------------------------------|----------|
| 25565 | TCP      | Minecraft server (client connect) | Yes      |

Open it on the host firewall if applicable, e.g.:

```bash
sudo ufw allow 25565/tcp
```

If you enable RCON or query in `data/server.properties`, open the corresponding ports too (`25575/tcp` for RCON by default) and map them in `docker-compose.yaml`.

## Data and persistence

Everything that needs to survive a rebuild or container recreation lives under `./data` on the host, bind-mounted to `/app/runner/data` in the container:

```yaml
volumes:
  - ./data:/app/runner/data
```

This includes `server.properties`, whitelist/ops/ban lists, `bukkit.yml`/`spigot.yml`, plugin configs, world saves, and logs. The compiled `server.jar` and `start.sh` live outside this folder and are rebuilt from the image, so they're safe to discard.

To install plugins, drop `.jar` files into `./data/plugins` and restart the server:

```bash
docker compose restart server
```

## Managing the server

```bash
docker compose stop server      # stop
docker compose start server     # start
docker compose restart server   # restart
docker compose down             # stop and remove the container (data is preserved on disk)
```

To send console commands or attach to the live console:

```bash
docker attach mc-server
```

Detach without stopping the server using `Ctrl+P` then `Ctrl+Q`.

## Updating

To rebuild with a new Minecraft version or JVM settings, update the `args` in `docker-compose.yaml`, then:

```bash
docker compose build server
docker compose up -d server
```

World data and configs in `./data` are untouched by rebuilds.
