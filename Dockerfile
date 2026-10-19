# syntax=docker/dockerfile:1
# =============================================================================
#  Dockerfile - FILE KHUNG (multi-stage build cho Spring Boot 4 / Java 21 / Gradle)
#  Sinh viên hoàn chỉnh các ô ______ theo yêu cầu Phần 2 của đề thi.
# =============================================================================

# ---------- Stage 1: build - biên dịch & đóng gói bằng Gradle + JDK 21 ----------
# Spring Boot 4 yêu cầu Gradle >= 8.14
FROM gradle:8.5-jdk21-alpine AS builder
WORKDIR /app

# Copy build.gradle + settings.gradle trước, tải dependency để tận dụng cache layer
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Copy mã nguồn rồi đóng gói file JAR (bỏ qua test)
COPY src ./src
RUN ./gradlew bootJar -x test --no-daemon

# ---------- Stage 2: runtime - chỉ chứa JRE 21 + file JAR ----------
FROM eclipse-temurin:21-jre-alpine AS runtime

# Phiên bản ứng dụng truyền vào lúc build (docker compose: build-arg APP_VERSION)
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

WORKDIR /app

# Chạy ứng dụng bằng user thường, không dùng root
RUN addgroup -S spring && adduser -S spring -G spring
# Chỉ lấy file JAR từ stage build
COPY --from=builder --chown=spring:spring /app/build/libs/*.jar /app/app.jar
USER spring

EXPOSE 8083

# ENTRYPOINT dạng exec (mảng JSON)
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]