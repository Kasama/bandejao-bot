use std::sync::Arc;

use tokio::join;
use tokio_schedule::{every, Job};

use super::Bot;

pub async fn spawn_schedules(bot: Arc<Bot>) {
    let hour /* in seconds */ = 60 /* minutes */ * 60 /* seconds */;

    let handler = || async {
        if let Err(e) = bot.notify_subscribed_users().await {
            log::error!("failed to find subscribed users to notify: {:?}", e);
        }
    };

    let lunch_schedule = every(1)
        .day()
        .at(11, 00, 00)
        .in_timezone(&chrono::FixedOffset::west(3 * hour))
        .perform(handler);
    let dinner_schedule = every(1)
        .day()
        .at(17, 00, 00)
        .in_timezone(&chrono::FixedOffset::west(3 * hour))
        .perform(handler);

    join!(
        lunch_schedule,
        dinner_schedule,
        every(20).seconds().perform(handler) // test
    );
}
