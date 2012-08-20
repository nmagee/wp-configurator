#!/bin/bash

###
# This script does four things in order:
#   1. Creates and populates a web root with WordPress
#   2. Creates an Apache site config for the web root
#   3. Creates a remote MySQL database for the site
#   4. Creates a customized wp-config.php file for the site with 
#      optimal config tweaks for security and performance.
###

set -e

hostdom=".company.com" 	// the domain for your server
basedir="/home-nfs" 	// no trailing slashes
webmaster="webmaster@company.com"		// the email address of your site admin
U="dbsuperuser"			// your DB superuser
P="dbpassword" 			// your DB password
H="dbhost" 				// the name of your DB host, localhost or remote

# Read the site/DB name from user input
echo -e "Assign a primary identifier to this site (a simple name): [ENTER]"
read dbname
echo -e "What is the primary domain for this site? ($dbname.org, etc.): [ENTER]"
read domain
echo -e "List any additional server aliases for this site (*.$dbname.*, etc.): [ENTER]"
read serveralias

# Create a strong DB password
dbpass=`</dev/urandom tr -dc A-Za-z0-9 | head -c12`

hostpre=`cat /etc/hostname`
hostname=$hostpre$hostdom

# Create the webroot and populate with the latest WordPress
mkdir $basedir/$dbname
chown nobody.nogroup $basedir/$dbname
cd $basedir/$dbname
wget http://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz
mv wordpress/ www/
webroot="$basedir/$dbname/www"
rm -R latest.tar.gz
rm www/wp-config-sample.php
rm www/readme.html
rm www/license.txt
touch www/.htaccess
mkdir www/wp-content/uploads
chmod 777 www/wp-content/uploads
chown -R www-data.www-data $webroot

# Create Apache config file
{
echo "<VirtualHost *:80>";
echo "	ServerAdmin $webmaster";
echo "	ServerName $domain";
echo "	ServerAlias $serveralias";
echo "";
echo "	DocumentRoot $basedir/$dbname/www";
echo "	<Directory />";
echo "		Options FollowSymLinks";
echo "		AllowOverride None";
echo "	</Directory>";
echo "	<Directory $basedir/$dbname/www>";
echo "		Options Indexes FollowSymLinks MultiViews";
echo "		AllowOverride FileInfo Indexes";
echo "		Order allow,deny";
echo "		allow from all";
echo "	</Directory>";
echo "	<Directory \"$basedir/$dbname/www/wp-content/uploads\">";
echo "	   php_admin_flag engine off";
echo "	   Options -Indexes";
echo "	   AllowOverride None";
echo "	   # DirectoryIndex Off";
echo "	   RewriteEngine On";
echo "	   RewriteRule \.php$ - [F,L]";
echo "	</Directory>";
echo "";
echo "	ErrorLog /var/log/apache2/$domain-error.log";
echo "	LogLevel warn";
echo "	CustomLog /var/log/apache2/$domain-access.log combined";
echo "";
echo "</VirtualHost>";
} > /etc/apache2/sites-available/$dbname

ln -s /etc/apache2/sites-available/$dbname /etc/apache2/sites-enabled/999-$domain
/etc/init.d/apache2 restart

# Now talk to the AWS RDS instance and create user and DB
MYSQL=`which mysql`

Q1="CREATE DATABASE IF NOT EXISTS $dbname;"
Q2="GRANT USAGE ON *.* TO '$dbname'@'%' IDENTIFIED BY '$dbpass';"
Q3="GRANT ALL PRIVILEGES ON $dbname.* TO $dbname@'%';"
Q4="FLUSH PRIVILEGES;"

SQL="${Q1}${Q2}${Q3}${Q4}"

$MYSQL -u "$U" -p"$P" -h "$H" -e "$SQL"

# Now populate a few more variables and create the wp-config.php file.

{

a=`</dev/urandom tr -dc A-Za-z0-9 | head -c6`
b="_"
c=$a$b

curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/salts

echo "<?php";
echo "/** Custom WP configurator. */";
echo "/** DB Settings */";
echo "define('DB_NAME', '$dbname');";
echo "define('DB_USER', '$dbname');";
echo "define('DB_PASSWORD', '$dbpass');";
echo "define('DB_HOST', '$H');";
echo "define('DB_CHARSET', 'utf8');";
echo "define('DB_COLLATE', '');";
echo "/**#@+ * Authentication Unique Keys and Salts. */";
cat /tmp/salts
echo "\$table_prefix  = '$c';";
echo "define('WP_POST_REVISIONS', 5 );";
echo "define('AUTOSAVE_INTERVAL', 300 ); // value in seconds";
echo "define('WP_CACHE', true);";
echo "define ('WPLANG', '');";
echo "define('WP_DEBUG', false);";
echo "/* --- */";
echo "/** Absolute path to the WordPress directory. */";
echo "if ( !defined('ABSPATH') )";
echo "define('ABSPATH', dirname(__FILE__) . '/');";
echo "/** Sets up WordPress vars and included files. */";
echo "require_once(ABSPATH . 'wp-settings.php');";

} > $webroot/wp-config.php

chmod 644 $webroot/wp-config.php
chown www-data.www-data $webroot/wp-config.php

echo "--------------------------------------------------"
echo "Your WordPress site has been created and deployed:"
echo "--------------------------------------------------"
echo "   Site Name:   $dbname"
echo "   Site Domain: $domain"
echo "   Site Path:   $webroot"
echo "   Site Host:   $hostname"
echo "   DB Name:     $dbname"
echo "   DB Pass:     $dbpass"
echo "   DB Host:     $H"
echo "--------------------------------------------------"

