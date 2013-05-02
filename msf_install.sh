#!/bin/bash

KVER=`uname -a`
# Variable to know if Homebrew should be installed
MSFPASS=`openssl rand -hex 16`
#Variable with time of launch used for log names
NOW=$(date +"-%b-%d-%y-%H%M%S")
IGCC=1
INSTALL=1
RVM=1

function print_good ()
{
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}
########################################

function print_error ()
{
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}
########################################

function print_status ()
{
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}
########################################

function check_root
{
    if [ "$(id -u)" != "0" ]; then
       print_error "This step mus be ran as root"
       exit 1
    fi
}
########################################

function install_armitage_osx
{
    if [ -e /usr/bin/curl ]; then
        print_status "Downloading latest version of Armitage"
        curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage-latest.tgz && print_good "Finished"
        if [ $? -eq 1 ] ; then
               print_error "Failed to download the latest version of Armitage make sure you"
               print_error "are connected to the intertet and can reach http://www.fastandeasyhacking.com"
        else
            print_status "Decompressing package to /opt/armitage"
            tar -xvzf /tmp/armitage.tgz -C /usr/local/share >> $LOGFILE 2>&1
        fi

        # Check if links exists and if they do not create them
        if [ ! -e /usr/local/bin/armitage ]; then
            print_status "Creating link for Armitage in /usr/local/bin/armitage"
            sh -c "echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/share/armitage/armitage"
            ln -s /usr/local/share/armitage/armitage /usr/local/bin/armitage
        else
            print_good "Armitage is already linked to /usr/local/bin/armitage"
            sh -c "echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/share/armitage/armitage"
        fi

        if [ ! -e /usr/local/bin/teamserver ]; then
            print_status "Creating link for Teamserver in /usr/local/bin/teamserver"
            ln -s /usr/local/share/armitage/teamserver /usr/local/bin/teamserver
            perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        else
            print_good "Teamserver is already linked to /usr/local/bin/teamserver"
            perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        fi
        print_good "Finished"
    fi
}
########################################

function check_for_brew_osx
{
    print_status "Verifiying that Homebrew is installed:"
    if [ -e /usr/local/bin/brew ]; then
        print_good "Homebrew is installed on the system, updating formulas."
        /usr/local/bin/brew update >> $LOGFILE 2>&1
        print_good "Finished updating formulas"
        brew tap homebrew/versions >> $LOGFILE 2>&1
        print_status "Verifying that the proper paths are set"

        if [ -d ~/.bash_profile ]; then
            if [ "$(grep ":/usr/local/sbin" ~/.bash_profile -q)" ]; then
                print_good "Paths are properly set"
            else
                print_status "Setting the path for homebrew"
                echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
                source  ~/.bash_profile
            fi
         else
            echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
            source  ~/.bash_profile
         fi
    else

        print_status "Installing Homebrew"
        /usr/bin/ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
        if [ "$(grep ":/usr/local/sbin" ~/.bash_profile -q)" ]; then
            print_good "Paths are properly set"
        else
            print_status "Setting the path for homebrew"
            echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
            source  ~/.bash_profile
        fi

    fi
}
########################################

function check_dependencies_osx
{
    # Get a list of all the packages installed on the system
    PKGS=`pkgutil --pkgs`
    print_status "Verifiying that Development Tools and Java are installed:"
    if [[ $PKGS =~ com.apple.pkg.JavaForMacOSX ]] ; then
        print_good "Java is intalled."
    else
        print_error "Java is not installed on this system."
        print_error "Run the command java in terminal and install Apples Java"
        exit 1
    fi

    if [[ $PKGS =~ com.apple.pkg.XcodeMAS ]] ; then
        print_good "Xcode is intalled."
    else
        print_error "Xcode is not installed on this system. Install from the App AppStore."
        exit 1
    fi

    if [[ $PKGS =~ com.apple.pkg.DeveloperToolsCLI ]] ; then
        print_good "Command Line Development Tools is intalled."
    else
        print_error "Command Line Development Tools is not installed on this system."
        exit 1
    fi
}
########################################

