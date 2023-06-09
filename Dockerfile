FROM ruby:3.2-slim-bullseye@sha256:506427360ecafed78530865257378ce4a287bd004315e5cafdd64690bcb56efe

ADD README.md .

CMD ruby -e "puts RUBY_DESCRIPTION"
