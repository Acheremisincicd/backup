#!/usr/bin/expect
set timeout 10
set username "[lindex $argv 0]"
set password "[lindex $argv 1]"
set email    "[lindex $argv 2]"
set TO       "[lindex $argv 3]"
set SUBJECT  "[lindex $argv 4]"
set BODY     "[lindex $argv 5]"
spawn openssl s_client -starttls smtp -connect smtp.gmail.com:587 -crlf -ign_eof
    
    expect "250" {
        send  "helo 1233\n"

    expect "250" { 
        send  "auth login\n"

    expect "334"  { 
        send  "$username\n"

    expect "334"  {  
        send "$password\n"

    expect "235" { 
        send "mail from:<$email>\n"

    expect "250" { 
        send   "rcpt to:<$TO>\n"

    expect "250" {
         send "DATA\n"
    expect "354" { 
        send   "From: $email\n" 
        send   "To:$TO\n"
        send   "Subject: $SUBJECT \n"
        send   "$BODY \n"
        send   ".\n"
    expect "250" {
        send   "QUIT"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


