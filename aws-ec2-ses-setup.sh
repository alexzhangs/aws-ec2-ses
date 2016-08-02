#!/bin/bash

[[ DEBUG -gt 0 ]] && set -x

usage () {
    printf "Setup Sendmail to use AWS SES SMTP server on an EC2 instance. Run this script on the remote EC2 instance.\n"
    printf "Use sudo to run this script as root.\n"
	printf "${0##*/}\n"
    printf "\t-d SES_DOMAIN\n"
    printf "\t-r REGION\n"
    printf "\t-u SMTP_USERNAME\n"
    printf "\t-p SMTP_PASSWORD\n"
    printf "\t-m SMTP_AUTH_METHOD\n"
    printf "\t[-t TEST_EMAIL_SEND_TO]\n"
    printf "\t[-h]\n\n"

    printf "OPTIONS\n"
    printf "\t-d SES_DOMAIN\n\n"
    printf "\tDomain setup in AWS SES.\n\n"

    printf "\t-r REGION\n\n"
    printf "\tAWS Region used by SES.\n\n"

    printf "\t-u SMTP_USERNAME\n\n"
    printf "\tUsername of AWS SES SMTP.\n\n"

    printf "\t-p SMTP_PASSWORD\n\n"
    printf "\tUsername of AWS SES SMTP.\n\n"

    printf "\t-m SMTP_AUTH_METHOD\n\n"
    printf "\tSMTP authentication method.\n\n"

    printf "\t[-t TEST_EMAIL_SEND_TO]\n\n"
    printf "\tAn Email address to test this setup.\n\n"


    printf "\t[-h]\n\n"
    printf "\tThis help.\n\n"
    exit 255
}

while getopts d:r:u:p:m:t:h opt; do
    case $opt in
        d)
            SES_DOMAIN=$OPTARG
            ;;
        r)
            REGION=$OPTARG
            ;;
        u)
            SMTP_USERNAME=$OPTARG
            ;;
        p)
            SMTP_PASSWORD=$OPTARG
            ;;
        m)
            SMTP_AUTH_METHOD=$OPTARG
            ;;
        t)
            TEST_EMAIL_SEND_TO=$OPTARG
            ;;
        h|*)
            usage
            ;;
    esac
done

[[ -z $SES_DOMAIN || -z $REGION || -z $SMTP_USERNAME || -z $SMTP_PASSWORD || -z $SMTP_AUTH_METHOD ]] && usage

# sendmail-cf
echo "Installing sendmail-cf"
yum install -y m4 sendmail-cf || exit

# /etc/mail/authinfo
echo "Modifying /etc/mail/authinfo"
cat > /etc/mail/authinfo << EOF || exit
AuthInfo:email-smtp.${REGION}.amazonaws.com "U:root" "I:${USERNAME}" "P:${PASSWORD}" "M:${SMTP_AUTH_METHOD}"
EOF

# /etc/mail/authinfo.db
echo "Generating /etc/mail/authinfo.db"
makemap hash /etc/mail/authinfo.db < /etc/mail/authinfo || exit

# /etc/mail/access
echo "Modifying /etc/mail/access"
LINE="Connect:email-smtp.${REGION}.amazonaws.com RELAY"
if ! grep "$LINE" /etc/mail/access; then
	echo "$LINE" >> /etc/mail/access || exit
fi

# /etc/mail/access.db
echo "Generating /etc/mail/access.db"
makemap hash /etc/mail/access.db < /etc/mail/access || exit

# Variables
mark_begin="# BEGIN == Generated by ${0##*/}"
mark_end="# END == Generated by ${0##*/}"
config="
define(\`SMART_HOST', \`email-smtp.${REGION}.amazonaws.com')dnl
define(\`RELAY_MAILER_ARGS', \`TCP \$h 25')dnl
define(\`confAUTH_MECHANISMS', \`LOGIN ${SMTP_AUTH_METHOD}')dnl
FEATURE(\`authinfo', \`hash -o /etc/mail/authinfo.db')dnl
MASQUERADE_AS(\`${SES_DOMAIN}')dnl
FEATURE(masquerade_envelope)dnl
FEATURE(masquerade_entire_domain)dnl
"

# /etc/mail/sendmail.mc
echo "Modifying /etc/mail/sendmail.mc"
inject_to_file -c "$config" -f /etc/mail/sendmail.mc \
               -p before \
               -b "^MAILER" \
               -m "$mark_begin" \
               -n "$mark_end" \
               -x "$mark_begin" \
               -y "$mark_end" || exit

# /etc/mail/sendmail.cf
echo "Generating /etc/mail/sendmail.cf"
m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf || exit

# Restart Sendmail service
service sendmail restart || exit

# Send test Email to verify the installation
if [[ -n $TEST_EMAIL_SEND_TO ]]; then
    echo "Sending test Email to TEST_EMAIL_SEND_TO"
    sendmail -F "${0##*/}" -f "no-reply@$SES_DOMAIN" -t "$TEST_EMAIL_SEND_TO" << EOF
Subject: ${0##*/} test Email
To: $TEST_EMAIL_SEND_TO
This is a test Email sent from AWS EC2 instance through AWS SES SMTP service.
EOF
fi

exit
