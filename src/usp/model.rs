use cached::lazy_static::lazy_static;
use chrono::{Datelike, NaiveDate};
use inflection_rs::inflection::Inflection;
use regex::Regex;
use serde::{Deserialize, Deserializer, Serialize, Serializer};

#[derive(serde::Deserialize, serde::Serialize, Debug, Clone)]
pub struct Campus {
    pub name: String,
    pub restaurants: Vec<Restaurant>,
}

impl Campus {
    pub fn normalized_name(&self) -> String {
        normalize_name(&self.name)
    }
}

#[derive(serde::Deserialize, serde::Serialize, Debug, Clone)]
pub struct Restaurant {
    pub alias: String,
    pub address: String,
    pub name: String,
    pub phones: String,
    pub id: String,
}

impl Restaurant {
    pub fn normalized_name(&self) -> String {
        normalize_name(&self.name)
    }

    pub fn normalized_alias(&self) -> String {
        normalize_name(&self.alias)
    }
}

fn normalize_name(name: &'_ str) -> String {
    lazy_static! {
        static ref QUOTE: Regex = Regex::new(r#""|'"#).unwrap();
        static ref CAMPUS: Regex = Regex::new(r#"(?i)\s*campus\s*(de)?\s*"#).unwrap();
        static ref RESTAURANT: Regex = Regex::new(r#"(?i)\s*restaurante\s*"#).unwrap();
        static ref FAC: Regex = Regex::new(r#"(?i)\s*fac\.?\s*"#).unwrap();
        static ref PUSP: Regex = Regex::new(r#"(?i)pusp.(c)"#).unwrap();
    }

    let mut inflection = Inflection::new();

    let replaced = vec![
        (&*QUOTE, ""),
        (&*CAMPUS, ""),
        (&*RESTAURANT, ""),
        (&*FAC, ""),
        (&*PUSP, "Prefeitura"),
    ]
    .into_iter()
    .fold(name.to_string(), |val, (re, replacement)| {
        re.replace_all(&val, replacement).to_string()
    });

    // let singular = inflection.singularize(replaced);
    let titlelized = inflection.titleize(replaced);

    // Titleize a second time to handle edge cases with acronyms
    inflection.titleize(titlelized)
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Deserialize, Serialize)]
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
    pub fn get_meal(&self, period: &Period) -> &Meal {
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
