# Makefile for CMSC417 Project 3: Part 1

PUBLIC_TESTS:=$(wildcard public? public??)
RELEASE_TESTS:=$(wildcard release? release??)

all:	copy chmod clean

clear: 
	rm *.rb;

copy:
	cp ../controller.rb ./controller.rb; cp -r ../../starter/ ../part3;

chmod:
	chmod a+x $(PUBLIC_TESTS) $(RELEASE_TESTS) controller

clean:
	rm -f console_n* *~ *.dt; 