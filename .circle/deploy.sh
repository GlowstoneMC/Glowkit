sftp -b .circle/upload_jd leaf@glowstone.gserv.me
ssh -t leaf@glowstone.gserv.me "./deploy_javadocs.sh"
