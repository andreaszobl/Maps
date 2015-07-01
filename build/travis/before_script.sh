#! /bin/bash

set -x

composer self-update

originalDirectory=$(pwd)

cd ..

wget https://github.com/wikimedia/mediawiki-core/archive/$MW.tar.gz
tar -zxf $MW.tar.gz
mv mediawiki-$MW phase3

cd phase3

git checkout $MW

composer install --prefer-source

if [ "$DB" == "postgres" ]
then
	psql -c 'create database its_a_mw;' -U postgres
	php maintenance/install.php --dbtype $DBTYPE --dbuser postgres --dbname its_a_mw --pass nyan TravisWiki admin --scriptpath /TravisWiki
else
	mysql -e 'create database its_a_mw;'
	php maintenance/install.php --dbtype $DBTYPE --dbuser root --dbname its_a_mw --dbpath $(pwd) --pass nyan TravisWiki admin --scriptpath /TravisWiki
fi

cd extensions

cp -r $originalDirectory Maps

cd Maps
composer install --prefer-source
composer require 'phpunit/phpunit=3.7.*' --prefer-source

cd ../..

echo 'require_once( __DIR__ . "/extensions/Maps/Maps.php" );' >> LocalSettings.php

echo 'error_reporting(E_ALL| E_STRICT);' >> LocalSettings.php
echo 'ini_set("display_errors", 1);' >> LocalSettings.php
echo '$wgShowExceptionDetails = true;' >> LocalSettings.php
echo '$wgDevelopmentWarnings = true;' >> LocalSettings.php
echo "putenv( 'MW_INSTALL_PATH=$(pwd)' );" >> LocalSettings.php

php maintenance/update.php --quick
