#!/usr/bin/env expect
#
# This Expect script was generated by autoexpect on Wed Aug  1 17:10:59 2018
# Expect and autoexpect were both written by Don Libes, NIST.
#
# Note that autoexpect does not guarantee a working script.  It
# necessarily has to guess about certain things.  Two reasons a script
# might fail are:
#
# 1) timing - A surprising number of programs (rn, ksh, zsh, telnet,
# etc.) and devices discard or ignore keystrokes that arrive "too
# quickly" after prompts.  If you find your new script hanging up at
# one spot, try adding a short sleep just before the previous send.
# Setting "force_conservative" to 1 (see below) makes Expect do this
# automatically - pausing briefly before sending each character.  This
# pacifies every program I know of.  The -c flag makes the script do
# this in the first place.  The -C flag allows you to define a
# character to toggle this mode off and on.

set force_conservative 0  ;# set to 1 to force conservative mode even if
			  ;# script was not run conservatively originally
if {$force_conservative} {
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- $arg
	}
}

#
# 2) differing output - Some programs produce different output each time
# they run.  The "date" command is an obvious example.  Another is
# ftp, if it produces throughput statistics at the end of a file
# transfer.  If this causes a problem, delete these patterns or replace
# them with wildcards.  An alternative is to use the -p flag (for
# "prompt") which makes Expect only look for the last line of output
# (i.e., the prompt).  The -P flag allows you to define a character to
# toggle this mode off and on.
#
# Read the man page for more info.
#
# -Don

set timeout -1
match_max 100000

# https://stackoverflow.com/a/17060172
set realname [lindex $argv 0];
set email    [lindex $argv 1];
set comment  [lindex $argv 2];

# Turn off OTP.
send_user "Turning off Yubikey OTP:\n"
spawn ykman mode "FIDO+CCID"
expect {
  "Mode is already FIDO+CCID, nothing to do..." {
    expect eof
  }

  ": " {
    send -- "y\r"
    # FIXME: The following line is required on Yubikey 4, but I'm not sure how
    # to fix this right now.
    #expect -exact "Mode set! You must remove and re-insert your YubiKey for this change to take effect."
    expect eof
  }
}

# Set up PIN, PUK, and then generate keys on card.

send_user "Now generating your GPG keys on the Yubikey itself.\n"
spawn gpg --card-edit

expect -exact "gpg/card> "
send -- "admin\r"

# https://developers.yubico.com/PGP/Card_edit.html

expect -exact "gpg/card> "
send -- "passwd\r"

expect -exact "Your selection? "
send -- "1\r"

expect -exact "Your selection? "
send -- "3\r"

expect -exact "Your selection? "
send -- "q\r"

# Set desired key attributes.

expect -exact "gpg/card> "
send -- "key-attr\r"

# Signature key.
expect -exact "Your selection? "
# RSA
send -- "1\r"

expect "What keysize do you want? (*) "
send -- "4096\r"

# Encryption key.
expect -exact "Your selection? "
# RSA
send -- "1\r"

expect "What keysize do you want? (*) "
send -- "4096\r"

# Authentication key.
expect -exact "Your selection? "
# RSA
send -- "1\r"

expect "What keysize do you want? (*) "
send -- "4096\r"

# Time to generate.

expect -exact "gpg/card> "
send -- "generate\r"

expect -exact "Make off-card backup of encryption key? (Y/n) "
send -- "n\r"

expect -exact "Key is valid for? (0) "
send -- "10y\r"

expect -exact "Is this correct? (y/N) "
send -- "y\r"

expect -exact "Real name: "
send -- "$realname\r"

expect -exact "Email address: "
send -- "$email\r"

expect -exact "Comment: "
send -- "$comment\r"

expect -exact "Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? "
send -- "O\r"

send_user "\nNow generating keys on card, lights will be flashing, this will take a few minutes, please wait...\n"

expect -exact "gpg/card> "
send -- "quit\r"

expect eof

# Turn on touch for signature.

send_user "Now requiring you to touch your Yubikey to sign any message.\n"
spawn ykman openpgp touch sig on
expect -exact "Set touch policy of SIGNATURE key to ON? \[y/N\]: "
send -- "y\r"

expect -exact "Enter admin PIN: "
stty -echo
expect_user -re "(.*)\n"
set puk $expect_out(1,string)
send -- "$puk\r"

expect eof

# Turn on touch for authentication.

send_user "Now requiring you to touch your Yubikey to authenticate SSH.\n"
spawn ykman openpgp touch aut on
expect -exact "Set touch policy of AUTHENTICATION key to ON? \[y/N\]: "
send -- "y\r"

expect -exact "Enter admin PIN: "
stty -echo
expect_user -re "(.*)\n"
set puk $expect_out(1,string)
send -- "$puk\r"

expect eof

