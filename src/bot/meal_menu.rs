use chrono::Datelike;

use crate::usp::model::Period;

use super::command::MealResponse;

fn period_emoji(p: Period) -> String {
    match p {
        Period::Dinner => "🌙",
        Period::Lunch => "☀️",
    }
    .to_string()
}

fn format_calories(calories: &String) -> String {
    if let Ok(calories) = calories.parse::<i32>() {
        if calories > 0 {
            return format!("\n{} kcal", calories)
        }
    }
    "".to_string()
}

pub fn format_message(resp: MealResponse) -> String {
    let meal = resp.meal.get_meal(resp.period.clone());

    let main_message = format!(
        "🏫 *{}, {} 🍽\n{} Jantar de {} ({}):*\n{}",
        resp.campus,
        resp.restaurant,
        period_emoji(resp.period),
        resp.meal.date.weekday(),
        resp.meal.date.format("%d/%m"),
        meal.menu,
    );

    let footer = format_calories(&meal.calories);

    format!("{}{}", main_message, footer)
}
