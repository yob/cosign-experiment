FROM ruby:3.2-slim-buster@sha256:aaf31982a84c7543a44814bf3e2dc8f8512eeeda0a7d70fe8226edbbd529dc2f

ADD README.md .

CMD ruby -e "puts RUBY_DESCRIPTION"
