# Server se gradi samo sa paketima koji su mu potrebni (bez Fluttera).
FROM dart:3.13.5 AS build
WORKDIR /workspace
COPY <<EOT pubspec.yaml
name: svezko_server_image
environment:
  sdk: ^3.13.5
workspace:
  - packages/contract
  - packages/domain
  - packages/mapping
  - apps/server
EOT
COPY pubspec.lock ./
COPY packages/contract packages/contract
COPY packages/domain packages/domain
COPY packages/mapping packages/mapping
COPY apps/server apps/server
RUN dart pub get
RUN dart compile exe apps/server/bin/server.dart -o /server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server /app/server
WORKDIR /app
ENV HOST=0.0.0.0
USER 65532:65532
EXPOSE 8080
CMD ["/app/server"]
