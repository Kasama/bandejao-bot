use chrono::{Datelike, Weekday};

use crate::usp::model::Period;

use super::MealResponse;

fn period_emoji(p: &Period) -> &str {
    match p {
        Period::Dinner => "🌙",
        Period::Lunch => "☀️",
    }
}

fn weekday_name(w: &Weekday) -> &str {
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
            return format!("\n\nValor energético médio: ⚡️ {}Kcal", calories);
        }
    }
    "".to_string()
}

pub fn format_message(response: MealResponse) -> String {
    let meal = response.meal.get_meal(response.period.clone());

    let main_message = format!(
        "🏫 <b>{}, {} 🍽\n{} Jantar de {} ({}):</b>\n{}",
        response.campus,
        response.restaurant,
        period_emoji(&response.period),
        weekday_name(&response.meal.date.weekday()),
        response.meal.date.format("%d/%m"),
        meal.menu,
    );

    let footer = format_calories(&meal.calories);

    format!("{}{}", main_message, footer)
}
