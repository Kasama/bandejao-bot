use chrono::{DateTime, Datelike, Local, Weekday};

use crate::database::config::Config;
use crate::usp::model::Period;
use crate::usp::Usp;

use super::command::Moment;
use super::{MealResponse, Response};

fn period_text(p: &Period) -> &str {
    match p {
        Period::Dinner => "🌙 Jantar",
        Period::Lunch => "☀️  Almoço",
    }
}

fn pt_weekday_name(w: &Weekday) -> &str {
    match w {
        Weekday::Mon => "Segunda",
        Weekday::Tue => "Terça",
        Weekday::Wed => "Quarta",
        Weekday::Thu => "Quinta",
        Weekday::Fri => "Sexta",
        Weekday::Sat => "Sábado",
        Weekday::Sun => "Domingo",
    }
}

fn format_calories(calories: &String) -> String {
    if let Ok(calories) = calories.parse::<i32>() {
        if calories > 0 {
            return format!("\n\n<i>Valor energético médio: ⚡️ {}Kcal</i>", calories);
        }
    }
    "".to_string()
}

pub fn format_message(response: MealResponse) -> String {
    match response.meal {
        Some(m) => {
            let meal = m.get_meal(&response.period);

            let main_message = format!(
                "🏫 <b>{}, {} 🍽\n{} de {} ({}):</b>\n{}",
                response.campus,
                response.restaurant,
                period_text(&response.period),
                pt_weekday_name(&m.date.weekday()),
                m.date.format("%d/%m"),
                meal.menu,
            );

            let footer = format_calories(&meal.calories);

            format!("{}{}", main_message, footer)
        }
        None => {
            format!(
                "🏫 <b>{}, {}</b> 🍽\nNão foi possivel encontrar o cardápio para esse restaurante.\nTalvez ele não tenha sido atualizado ainda, ou o sistema está fora do ar",
                response.campus, response.restaurant
            )
        }
    }
}

pub async fn get_meal(
    period: &Period,
    moment: &Moment,
    configs: Vec<Config>,
    usp_client: &futures::lock::Mutex<Usp>,
    today: DateTime<Local>,
) -> anyhow::Result<Response> {
    let zipper = (0..configs.len()).into_iter().map(|_| (period, moment));
    let a: anyhow::Result<Vec<MealResponse>> =
        futures::future::join_all(configs.into_iter().zip(zipper).map(
            |(config, (period, moment))| async move {
                let mut usp = usp_client.lock().await;
                let meal = usp
                    .get_meal(&config.restaurant_id, moment.into_date(today))
                    .await
                    .ok();
                let (campus, restaurant) = usp.get_restaurant_by_id(&config.restaurant_id).await?;
                Ok(MealResponse {
                    campus: campus.normalized_name(),
                    restaurant: restaurant.normalized_alias(),
                    period: period.clone(),
                    meal,
                })
            },
        ))
        .await
        .into_iter()
        .collect();
    let meals = a?;
    Ok(Response::Meals(meals))
}
