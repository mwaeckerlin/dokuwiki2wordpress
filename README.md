Migrate Dokuwiki to Wordpress
=============================

Idea:

 * Generate HTML from dokuwiki on commandline.
 * Add it within RSS-XML structure to imprt into Wordpress

Supports:
 - file structure is mapped to categories

Thanks to:
 - https://www.dokuwiki.org/tips:dokuwiki_parser_cli
 - https://wordpress.stackexchange.com/questions/82399/what-is-the-required-format-for-importing-posts-into-wordpress

Usage
-----

 - install package `php-cli`
   (e.g. sudo apt install php7.2-cli)
 - go to your dokuwiki root directory
 - run [dokuwiki2wordpress path]/dokuwiki2wordpress.sh to create .xml file
 - In Wordpress -> menu -> tools -> import -> wordpress -> (install now) -> run importer -> select .xml file
...
