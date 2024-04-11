FROM rustlang/rust:nightly as builder

# create a new empty shell project
RUN USER=root cargo new --bin bandejao-bot
WORKDIR /bandejao-bot

# copy over your manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

# this build step will cache your dependencies
RUN SQLX_OFFLINE=1 cargo build --release
RUN rm src/*.rs || true

# copy your source tree
COPY ./src ./src
COPY ./sqlx-data.json ./sqlx-data.json
COPY ./.sqlx ./.sqlx
COPY ./migrations ./migrations

# build for release
RUN rm -rf ./target/release || true
RUN SQLX_OFFLINE=1 cargo build --release

# our final base
FROM rustlang/rust:nightly

# copy the build artifact from the build stage
COPY --from=builder /bandejao-bot/target/release/bandejao-bot .

# set the startup command to run your binary
CMD ["./bandejao-bot"]
