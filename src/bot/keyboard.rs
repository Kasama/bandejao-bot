use teloxide::types::{InlineKeyboardButton, InlineKeyboardMarkup};

pub fn create_inline(buttons: Vec<(String, String)>) -> InlineKeyboardMarkup {
    let inline_button_grid: Vec<Vec<InlineKeyboardButton>> = buttons
        .iter()
        .map(|(text, callback)| vec![InlineKeyboardButton::callback(text, callback)])
        .collect();
    InlineKeyboardMarkup::new(inline_button_grid)
}
