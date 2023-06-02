pub mod callback;
pub mod command;
pub mod config;
pub mod help;
pub mod internal;
pub mod keyboard;
pub mod meal;
pub mod papoco;
pub mod schedule;
pub mod subscription;

use std::sync::Arc;
use std::time::Duration;

use anyhow::anyhow;
use futures::future::join_all;
use teloxide::dispatching::UpdateFilterExt;
use teloxide::payloads::EditMessageTextSetters;
use teloxide::prelude::Dispatcher;
use teloxide::requests::Requester;
use teloxide::types::ParseMode::Html;
use teloxide::types::{CallbackQuery, ChatId, KeyboardRemove, Message, Update};
use teloxide::{dptree, respond, RequestError};
use tokio::time::Instant;

use crate::database::schedule::DayPeriod;
use crate::database::users::{User, UserId};
use crate::usp::model::{Meals, Period};
use crate::Context;

use self::callback::CallbackCommand;
use self::command::Command;

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
    Fireworks,
}

#[derive(Debug, Clone)]
pub struct HandlerContext(Arc<Context>);

impl HandlerContext {
    pub fn new(ctx: Arc<Context>) -> Self {
        Self(ctx)
    }

    pub async fn send_message<T>(
        &self,
        bot: &teloxide::Bot,
        chat_id: ChatId,
        text: T,
    ) -> internal::BotRequest
    where
        T: Into<String>,
    {
        let base_msg = internal::BotRequest::send_message(bot, chat_id, text).parse_mode(Html);
        if chat_id.is_user() {
            let has_schedules = (|| async {
                if let Ok(s) = self.0.db.get_schedules(chat_id.0).await {
                    if s.configuration.is_empty() {
                        return true;
                    }
                }
                false
            })()
            .await;
            base_msg.reply_markup(keyboard::create_keyboard(has_schedules))
        } else {
            base_msg.reply_markup(KeyboardRemove::new())
        }
    }

    pub async fn message_handler(self, bot: teloxide::Bot, msg: Message) -> anyhow::Result<()> {
        // Ignore replies in group chats
        // Only MessageKind::Common is allowed, and the bot will only respond if it was not a reply
        if !msg.chat.is_private() {
            if msg.via_bot.is_some() {
                return Ok(());
            }
            if let teloxide::types::MessageKind::Common(ref m) = msg.kind {
                if m.reply_to_message.is_some() {
                    return Ok(());
                }
            } else {
                return Ok(());
            }
        }

        if let Some(user) = Bot::get_user(msg.from()) {
            self.0.db.upsert_user(user).await?;
        }

        let command = command::parse_command(&msg);

        // ignore unknown commands in group chats
        if !msg.chat.is_private() && matches!(command, Command::Unknown) {
            return Ok(());
        };

        bot.send_chat_action(msg.chat.id, teloxide::types::ChatAction::Typing)
            .await?;

        match command::execute_command(&self, &command, msg.from().unwrap().id.0 as UserId, &bot)
            .await
        {
            Ok(resp) => match resp {
                Response::Meals(meal_responses) => {
                    if meal_responses.is_empty() {
                        self.send_message(
                            &bot,
                            msg.chat.id,
                            "nenhum restaurante está selecionado. Use /config para configurar um",
                        )
                        .await
                        .send()
                        .await?;
                    } else {
                        for meal_response in meal_responses {
                            let message = meal::format_message(meal_response);
                            self.send_message(&bot, msg.chat.id, message)
                                .await
                                .send()
                                .await?;
                        }
                    }
                }
                Response::Buttons(text, buttons) => {
                    self.send_message(
                        &bot,
                        msg.chat.id,
                        text.unwrap_or_else(|| msg.text().unwrap_or("").to_string()),
                    )
                    .await
                    .reply_markup(keyboard::create_inline(buttons))
                    .send()
                    .await?;
                }
                Response::Text(txt) => {
                    self.send_message(&bot, msg.chat.id, txt)
                        .await
                        .send()
                        .await?;
                }
                Response::Fireworks => {
                    let fireworks = papoco::generate_papoco();
                    for (firework, duration) in fireworks {
                        self.send_message(&bot, msg.chat.id, firework)
                            .await
                            .send()
                            .await?;
                        tokio::time::sleep_until(Instant::now() + Duration::from_millis(duration))
                            .await;
                    }
                }
            },
            Err(err) => {
                self.send_message(&bot, msg.chat.id, format!("failed: {:?}", err))
                    .await
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
        let data = q.data.ok_or_else(|| anyhow!("got empty callback data"))?;
        let callback_command: CallbackCommand = serde_json::from_str(data.as_str())?;

        let msg = q
            .message
            .ok_or_else(|| anyhow!("clicked a button without message"))?;

        match callback::execute_callback(self, callback_command, q.from.id.0 as UserId).await? {
            Response::Meals(_) => (),
            Response::Buttons(text, buttons) => {
                bot.edit_message_text(
                    msg.chat.id,
                    msg.id,
                    text.unwrap_or_else(|| msg.text().unwrap_or("").to_string()),
                )
                .parse_mode(Html)
                .reply_markup(keyboard::create_inline(buttons))
                .await?;
            }
            Response::Text(text) => {
                bot.edit_message_text(msg.chat.id, msg.id, text).await?;
            }
            Response::Fireworks => (),
        };

        bot.answer_callback_query(q.id).await?;
        Ok(())
    }
}

impl Bot {
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
            created_at: None,
            updated_at: None,
        };

        Some(user)
    }

