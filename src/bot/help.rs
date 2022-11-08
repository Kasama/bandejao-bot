pub fn help_text() -> String {
    r#"
Enviando uma mensagem com qualquer texto você receberá o cardápio para a próxima refeição.
O restaurante pode ser alterado nas configurações.

Comandos:
/proximo - Envia o cardápio da próxima refeição, da mesma forma que enviar qualquer texto
/almoco [<Dia da Semana>] - Envia o cardápio do almoço do dia indicado (hoje caso não indicado)
/jantar [<Dia da Semana>] - Envia o cardápio do jantar do dia indicado (hoje caso não indicado)
/configuracoes - Abre o menu de configurações, que permite alterar o restaurante atual
/inscrever - Cadastra o chat para receber o cardápio para a próxima refeição antes do restaurante abrir, todos os dias (seg-sab 11:00 e seg-sex 17:00)
/desinscrever - Remove a inscrição efetuada pelo comando acima
/ajuda - Envia essa mensagem

/feedback <TEXTO> - Envia o texto especificado para o desenvolvedor do bot. Pode ser usado para reportar problemas, erros, sugerir funcionalidades, etc
Também é possível entrar em contato direto com o desenvolvedor @Kasama, para qualquer dificuldade

O código fonte desse bot está disponível em https://github.com/Kasama/bandejao-bot,
            "#.to_string()
}
