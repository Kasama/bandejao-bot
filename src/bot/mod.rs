pub mod callback;
pub mod command;
pub mod config;
pub mod help;
pub mod keyboard;
pub mod meal;
pub mod schedule;
pub mod subscription;

use std::sync::Arc;

use anyhow::anyhow;
use futures::future::join_all;
use teloxide::dispatching::UpdateFilterExt;
use teloxide::payloads::{EditMessageTextSetters, SendMessageSetters};
use teloxide::prelude::Dispatcher;
use teloxide::requests::{Request, Requester};
use teloxide::types::ParseMode::Html;
use teloxide::types::{CallbackQuery, ChatId, Message, Update};
use teloxide::{dptree, respond};

use crate::database::schedule::DayPeriod;
use crate::database::users::{User, UserId};
use crate::usp::model::{Meals, Period};
use crate::Context;

use self::callback::CallbackCommand;

pub struct Bot {
    bot: teloxide::Bot,
    context: HandlerContext,
    configs: BotConfigs,
}

#[derive(Debug, Clone)]
pub struct BotConfigs {
    pub admin_id: UserId,
}

#[derive(Debug)]
pub struct MealResponse {
    pub campus: String,
    pub restaurant: String,
    pub period: Period,
    pub meal: Option<Meals>,
}

#[derive(Debug)]
pub enum Response {
    Meals(Vec<MealResponse>),
    Buttons(Option<String>, Vec<(String, String)>),
    Text(String),
    Noop,
}

#[derive(Debug, Clone)]
pub struct HandlerContext(Arc<Context>);

impl HandlerContext {
    pub fn new(ctx: Arc<Context>) -> Self {
        Self { 0: ctx }
    }

    pub async fn message_handler(self, bot: teloxide::Bot, msg: Message) -> anyhow::Result<()> {
        if let Some(user) = Bot::get_user(msg.from()) {
            self.0.db.upsert_user(user).await?;
        }

        bot.send_chat_action(msg.chat.id, teloxide::types::ChatAction::Typing)
            .await?;

        let command = command::parse_command(&msg);

        match command::execute_command(self, &command, msg.from().unwrap().id.0 as UserId, &bot)
            .await
        {
            Ok(resp) => match resp {
                Response::Meals(meal_responses) => {
                    if meal_responses.len() == 0 {
                        bot.send_message(
                            msg.chat.id,
                            "nenhum restaurante está selecionado. Use /config para configurar um",
                        )
                        .send()
                        .await?;
                    } else {
                        for meal_response in meal_responses {
                            let message = meal::format_message(meal_response);
                            let msg = bot.send_message(msg.chat.id, message).parse_mode(Html);
                            msg.send().await?;
                        }
                    }
                }
                Response::Buttons(text, buttons) => {
                    bot.send_message(
                        msg.chat.id,
                        text.unwrap_or(msg.text().unwrap_or("").to_string()),
                    )
                    .parse_mode(Html)
                    .reply_markup(keyboard::create_inline(buttons))
                    .await?;
                }
                Response::Text(txt) => {
                    let msg = bot.send_message(msg.chat.id, txt).parse_mode(Html);
                    msg.send().await?;
                }
                Response::Noop => (),
            },
            Err(err) => {
                bot.send_message(msg.chat.id, format!("failed: {:?}", err))
                    .parse_mode(Html)
                    .send()
                    .await?;
            }
        };

        respond(()).map_err(anyhow::Error::new)
    }

    pub async fn callback_handler(
        self,
        bot: teloxide::Bot,
        q: CallbackQuery,
    ) -> anyhow::Result<()> {
        let data = q.data.ok_or(anyhow!("got empty callback data"))?;
        let callback_command: CallbackCommand = serde_json::from_str(data.as_str())?;

        let msg = q
            .message
            .ok_or(anyhow!("clicked a button without message"))?;

        match callback::execute_callback(self, callback_command, q.from.id.0 as UserId).await? {
            Response::Meals(_) => (),
            Response::Buttons(text, buttons) => {
                bot.edit_message_text(
                    msg.chat.id,
                    msg.id,
                    text.unwrap_or(msg.text().unwrap_or("").to_string()),
                )
                .parse_mode(Html)
                .reply_markup(keyboard::create_inline(buttons))
                .await?;
            }
            Response::Text(text) => {
                bot.edit_message_text(msg.chat.id, msg.id, text).await?;
            }
            Response::Noop => (),
        };

        bot.answer_callback_query(q.id).await?;
        Ok(())
    }
}

