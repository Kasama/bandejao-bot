pub mod callback;
pub mod command;
pub mod config;
pub mod keyboard;
pub mod meal_menu;

use std::sync::Arc;

use anyhow::anyhow;
use teloxide::dispatching::UpdateFilterExt;
use teloxide::payloads::{EditMessageTextSetters, SendMessageSetters};
use teloxide::prelude::Dispatcher;
use teloxide::requests::{Request, Requester};
use teloxide::types::ParseMode::Html;
use teloxide::types::{CallbackQuery, Message, Update};
use teloxide::{dptree, respond};

use crate::database::users::{User, UserId};
use crate::usp::model::{Meals, Period};
use crate::Context;

use self::callback::CallbackCommand;

pub struct Bot {
    bot: teloxide::Bot,
    context: HandlerContext,
}

#[derive(Debug)]
pub struct MealResponse {
    pub campus: String,
    pub restaurant: String,
    pub period: Period,
    pub meal: Meals,
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

        let message_text = msg.text().unwrap_or_default().to_string();
        let command = command::parse_command(&message_text);

        match command::execute_command(self, &command, msg.from().unwrap().id.0 as UserId).await {
            Ok(resp) => match resp {
                Response::Meals(meal_responses) => {
                    for meal_response in meal_responses {
                        let message = meal_menu::format_message(meal_response);
                        let msg = bot.send_message(msg.chat.id, message).parse_mode(Html);
                        msg.send().await?;
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
    pub fn from_env(context: HandlerContext) -> Self {
        Bot {
            bot: teloxide::Bot::from_env(),
            context,
        }
    }

    pub fn new(token: String, context: HandlerContext) -> Self {
        Bot {
            bot: teloxide::Bot::new(token),
            context,
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
}
