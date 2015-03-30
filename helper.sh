#!/bin/bash

# set debugging mode (1 - debugging ON)
debugging=1;

#-------------------------------------
#-------------------------------------
# helper function for debugging
show_text () {
  if [ $debugging == 1 ]; then
      echo "++++++++++++++++++++++++++++++++++++++";
      echo -e "\033[36m$1\033[0m";
      echo "--------------------------------------";
  fi;
}

#-------------------------------------
#-------------------------------------
# trace command in the terminal
trace() {
  local par="$*";
  echo "~~~~~~~~~~trace~~~~~~~~~";
  echo -e "command: \t\033[31m$par\033[0m"
  echo -e "`$par`";
  echo "~~~~~~~~~~~~~~~~~~~~~~~~";
}

#-------------------------------------
#-------------------------------------
# log & run the command
log() {
        #local level=${1?}
        shift
        #local code= line="[$level] $*"
        local code = "$*" 
        if [ -t 2 ]
        then
                case "$level" in
                INFO) code=36 ;;
                DEBUG) code=30 ;;
                WARN) code=33 ;;
                ERROR) code=31 ;;
                *) code=37 ;;
                esac
                echo -e "\033[${code}m${line}\033[0m"
        else
                echo "$line"
        fi >&2
}

#-------------------------------------
#-------------------------------------
# append text to the end of the file
add_to_file() {
  local string="$1"
  local filename="$2"
  
  #echo "$string"
  #echo ""
  #$string="echo $string >> $filename";
  echo $string | sudo tee -a $filename > /dev/null
  
  #echo $string;
  #sudo bash -c $string;
  
#$string="echo >> $filename"
  #sudo bash -c $string;
}

#-------------------------------------
#-------------------------------------
# enable modules for the given site (custom, contrib, featured)
enable_modules() {
  local folder=$1;
  local output=$2;
  # get the list of all the custom modules in the site (then enable all of them)
  cd $sites_src/$website/modules/$folder;
  modules=`ls -l | egrep '^d' | awk '{print $9}'`
 #  cd $output/sites/default;
  cd $output/sites;
  
  for module in $modules; do 
    drush en $module -y; 
  done;
}

#-------------------------------------
#-------------------------------------
# create the database in case it does not exist already
create_database(){
  # params
  dbname=$1;
  username=$2;
  pass=$3;
  mysql_dir="";
  
  # database cleanup
  echo "DROP DATABASE IF EXISTS $dbname;";
  mysql="${mysql_dir}mysql"
  $mysql -u $username -p$pass -e "DROP DATABASE IF EXISTS $dbname;";
  echo "CREATE DATABASE IF NOT EXISTS $dbname;";
  $mysql -u $username -p$pass -e "CREATE DATABASE IF NOT EXISTS $dbname;";
  echo "USE $dbname;"; 
  $mysql -u $username -p$pass -e "USE $dbname;";
}

#-------------------------------------
#-------------------------------------
new_site_enable_modules() {
  local output=$1;
  
  cd $output;
  
  # set timezones -----------------------
  drush vset date_first_day 1 -y
  drush vset date_default_timezone 'America/New_York' -y
  drush vset date_api_use_iso8601 0 -y
  drush vset site_default_country 'US' -y
  echo "++++ Setting timezone and country"
  
  show_text "Enable Views UI and other important modules";
  drush cc all && drush en views_ui -y && drush en field_ui -y && drush en dblog -y && drush php-eval 'node_access_rebuild();' &&  drush eval 'menu_rebuild();'
  
  drush dis field_collection -y;
  
  show_text "Enable contrib modules";
  enable_modules "contrib" $output;
  
  show_text "Enable custom modules";
  enable_modules "custom" $output;
  
  show_text "Enable features modules";
  enable_modules "features" $output;
  
  show_text "Enable Backup and Migrate";
  drush en backup_migrate -y;
  
  show_text "Enable Admin Menu";
  drush en admin_menu -y;
}

#-------------------------------------
#-------------------------------------
# Clear Cache on the site 
cc_site(){
  local cur_dir=$PWD;
  # site directory
  local output=$1;
  
  cd $output;
  
  # revert to the original values
  drush cc all;
	drush fra -y && drush cc all;
	drush eval 'menu_rebuild();';
  drush image-flush;
  
  cd $cur_dir;
}

