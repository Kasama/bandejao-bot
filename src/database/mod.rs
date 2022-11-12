pub mod config;
pub mod schedule;
pub mod users;

use sqlx::postgres::PgPoolOptions;
use sqlx::{migrate, Pool, Postgres};

#[derive(Debug)]
pub struct DB {
    pub pool: Pool<Postgres>,
}

impl DB {
    pub async fn new(url: String) -> anyhow::Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(5)
            .connect(&url)
            .await?;

        let migrator = migrate!("./migrations");

        migrator.run(&pool).await?;

        Ok(Self { pool })
    }
}
