# Stage 1: Build environment
FROM ubuntu:22.04 AS build-env

# Install flutter dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    openjdk-17-jdk-headless wget \
    && rm -rf /var/lib/apt/lists/*

# Set up Flutter SDK
ENV FLUTTER_VERSION=3.22.0
RUN git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-download development binaries
RUN flutter doctor

WORKDIR /app
COPY . .

# Run pub get and code generator
RUN flutter pub get
RUN dart run build_runner build --delete-conflicting-outputs

# Execute unit tests
RUN flutter test

# Build Flutter Web for production
RUN flutter build web -t lib/main_prod.dart

# Stage 2: Serve Flutter Web on Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
