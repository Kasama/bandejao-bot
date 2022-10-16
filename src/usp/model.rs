use chrono::{Datelike, NaiveDate};
use serde::{Deserialize, Deserializer, Serializer};

#[derive(serde::Deserialize, serde::Serialize, Debug)]
pub struct Campus {
    pub name: String,
    pub restaurants: Vec<Restaurant>,
}

#[derive(serde::Deserialize, serde::Serialize, Debug)]
pub struct Restaurant {
    pub alias: String,
    pub address: String,
    pub name: String,
    pub phones: String,
    pub id: String,
}

#[derive(Debug, Clone)]
pub enum Period {
    Dinner,
    Lunch,
}

#[derive(serde::Deserialize, serde::Serialize, Debug, Clone)]
pub struct Meal {
    pub menu: String,
    pub calories: String,
}

#[derive(serde::Deserialize, serde::Serialize, Debug, Clone)]
pub struct Meals {
    pub dinner: Meal,
    pub lunch: Meal,
    #[serde(
        deserialize_with = "naive_date_from_str",
        serialize_with = "naive_date_into_str"
    )]
    pub date: NaiveDate,
}

impl Meals {
    pub fn get_meal(&self, period: Period) -> &Meal {
        match period {
            Period::Dinner => &self.dinner,
            Period::Lunch => &self.lunch,
        }
    }
}

fn naive_date_from_str<'de, D: Deserializer<'de>>(d: D) -> Result<NaiveDate, D::Error> {
    NaiveDate::parse_from_str(String::deserialize(d)?.as_str(), "%d/%m/%Y")
        .map_err(serde::de::Error::custom)
}

fn naive_date_into_str<S: Serializer>(date: &NaiveDate, s: S) -> Result<S::Ok, S::Error> {
    s.serialize_str(format!("{}/{}/{}", date.day(), date.month(), date.year()).as_str())
}

#[derive(serde::Deserialize, serde::Serialize, Debug)]
pub struct Menu {
    pub meals: Vec<Meals>,
}