function install_ruby_osx
{
    print_status "Checking if Ruby 1.9.3 is installed if not installing it."
    if [ -d /usr/local/Cellar/ruby193 ] && [ -L /usr/local/bin/ruby ]; then
        print_good "Correct version of Ruby is installed."
    else
        print_status "Installing Ruby 1.9.3"
        brew tap homebrew/versions >> $LOGFILE 2>&1
        brew install homebrew/versions/ruby193 >> $LOGFILE 2>&1
        echo PATH=/usr/local/opt/ruby193/bin:$PATH >> ~/.bash_profile
        source  ~/.bash_profile
    fi
    print_status "Inatlling the bundler and SQLite3 Gems"
    gem install bundler sqlite3 >> $LOGFILE 2>&1
}
########################################

function install_nmap_osx
{
    print_status "Checking if Nmap is installed using Homebrew if not installing it."
    if [ -d /usr/local/Cellar/nmap ] && [ -L /usr/local/bin/nmap ]; then
        print_good "Nmap is installed."
    else
        print_status "Installing Nmap"
        brew install nmap >> $LOGFILE 2>&1
    fi
}
########################################

function install_postgresql_osx
{
    print_status "Checking if PostgreSQL is installed using Homebrew if not installing it."
    echo "#### POSTGRESQL INSTALLATION ####" >> $LOGFILE 2>&1
    if [ -d /usr/local/Cellar/postgresql ] && [ -L /usr/local/bin/postgres ]; then
        print_good "PostgreSQL is installed."
    else
        print_status "Installing PostgresQL"
        echo "---- Installing PostgreSQL ----" >> $LOGFILE 2>&1
        brew install postgresql >> $LOGFILE 2>&1
        if [ $? -eq 0 ]; then
        	echo "---- Installtion of PostgreSQL successful----" >> $LOGFILE 2>&1
            print_good "Installtion of PostgreSQL was successful"
             echo "---- Initiallating the PostgreSQL Database ----" >> $LOGFILE 2>&1
            print_status "Initiating postgres"
            initdb /usr/local/var/postgres >> $LOGFILE 2>&1
            if [ $? -eq 0 ]; then
                print_good "Database initiation was successful"
                echo "---- Initiallitation of PostgreSQL successful----" >> $LOGFILE 2>&1
            fi

            # Getting the Postgres version so as to configure startup of the databse
            PSQLVER=`psql --version | cut -d " " -f3`
            echo "---- Postgres Version $PSQLVER ----" >> $LOGFILE 2>&1
            print_status "Configuring the database engine to start at logon"
            echo "---- Starting PostgreSQL Server ----" >> $LOGFILE 2>&1
            pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start >> $LOGFILE 2>&1
            mkdir -p ~/Library/LaunchAgents
            ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
            # Give enough time for the database to start for the first time
            sleep 5
            #launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
            print_status "Creating the MSF Database user msf with the password provided"
            echo "---- Postgres Version $PSQLVER ----" >> $LOGFILE 2>&1
            echo "---- Creating Metasploit DB user ----" >> $LOGFILE 2>&1
            psql postgres -c "create role msf login password '$MSFPASS'" >> $LOGFILE 2>&1
            if [ $? -eq 0 ]; then
                print_good "Metasploit Role named msf has been created."
                echo "---- Creation of Metasploit user was successful ----" >> $LOGFILE 2>&1
            else
                print_error "Failed to create the msf role"
                echo "---- Creation of Metasploit user failed ----" >> $LOGFILE 2>&1
            fi
            print_status "Creating msf database and setting the owner to msf user"
            echo "---- Creating Metasploit Database and assigning the role ----" >> $LOGFILE 2>&1
            createdb -O msf msf -h localhost >> $LOGFILE 2>&1
            if [ $? -eq 0 ]; then
                print_good "Metasploit Databse named msf has been created."
                echo "---- Database creation was successful ----" >> $LOGFILE 2>&1
            else
                print_error "Failed to create the msf database."
                echo "---- Database creation failed ----" >> $LOGFILE 2>&1
            fi
        fi
    fi
}
########################################

