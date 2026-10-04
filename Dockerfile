FROM ubuntu:latest AS download
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /loader

RUN apt update && apt install wget -y
RUN wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

FROM eclipse-temurin:21-jdk AS jdk-base
WORKDIR /app

FROM jdk-base AS builder
USER root
RUN apt update && apt install -y git

COPY --from=download /loader/BuildTools.jar /app/build/BuildTools.jar
WORKDIR /app/build

ARG MC_VERSION
RUN java -jar BuildTools.jar --rev ${MC_VERSION}
RUN mkdir -p /app/runner ; mv $(find /app/build -maxdepth 1 -type f -name "spigot*.jar") \
    /app/runner/server.jar

FROM jdk-base AS runner
WORKDIR /app/runner
COPY --from=builder /app/runner/server.jar .
RUN mkdir data

ARG EULA
RUN if [ "$EULA" != "true" ]; then \
        echo "You must agree with EULA policy to run this server!" ; \
        exit 1 ; \
    fi

ARG JAVA_ARGS
RUN echo "#!/bin/bash\ncd data\necho \"eula=$EULA\" > eula.txt\njava $JAVA_ARGS -jar ../server.jar --plugins \"$(pwd)/data/plugins\" --world-container \"$(pwd)/data/worlds\" nogui" | tee "start.sh" ; chmod +x ./start.sh

CMD ["./start.sh"]