pub mod cache;

use std::collections::HashMap;
use std::fmt::Display;

use anyhow::anyhow;
use cached::Cached;
use chrono::NaiveDate;
use serde::de::DeserializeOwned;

use self::cache::{MealCache, MealCacheKey, RestaurantCache, RestaurantCacheKey};
use self::model::{Campus, Meal, Meals, Menu, Restaurant};
pub mod model;

const USP_RESTAURANTS_ENDPOINT: &str = "restaurants";
const USP_MENU_ENDPOINT: &str = "menu";

pub struct Usp {
    base_url: String,
    api_key: String,
    meal_cache: MealCache,
    restaurant_cache: RestaurantCache,
}

impl Usp {
    pub fn new(base_url: String, api_key: String) -> Self {
        let meal_cache = cache::new_meal_cache();
        let restaurant_cache = cache::new_restaurant_cache();
        Self {
            base_url,
            api_key,
            meal_cache,
            restaurant_cache,
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

        Ok(result)
    }

    async fn get_campi_raw(&self) -> Result<Vec<Campus>, anyhow::Error> {
        self.request_usp(USP_RESTAURANTS_ENDPOINT).await
    }

    #[allow(unreachable_code)]
    pub async fn get_campi(&self) -> Result<Vec<Campus>, anyhow::Error> {
        return self.get_campi_raw().await;

        if true {
            return Err(anyhow!("Hello"));
        }
        Ok(vec![
            Campus {
                name: "USP SP".to_string(),
                restaurants: vec![
                    Restaurant {
                        alias: "Central".to_string(),
                        address: "praça do relogio".to_string(),
                        name: "central".to_string(),
                        phones: "+12182192918".to_string(),
                        id: "central".to_string(),
                    },
                    Restaurant {
                        alias: "pusp".to_string(),
                        address: "ali".to_string(),
                        name: "pusp".to_string(),
                        phones: "+1128821981".to_string(),
                        id: "pusp".to_string(),
                    },
                ],
            },
            Campus {
                name: "Restaurante São carlos".to_string(),
                restaurants: vec![Restaurant {
                    alias: "Area 1".to_string(),
                    address: "aosjdoisajd".to_string(),
                    name: "area 1".to_string(),
                    phones: "+19129819882".to_string(),
                    id: "area 1".to_string(),
                }],
            },
        ])
    }

    pub async fn get_restaurant_by_id<'a>(
        &mut self,
        restaurant_id: &'a str,
    ) -> anyhow::Result<(Campus, Restaurant)> {
        let key = RestaurantCacheKey::new(restaurant_id.to_string());
        let cached_restaurant = self.restaurant_cache.cache_get(&key);

        match cached_restaurant {
            Some((campus, rest)) => {
                log::debug!("Cache hit for key: {:?}", key);
                Ok((campus.clone(), rest.clone()))
            }
            None => {
                log::debug!("Cache miss for key: {:?}", key);
                let campi = self.get_campi().await?;

                let campus = campi
                    .into_iter()
                    .find(|campus| {
                        campus
                            .restaurants
                            .iter()
                            .any(|restaurant| restaurant.id == restaurant_id)
                    })
                    .ok_or_else(|| anyhow!("couldn't find campus from restaurant id"))?;

                let rest = campus
                    .restaurants
                    .iter()
                    .find(|r| r.id == restaurant_id)
                    .ok_or_else(|| anyhow!("couldn't find restaurant id"))?
                    .clone();

                let k = RestaurantCacheKey::new(restaurant_id.to_string());
                self.restaurant_cache
                    .cache_set(k, (campus.clone(), rest.clone()));

                Ok((campus, rest))
            }
        }
    }

    async fn get_menu_raw<'r>(&self, restaurant_id: &'r str) -> Result<Menu, anyhow::Error> {
        self.request_usp(format!("{}/{}", USP_MENU_ENDPOINT, restaurant_id))
            .await
    }

    #[allow(unreachable_code)]
    pub async fn get_menu<'r>(&self, restaurant_id: &'r str) -> Result<Menu, anyhow::Error> {
        return self.get_menu_raw(restaurant_id).await;

        Ok(Menu {
            meals: vec![
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 16).expect("couldn't create date"),
                },
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 17).expect("couldn't create date"),
                },
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 18).expect("couldn't create date"),
                },
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 19).expect("couldn't create date"),
                },
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 20).expect("couldn't create date"),
                },
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 21).expect("couldn't create date"),
                },
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 22).expect("couldn't create date"),
                },
                Meals {
                    dinner: Meal {
                        menu: "comidas verdes\narroz\nfeijao\nbatata\nsuco de verde".to_string(),
                        calories: "1290".to_string(),
                    },
                    lunch: Meal {
                        menu: "comidas quase verdes\nsuco de azul".to_string(),
                        calories: "281".to_string(),
                    },
                    date: NaiveDate::from_ymd_opt(2022, 10, 23).expect("couldn't create date"),
                },
            ],
        })
    }

    pub async fn get_meal<'a>(
        &mut self,
        restaurant_id: &'a str,
        date: NaiveDate,
    ) -> Result<Meals, anyhow::Error> {
        let key = MealCacheKey::new(date, restaurant_id.to_string());
        let cached_meals = self.meal_cache.cache_get(&key);

        match cached_meals {
            Some(meals) => {
                log::debug!("Cache hit for key: {:?}", key);
                Ok(meals.clone())
            }
            None => {
                log::debug!("Cache miss for key {:?}", key);
                let menu = self.get_menu(restaurant_id).await?;

                // Collect every restaurant in the list to eagerly cache them.
                // if .map().find() was used instead, it would stop caching in the first match,
                // which would cause more unecessary api requests to be done in subsquent calls.
                let mut meals: Vec<Meals> = menu
                    .meals
                    .into_iter()
                    .map(|meals| {
                        let k = MealCacheKey::new(meals.date, restaurant_id.to_string());
                        self.meal_cache.cache_set(k, meals.clone());
                        meals
                    })
                    .filter(|meals| meals.date == date)
                    .collect();

                meals.pop().ok_or_else(|| anyhow!("couldn't fetch meals"))
            }
        }
    }
}
