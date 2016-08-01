# aws-ec2-ses

Setup sendmail to use AWS SES Service send Email on EC2 instance.

## Installation

```
git clone https://github.com/alexzhangs/aws-ec2-ses
sudo sh aws-ec2-ses/install.sh
```

## Usage

aws-ec2-ses-setup needs to be run under root.

```
aws-ec2-ses-setup
	-d SES_DOMAIN
	-r REGION
	-u SMTP_USERNAME
	-p SMTP_PASSWORD
    -m SMTP_AUTH_METHOD
	[-t TEST_EMAIL_SEND_TO]
	[-h]

OPTIONS
	-d SES_DOMAIN

	Domain setup in AWS SES.

	-r REGION

	AWS Region used by SES.

	-u SMTP_USERNAME

	Username of AWS SES SMTP.

	-p SMTP_PASSWORD

	Username of AWS SES SMTP.

    -m SMTP_AUTH_METHOD

    SMTP authentication method.

	[-t TEST_EMAIL_SEND_TO]

	An Email address to test this setup.

	[-h]

	This help.
```
