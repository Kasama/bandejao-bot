Telegram Bandejão Bot
=====================

Esse bot usa a [API][1] do [Telegram][2] para mostrar o cardápio do Restaurante Universitário da USP

Como Usar
---------

Para usar o bot, basta enviar qualquer mensagem para [@BandejaoBot][3] no [Telegram][2] e o bot responderá com o cardápio da próxima refeição

Interface:

![Interface][5]

Existem também dois comandos principais, /almoco <Dia da Semana> e /jantar <Dia da Semana> a resposta desses comandos é o cardápio do almoço/jantar do dia da semana especificado (ou do dia atual, caso vazio)

É possível alterar o Restaurante nas configurações do bot, através do comando /configuracoes

Também é possivel usar o bot no modo [inline][4]. Para isso basta digitar [@BandejaoBot][3] na caixa de texto do [Telegram][2] em qualquer conversa. Aparecerá uma janela de seleção como na imagem abaixo

No modo [inline][4], o bot aceita também um dia da semana e opção de almoço ou janta
 
![Exemplo inline][5]

API Web
-------

Status: **Desativada**

O bot também está equipado com uma simples API web, disponível no endereço [http://bit.ly/2lQagON](http://bit.ly/2lQagON)

A api tem duas rotas configuradas:

####/date/<dia>/<mes>/<periodo>

Nesse modo é possível receber o conteúdo do cardápio para o dia <dia> no mes <mes> no período <periodo>, período pode ser __almoco__ ou __jantar__.

####/next

Nesse modo é possível receber o conteúdo do cardápio para a próxima refeição

Problemas/Bugs
--------------

Para bugs no código, favor usar o canal de [Issues][7] do GitHub.

Para outros problemas, dúvidas ou sugestões, mande-me uma mensagem [@Kasama][8], use o comando /feedback do bot, ou use o canal de [Issues][7] do GitHub.

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
[3]: https://t.me/BandejaoBot
[4]: https://core.telegram.org/bots/inline
[5]: img/inlineEx1.png
[6]: img/interface.png
[7]: https://github.com/Kasama/bandejao-bot/issues
[8]: http://telegram.me/Kasama
[9]: https://opensource.org/licenses/MIT

