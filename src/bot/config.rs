use crate::database::config::Config;
use crate::usp::model::{Campus, Restaurant};

use super::callback::CallbackCommand;
use super::Response;

pub fn config_menu(campi: Vec<Campus>, configs: Vec<Config>) -> anyhow::Result<Response> {
    let restaurant_list = selected_restaurants(&campi, &configs);

    let restaurant_text_list = restaurant_list
        .into_iter()
        .map(|(a, b)| campus_restaurant_list_text(a, b))
        .collect::<Vec<String>>()
        .join("\n");

    Ok(Response::Buttons(
        Some(format!(
            "<b>Restaurantes selecionados</b>:\n{}\nSelecione uma opção",
            restaurant_text_list
        )),
        vec![
            (
                "Alterar Restaurantes".to_string(),
                CallbackCommand::ListCampi,
            ),
            ("Finalizar".to_string(), CallbackCommand::Cancel),
        ]
        .into_iter()
        .map(|(s, c)| (s, serde_json::to_string(&c)))
        .map(|(s, c)| c.map(|a| (s, a)))
        .collect::<Result<Vec<(String, String)>, serde_json::Error>>()?,
    ))
}

fn is_checked_emoji(is: bool) -> String {
    match is {
        true => "✅",
        false => "⬜️",
    }
    .to_string()
}

fn selected_restaurants<'a>(
    campi: &'a [Campus],
    configs: &'a [Config],
) -> Vec<(&'a Campus, &'a Restaurant)> {
    let find_campus = |id: &str| {
        campi
            .iter()
            .find(|c| c.restaurants.iter().any(|r| r.id == id))
    };
    let find_restaurant =
        |campus: &'a Campus, id: &str| campus.restaurants.iter().find(|r| r.id == id);

    configs
        .iter()
        .filter_map(|c| {
            let campus = find_campus(&c.restaurant_id);
            let restaurant = campus.and_then(|camp| find_restaurant(camp, &c.restaurant_id));
            Some((campus?, restaurant?))
        })
        .collect::<Vec<(&Campus, &Restaurant)>>()
}

pub fn campus_restaurant_list_text(campus: &Campus, restaurant: &Restaurant) -> String {
    format!(
        " - {}, {}",
        campus.normalized_name(),
        restaurant.normalized_name()
    )
}

fn selected_restaurants_text(campi: Vec<Campus>, configs: Vec<Config>) -> String {
    let restaurant_list = selected_restaurants(&campi, &configs);

    let restaurant_text_list = restaurant_list
        .into_iter()
        .map(|(a, b)| campus_restaurant_list_text(a, b))
        .collect::<Vec<String>>()
        .join("\n");
    format!(
        "<b>Restaurantes selecionados:</b>\n{}\nAdicione ou remova restaurantes abaixo",
        restaurant_text_list
    )
}

pub fn select_restaurant_menu(
    restaurants: Vec<Restaurant>,
    configs: Vec<Config>,
) -> anyhow::Result<Response> {
    let buttons: Vec<(String, String)> = restaurants
        .into_iter()
        .map(|restaurant| {
            let restaurant_alias = restaurant.normalized_name();
            let checked = configs.iter().any(|c| restaurant.id == c.restaurant_id);
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

pub fn select_campus_menu(campi: Vec<Campus>, configs: Vec<Config>) -> anyhow::Result<Response> {
    let buttons: Vec<(String, String)> = campi
        .iter()
        .map(|campus| {
            let campus_alias = campus.normalized_name();
            match campus.restaurants.as_slice() {
                [r] => {
                    let checked = configs.iter().any(|c| r.id == c.restaurant_id);
                    (
                        format!("{} {}", is_checked_emoji(checked), campus_alias),
                        CallbackCommand::SelectRestaurant(r.id.clone(), !checked),
                    )
                }
                rs => {
                    let checked = rs
                        .iter()
                        .any(|r| configs.iter().any(|c| r.id == c.restaurant_id));
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
        Some(selected_restaurants_text(campi, configs)),
        buttons,
    ))
}
