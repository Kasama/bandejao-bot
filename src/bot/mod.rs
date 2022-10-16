pub mod command;
pub mod meal_menu;

use std::sync::Arc;

use futures::lock::Mutex;
use teloxide::dispatching::UpdateFilterExt;
use teloxide::prelude::Dispatcher;
use teloxide::requests::{Request, Requester};
use teloxide::types::{Message, Update};
use teloxide::{dptree, respond};

use crate::database::users::User;
use crate::database::DB;
use crate::usp::Usp;

pub struct Bot {
    bot: teloxide::Bot,
    context: HandlerContext,
}

#[derive(Debug, Clone)]
pub struct HandlerContext(Arc<Context>);

#[derive(Debug)]
pub struct Context {
    usp_client: Mutex<Usp>,
    db: DB,
}

impl HandlerContext {
    pub fn new(usp_client: Usp, db: DB) -> Self {
        Self {
            0: Arc::new(Context {
                usp_client: Mutex::new(usp_client),
                db,
            }),
        }
    }

    pub async fn dispatch_handler(self, bot: teloxide::Bot, msg: Message) -> anyhow::Result<()> {
        if let Some(user) = Bot::get_user(msg.from()).await {
            self.0.db.upinsert_user(user).await?;
        }

        let message_text = msg.text().unwrap_or_default().to_string();
        let command = command::parse_command(&message_text);

        match command::execute_command(self, command.clone()).await {
            Ok(resp) => match resp {
                command::Response::Meal(meal_response) => {
                    let message = meal_menu::format_message(meal_response);
                    bot.send_message(msg.chat.id, message).send().await?;
                }
                command::Response::Noop => (),
            },
            Err(err) => {
                bot.send_message(msg.chat.id, format!("failed: {:?}", err))
                    .send()
                    .await?;
            }
        };

        respond(()).map_err(anyhow::Error::new)
    }
}

impl Bot {
    pub fn from_env(context: HandlerContext) -> Self {
        Bot {
            bot: teloxide::Bot::from_env(),
            context,
        }
    }

    async fn get_user(telegram_user: Option<&teloxide::types::User>) -> Option<User> {
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
        let handler = Update::filter_message().endpoint(
            |bot: teloxide::Bot, ctx: HandlerContext, msg: Message| async {
                ctx.dispatch_handler(bot, msg).await
            },
        );

        Dispatcher::builder(self.bot.clone(), handler)
            .dependencies(dptree::deps![self.context.clone()])
            .enable_ctrlc_handler()
            .build()
    }
}
