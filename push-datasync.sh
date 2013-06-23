#!/usr/bin/env bash

# push-datasync.sh
# Push site updates from master server to front end web servers via rsync
#
# Copyright (c) 2013, Stephen Lang
# All rights reserved.
#
# Git repository available at:
# https://github.com/stephenlang/datasync
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


##########################################
# Server Configuration Options           #
##########################################

# Specify the slave web servers
webservers=( web02 web03 web04 web05 )

# List of directories to keep in sync
# DO NOT include trailing slash!
include_list=( /var/www )

# Output file to monitor status
status="/var/www/html/datasync.status"


##########################################
# End User Configuration Settings        #
##########################################

# Check to see if rsync is already running
if [ -d /tmp/.rsync.lock ]; then
echo "FAILURE : rsync lock exists : Perhaps there is a lot of new data to push to front end web servers. Will retry soon." > $status
exit 1
fi

# Create lock file
/bin/mkdir /tmp/.rsync.lock

if [ $? = "1" ]; then
echo "FAILURE : can not create lock" > $status
exit 1
else
echo "SUCCESS : created lock" > $status
fi

# Begin rsync
for server in ${webservers[@]}; do
for directory in ${include_list[@]}; do

echo "===== Beginning rsync of $server ====="

nice -n 20 /usr/bin/rsync -avzx --delete -e ssh $directory/ root@$server:$directory/

if [ $? = "1" ]; then
echo "FAILURE : rsync failed. Please refer to the solution documentation " > $status
exit 1
fi

echo "===== Completed rsync of $server =====";
done
done

# Remove lock file and update status
/bin/rm -rf /tmp/.rsync.lock
echo "SUCCESS : rsync completed successfully" > $status
