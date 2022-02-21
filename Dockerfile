FROM ruby:3.0.0

WORKDIR /app

COPY . /app

RUN bundle install

CMD ["bash", "-c", "rake db:create; rake db:migrate; ./run.sh"]