#-------------------------------------
#-------------------------------------
# update site (update Core + modules)
update_site_prem(){
  # update core
  echo "."
  # update modules
}

#-------------------------------------
#-------------------------------------
# update PWDS (Template) site
update_site_pwds(){
  # update Core
  echo "."
  # update modules
}

#-------------------------------------
#-------------------------------------
#config_file="test.txt"
config_file="/etc/apache2/sites-available/pwds_template.conf"

#hosts file
hosts_file="/etc/hosts";
#-------------------------------------
#-------------------------------------
# add info to the Apache Config
add_host() {
  local port=$1;
  local host_name=$2;
  local config=$config_file;
  local host="${host_name}";
  # check if already added to the config file
  local found=`grep "VirtualHost ${host_name}:${port}" $config_file`;
  if [ "$found" ]; then
    echo "already found that config";
  else
    add_to_file "" $config
    add_to_file "# ----- $host : $port --------- --START" $config
    add_to_file "<VirtualHost $host:$port>" $config
    add_to_file "   ServerAdmin webmaster@localhost" $config
    add_to_file "   ServerName ${host}_${port}" $config
    add_to_file "        DocumentRoot \"/home/nreljin/Documents/Projects/$host\"" $config
    add_to_file "        ErrorLog ${APACHE_LOG_DIR}/error.log" $config
    add_to_file "        CustomLog ${APACHE_LOG_DIR}/access.log combined" $config
    add_to_file "    <Directory \"/home/nreljin/Documents/Projects/$host\">" $config
    add_to_file "        DirectoryIndex index.php index.html home.aspx" $config
    add_to_file "        Order allow,deny" $config
    add_to_file "        Allow from all" $config
    add_to_file "        Options Indexes FollowSymLinks ExecCGI Includes" $config
    add_to_file "        AllowOverride All" $config
    add_to_file "        Require all granted" $config
    add_to_file "    </Directory>" $config
    add_to_file "</VirtualHost>" $config
    add_to_file "# ----- $host : $port --------- --END" $config
    
    add_to_file "" $config
  fi;
}

#-------------------------------------
#-------------------------------------
# add info to the HOSTS file
add_host_names() {
  local host_name=$1;
  local found=`grep "127.0.0.1 $host_name" $hosts_file`;
  # check if settings are already in place 
  if [ "$found" ]; then
    echo "already added the line";
  else
    local ip="127.0.0.1";
    local host=$host_name;
    add_to_file "## $host ## --START" $hosts_file;
    add_to_file "$ip $host" $hosts_file;  
    add_to_file "## $host ## --END" $hosts_file;
    add_to_file "" $hosts_file;
  fi;
}

#-------------------------------------
#-------------------------------------
# Delete the data from the Apache Conf
del_host() {
  local port=$1;
  local config=$config_file;
  local host="${host_name}";
  # check if already added to the config file
  local found=`grep "VirtualHost ${host_name}:${port}" $config_file`;
  
  local param_start="# ----- $host : $port --------- --START";
  local param_end="# ----- $host : $port --------- --END";
    
  if [ "$found" ]; then
    echo "already found that config";
  else
    # remove from the Config file
    awk 'BEGIN{f=0}
    {
        match($0,$param_start)
        if(RSTART){
            print substr($0,1,RSTART-1)
            f=1
            next
        }
        match($0,$param_end)
        if(RSTART){
            $0=substr($0,RSTART)
            f=0
        }
    }
    f==0{print}
     ' $config
  fi;
}

#-------------------------------------
#-------------------------------------
# Delete the data from the HOSTS
del_host_names() {
  local found=`grep "127.0.0.1 $host_name" $hosts_file`;
  local param_start="";
  local param_end="";
  
  # check if settings are already in place 
  if [ "$found" ]; then
    echo "already added the line";
  else
    
    local ip="127.0.0.1";
    local host=$host_name;
    add_to_file "## $host ## --START" $hosts_file;
    add_to_file "$ip $host" $hosts_file;  
    add_to_file "" $hosts_file;
  fi;
}