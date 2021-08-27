# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases
alias ll="ls -al"

# User specific functions
function auto_agent()
{
  # Source file if this has been run before
  if [ -f ~/.ssh/ssh-agent ]; then
    source ~/.ssh/ssh-agent > /dev/null
  fi
  # See if the agent is still running, maybe rebooted
  kill -0 $SSH_AGENT_PID >& /dev/null
  # If not running
  if [ "$?" != "0" ]; then
    # Cleanup
    rm -f ~/.ssh/ssh-agent_pipe >& /dev/null
    # Run again, using a socket in my home dir, storing the env vars in root of
    # home dir
    ssh-agent -a ~/.ssh/ssh-agent_pipe > ~/.ssh/ssh-agent
    source ~/.ssh/ssh-agent
    # Auto kill after a week of not being used
    function watch_ssh_agent()
    {
      # Do one touch just to cover corner conditions
      touch ~/.last_ran_command
      # Store the last bash pid running this function
      echo $$ > ~/.ssh/.watch_ssh.pid
      while kill -0 "${SSH_AGENT_PID}" && (( $(date '+%s') - $(date -r ~/.last_ran_command '+%s') < 1*3600*24 )); do
        # In case this function get called multiple time, last one wins, only need one
        if [ "$(cat ~/.ssh/.watch_ssh.pid)" != "$$" ]; then
          return
        fi
        sleep 60
      done
      kill ${SSH_AGENT_PID}
    }
    export -f watch_ssh_agent
    if command -v screen &> /dev/null; then
      screen -d -m -S auto_kill_ssh_agent bash -c watch_ssh_agent
    elif [ "${OS-}" = "Windows_NT" ]; then
      # https://superuser.com/a/1657415/352118
      if command -v mintty &> /dev/null; then
        mintty bash -mc '(watch_ssh_agent) &> /dev/null < /dev/null &'
      # elif command -v cygstart &> /dev/null; then
      else
        echo "Woops, fixme"
      fi
    else
      watch_ssh_agent &
    fi
    unset watch_ssh_agent
  fi
}
if [ -e ~/.ssh/auto_agent ]; then
  auto_agent
else
  if [ -f ~/.ssh/ssh-agent ]; then
    source ~/.ssh/ssh-agent > /dev/null
  fi
fi