#!/bin/bash

minor_version=`cat version | cut -d'.' -f2`
new_minor_version=$((minor_version+1))
sed -i 's/\.'"$minor_version"'\..*/\.'"$new_minor_version"'\.0/' version