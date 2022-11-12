use std::str::pattern::Pattern;

use chrono::{Timelike, Weekday};
use teloxide::requests::Requester;
use teloxide::types::{ChatId, Message};
use teloxide::Bot;

use crate::database::users::UserId;
use crate::usp::model::Period;

use super::help;
use super::subscription;
use super::{config, meal, HandlerContext, Response};

#[derive(Debug, Clone)]
pub enum SubscriptionType {
    User(UserId),
    Group(ChatId),
}

#[derive(Debug, Clone)]
pub enum Command {
    Meal(Period, Moment),
    Fireworks,
    Help,
    Next,
    Start,
    Subscribe(SubscriptionType),
    Unsubscribe,
    Config,
}

#[derive(Debug, Clone)]
pub enum Moment {
    Explicit(chrono::Weekday),
    Today,
    Tomorrow,
}

impl Moment {
    pub fn weekday<T: chrono::Datelike>(&self, today: T) -> chrono::Weekday {
        match self {
            Moment::Explicit(weekday) => *weekday,
            Moment::Today => today.weekday(),
            Moment::Tomorrow => today.weekday().succ(),
        }
    }

    pub fn date<T: chrono::Datelike>(&self, today: T) -> chrono::NaiveDate {
        let current_week = today.iso_week().week();
        let year = today.year();
        let today_weekday = today.weekday();
        match self {
            Moment::Explicit(weekday) => {
                chrono::NaiveDate::from_isoywd(year, current_week, *weekday)
            }
            Moment::Today => chrono::NaiveDate::from_isoywd(year, current_week, today_weekday),
            Moment::Tomorrow => {
                chrono::NaiveDate::from_isoywd(year, current_week, today_weekday).succ()
            }
        }
    }
}

#[cfg(test)]
mod period_tests {
    use chrono::{Datelike, Duration, Weekday};

    use super::Moment;

    #[test]
    fn explicit_period_midweek() {
        let today = chrono::NaiveDate::from_ymd(2022, 10, 16); // it's sunday
        let current_weekday = today.weekday();
        let target_weekday = today.weekday().pred();
        let period = Moment::Explicit(target_weekday);

        let date = period.date(today);
        println!(
            "Got {:?} ({:?}) for today {:?} ({:?}) and target {:?}",
            date,
            date.weekday(),
            today,
            current_weekday,
            target_weekday
        );
        assert!(date.succ() == today);
    }

    #[test]
    fn explicit_period_sunday() {
        let today = chrono::NaiveDate::from_ymd(2022, 10, 17); // it's monday
        let current_weekday = Weekday::Mon;
        let target_weekday = Weekday::Sun;
        let period = Moment::Explicit(target_weekday);

        let date = period.date(today);
        let six_days_before_date = date.checked_add_signed(Duration::days(-6)).unwrap();
        assert!(
            six_days_before_date == today,
            "Expected {:?} ({:?}) for today {:?} ({:?}) and target {:?}",
            date,
            date.weekday(),
            today,
            current_weekday,
            target_weekday
        );
    }

    #[test]
    fn implicit_period_tomorrow() {
        let current_weekday = Weekday::Tue;
        let today = chrono::NaiveDate::from_isoywd(2022, 13, current_weekday);
        let period = Moment::Tomorrow;

        let date = period.date(today);
        assert!(
            date == today.succ(),
            "Expected {:?} ({:?}) to be tomorrow of {:?} ({:?})",
            date,
            date.weekday(),
            today,
            current_weekday
        );
    }

    #[test]
    fn implicit_period_today() {
        let current_weekday = Weekday::Tue;
        let today = chrono::NaiveDate::from_isoywd(2022, 13, current_weekday);
        let period = Moment::Today;

        let date = period.date(today);
        assert!(
            date == today,
            "Expected {:?} ({:?}) to be the same as {:?} ({:?})",
            date,
            date.weekday(),
            today,
            current_weekday
        );
    }
}

fn one_of_is_contained_in(checks: &[&str], haystack: &str) -> bool {
    checks.iter().any(|c| c.is_contained_in(haystack))
}

fn parse_period(command: &str) -> Moment {
    if one_of_is_contained_in(&["seg", "mon"], command) {
        return Moment::Explicit(Weekday::Mon);
    }

    if one_of_is_contained_in(&["ter", "tue"], command) {
        return Moment::Explicit(Weekday::Tue);
    }

    if one_of_is_contained_in(&["qua", "wed"], command) {
        return Moment::Explicit(Weekday::Wed);
    }

    if one_of_is_contained_in(&["qui", "thu"], command) {
        return Moment::Explicit(Weekday::Thu);
    }

    if one_of_is_contained_in(&["sex", "fri"], command) {
        return Moment::Explicit(Weekday::Fri);
    }

    if one_of_is_contained_in(&["sab", "sat"], command) {
        return Moment::Explicit(Weekday::Sat);
    }

    if one_of_is_contained_in(&["dom", "sun"], command) {
        return Moment::Explicit(Weekday::Sun);
    }

    if one_of_is_contained_in(&["amanha", "amanhã", "tomorrow"], command) {
        return Moment::Tomorrow;
    }

    Moment::Today
}

