pub mod users;

use sqlx::postgres::PgPoolOptions;
use sqlx::{migrate, Pool, Postgres};

#[derive(Debug)]
pub struct DB {
    pub pool: Pool<Postgres>,
}

impl DB {
    /// Creates a new Database client
    /// Expect the environment variables below to exist. Returns an Err otherwise
    ///
    /// `DATABASE_URL`: the full connection url to the database
    pub async fn from_env() -> anyhow::Result<Self> {
        let database_url = ::std::env::var("DATABASE_URL")?;
        DB::new(database_url).await
    }

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
