use std::str::pattern::Pattern;

use chrono::Weekday;

use crate::usp::model::{Meals, Period};

use super::HandlerContext;

#[derive(Debug, Clone)]
pub enum Command {
    Meal(Period, Moment),
    Fireworks,
    Help,
    Next,
    Subscribe,
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
    pub fn into_weekday<T: chrono::Datelike>(self, today: T) -> chrono::Weekday {
        match self {
            Moment::Explicit(weekday) => weekday,
            Moment::Today => today.weekday(),
            Moment::Tomorrow => today.weekday().succ(),
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

    use super::Moment;

    #[test]
    fn explicit_period_midweek() {
        let today = chrono::NaiveDate::from_ymd(2022, 10, 16); // it's sunday
        let current_weekday = today.weekday();
        let target_weekday = today.weekday().pred();
        let period = Moment::Explicit(target_weekday.clone());

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
        let period = Moment::Explicit(target_weekday.clone());

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
        let period = Moment::Tomorrow;

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
        let period = Moment::Today;

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

fn parse_period(command: &String) -> Moment {
    if one_of_is_contained_in(vec!["seg", "mon"], command) {
        return Moment::Explicit(Weekday::Mon);
    }

    if one_of_is_contained_in(vec!["ter", "tue"], command) {
        return Moment::Explicit(Weekday::Tue);
    }

    if one_of_is_contained_in(vec!["qua", "wed"], command) {
        return Moment::Explicit(Weekday::Wed);
    }

    if one_of_is_contained_in(vec!["qui", "thu"], command) {
        return Moment::Explicit(Weekday::Thu);
    }

    if one_of_is_contained_in(vec!["sex", "fri"], command) {
        return Moment::Explicit(Weekday::Fri);
    }

    if one_of_is_contained_in(vec!["sab", "sat"], command) {
        return Moment::Explicit(Weekday::Sat);
    }

    if one_of_is_contained_in(vec!["dom", "sun"], command) {
        return Moment::Explicit(Weekday::Sun);
    }

    if one_of_is_contained_in(vec!["amanha", "amanhã", "tomorrow"], command) {
        return Moment::Tomorrow;
    }

    return Moment::Today;
}

pub fn parse_command(command: &String) -> Command {
    let lower_cmd = command.to_lowercase();

    if one_of_is_contained_in(vec!["janta"], &lower_cmd) {
        return Command::Meal(Period::Dinner, parse_period(&lower_cmd));
    }

    if one_of_is_contained_in(vec!["almoco", "almoço"], &lower_cmd) {
        return Command::Meal(Period::Lunch, parse_period(&lower_cmd));
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
pub struct MealResponse {
    pub campus: String,
    pub restaurant: String,
    pub period: Period,
    pub meal: Meals,
}

#[derive(Debug)]
pub enum Response {
    Meal(MealResponse),
    Noop,
}

pub async fn execute_command(
    ctx: HandlerContext,
    command: Command,
) -> Result<Response, anyhow::Error> {
    let today = chrono::offset::Local::now();
    let restaurant_id = "6".to_string();

    return match command {
        Command::Meal(period, moment) => {
            let meal = ctx
                .0
                .usp_client
                .lock()
                .await
                .get_meal(&restaurant_id, moment.clone().into_date(today))
                .await?;
            Ok(Response::Meal(MealResponse {
                campus: "Algum".to_string(),
                restaurant: "olar".to_string(),
                period,
                meal,
            }))
        }
        _ => Ok(Response::Noop),
    };
}
