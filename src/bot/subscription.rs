use crate::database::schedule::{Schedule, DEFAULT_CONFIG};
use crate::database::users::UserId;
use crate::database::DB;

pub async fn subscribe_user(db: &DB, chat_id: i64, user_id: UserId) -> Result<bool, anyhow::Error> {
    let inserted = db
        .upsert_schedule(Schedule {
            chat_id,
            user_id,
            configuration: DEFAULT_CONFIG.to_owned(),
        })
        .await?;
    Ok(inserted.rows_affected() > 0)
}

pub async fn unsubscribe_user(db: &DB, chat_id: i64) -> Result<bool, anyhow::Error> {
    let deleted = db.delete_schedules(chat_id).await?;
    Ok(deleted.rows_affected() > 0)
}
