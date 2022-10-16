#![feature(pattern)]
mod bot;
mod database;
mod usp;

use crate::usp::Usp;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    dotenvy::dotenv().ok();
    pretty_env_logger::init();

    log::info!("Starting 🍱 bandejao bot");

    // Consumes env vars
    // `USP_API_TOKEN` and `USP_BASE_URL`
    let usp = Usp::new_from_env()?;
    // Consumes env vars
    // `DATABASE_URL`
    let db = database::DB::from_env().await?;
    let context = bot::HandlerContext::new(usp, db);
    // Consumes env vars
    // `TELOXIDE_TOKEN` as the telegram bot's token
    let b = bot::Bot::from_env(context);

    // Run dispatcher. await will block until bot is done
    b.dispatcher().dispatch().await;

    Ok(())
}
