# ---- Stage 1: build the WAR with Maven -------------------------------------------------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Copy only the POM first so the dependency layer is cached until pom.xml changes.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q package -DskipTests

# ---- Stage 2: run it on a standalone Tomcat --------------------------------------------
FROM tomcat:10.1-jdk21-temurin

# Remove the sample apps, then deploy our WAR as ROOT so it is served at "/" (=> /api/orders).
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /build/target/orders-api.war /usr/local/tomcat/webapps/ROOT.war

# JVM flags for Tomcat live in CATALINA_OPTS. Size the heap relative to the container limit.
ENV CATALINA_OPTS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

# Do not run as root.
RUN useradd --system --uid 1001 --home-dir /usr/local/tomcat tomcatapp \
 && chown -R tomcatapp:tomcatapp /usr/local/tomcat
USER tomcatapp

EXPOSE 8080
CMD ["catalina.sh", "run"]
