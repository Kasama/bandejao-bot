pub mod command;

use teloxide::prelude::*;

pub fn bot() -> Bot {
    let b = Bot::from_env();

    b
}
