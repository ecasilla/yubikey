#!/bin/bash

# Stop on error.
set -e

source env.sh

# enable ssh support
backup_default_gpg_agent_conf
echo "enable-ssh-support" >> $DEFAULT_GPG_AGENT_CONF

if [[ $(cat ~/.bash_profile) =~ "gpg-agent.ssh" ]]; then
  echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> ~/.bash_profile
fi

if [[ $(cat ~/.zshrc) =~ "gpg-agent.ssh" ]]; then
  echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> ~/.zshrc
fi

if [[ $(cat ~/.profile) =~ "gpg-agent.ssh" ]]; then
  echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> ~/.profile
fi

# NOTE: Kill existing SSH and GPG agents, and start GPG agent manually (with SSH
# support added above) to maximize odds of picking up SSH key.
killall ssh-agent || echo "ssh-agent was not running."
$GPGCONF --kill all
$GPG_AGENT --daemon

# Export SSH key derived from GPG authentication subkey.
KEYID=$(get_keyid $DEFAULT_GPG_HOMEDIR)
SSH_PUBKEY=$KEYID.ssh.pub
echo "Exporting your SSH public key to $SSH_PUBKEY"
ssh-add -L | grep -iF 'cardno' > $SSH_PUBKEY
cat $SSH_PUBKEY | pbcopy
echo "It has also been copied to your clipboard."
echo "You may now add it to GitHub: https://github.com/settings/ssh/new"
echo "Opening GitHub..."
open "https://github.com/settings/ssh/new"
echo "Please save a copy in your password manager."
read -p "Have you done this? "
echo "Great."
echo ""