pub fn parse_command(command: &Message) -> Command {
    let message_text = command.text().unwrap_or_default().to_string();
    let lower_cmd = message_text.to_lowercase();

    if one_of_is_contained_in(&["janta"], &lower_cmd) {
        return Command::Meal(Period::Dinner, parse_period(&lower_cmd));
    }

    if one_of_is_contained_in(&["almoco", "almoço"], &lower_cmd) {
        return Command::Meal(Period::Lunch, parse_period(&lower_cmd));
    }

    if one_of_is_contained_in(&["acende"], &lower_cmd) {
        return Command::Fireworks;
    }

    if one_of_is_contained_in(&["help", "ajuda"], &lower_cmd) {
        return Command::Help;
    }

    if one_of_is_contained_in(&["next", "prox", "próx"], &lower_cmd) {
        return Command::Next;
    }

    if one_of_is_contained_in(&["desinscrever", "unsubscribe", "desativar"], &lower_cmd) {
        return Command::Unsubscribe;
    }

    if one_of_is_contained_in(&["inscrever", "subscribe", "ativar"], &lower_cmd) {
        let private_chat = command.chat.is_private();
        if private_chat {
            return Command::Subscribe(SubscriptionType::User(
                command
                    .from()
                    .map(|a| a.id.0 as i64)
                    .unwrap_or(command.chat.id.0),
            ));
        } else {
            return Command::Subscribe(SubscriptionType::Group(command.chat.id));
        }
    }

    if one_of_is_contained_in(&["config", "preferencias", "preferências"], &lower_cmd) {
        return Command::Config;
    }

    if one_of_is_contained_in(&["start"], &lower_cmd) {
        return Command::Start;
    }

    match parse_period(&lower_cmd) {
        Moment::Today => Command::Next,
        others => Command::Meal(Period::Lunch, others),
    }
}

pub fn get_next<T>(now: T) -> (Period, Moment)
where
    T: Timelike,
{
    let (pm, hour) = now.hour12();
    if pm && hour >= 8 {
        (Period::Lunch, Moment::Tomorrow)
    } else if pm && hour >= 2 {
        (Period::Dinner, Moment::Today)
    } else {
        (Period::Lunch, Moment::Today)
    }
}

pub async fn execute_command(
    ctx: HandlerContext,
    command: &Command,
    user_id: UserId,
    bot: &Bot,
) -> Result<Response, anyhow::Error> {
    let today = chrono::offset::Local::now();
    let configs = ctx.0.db.get_configs(user_id).await?;

    let client = &ctx.0.usp_client;

    return match command {
        Command::Meal(period, moment) => {
            meal::get_meal(period, moment, configs, client, today).await
        }
        Command::Next => {
            let (period, moment) = get_next(today.time());
            meal::get_meal(&period, &moment, configs, client, today).await
        }
        Command::Config => {
            let campi = client.lock().await.get_campi().await?;
            config::config_menu(campi, configs)
        }
        Command::Subscribe(SubscriptionType::User(_)) => {
            let subscribed = subscription::subscribe_user(&ctx.0.db, user_id, user_id).await?;
            if subscribed {
                Ok(Response::Text(
                    "🔔 <b>Notificações ativadas com sucesso!</b>\nVocê será notificado(a) diariamente antes do horário de abertura do bandejão!".to_string(),
                ))
            } else {
                Ok(Response::Text(
                    "Não foi possível ativar as notificações!\n talvez você já esteja inscrito(a) 🤔"
                        .to_string(),
                ))
            }
        }
        Command::Subscribe(SubscriptionType::Group(id)) => {
            let membership = bot
                .get_chat_member(*id, teloxide::types::UserId(user_id as u64))
                .await?;

            if membership.is_privileged() {
                let subscribed = subscription::subscribe_user(&ctx.0.db, id.0, user_id).await?;
                if subscribed {
                    Ok(Response::Text(
                        "🔔 <b>Notificações ativadas com sucesso!</b>\n O grupo será notificado diariamente antes do horário de abertura do bandejão!".to_string(),
                    ))
                } else {
                    Ok(Response::Text(
                        "Não foi possível ativar as notificações!\n Talvez o grupo já esteja inscrito 🤔".to_string()
                    ))
                }
            } else {
                Ok(Response::Text(
                    "Não foi possível ativar as notificações!\n Apenas administradores podem ativar as notificações 🤔".to_string()
                ))
            }
        }
        Command::Unsubscribe => {
            let unsubscribed = subscription::unsubscribe_user(&ctx.0.db, user_id).await?;
            if unsubscribed {
                Ok(Response::Text("🔕 <b>Notificações desativadas com sucesso!</b>\nVocê pode ativá-las novamente /inscrever".to_owned()))
            } else {
                Ok(Response::Text("Inscrição não existe".to_string()))
            }
        }
        Command::Help => Ok(Response::Text(help::help_text())),
        Command::Fireworks => Ok(Response::Fireworks),
        Command::Start => Ok(Response::Text("Olá! Boas vindas ao BandejaoBot. envie /ajuda para uma descrição detalhada de funcionalidades. Envie /config para alterar as suas preferências.".to_owned())),
    };
}
