__author__ = 'T.Vo'
#!/usr/bin/python

import smtplib

sender = 'from@fromdomain.com'
receivers = ['t.vo@aswigsolutions.com']

message = """From: From Person <from@fromdomain.com>
To: To Person <to@todomain.com>
Subject: SMTP e-mail test

This is a test e-mail message.
"""

try:
    smtpObj = smtplib.SMTP('10.9.0.22')
    smtpObj.sendmail(sender, receivers, message)
    print "Successfully sent email"
    except SMTPException:
    print "Error: unable to send email"
