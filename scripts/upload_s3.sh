#!/bin/bash
file=$1
bucket=YOUR_BUCKET
resource="/${bucket}/${file}"
contentType="application/x-itunes-ipa"
dateValue=`date -R`
stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
s3Key=YOUR_KEY_HERE
s3Secret=YOUR_SECRET
echo "SENDING TO S3"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
curl -vv -X PUT -T "${file}" \
  -H "Host: ${bucket}.s3.amazonaws.com" \
  -H "Date: ${dateValue}" \
  -H "Content-Type: ${contentType}" \
  -H "Authorization: AWS ${s3Key}:${signature}" \

https://${bucket}.s3.amazonaws.com/${file}
