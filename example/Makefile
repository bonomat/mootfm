all: test start

test: has-coffee
	@find test -name '*.coffee' | xargs -n 1 -t mocha --compilers coffee:coffee-script -R spec

watch-test: has-coffee
	@find test -name '*.coffee' | xargs -n 1 -t mocha --compilers coffee:coffee-script -R spec -w

start: has-coffee
	@coffee server.coffee

watch-server: has-coffee
	@coffee -w server.coffee

has-coffee:
	@test `which coffee` || 'You need to install CoffeeScript.'
