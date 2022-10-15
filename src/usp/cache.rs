use cached::TimedSizedCache;
use chrono::{Duration, NaiveDate};

use super::model::Meals;

#[derive(Clone, Eq, PartialEq, Hash, Debug)]
pub struct CacheKey {
    date: NaiveDate,
    restaurant_id: String,
}

impl CacheKey {
    pub fn new(date: NaiveDate, restaurant_id: String) -> Self {
        Self {
            date,
            restaurant_id,
        }
    }
}

pub type MealCache = TimedSizedCache<CacheKey, Meals>;

pub fn new_meal_cache() -> MealCache {
    MealCache::with_size_and_lifespan_and_refresh(
        100,
        Duration::days(7).num_seconds() as u64,
        false,
    )
}
