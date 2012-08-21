wp-configurator
===============

A bash script to install WordPress in a new webroot, create the proper Apache site config, 
create a remote or local MySQL database, and to automatically create a wp-config.php file 
for the site.

I wrote this script for work with someone who often numerous WP sites set up on short
notice. After creating countless webroots in Apache, downloading and expanding the WP code
base, forgetting the "good" settings I always mean to remember to put in wp-config.php, and
issuing lots of remote commands to MySQL to set up a new DB, I just decided to script it.

All of it.


Details
=======
Here's what happens in this script:
1. It asks for a "simple" name for your site, such as to be used in a directory name. Use
no spaces in this name, such as "bilbobaggins".
2. It prompts you for a domain to be used with the site, such as "bilbobaggins.org", etc.
3. It also prompts you for any ServerAlias names, such as *.bilbobaggins.* or such.
4. The script then creates a new subdirectory in your base directory ("/home" in many cases).
5. It grabs a fresh copy of the WP source files from WordPress.com and unpacks them.
6. It removes a few unnecessary files, creates an uploads directory and chmods it properly.
7. It then creates an Apache config file and symbolically links it in sites-enabled. It
also restarts the Apache2 daemon.
8. It then makes calls to the MySQL DB server of your choice, creating a new user, new DB,
with a nice strong password. (I created this specifically to make calls to an Amazon RDS
instance, but you can use "localhost" or an IP, or remote server address.
9. Finally, the script creates a wp-config.php file with all server values, a minimal number
of revisions kept, caching turned on, autosave spaced every 5 minutes, and a fresh set of
password salts grabbed from the WordPress API. Also included is an ugly 6-char WP prefix,
to obfuscate the table names, to ward off SQL injections, etc.


Assumptions
===========
- You use a standard Linux server of some flavor with the bash shell installed to run this
script. You will also need PHP5 configured to work with Apache.
- You are running Apache2 and your site configuration files are in /etc/apache2/sites-available.
- You have a MySQL server engine running locally or remotely, and the proper credentials
to create users and DBs.


Installation
============
Copy this into your home directory (or a script directory), and you can even add it to your path
or as an alias within your .bashrc file.

In .bashrc create a line:
 alias wp-config='/path/to/wp-config.sh'

Then either logout/login again, or simply issue the command:
 $: source ~/.bashrc
 
The script can then be invoked by the command from anywhere:
 $: wp-config


Free
====
Please send a note if you have any feedback or suggestions of new features.