    pub fn dispatcher(
        &self,
    ) -> Dispatcher<teloxide::Bot, anyhow::Error, teloxide::dispatching::DefaultKey> {
        let handler = dptree::entry()
            .branch(Update::filter_message().endpoint(
                |bot: teloxide::Bot, ctx: HandlerContext, msg: Message| async {
                    log::info!("handling message for user {:?}", msg.from().map(|u| u.id));
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
        let timezone = chrono_tz::America::Sao_Paulo;
        let now = chrono::offset::Utc::now().with_timezone(&timezone);
        let (period, moment) = command::get_next(now);
        let weekday = moment.weekday(now);
        let day_period = DayPeriod::from((period, weekday));

        let chats = self.context.0.db.get_scheduled_chats(&day_period).await?;

        let total_subscriptions = chats.len();

        #[derive(Debug)]
        enum SubscriptionError {
            ClosedRestaurant,
            TelegramError((RequestError, ChatId)),
            AnyError(anyhow::Error),
            SqlxError(sqlx::Error),
        }
        let (successes, failures): (Vec<_>, Vec<_>) =
            join_all(chats.into_iter().map(|(chat, user)| async move {
                let (period, moment) = command::get_next(now);
                let configs = self.context.0.db.get_configs(user)
                    .await
                    .map_err(SubscriptionError::SqlxError)?;
                let meal =
                    meal::get_meal(&period, &moment, configs, &self.context.0.usp_client, now)
                        .await
                        .map_err(SubscriptionError::AnyError)?;
                if let Response::Meals(resp) = meal {
                    match resp.len() {
                        0 => self.context.send_message(&self.bot, ChatId(chat), "nenhum restaurante está selecionado. Use /config para configurar um")
                            .await
                            .send()
                            .await
                            .map(|a| vec![a])
                            .map_err(|e| (SubscriptionError::TelegramError((e, ChatId(chat))))),
                        _ => join_all(resp.into_iter().map(|r| async {
                            let txt = meal::format_message(r);
                            if txt.to_lowercase().contains("fechado") {
                                Err(SubscriptionError::ClosedRestaurant)
                            } else {
                                self.context
                                    .send_message(&self.bot, ChatId(chat), txt)
                                    .await
                                    .send()
                                    .await
                                    .map_err(|e| (SubscriptionError::TelegramError((e, ChatId(chat)))))
                            }
                        }))
                        .await
                        .into_iter()
                        .filter(|r| {
                            !matches!(r, Err(SubscriptionError::ClosedRestaurant))
                        })
                        .collect::<Result<Vec<_>, _>>()
                    }
                } else {
                    Ok(vec![])
                }
            }))
            .await
            .into_iter()
            .partition(|r| r.is_ok());

        let original_failures = failures.len();

        // Automatically resolve errors that can be resolved like blocking, kicking, migrating to
        // another chat, etc
        let remaining_errors: Vec<anyhow::Error> =
            join_all(failures.into_iter().filter_map(|f| f.err()).map(|e| async {
                let se = match e {
                    SubscriptionError::TelegramError(e) => e,
                    _ => return Err(anyhow::anyhow!("{e:?}")),
                };

                match se.0 {
                    teloxide::RequestError::Api(api_error) => match api_error {
                        teloxide::ApiError::BotBlocked
                        | teloxide::ApiError::ChatNotFound
                        | teloxide::ApiError::UserNotFound
                        | teloxide::ApiError::GroupDeactivated
                        | teloxide::ApiError::BotKicked
                        | teloxide::ApiError::BotKickedFromSupergroup
                        | teloxide::ApiError::UserDeactivated
                        | teloxide::ApiError::CantInitiateConversation => {
                            log::info!(
                                "Removing schedule for chat {} because it was {api_error}",
                                se.1,
                            );
                            self.context.0.db.delete_schedules(&se.1 .0).await?;
                        }
                        teloxide::ApiError::Unknown(e)
                            if e == "Forbidden: bot was kicked from the group chat"
                                || e == "Forbidden: the group chat was deleted" =>
                        {
                            log::info!("Removing schedule for chat {} because it was {e}", se.1,);
                            self.context.0.db.delete_schedules(&se.1 .0).await?;
                        }
                        _ => return Err(anyhow::anyhow!("{api_error:?}")),
                    },
                    teloxide::RequestError::MigrateToChatId(new_chat_id) => {
                        log::info!("Migrating {} to chat {}", se.1, new_chat_id);
                        let mut schedule = self.context.0.db.get_schedules(se.1 .0).await?;
                        schedule.chat_id = new_chat_id;
                        self.context.0.db.delete_schedules(&se.1 .0).await?;
                        self.context.0.db.upsert_schedule(schedule).await?;
                        log::info!("    Migrated {} to {}", se.1, new_chat_id);
                    }
                    _ => return Err(anyhow::anyhow!("{se:?}")),
                };
                Ok(())
            }))
            .await
            .into_iter()
            .filter_map(|r| r.err())
            .collect();

        if total_subscriptions > 0 {
            let admin_id = self.configs.admin_id;

            if let Err(e) = self
                .context
                .send_message(
                    &self.bot,
                    ChatId(admin_id),
                    format!(
                        "Got {}/{} successess and {} errors. {} auto-fixed:",
                        successes.len(),
                        total_subscriptions,
                        remaining_errors.len(),
                        original_failures - remaining_errors.len()
                    ),
                )
                .await
                .send()
                .await
            {
                log::error!(
                    "could not notify schedule failure: {}: {}/{} successes",
                    e,
                    successes.len(),
                    total_subscriptions,
                )
            };

            // let a =
            join_all(remaining_errors.iter().map(|e| async move {
                self.context
                    .send_message(&self.bot, ChatId(admin_id), e.to_string())
                    .await
                    .send()
                    .await
            }))
            .await;
        }

        Ok(())
    }
}
