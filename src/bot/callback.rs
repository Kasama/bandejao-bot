use serde::{Deserialize, Serialize};

use crate::database::config::Config;
use crate::database::users::UserId;

use super::{config, HandlerContext, Response};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CallbackCommand {
    SelectCampus(String),
    SelectRestaurant(String, bool),
    ListCampi,
    Cancel,
}

pub async fn execute_callback(
    ctx: HandlerContext,
    command: CallbackCommand,
    user_id: UserId,
) -> anyhow::Result<Response> {
    let configs = ctx.0.db.get_configs(user_id).await?;
    let campi = ctx.0.usp_client.lock().await.get_campi().await?;
    match command {
        CallbackCommand::SelectCampus(campus_name) => {
            let restaurants = campi
                .into_iter()
                .find(|c| c.name == campus_name)
                .unwrap()
                .restaurants;
            config::select_restaurant_menu(restaurants, configs)
        },
        CallbackCommand::SelectRestaurant(restaurant_id, set) => {
            match set {
                true => {
                    ctx.0
                        .db
                        .upsert_config(Config {
                            user_id,
                            restaurant_id,
                        })
                        .await?;
                    let new_configs = ctx.0.db.get_configs(user_id).await?;
                    config::config_menu(campi, new_configs)
                }
                false => {
                    ctx.0
                        .db
                        .delete_config(Config {
                            user_id,
                            restaurant_id,
                        })
                        .await?;
                    let new_configs = ctx.0.db.get_configs(user_id).await?;
                    config::config_menu(campi, new_configs)
                }
            }
        }
        CallbackCommand::ListCampi => {
            config::config_menu(campi, configs)
        },
        CallbackCommand::Cancel => {
            Ok(Response::Text("Cancelled".to_string()))
        },
    }
}
