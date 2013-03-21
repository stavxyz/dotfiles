PATH=/usr/local/bin:/usr/local/mysql/bin:/usr/local/sbin:/usr/local/lib:/usr/local/share/python:$PATH
export PATH

#for pythonrc
export PYTHONSTARTUP=~/.pystartup/.pythonrc

source /usr/local/share/python/virtualenvwrapper.sh
#export WORKON_HOME=~/.virtualenvs


export WORKON_HOME=$HOME/.virtualenvs
export PIP_VIRTUALENV_BASE=$WORKON_HOME
export PIP_RESPECT_VIRTUALENV=true


# Tell ls to be colourful
export CLICOLOR=1
export LSCOLORS=Exfxcxdxbxegedabagacad

# Tell grep to highlight matches
export GREP_OPTIONS='--color=auto'

#REMOTES
alias smbops='ssh -p314 sam@smbops.slicehost.com'




