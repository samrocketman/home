# Create a socks proxy using SSH

    ssh -ND 1080 <some other host>

Configure your normal browser to use that as a SOCKSv5 proxy (`localhost:1080`).

This is useful for connecting to remote servers via SSH and browse the web from
the perspective of that server.
