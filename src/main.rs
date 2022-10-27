#![feature(pattern, proc_macro_hygiene, decl_macro)]

// #[macro_use]
// extern crate rocket;
mod api;
mod bot;
mod database;
mod usp;

use std::sync::Arc;

use clap::Parser;
use futures::lock::Mutex;

use crate::usp::Usp;

use self::database::DB;

#[derive(Debug)]
pub struct Context {
    usp_client: Mutex<Usp>,
    db: DB,
    // config: Arc<Config>,
}

#[derive(Parser, Debug, Clone)]
#[command(author, version, about, long_about = None)]
struct Config {
    // Usp Parameters
    #[arg(long, env = "USP_API_KEY", required = true)]
    usp_api_key: String,
    #[arg(
        long,
        env = "USP_BASE_URL",
        default_value = "https://uspdigital.usp.br/rucard/servicos"
    )]
    usp_base_url: String,

    // Database Parameters
    #[arg(long, env = "DATABASE_URL", required = true)]
    database_url: String,

    // Bot parameters
    #[arg(long, env = "TELOXIDE_TOKEN", required = true)]
    bot_token: String,
}

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    dotenvy::dotenv().ok();
    pretty_env_logger::init();

    log::info!("Starting 🍱 bandejao bot");

    // Will consume the env vars specified in the struct definition above
    let cfg = Config::parse();

    let usp = Usp::new(cfg.usp_base_url, cfg.usp_api_key);
    let db = database::DB::new(cfg.database_url).await?;
    let context = Arc::new(Context {
        usp_client: Mutex::new(usp),
        db,
        // config: cfg.clone(),
    });

    // Telegram bot
    let bot_context = bot::HandlerContext::new(
        context.clone(), /* doesn't actually clone, but increments RC */
    );
    let b = bot::Bot::new(cfg.bot_token, bot_context);

    // Run dispatcher. await will block until bot is done
    let mut bot_dispatcher = b.dispatcher();
    let dispatched_bot = bot_dispatcher.dispatch();

    // Http API
    // let api = api::create_v1_handler(
    //     context, /* no need to clone as it's te last use of context */
    // )
    // .await?
    // .launch();

    // futures::join!(dispatched_bot, api).1?.shutdown().await;
    dispatched_bot.await;

    Ok(())
}
