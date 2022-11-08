use super::config::Config;
use super::DB;

pub type UserId = i64;

#[derive(Debug, Clone)]
pub struct User {
    pub id: UserId,
    pub username: Option<String>,
    pub first_name: String,
    pub last_name: Option<String>,
}

impl DB {
    pub async fn get_user(&self, id: UserId) -> Result<User, sqlx::Error> {
        sqlx::query_as!(User, r#"SELECT * from users WHERE id = $1"#, id)
            .fetch_one(&self.pool)
            .await
    }

    pub async fn upsert_user(
        &self,
        user: User,
    ) -> Result<sqlx::postgres::PgQueryResult, sqlx::Error> {
        let query = sqlx::query!(
            r#"INSERT INTO users (id, username, first_name, last_name)
               VALUES ($1, $2, $3, $4)
               ON CONFLICT (id) DO
                   UPDATE SET username = $2, first_name = $3, last_name = $4
            "#,
            user.id,
            user.username,
            user.first_name,
            user.last_name
        );
        if let Err(sqlx::Error::RowNotFound) = self.get_user(user.id).await {
            let mut result = query.execute(&self.pool).await?;

            let default_config = Config {
                user_id: user.id,
                restaurant_id: "2".to_owned(),
            };

            let default_config_result = self.upsert_config(default_config).await?;

            result.extend(Some(default_config_result));
            Ok(result)
        } else {
            query.execute(&self.pool).await
        }
    }
}
