# syntax=docker/dockerfile:1
# check=error=true

# Production image for WeighTags. For development, use `bin/dev`.
# Build:  docker build -t weightags .
# Run:    docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value> --name weightags weightags

ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Packages needed at runtime (libpq for the pg gem; jemalloc for memory).
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Production environment.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage — compile gems and assets.
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

# Restore the executable bit on bin/*.
#
# Git records these as mode 100755, so a build whose context comes from a git
# checkout gets +x for free. A build whose context is an *archive of a Windows
# working tree* does not: NTFS has no exec bit, so `railway up` (and any other
# local-upload deploy) ships them 0644 and the build dies with
# "./bin/rails: Permission denied" (exit 126). Docker Desktop on Windows masks
# this locally by synthesizing 0777, so it only shows up on a real builder.
# The final stage inherits these modes via `COPY --from=build /rails /rails`,
# which also keeps ENTRYPOINT (bin/docker-entrypoint) and CMD (bin/thrust,
# bin/rails) executable at runtime.
RUN chmod +x bin/*

RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets without the real secret (SECRET_KEY_BASE_DUMMY).
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final image — copy artifacts, run as a non-root user.
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Prepare the database on boot, then exec the server.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
