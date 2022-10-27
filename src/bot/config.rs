use crate::database::config::Config;
use crate::usp::model::{Campus, Restaurant};

use super::callback::CallbackCommand;
use super::Response;

pub fn config_menu(campi: Vec<Campus>, configs: Vec<Config>) -> anyhow::Result<Response> {
    select_campus_menu(campi, configs)
}

fn is_checked_emoji(is: bool) -> String {
    match is {
        true => "✅",
        false => "⬜️",
    }
    .to_string()
}

fn selected_restaurants(campi: Vec<Campus>, configs: Vec<Config>) -> String {
    let find_campus = |id: &str| {
        campi
            .iter()
            .find(|c| c.restaurants.iter().any(|r| r.id == id))
    };
    let find_restaurant = |campus: &Campus, id: &str| {
        campus
            .restaurants
            .iter()
            .find(|r| r.id == id)
            .map(|r| r.clone())
    };

    let restaurant_list = configs
        .into_iter()
        .map(|c| {
            let campus = find_campus(&c.restaurant_id);
            let restaurant = campus.and_then(|camp| find_restaurant(camp, &c.restaurant_id));
            format!(
                " - {}, {}",
                campus
                    .map(|c| c.normalized_name())
                    .unwrap_or("Unknown Campus".to_string()),
                restaurant
                    .map(|r| r.normalized_name())
                    .unwrap_or("Unknown Restaurant".to_string())
            )
        })
        .collect::<Vec<String>>()
        .join("\n");
    format!("Restaurantes selecionados:\n{}", restaurant_list)
}

pub fn select_restaurant_menu(
    restaurants: Vec<Restaurant>,
    configs: Vec<Config>,
) -> anyhow::Result<Response> {
    let buttons: Vec<(String, String)> = restaurants
        .into_iter()
        .map(|restaurant| {
            let restaurant_alias = restaurant.normalized_name();
            let checked = configs
                .iter()
                .find(|c| restaurant.id == c.restaurant_id)
                .is_some();
            (
                format!("{} {}", is_checked_emoji(checked), restaurant_alias),
                CallbackCommand::SelectRestaurant(restaurant.id, !checked),
            )
        })
        .chain(vec![("Voltar".to_string(), CallbackCommand::ListCampi)])
        .map(|(s, c)| (s, serde_json::to_string(&c)))
        .map(|(s, c)| c.map(|a| (s, a)))
        .collect::<Result<Vec<(String, String)>, serde_json::Error>>()?;

    Ok(Response::Buttons(None, buttons))
}

fn select_campus_menu(campi: Vec<Campus>, configs: Vec<Config>) -> anyhow::Result<Response> {
    let buttons: Vec<(String, String)> = campi
        .iter()
        .map(|campus| {
            let campus_alias = campus.normalized_name();
            match campus.restaurants.as_slice() {
                [r] => {
                    let checked = configs.iter().find(|c| r.id == c.restaurant_id).is_some();
                    (
                        format!("{} {}", is_checked_emoji(checked), campus_alias),
                        CallbackCommand::SelectRestaurant(r.id.clone(), !checked),
                    )
                }
                rs => {
                    let checked = rs
                        .iter()
                        .find(|r| configs.iter().find(|c| r.id == c.restaurant_id).is_some())
                        .is_some();
                    (
                        format!("{} {} ▶️", is_checked_emoji(checked), campus_alias),
                        CallbackCommand::SelectCampus(campus.name.clone()),
                    )
                }
            }
        })
        .chain(vec![("Finalizar".to_string(), CallbackCommand::Cancel)])
        .map(|(s, c)| (s, serde_json::to_string(&c)))
        .map(|(s, c)| c.map(|a| (s, a)))
        .collect::<Result<Vec<(String, String)>, serde_json::Error>>()?;

    Ok(Response::Buttons(
        Some(selected_restaurants(campi, configs)),
        buttons,
    ))
}
