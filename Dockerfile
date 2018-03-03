FROM ruby:2.4.1

WORKDIR /app

COPY . /app

RUN bundle install

CMD ["bash", "-c", "rake db:create; rake db:migrate; ./run.sh"]
