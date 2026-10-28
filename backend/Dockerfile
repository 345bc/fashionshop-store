# Build with the backend directory as the Docker build context.
# Stage 1: Build
FROM maven:3.9-amazoncorretto-21 AS build

# Copy source code and pom.xml to /build
WORKDIR /build
COPY pom.xml ./
COPY src ./src

# Build source code
RUN mvn package -DskipTests

# Stage 2: Build image
FROM amazoncorretto:21-al2023

WORKDIR /app

COPY --from=build /build/target/zella-*.jar /app/app.jar

ENV SPRING_PROFILES_ACTIVE=product,jwt-auth \
    SERVER_PORT=8080

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
