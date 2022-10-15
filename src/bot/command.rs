use std::str::pattern::Pattern;
use std::sync::Arc;

use chrono::Weekday;
use futures::lock::Mutex;

use crate::usp::Usp;

#[derive(Debug)]
pub enum Command {
    Dinner(Period),
    Lunch(Period),
    Fireworks,
    Help,
    Next,
    Subscribe,
    Unsubscribe,
    Config,
}

#[derive(Debug, Clone)]
pub enum Period {
    Explicit(chrono::Weekday),
    Today,
    Tomorrow,
}

impl Period {
    pub fn into_weekday<T: chrono::Datelike>(self, today: T) -> chrono::Weekday {
        match self {
            Period::Explicit(weekday) => weekday,
            Period::Today => today.weekday(),
            Period::Tomorrow => today.weekday().succ(),
        }
    }

    pub fn into_date<T: chrono::Datelike>(self, today: T) -> chrono::NaiveDate {
        let current_week = today.iso_week().week();
        let year = today.year();
        let week_day = self.into_weekday(today);

        chrono::NaiveDate::from_isoywd(year, current_week, week_day)
    }
}

#[cfg(test)]
mod period_tests {
    use chrono::{Datelike, Duration, Weekday};

    use super::Period;

    #[test]
    fn explicit_period_midweek() {
        let today = chrono::NaiveDate::from_ymd(2022, 10, 16); // it's sunday
        let current_weekday = today.weekday();
        let target_weekday = today.weekday().pred();
        let period = Period::Explicit(target_weekday.clone());

        let date = period.into_date(today);
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
        let period = Period::Explicit(target_weekday.clone());

        let date = period.into_date(today);
        println!(
            "Got {:?} ({:?}) for today {:?} ({:?}) and target {:?}",
            date,
            date.weekday(),
            today,
            current_weekday,
            target_weekday
        );
        let six_days_before_date = date.checked_add_signed(Duration::days(-6)).unwrap();
        assert!(six_days_before_date == today);
    }

    #[test]
    fn implicit_period_tomorrow() {
        let current_weekday = Weekday::Tue;
        let today = chrono::NaiveDate::from_isoywd(2022, 13, current_weekday);
        let period = Period::Tomorrow;

        let date = period.into_date(today);
        println!(
            "Got {:?} ({:?}) as tomorrow of {:?} ({:?})",
            date,
            date.weekday(),
            today,
            current_weekday
        );
        assert!(date.pred() == today);
    }

    #[test]
    fn implicit_period_today() {
        let current_weekday = Weekday::Tue;
        let today = chrono::NaiveDate::from_isoywd(2022, 13, current_weekday);
        let period = Period::Today;

        let date = period.into_date(today);
        println!(
            "Got {:?} ({:?}) as tomorrow of {:?} ({:?})",
            date,
            date.weekday(),
            today,
            current_weekday
        );
        assert!(date == today);
    }
}

fn one_of_is_contained_in(checks: Vec<&str>, haystack: &str) -> bool {
    checks.iter().any(|c| return c.is_contained_in(haystack))
}

fn parse_period(command: &String) -> Period {
    if one_of_is_contained_in(vec!["seg", "mon"], command) {
        return Period::Explicit(Weekday::Mon);
    }

    if one_of_is_contained_in(vec!["ter", "tue"], command) {
        return Period::Explicit(Weekday::Tue);
    }

    if one_of_is_contained_in(vec!["qua", "wed"], command) {
        return Period::Explicit(Weekday::Wed);
    }

    if one_of_is_contained_in(vec!["qui", "thu"], command) {
        return Period::Explicit(Weekday::Thu);
    }

    if one_of_is_contained_in(vec!["sex", "fri"], command) {
        return Period::Explicit(Weekday::Fri);
    }

    if one_of_is_contained_in(vec!["sab", "sat"], command) {
        return Period::Explicit(Weekday::Sat);
    }

    if one_of_is_contained_in(vec!["dom", "sun"], command) {
        return Period::Explicit(Weekday::Sun);
    }

    if one_of_is_contained_in(vec!["amanha", "amanhã", "tomorrow"], command) {
        return Period::Tomorrow;
    }

    return Period::Today;
}

pub fn parse_command(command: &String) -> Command {
    let lower_cmd = command.to_lowercase();

    if one_of_is_contained_in(vec!["janta"], &lower_cmd) {
        return Command::Dinner(parse_period(&lower_cmd));
    }

    if one_of_is_contained_in(vec!["almoco", "almoço"], &lower_cmd) {
        return Command::Lunch(parse_period(&lower_cmd));
    }

    if one_of_is_contained_in(vec!["acende"], &lower_cmd) {
        return Command::Fireworks;
    }

    if one_of_is_contained_in(vec!["help", "ajuda"], &lower_cmd) {
        return Command::Help;
    }

    if one_of_is_contained_in(vec!["next", "prox"], &lower_cmd) {
        return Command::Next;
    }

    if one_of_is_contained_in(vec!["desinscrever", "unsubscribe", "desativar"], &lower_cmd) {
        return Command::Unsubscribe;
    }

    if one_of_is_contained_in(vec!["inscrever", "subscribe", "ativar"], &lower_cmd) {
        return Command::Subscribe;
    }

    if one_of_is_contained_in(vec!["config", "preferencias", "preferências"], &lower_cmd) {
        return Command::Config;
    }

    return Command::Next;
}

#[derive(Debug)]
pub enum Response {
    Text(String),
    Noop,
}

pub async fn execute_command(
    usp: Arc<Mutex<Usp>>,
    command: Command,
) -> Result<Response, anyhow::Error> {
    let today = chrono::offset::Local::now();
    let restaurant_id = "6".to_string();

    return match command {
        Command::Dinner(period) => {
            let meal = usp.lock().await.get_meal(&restaurant_id, period.clone().into_date(today)).await?;
            Ok(Response::Text(meal.dinner.menu.to_string()))
        }
        Command::Lunch(period) => {
            let meal = usp.lock().await.get_meal(&restaurant_id, period.clone().into_date(today)).await?;
            Ok(Response::Text(meal.lunch.menu.to_string()))
        },
        _ => Ok(Response::Noop),
    };
}
