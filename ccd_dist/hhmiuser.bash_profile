# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
 . ~/.bashrc
fi

# User specific environment and startup programs

export PATH=$PATH:$HOME/bin:/usr/local/ccd_dist/bin/linux

export http_proxy=http://192.168.1.4:3128

source /usr/local/ccd_dist/LOGIN_files/log_x4a_api_418

unset USERNAME