function install_msf_osx
{
    print_status "Installing Metasploit Framework from the GitHub Repository"
    if [[ ! -d /usr/local/share/metasploit-framework ]]; then
        print_status "Cloning latest version of Metasploit Framework"
        git clone https://github.com/rapid7/metasploit-framework.git /usr/local/share/metasploit-framework >> $LOGFILE 2>&1
        print_status "Linking metasploit commands."
        cd /usr/local/share/metasploit-framework
        for MSF in $(ls msf*); do
            print_status "linking $MSF command"
            ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF
        done
        print_status "Creating Database configuration YAML file."
        echo 'production:
   adapter: postgresql
   database: msf
   username: msf
   password: $MSFPASS
   host: 127.0.0.1
   port: 5432
   pool: 75
   timeout: 5' > /usr/local/share/metasploit-framework/database.yml
       	print_status "setting environment variable in system profile. Password will be requiered"
       	sudo sh -c "echo export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml >> /etc/profile"
       	echo "export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml" >> ~/.bash_profile
       	source /etc/profile
       	source ~/.bash_profile
       	cd /usr/local/share/metasploit-framework
	   	if [[ $RVM -eq 0 ]]; then
	        print_status "Installing required ruby gems by Framework using bundler on RVM Ruby"
	        ~/.rvm/bin/rvm 1.9.3-metasploit do bundle install  >> $LOGFILE 2>&1
	    else
	        print_status "Installing required ruby gems by Framework using bundler on System Ruby"
	        bundle install  >> $LOGFILE 2>&1
	    fi
	    print_status "Starting Metasploit so as to populate de database."
	    if [[ $RVM -eq 0 ]]; then
	        ~/.rvm/bin/rvm 1.9.3-metasploit do ruby /usr/local/share/metasploit-framework/msfconsole -q -x "exit" >> $LOGFILE 2>&1
	    else
	        /usr/local/share/metasploit-framework/msfconsole -q -x "exit" >> $LOGFILE 2>&1
	        print_status "Finished Metasploit installation"
	    fi
    else
        print_status "Metasploit already present."
    fi
}
########################################

function install_plugins
{
    print_status "Installing addiotional Metasploit plugins"
    print_status "Installing Pentest plugin"
    curl -# -o /usr/local/share/metasploit-framework/plugins/pentest.rb https://raw.github.com/darkoperator/Metasploit-Plugins/master/pentest.rb
    if [ $? -eq 0 ]; then
        print_good "The pentest plugin has been installed."
    else
        print_error "Failed to install the pentest plugin."
    fi
    print_status "Installing DNSRecon Import plugin"
    curl -# -o /usr/local/share/metasploit-framework/plugins/dnsr_import.rb https://raw.github.com/darkoperator/dnsrecon/master/msf_plugin/dnsr_import.rb
    if [ $? -eq 0 ]; then
        print_good "The dnsr_import plugin has been installed."
    else
        print_error "Failed to install the dnsr_import plugin."
    fi
}
#######################################

function install_deps_deb
{
    print_status "Installing dependencies for Metasploit Framework"
    sudo apt-get -y update  >> $LOGFILE 2>&1
    sudo apt-get -y install build-essential libreadline-dev  libssl-dev libpq5 libpq-dev libreadline5 libsqlite3-dev libpcap-dev openjdk-7-jre subversion git-core autoconf postgresql pgadmin3 curl zlib1g-dev libxml2-dev libxslt1-dev vncviewer libyaml-dev ruby1.9.3 sqlite3 libgdbm-dev libncurses5-dev libtool bison libffi-dev>> $LOGFILE 2>&1
    print_status "Finished installing the dependencies."
    print_status "Installing base Ruby Gems"
    sudo gem install wirble sqlite3 bundler >> $LOGFILE 2>&1
    print_status "Finished installing the base gems."
}
#######################################

