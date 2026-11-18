# Build from the repository root (the server depends on packages/fasal_core):
#   docker build -f server/Dockerfile -t fasal-api .
FROM dart:stable AS build
WORKDIR /app
COPY packages/fasal_core packages/fasal_core
COPY server/pubspec.yaml server/
WORKDIR /app/server
RUN dart pub get
COPY server/ .
RUN dart pub get --offline && dart compile exe bin/server.dart -o bin/server

# Minimal runtime image (includes CA certificates for MongoDB Atlas / Open-Meteo TLS).
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server/bin/server /app/bin/server
ENV APP_ENV=production PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
