use std::collections::HashSet;

use cached::lazy_static::lazy_static;
use chrono::Weekday;
use serde::{Deserialize, Deserializer, Serialize, Serializer};

use crate::usp::model::Period;

use super::users::UserId;
use super::DB;

#[derive(Debug, Clone)]
pub struct Schedule {
    pub chat_id: i64,
    pub user_id: UserId,
    pub configuration: HashSet<DayPeriod>,
}

#[derive(Deserialize, Serialize, Debug, Clone, PartialEq, Eq, Hash)]
pub struct DayPeriod {
    pub period: Period,
    #[serde(
        deserialize_with = "weekday_from_str",
        serialize_with = "weekday_into_str"
    )]
    pub weekday: Weekday,
}

impl From<(Period, Weekday)> for DayPeriod {
    fn from((period, weekday): (Period, Weekday)) -> Self {
        Self { period, weekday }
    }
}

impl From<(Weekday, Period)> for DayPeriod {
    fn from((weekday, period): (Weekday, Period)) -> Self {
        Self { period, weekday }
    }
}

fn weekday_from_str<'de, D: Deserializer<'de>>(d: D) -> Result<Weekday, D::Error> {
    let deserialized = String::deserialize(d)?;
    let val = deserialized.as_str();
    match val {
        "mon" => Ok(Weekday::Mon),
        "tue" => Ok(Weekday::Tue),
        "wed" => Ok(Weekday::Wed),
        "thu" => Ok(Weekday::Thu),
        "fri" => Ok(Weekday::Fri),
        "sat" => Ok(Weekday::Sat),
        "sun" => Ok(Weekday::Sun),
        _ => Err(serde::de::Error::invalid_value(
            serde::de::Unexpected::Str(val),
            &"a value from mon-sun",
        )),
    }
}

fn weekday_into_str<S: Serializer>(date: &Weekday, s: S) -> Result<S::Ok, S::Error> {
    match date {
        Weekday::Mon => s.serialize_str("mon"),
        Weekday::Tue => s.serialize_str("tue"),
        Weekday::Wed => s.serialize_str("wed"),
        Weekday::Thu => s.serialize_str("thu"),
        Weekday::Fri => s.serialize_str("fri"),
        Weekday::Sat => s.serialize_str("sat"),
        Weekday::Sun => s.serialize_str("sun"),
    }
}

lazy_static! {
/// DEFAULT_CONFIG is from monday to sunday, on all periods
pub static ref DEFAULT_CONFIG: HashSet<DayPeriod> = HashSet::from([
    DayPeriod {
        period: Period::Lunch,
        weekday: Weekday::Mon,
    },
    DayPeriod {
        period: Period::Dinner,
        weekday: Weekday::Mon,
    },
    DayPeriod {
        period: Period::Lunch,
        weekday: Weekday::Tue,
    },
    DayPeriod {
        period: Period::Dinner,
        weekday: Weekday::Tue,
    },
    DayPeriod {
        period: Period::Lunch,
        weekday: Weekday::Wed,
    },
    DayPeriod {
        period: Period::Dinner,
        weekday: Weekday::Wed,
    },
    DayPeriod {
        period: Period::Lunch,
        weekday: Weekday::Thu,
    },
    DayPeriod {
        period: Period::Dinner,
        weekday: Weekday::Thu,
    },
    DayPeriod {
        period: Period::Lunch,
        weekday: Weekday::Fri,
    },
    DayPeriod {
        period: Period::Dinner,
        weekday: Weekday::Fri,
    },
    DayPeriod {
        period: Period::Lunch,
        weekday: Weekday::Sat,
    },
    DayPeriod {
        period: Period::Dinner,
        weekday: Weekday::Sat,
    },
    DayPeriod {
        period: Period::Lunch,
        weekday: Weekday::Sun,
    },
    DayPeriod {
        period: Period::Dinner,
        weekday: Weekday::Sun,
    },
]);
}

impl DB {
    //////////
    // pub async fn get_schedules(&self, chat_id: i64) -> Result<Schedule, anyhow::Error> {
    //     let zipped = sqlx::query!(r#"SELECT * FROM schedules WHERE chat_id = $1"#, chat_id)
    //         .map(|s| {
    //             (
    //                 serde_json::from_str::<DayPeriod>(&s.configuration),
    //                 s.user_id,
    //             )
    //         })
    //         .fetch_all(&self.pool)
    //         .await?
    //         .into_iter()
    //         .map(|(res, a)| res.map(|r| (r, a)))
    //         .collect::<Result<Vec<(DayPeriod, UserId)>, serde_json::Error>>()
    //         .map_err(anyhow::Error::new)?;
    //     let (schedules, uids): (Vec<_>, Vec<_>) = zipped.into_iter().unzip();
    //     Ok(Schedule {
    //         chat_id,
    //         user_id: *uids.first().unwrap_or(&chat_id),
    //         configuration: HashSet::from_iter(schedules.into_iter()),
    //     })
    // }

    pub async fn get_scheduled_chats(
        &self,
        day_period: &DayPeriod,
    ) -> Result<Vec<(i64, UserId)>, anyhow::Error> {
        let configuration = serde_json::to_string(&day_period)?;
        sqlx::query!(
            r#"SELECT chat_id, user_id from schedules where configuration = $1"#,
            configuration
        )
        .map(|row| (row.chat_id, row.user_id))
        .fetch_all(&self.pool)
        .await
        .map_err(anyhow::Error::new)
    }

    pub async fn upsert_schedule(
        &self,
        config: Schedule,
    ) -> Result<sqlx::postgres::PgQueryResult, anyhow::Error> {
        futures::future::join_all(config.configuration.into_iter().map(|c| async move {
            let config_configuration = serde_json::to_string(&c)?;
            sqlx::query!(
                r#"INSERT INTO "schedules" (chat_id, user_id, configuration)
               VALUES ($1, $2, $3)
               ON CONFLICT (chat_id, configuration) DO NOTHING"#,
                config.chat_id,
                config.user_id,
                config_configuration,
            )
            .execute(&self.pool)
            .await
            .map_err(anyhow::Error::new)
        }))
        .await
        .into_iter()
        .collect::<Result<Vec<sqlx::postgres::PgQueryResult>, anyhow::Error>>()?
        .into_iter()
        .reduce(|mut prev, next| {
            prev.extend(Some(next));
            prev
        })
        .ok_or_else(|| anyhow::Error::msg("couldn't get postgres query results"))
    }

    pub async fn delete_schedules(
        &self,
        chat_id: &i64,
    ) -> Result<sqlx::postgres::PgQueryResult, sqlx::Error> {
        sqlx::query!(
            r#"DELETE FROM "schedules"
               WHERE chat_id = $1
            "#,
            chat_id,
        )
        .execute(&self.pool)
        .await
    }
}
