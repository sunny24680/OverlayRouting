# Makefile for CMSC417 Project 3: Part 1

PUBLIC_TESTS:=$(wildcard public? public??)
RELEASE_TESTS:=$(wildcard release? release??)

all:	copy chmod clean


copy:
	cp ../controller.rb ./controller; cp ../../starter/node.rb node.rb; cp ../../starter/structs.rb structs.rb

chmod:
	chmod a+x $(PUBLIC_TESTS) $(RELEASE_TESTS) controller

clean:
	rm -f console_n* *~ *.dt