function install_nmap_linux
{
    if [[ ! -e /usr/local/bin/nmap ]]; then
        print_status "Downloading and Compiling the latest version if Nmap"
        print_status "Downloading from SVN the latest version of Nmap"
        cd /usr/src
        sudo svn co https://svn.nmap.org/nmap >> $LOGFILE 2>&1
        cd nmap
        print_status "Configuring Nmap"
        sudo ./configure >> $LOGFILE 2>&1
        print_status "Compiling the latest version of Nmap"
        sudo make >> $LOGFILE 2>&1
        print_status "Installing the latest version of Nmap"
        sudo make install >> $LOGFILE 2>&1
        sudo make clean  >> $LOGFILE 2>&1
    else
        print_status "Nmap is already installed on the system"
    fi
}
#######################################

function configure_psql_deb
{
    print_status "Creating the MSF Database user msf with the password provided"
    MSFEXIST="$(sudo su postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='msf'\"")"
    if [[ ! $MSFEXIST -eq 1 ]]; then
        sudo -u postgres psql postgres -c "create role msf login password '$MSFPASS'"  >> $LOGFILE 2>&1
        if [ $? -eq 0 ]; then
            print_good "Metasploit Role named msf has been created."
        else
            print_error "Failed to create the msf role"
        fi
    else
        print_status "The msf role already exists."
    fi

    DBEXIST="$(sudo su postgres -c "psql postgres -l | grep msf")"
    if [[ ! $DBEXIST ]]; then
        print_status "Creating msf database and setting the owner to msf user"
        sudo -u postgres psql postgres -c "CREATE DATABASE msf OWNER msf;" >> $LOGFILE 2>&1
        if [ $? -eq 0 ]; then
            print_good "Metasploit Databse named msf has been created."
        else
            print_error "Failed to create the msf database."
        fi
    else
        print_status "The msf database already exists."
    fi
}
#######################################

function install_msf_linux
{
    print_status "Installing Metasploit Framework from the GitHub Repository"

    if [[ ! -d /usr/local/share/metasploit-framework ]]; then
        print_status "Cloning latest version of Metasploit Framework"
        sudo git clone https://github.com/rapid7/metasploit-framework.git /usr/local/share/metasploit-framework >> $LOGFILE 2>&1
        print_status "Linking metasploit commands."
        cd /usr/local/share/metasploit-framework
        for MSF in $(ls msf*); do
            print_status "linking $MSF command"
            sudo ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF
        done
        print_status "Creating Database configuration YAML file."
        sudo sh -c "echo 'production:
   adapter: postgresql
   database: msf
   username: msf
   password: $MSFPASS
   host: 127.0.0.1
   port: 5432
   pool: 75
   timeout: 5' > /usr/local/share/metasploit-framework/database.yml"
        print_status "setting environment variable in system profile. Password will be requiered"
        sudo sh -c "echo export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml >> /etc/environment"
        echo "export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml" >> ~/.bashrc
        PS1='$ '
        source ~/.bashrc

        cd /usr/local/share/metasploit-framework
        if [[ $RVM -eq 0 ]]; then
            print_status "Installing required ruby gems by Framework using bundler on RVM Ruby"
            ~/.rvm/bin/rvm 1.9.3-metasploit do bundle install  >> $LOGFILE 2>&1
        else
            print_status "Installing required ruby gems by Framework using bundler on System Ruby"
            sudo bundle install  >> $LOGFILE 2>&1
        fi
        print_status "Starting Metasploit so as to populate de database."
        if [[ $RVM -eq 0 ]]; then
            ~/.rvm/bin/rvm 1.9.3-metasploit do ruby /usr/local/share/metasploit-framework/msfconsole -q -x "exit" >> $LOGFILE 2>&1
        else
            /usr/local/share/metasploit-framework/msfconsole -q -x "exit" >> $LOGFILE 2>&1
            print_status "Finished Metasploit installation"
        fi
    else
        print_status "Metasploit already present."
    fi
}
#######################################

