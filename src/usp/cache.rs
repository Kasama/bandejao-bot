use cached::TimedSizedCache;
use chrono::{Duration, NaiveDate};

use super::model::{Campus, Meals, Restaurant};

#[derive(Clone, Eq, PartialEq, Hash, Debug)]
pub struct MealCacheKey {
    date: NaiveDate,
    restaurant_id: String,
}

impl MealCacheKey {
    pub fn new(date: NaiveDate, restaurant_id: String) -> Self {
        Self {
            date,
            restaurant_id,
        }
    }
}

pub type MealCache = TimedSizedCache<MealCacheKey, Meals>;

pub fn new_meal_cache() -> MealCache {
    MealCache::with_size_and_lifespan_and_refresh(
        100,
        Duration::days(7).num_seconds() as u64,
        false,
    )
}

#[derive(Clone, Eq, PartialEq, Hash, Debug)]
pub struct RestaurantCacheKey {
    restaurant_id: String,
}

impl RestaurantCacheKey {
    pub fn new(restaurant_id: String) -> Self {
        Self { restaurant_id }
    }
}

pub type RestaurantCache = TimedSizedCache<RestaurantCacheKey, (Campus, Restaurant)>;

pub fn new_restaurant_cache() -> RestaurantCache {
    RestaurantCache::with_size_and_lifespan_and_refresh(
        100,
        Duration::days(7).num_seconds() as u64,
        false,
    )
}
