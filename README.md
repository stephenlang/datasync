## Datasync

Rsync replication scripts to keep web content in sync between multiple web front end servers


### Purpose

People looking to create a load balanced web server solution often ask, how can they keep their web servers in sync with each other? There are many ways to go about this: NFS, lsync, rsync, etc. This guide will discuss a technique using rsync that runs from a cron job every 10 minutes.

Our master web server is going to the single point of truth for the web content of our solution. Therefore, the web developers will only be modifying content from the master web server, and will let rsync handle keeping all the slave nodes in sync with each other.


### Use Cases

There will be two different options presented, pulling the updates from the master web server, and pushing the updates from the master web server down to the slave web servers.

<strong>pull-datasync.sh</strong>

This is especially useful if you are in a cloud environment and scale your environment by snapshotting an existing slave web server to provision a new one. When the new slave web server comes online, and assuming it already has the SSH key in place, it will automatically grab the latest content from the master server with no interaction needed by yourself except to test, then enable in your load balancer.

The disadvantage with using the pull method for your rsync updates comes into play when you have multiple slave web servers all running the rsync job at the same time. This can put a strain on the master web servers CPU, which can cause performance degradation. However if you have under 10 servers, or if your site does not have a lot of content, then the pull method should work fine.

<strong>push-datasync.sh</strong>

Using rsync to push changes from the master down to the slaves has some important advantages. First off, the slave web servers will not have SSH access to the master server. This could become critical if one of the slave servers is ever compromised and tries to gain access to the master web server. The next advantage is the push method does not cause a serious CPU strain cause the master will run rsync against the slave servers, one at a time.

The disadvantage here would be if you have a lot of web servers syncing content that changes often. Its possible that your updates will not be pushed down to the web servers as quickly as expected since the master server is syncing the servers one at a time. So be sure to test this out to see if the results work for your solution. Also if you are cloning your servers to create additional web servers, you will need to update the rsync configuration accordingly to include the new node.


### Features

- Simple configuration options
- Executed via cron on a interval of your choosing
- Outputs a status file that can be checked remotely with a HTTP content check


### Prerequisites

- Confirm that rsync is installed.
- If pulling updates from the master web server, all slave servers must be able to SSH to the master server using a SSH key with no passphrase.
- If pushing updates from the master down to the slave servers, the master server must be able to SSH to the slave web servers using a SSH key with no passphrase.


### Configuration

The currently configurable options:

push-datasync.sh

	# Specify the slave web servers
	webservers=( web02 web03 web04 web05 )

	# List of directories to keep in sync
	# DO NOT include trailing slash!
	include_list=( /var/www )

	# Output file to monitor status
	status="/var/www/html/datasync.status"


pull-datasync.sh

	# Define the master webserver
	master_webserver="web01"

	# List of directories to keep in sync
	# DO NOT include trailing slash!
	include_list=( /var/www )

	# Output file to monitor datasync status
	status="/var/www/html/datasync.status"


### Implementation

While not a requirement, you should setup your /etc/hosts file on each server so you can reference the other servers in the solution by hostname rather then IP so its easily readable.  For this example, we will set each server's /etc/hosts as follows:

	vi /etc/hosts
	web01.example.com (192.168.1.1) # Master Web Server
	web02.example.com (192.168.1.2) # Slave Web Server
	web03.example.com (192.168.1.3) # Slave Web Server

To allow the script to automatically keep the servers in sync, SSH keys must be setup accordingly between the servers.  Below outlines how to do this depending on which script your using:

If using push-datasync.sh, perform the following on the master web server:

	mkdir /opt/scripts
	cd /opt/scripts
	git clone https://github.com/stephenlang/datasync
	chmod 755 datasync/push-datasync.sh

	# After configuring the tunables in the script (see above), create a cron job to execute the script every 10 minutes:

	crontab -e
	*/10 * * * * /opt/scripts/datasync/push-datasync.sh

If using pull-datasync.sh, perform the following on each slave web server:

	mkdir /opt/scripts
	cd /opt/scripts
	git clone https://github.com/stephenlang/datasync
	chmod 755 datasync/pull-datasync.sh

	# After configuring the tunables in the script (see above), create a cron job to execute the script every 10 minutes:

	crontab -e
	*/10 * * * * /opt/scripts/datasync/pull-datasync.sh