function install_plugins_linux
{
    print_status "Installing addiotional Metasploit plugins"
    print_status "Installing Pentest plugin"
    sudo curl -# -o /usr/local/share/metasploit-framework/plugins/pentest.rb https://raw.github.com/darkoperator/Metasploit-Plugins/master/pentest.rb
    if [ $? -eq 0 ]; then
        print_good "The pentest plugin has been installed."
    else
        print_error "Failed to install the pentest plugin."
    fi
    print_status "Installing DNSRecon Import plugin"
    sudo curl -# -o /usr/local/share/metasploit-framework/plugins/dnsr_import.rb https://raw.github.com/darkoperator/dnsrecon/master/msf_plugin/dnsr_import.rb
    if [ $? -eq 0 ]; then
        print_good "The dnsr_import plugin has been installed."
    else
        print_error "Failed to install the dnsr_import plugin."
    fi
}
#######################################

function install_armitage_linux
{
    if [ -e /usr/bin/curl ]; then
        print_status "Downloading latest version of Armitage"
        curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage-latest.tgz && print_good "Finished"
        if [ $? -eq 1 ] ; then
               print_error "Failed to download the latest version of Armitage make sure you"
               print_error "are connected to the intertet and can reach http://www.fastandeasyhacking.com"
        else
            print_status "Decompressing package to /opt/armitage"
            sudo tar -xvzf /tmp/armitage.tgz -C /usr/local/share >> $LOGFILE 2>&1
        fi

        # Check if links exists and if they do not create them
        if [ ! -e /usr/local/bin/armitage ]; then
            print_status "Creating link for Armitage in /usr/local/bin/armitage"
            sudo sh -c "echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/share/armitage/armitage"
            sudo ln -s /usr/local/share/armitage/armitage /usr/local/bin/armitage
        else
            print_good "Armitage is already linked to /usr/local/bin/armitage"
            sudo sh -c "echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/share/armitage/armitage"
        fi

        if [ ! -e /usr/local/bin/teamserver ]; then
            print_status "Creating link for Teamserver in /usr/local/bin/teamserver"
            sudo ln -s /usr/local/share/armitage/teamserver /usr/local/bin/teamserver
            sudo perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        else
            print_good "Teamserver is already linked to /usr/local/bin/teamserver"
            sudo perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        fi
        print_good "Finished"
    fi
}
#######################################

function usage ()
{
    echo "Scritp for Installing Metasploit Framework"
    echo "By Carlos_Perez[at]darkoperator.com"
    echo "Ver 0.1.3"
    echo ""
    echo "-i                :Install Metasploit Framework."
    echo "-p <password>     :password for MEtasploit databse msf user. If not provided a random one is generated for you."
    echo "-r                :Installs Ruby using Ruby Version Manager."
    echo "-h                :This help message"
}

