FROM ruby:3.2@sha256:5efd846bccfafcabada226808406275e92269889467d571e897afc104e8c76c9

ADD README.md .

CMD ruby -e "puts RUBY_DESCRIPTION"
