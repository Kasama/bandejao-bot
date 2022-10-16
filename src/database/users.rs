use super::DB;

type UserId = i64;

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

    pub async fn upinsert_user(
        &self,
        user: User,
    ) -> Result<sqlx::postgres::PgQueryResult, sqlx::Error> {
        sqlx::query!(
            r#"INSERT INTO users (id, username, first_name, last_name) VALUES ($1, $2, $3, $4) ON CONFLICT (id) DO UPDATE SET username = $2, first_name = $3, last_name = $4"#,
            user.id,
            user.username,
            user.first_name,
            user.last_name
        )
        .execute(&self.pool)
        .await
    }
}