function install_ruby_rvm
{

    if [[ ! -e ~/.rvm/scripts/rvm ]]; then
        print_status "Installing RVM"

        bash < <(curl -sk https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer) >> $LOGFILE 2>&1
        #echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"' >> ~/.bashrc
        PS1='$ '
        if [[ $OSTYPE =~ darwin ]]; then
        	source ~/.bash_profile
        else
        	source ~/.bashrc
        fi

        print_status "Installing Ruby 1.9.3 under the name 1.9.3-metasploit"
        if [[ $OSTYPE =~ darwin ]]; then
        	print_status "Installing necessary dependencies under OSX for Ruby 1.9.3"
        	~/.rvm/bin/rvm requirements run
        	print_status "Installing Readline Library"
    		~/.rvm/bin/rvm pkg install readline
    		print_status "Installing Ruby"
    		~/.rvm/bin/rvm reinstall 1.9.3 --with-readline-dir=$rvm_path/usr -n metasploit
        else
        	~/.rvm/bin/rvm install 1.9.3 -n metasploit >> $LOGFILE 2>&1
        fi

        if [[ $? -eq 0 ]]; then
            print_good "Installation of Ruby 1.9.3 was successful"

            ~/.rvm/bin/rvm use 1.9.3-metasploit --default >> $LOGFILE 2>&1
            print_status "Installing base gems"
            ~/.rvm/bin/rvm 1.9.3-metasploit do gem install sqlite3 bundler >> $LOGFILE 2>&1
            if [[ $? -eq 0 ]]; then
                print_good "Base gems in the RVM Ruby have been installed."
            else
                print_error "Base Gems for the RVM Ruby have failed!"
                exit 1
            fi
        else
            print_error "Was not able to install Ruby 1.9.3!"
            exit 1
        fi
    else
        print_status "RVM is already installed"
        if [[ "$( ls -1 ~/.rvm/rubies/)" =~ ruby-1.9.3-p...-metasploit ]]; then
            print_status "Ruby for Metasploit is already installed"
        else
            PS1='$ '
            if [[ $OSTYPE =~ darwin ]]; then
        		source ~/.bash_profile
        	else
        		source ~/.bashrc
        	fi

            print_status "Installing Ruby 1.9.3 under the name metasploit"
            ~/.rvm/bin/rvm install 1.9.3 -n metasploit >> $LOGFILE 2>&1
            if [[ $? -eq 0 ]]; then
                print_good "Installation of Ruby 1.9.3 was successful"

                ~/.rvm/bin/rvm use 1.9.3-metasploit --default >> $LOGFILE 2>&1
                print_status "Installing base gems"
                ~/.rvm/bin/rvm 1.9.3-metasploit do gem install sqlite3 bundler >> $LOGFILE 2>&1
                if [[ $? -eq 0 ]]; then
                    print_good "Base gems in the RVM Ruby have been installed."
                else
                    print_error "Base Gems for the RVM Ruby have failed!"
                    exit 1
                fi
            else
                print_error "Was not able to install Ruby 1.9.3!"
                exit 1
            fi
        fi
    fi
}
#### MAIN ###
[[ ! $1 ]] && { usage; exit 0; }
#Variable with log file location for trobleshooting
LOGFILE="/tmp/msfinstall$NOW.log"
while getopts "irp:h" options; do
  case $options in
    p ) MSFPASS=$OPTARG;;
    i ) INSTALL=0;;
    h ) usage;;
    r ) RVM=0;;
    \? ) usage
         exit 1;;
    * ) usage
          exit 1;;

  esac
done

if [ $INSTALL -eq 0 ]; then
    print_status "Log file with command output and errors $LOGFILE"
    if [[ "$KVER" =~ Darwin ]]; then
        check_dependencies_osx
        check_for_brew_osx
        install_ruby_osx
        if [[ $RVM -eq 0 ]]; then
            install_ruby_rvm
        fi
        install_nmap_osx
        install_postgresql_osx
        install_msf_osx
        install_armitage_osx
        install_plugins

        print_status "#################################################################"
        print_status "### YOU NEED TO RELOAD YOUR PROFILE BEFORE USE OF METASPLOIT! ###"
        print_status "### RUN source ~/.bash_profile                                ###"
        if [[ $RVM -eq 0 ]]; then
            print_status "###                                                            ###"
            print_status "### INSTALLATION WAS USING RVM SET 1.9.3-metasploit AS DEFAULT ###"
            print_status "### RUN rvm use 1.9.3-metasploit --default                     ###"
            print_status "###                                                            ###"
        fi
        print_status "#################################################################"

    elif [[ "$KVER" =~ buntu ]]; then
        install_deps_deb

        if [[ $RVM -eq 0 ]]; then
            install_ruby_rvm
        fi

        install_nmap_linux
        configure_psql_deb
        install_msf_linux
        install_plugins_linux
        install_armitage_linux
        print_status "##################################################################"
        print_status "### YOU NEED TO RELOAD YOUR PROFILE BEFORE USE OF METASPLOIT!  ###"
        print_status "### RUN source ~/.bashrc                                       ###"
        if [[ $RVM -eq 0 ]]; then
            print_status "###                                                            ###"
            print_status "### INSTALLATION WAS USING RVM SET 1.9.3-metasploit AS DEFAULT ###"
            print_status "### RUN rvm use 1.9.3-metasploit --default                     ###"
            print_status "###                                                            ###"
        fi
        print_status "##################################################################"

    else
        print_error "The script does not support this platform at this moment."
        exit 1
    fi
fi