impl Bot {
    pub fn from_env(context: HandlerContext, configs: BotConfigs) -> Self {
        Bot {
            bot: teloxide::Bot::from_env(),
            context,
            configs,
        }
    }

    pub fn new(token: String, context: HandlerContext, configs: BotConfigs) -> Self {
        Bot {
            bot: teloxide::Bot::new(token),
            context,
            configs,
        }
    }

    fn get_user(telegram_user: Option<&teloxide::types::User>) -> Option<User> {
        let tu = telegram_user?;
        let user = User {
            id: tu.id.0 as i64,
            username: tu.username.clone(),
            first_name: tu.first_name.clone(),
            last_name: tu.last_name.clone(),
        };

        return Some(user);
    }

    pub fn dispatcher(
        &self,
    ) -> Dispatcher<teloxide::Bot, anyhow::Error, teloxide::dispatching::DefaultKey> {
        let handler = dptree::entry()
            .branch(Update::filter_message().endpoint(
                |bot: teloxide::Bot, ctx: HandlerContext, msg: Message| async {
                    ctx.message_handler(bot, msg).await
                },
            ))
            .branch(Update::filter_callback_query().endpoint(
                |bot: teloxide::Bot, ctx: HandlerContext, q: CallbackQuery| async {
                    ctx.callback_handler(bot, q).await
                },
            ));

        Dispatcher::builder(self.bot.clone(), handler)
            .dependencies(dptree::deps![self.context.clone()])
            .enable_ctrlc_handler()
            .build()
    }

    pub async fn notify_subscribed_users(&self) -> Result<(), anyhow::Error> {
        let now = chrono::offset::Local::now();
        let (period, moment) = command::get_next(now);
        let weekday = moment.into_weekday(now);
        let day_period = DayPeriod::from((period, weekday));

        let chats = self.context.0.db.get_scheduled_chats(&day_period).await?;

        let total_subscriptions = chats.len();

        let (successes, failures): (Vec<_>, Vec<_>) =
            join_all(chats.into_iter().map(|(chat, user)| async move {
                let (period, moment) = command::get_next(now);
                let configs = self.context.0.db.get_configs(user).await?;
                let meal =
                meal::get_meal(&period, &moment, configs, &self.context.0.usp_client, now)
                .await?;
                if let Response::Meals(resp) = meal {
                    match resp.len() {
                        0 => self.bot.send_message(ChatId(chat), "nenhum restaurante está selecionado. Use /config para configurar um")
                            .await
                            .map(|a| vec![a])
                            .map_err(anyhow::Error::new),
                        _ => join_all(resp.into_iter().map(|r| async {
                            let txt = meal::format_message(r);
                            self.bot
                                .send_message(ChatId(chat), txt)
                                .parse_mode(Html)
                            .await
                        }))
                        .await
                        .into_iter()
                        .collect::<Result<Vec<_>, _>>()
                        .map_err(anyhow::Error::new)
                    }
                } else {
                    Ok(vec![])
                }
            }))
            .await
            .into_iter()
            .partition(|r| r.is_ok());

        let errors: Vec<String> = failures
            .into_iter()
            .filter_map(|f| f.err())
            .map(|e| e.to_string())
            .collect();

        if total_subscriptions > 0 {
            let admin_id = self.configs.admin_id;

            if let Err(e) = self
                .bot
                .send_message(
                    ChatId(admin_id),
                    format!(
                        "Got {}/{} successess and {} errors:{}",
                        successes.len(),
                        total_subscriptions,
                        errors.len(),
                        errors
                            .iter()
                            .map(|e| format!("\n- {}", e))
                            .collect::<Vec<_>>()
                            .join(""),
                    ),
                )
                .await
            {
                log::error!(
                    "could not notify schedule failure: {}: {}/{} successes",
                    e,
                    successes.len(),
                    total_subscriptions,
                )
            };
        }

        Ok(())
    }
}
