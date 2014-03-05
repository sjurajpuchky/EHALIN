# Speed test of instructions Makefile
# @author Juraj Puchký - Devtech <sjurajpuchky@seznam.cz>

all:
	./prepare-temps.sh
	./prepare-test.sh
	gcc -O4 -lrt -o speedtest speedtest.c
	./prepare-data.sh|tee results.txt

results:
	./graph results.ps
	convert -density 300x300 results.ps results.jpg

