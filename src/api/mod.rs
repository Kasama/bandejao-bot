// use std::sync::Arc;

// use rocket::serde::json::Json;
// use rocket::{get, routes, Ignite, Rocket, State};

// use crate::usp::model::Campus;
// use crate::Context;

// #[get("/restaurants")]
// async fn restaurant<'r>(ctx: &State<Arc<Context>>) -> Option<Json<Vec<Campus>>> {
//     ctx.usp_client.lock().await.get_campi().await.map(Json).ok()
// }

// pub async fn create_v1_handler<'r>(ctx: Arc<Context>) -> anyhow::Result<Rocket<Ignite>> {
//     rocket::build()
//         .manage(ctx)
//         .mount("/v1", routes![restaurant])
//         .launch()
//         .await
//         .map_err(anyhow::Error::new)
// }
