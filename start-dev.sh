#!/bin/bash
#########################################################################
# © Ronan LE MEILLAT 2023
# released under the GPLv3 terms
#########################################################################
echo "this is for development only with tilt.dev use NODEV=1 for testing final image"
 kubectl delete namespace hcfschedule
 kubectl create namespace hcfschedule
 tilt up