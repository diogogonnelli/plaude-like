FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

ARG BACKEND_BASE_URL=http://localhost:8787
ARG SUPABASE_URL=
ARG SUPABASE_ANON_KEY=
RUN flutter build web --release \
  --dart-define=BACKEND_BASE_URL=${BACKEND_BASE_URL} \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
