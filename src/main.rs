#![feature(pattern, proc_macro_hygiene, decl_macro)]

mod api;
mod bot;
mod database;
mod usp;

use clap::Parser;
use futures::lock::Mutex;
use std::sync::Arc;
use tokio::spawn;

use crate::bot::BotConfigs;
use crate::usp::Usp;

use self::database::DB;

#[derive(Debug)]
pub struct Context {
    usp_client: Mutex<Usp>,
    db: DB,
    // config: Arc<App>,
}

#[derive(Parser, Debug, Clone)]
#[command(author, version, about, long_about = None)]
struct App {
    // Usp Parameters

    // Api key for USP rucard restaurants API
    #[arg(long, env = "USP_API_KEY", required = true)]
    usp_api_key: String,
    // Base url for USP's rucard restaurants API
    #[arg(
        long,
        env = "USP_BASE_URL",
        default_value = "https://uspdigital.usp.br/rucard/servicos"
    )]
    usp_base_url: String,

    // Database Parameters

    // Database URL, in the format postgres://username:password@address:port/database
    #[arg(long, env = "DATABASE_URL", required = true)]
    database_url: String,

    // Bot parameters

    // Telegram bot token
    #[arg(long, env = "BOT_TOKEN", required = true)]
    bot_token: String,
    // Telegram ID of the user that is considered the bot admin
    #[arg(long, env = "ADMIN_ID", default_value = "41487359")] // @Kasama's id by default
    admin_id: i64,
    // if DEBUG_MODE is true, the bot will only send messages to the ADMIN_ID
    #[arg(long, env = "DEBUG_MODE", default_value = "false")]
    debug_mode: bool,
}

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    dotenvy::dotenv().ok();
    pretty_env_logger::init();

    log::info!("Starting 🍱 bandejao bot");

    // Will consume the env vars specified in the struct definition above
    let app = App::parse();

    let usp = Usp::new(app.usp_base_url, app.usp_api_key);
    let db = database::DB::new(app.database_url).await?;
    let context = Arc::new(Context {
        usp_client: Mutex::new(usp),
        db,
    });

    // Telegram bot
    let bot_context = bot::HandlerContext::new(
        context.clone(), /* doesn't actually clone, but increments RC */
    );
    let b = Arc::new(bot::Bot::new(
        app.bot_token,
        bot_context,
        BotConfigs {
            admin_id: app.admin_id,
        },
    ));

    // Run bot scheduler for automatic notifications
    let schedule_task = bot::schedule::spawn_schedules(b.clone());
    spawn(schedule_task); // spawn to run schedules concurrently

    // Run dispatcher. await will block until bot is done
    let mut bot_dispatcher = b.dispatcher();
    let dispatched_bot = bot_dispatcher.dispatch();

    // Http API
    // let api = api::create_v1_handler(
    //     context, /* no need to clone as it's te last use of context */
    // )
    // .await?
    // .launch();
    // let api_joiner = spawn(api);

    dispatched_bot.await;
    // tokio::join!(api).0?.shutdown().await;

    Ok(())
}
