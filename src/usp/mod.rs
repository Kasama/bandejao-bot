pub mod cache;
pub mod error;

use std::collections::HashMap;
use std::fmt::Display;

use anyhow::anyhow;
use cached::Cached;
use chrono::NaiveDate;
use reqwest;
use serde::de::DeserializeOwned;

use self::cache::{MealCache, MealCacheKey};
use self::model::{Campus, Meals, Menu, Restaurant};
pub mod model;

const USP_RESTAURANTS_ENDPOINT: &str = "restaurants";
const USP_MENU_ENDPOINT: &str = "menu";

pub struct Usp {
    base_url: String,
    api_key: String,
    meal_cache: MealCache,
}

impl Usp {
    /// Creates a new Usp client using environment variables for the base URL and API Key.
    /// Expect the environment variables below to exist. Returns an Err otherwise
    ///
    /// `USP_BASE_URL`: will be used as the base URL for calls
    /// `USP_API_KEY`:  will use this key for all requests
    pub fn new_from_env() -> Result<Self, std::env::VarError> {
        let base_url = ::std::env::var("USP_BASE_URL")?;
        let api_key = ::std::env::var("USP_API_KEY")?;
        Ok(Usp::new(base_url, api_key))
    }

    pub fn new(base_url: String, api_key: String) -> Self {
        let meal_cache = cache::new_meal_cache();
        Self {
            base_url,
            api_key,
            meal_cache,
        }
    }

    async fn request_usp<T, S>(&self, path: S) -> Result<T, anyhow::Error>
    where
        S: Display,
        T: DeserializeOwned,
    {
        let mut params: HashMap<&str, &str> = HashMap::new();
        params.insert("hash", &self.api_key);

        let result = reqwest::Client::new()
            .request(reqwest::Method::POST, format!("{}/{}", self.base_url, path))
            .form(&params)
            .send()
            .await?
            .json()
            .await?;

        return Ok(result);
    }

    async fn get_campi_raw(&self) -> Result<Vec<Campus>, anyhow::Error> {
        return self.request_usp(USP_RESTAURANTS_ENDPOINT).await;
    }

    pub async fn get_campi(&self) -> Result<Vec<Campus>, anyhow::Error> {
        self.get_campi_raw().await
    }

    pub async fn get_campi_by_restaurant(
        &self,
        restaurant_id: &String,
    ) -> anyhow::Result<(Campus, Restaurant)> {
        let campi = self.get_campi().await?;

        let campus = campi
            .into_iter()
            .find(|campus| {
                campus
                    .restaurants
                    .iter()
                    .find(|restaurant| &restaurant.id == restaurant_id)
                    .is_some()
            })
            .ok_or(anyhow!("couldn't find campus from restaurant id"))?;

        let rest = campus
            .restaurants
            .iter()
            .find(|r| &r.id == restaurant_id)
            .ok_or(anyhow!("couldn't find restaurant id"))?
            .clone();

        Ok((campus, rest))
    }

    async fn get_menu_raw(&self, restaurant_id: &String) -> Result<Menu, anyhow::Error> {
        return self
            .request_usp(format!("{}/{}", USP_MENU_ENDPOINT, restaurant_id))
            .await;
    }

    pub async fn get_menu(&self, restaurant_id: &String) -> Result<Menu, anyhow::Error> {
        self.get_menu_raw(restaurant_id).await
    }

    pub async fn get_meal(
        &mut self,
        restaurant_id: &String,
        date: NaiveDate,
    ) -> Result<Meals, anyhow::Error> {
        let key = MealCacheKey::new(date, restaurant_id.clone());
        let cached_meals = self.meal_cache.cache_get(&key);

        match cached_meals {
            Some(meals) => {
                log::debug!("Cache hit for key: {:?}", key);
                Ok(meals.clone())
            }
            None => {
                log::debug!("Cache miss for key {:?}", key);
                let menu = self.get_menu(&restaurant_id).await?;

                // Collect every restaurant in the list to eagerly cache them.
                // if .map().find() was used instead, it would stop caching in the first match,
                // which would cause more unecessary api requests to be done in subsquent.
                let mut meals: Vec<Meals> = menu
                    .meals
                    .into_iter()
                    .map(|meals| {
                        let k = MealCacheKey::new(meals.date, restaurant_id.clone());
                        self.meal_cache.cache_set(k, meals.clone());
                        meals
                    })
                    .filter(|meals| meals.date == date)
                    .collect();

                meals.pop().ok_or(anyhow!("couldn't fetch meals"))
            }
        }
    }
}
