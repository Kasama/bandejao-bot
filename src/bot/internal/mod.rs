use teloxide::payloads::SendMessageSetters;
use teloxide::requests::Requester;
use teloxide::types::ParseMode;
use teloxide::types::Recipient;
use teloxide::types::ReplyMarkup;
use tokio::time::sleep_until;
use tokio::time::Instant;

pub struct BotRequest {
    pub send_message: teloxide::requests::JsonRequest<teloxide::payloads::SendMessage>,
}

impl BotRequest {
    pub fn send_message<C, T>(bot: &teloxide::Bot, chat_id: C, text: T) -> Self
    where
        C: Into<Recipient>,
        T: Into<String>,
    {
        Self {
            send_message: bot.send_message(chat_id, text),
        }
    }

    pub fn parse_mode(self, mode: ParseMode) -> Self {
        Self {
            send_message: self.send_message.parse_mode(mode),
        }
    }
    pub fn reply_markup<T: Into<ReplyMarkup>>(self, markup: T) -> Self {
        Self {
            send_message: self.send_message.reply_markup(markup),
        }
    }

    pub async fn send(self) -> Result<teloxide::types::Message, teloxide::RequestError> {
        loop {
            let b = self.send_message.clone().await;
            if let Err(teloxide::RequestError::RetryAfter(delay)) = b {
                sleep_until(Instant::now() + delay).await;
                continue;
            } else {
                break b;
            };
        }
    }
}
