use super::users::UserId;
use super::DB;

#[derive(Debug, Clone)]
pub struct Config {
    pub user_id: UserId,
    pub restaurant_id: String,
}

impl DB {
    pub async fn get_configs(&self, user_id: UserId) -> Result<Vec<Config>, sqlx::Error> {
        let default_config = Config {
            user_id,
            restaurant_id: "2".to_string(),
        };
        let cfgs: Vec<Config> = sqlx::query_as!(
            Config,
            r#"SELECT * FROM configurations WHERE user_id = $1"#,
            user_id
        )
        .fetch_all(&self.pool)
        .await?;

        if cfgs.is_empty() {
            Ok(vec![default_config])
        } else {
            Ok(cfgs)
        }
    }

    pub async fn upsert_config(
        &self,
        config: Config,
    ) -> Result<sqlx::postgres::PgQueryResult, sqlx::Error> {
        sqlx::query!(
            r#"INSERT INTO "configurations" (user_id, restaurant_id)
               VALUES ($1, $2)
               ON CONFLICT (user_id, restaurant_id) DO NOTHING
            "#,
            config.user_id,
            config.restaurant_id,
        )
        .execute(&self.pool)
        .await
    }

    pub async fn delete_config(
        &self,
        config: Config,
    ) -> Result<sqlx::postgres::PgQueryResult, sqlx::Error> {
        sqlx::query!(
            r#"DELETE FROM "configurations"
               WHERE user_id = $1 AND restaurant_id = $2
            "#,
            config.user_id,
            config.restaurant_id,
        )
        .execute(&self.pool)
        .await
    }
}
