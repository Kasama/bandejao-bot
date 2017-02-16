Telegram Bandejao Bot
=====================

Esse bot usa a [API][1] do [Telegram][2] para mostrar o cardápio do Restaurante Universitário da USP São Carlos

Como Usar
---------

Para usar o bot, basta mandar qualquer mensagem para [@BandejaoBot][3] no [Telegram][2] e o bot responderá com o cardápio do dia.

Existem também dois comandos principais, /almoco <data> e /jantar <data> quando esses comandos são recebidos, o bot responde com o cardápio da data oferecida (ou da atual, caso não seja especificada) no respectivo período (almoço ou jantar)

Também é possivel usar o bot na função [inline][4]. Para isso basta digitar [@BandejaoBot][3] na caixa de texto do [Telegram][2] em qualquer conversa. Aparecerá uma janela de seleção como na imagem ![Exemplo inline][5]

No modo [inline][4], o bot aceita também uma data uma opção almoço ou janta ![Exemplo inline 2][6]

API Web
-------

Status: **Ativada**

O bot também está equipado com uma simples API web, disponível no endereço [http://bit.ly/2lQagON](http://bit.ly/2lQagON)

A api tem duas rotas configuradas:

####/date/<dia>/<mes>/<periodo>

Nesse modo é possível receber o conteúdo do cardápio para o dia <dia> no mes <mes> no período <periodo>, período pode ser __almoco__ ou __jantar__.

####/next

Nesse modo é possível receber o conteúdo do cardápio para a próxima refeição

Problemas/Bugs
--------------

Para bugs no código, favor usar o canal de [Issues][7] do GitHub.

Para outros problemas, dúvidas ou sugestões, mande-me uma mensagem [@Kasama][8] ou use o canal de [Issues][7] do GitHub.

Contribuindo
------------

Contribuições são muito bem-vindas.

Para contribuir, favor seguir os passos

- Fazer um `fork` do repositório
- Alterar as partes que desejar
- Criar um novo `Pull Request`
- Se necessário, discutir sobre o pull request antes que ele seja aceito

Licença
-------
Copyright (c) 2016 Roberto Pommella Alegro  

Esse bot é distribuido sob a licença [MIT][9].

[1]: https://core.telegram.org/bots/api
[2]: https://telegram.org/
[3]: http://telegram.me/BandejaoBot
[4]: https://core.telegram.org/bots/inline
[5]: img/inlineEx1.png
[6]: img/inlineEx2.png
[7]: https://github.com/Kasama/bandejao-bot/issues
[8]: http://telegram.me/Kasama
[9]: https://opensource.org/licenses/MIT
