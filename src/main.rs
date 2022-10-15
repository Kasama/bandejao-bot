#![feature(pattern)]
mod bot;
mod usp;

use crate::usp::Usp;

use futures::lock::Mutex;
use std::sync::Arc;

use dotenv;
use teloxide::dispatching::UpdateFilterExt;
use teloxide::prelude::*;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    dotenv::dotenv().ok();
    pretty_env_logger::init();

    log::info!("Starting 🍱 bandejao bot");

    let b = bot::bot();
    let usp = Usp::new_from_env()?;
    let context = Arc::new(Mutex::new(usp));

    let handler = Update::filter_message().endpoint(
        |bot: Bot, ctx: Arc<Mutex<Usp>>, msg: Message| async move {
            let message_text = msg.text().unwrap_or_default().to_string();
            let command = bot::command::parse_command(&message_text);

            match bot::command::execute_command(ctx,command).await {
                Ok(resp) => {
                    bot.send_message(msg.chat.id, format!("Hello good sir: {:?}", resp))
                        .send()
                    .await?;
                },
                Err(err) => {
                    bot.send_message(msg.chat.id, format!("failed: {:?}", err))
                        .send()
                    .await?;
                },
            };


            respond(())
        },
    );

    Dispatcher::builder(b, handler)
        .dependencies(dptree::deps![context])
        .enable_ctrlc_handler()
        .build()
        .dispatch()
        .await;

    Ok(())
}
