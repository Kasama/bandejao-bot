use teloxide::types::{InlineKeyboardButton, InlineKeyboardMarkup, KeyboardButton, KeyboardMarkup};

pub fn create_inline(buttons: Vec<(String, String)>) -> InlineKeyboardMarkup {
    let inline_button_grid: Vec<Vec<InlineKeyboardButton>> = buttons
        .iter()
        .map(|(text, callback)| vec![InlineKeyboardButton::callback(text, callback)])
        .collect();
    InlineKeyboardMarkup::new(inline_button_grid)
}

pub fn create_keyboard(has_notifications: bool) -> KeyboardMarkup {
    KeyboardMarkup::new(vec![
        vec![KeyboardButton {
            text: "🍱 Próximo".to_string(),
            request: None,
        }],
        vec![
            KeyboardButton {
                text: "☀️ Almoço".to_string(),
                request: None,
            },
            KeyboardButton {
                text: "🌙 Jantar".to_string(),
                request: None,
            },
        ],
        vec![KeyboardButton {
            text: if has_notifications {
                "🔔 Ativar Notificações"
            } else {
                "🔕 Desativar Notificações"
            }
            .to_string(),
            request: None,
        }],
        vec![
            KeyboardButton {
                text: "⚙️ Configurações".to_string(),
                request: None,
            },
            KeyboardButton {
                text: "❓ Ajuda".to_string(),
                request: None,
            },
        ],
    ])
}
