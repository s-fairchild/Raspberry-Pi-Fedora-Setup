ONESHELL:
SHELL = /bin/bash

runssh:
	# TODO create script to setup automated testing environment for others
	# this is only for testing purposes
	ssh rpi4 'sudo bash -xs' < archLinuxArm/setup.sh