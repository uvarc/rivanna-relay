#!/bin/sh

set -e

chmod 600 /root/.ssh/id_rsa

QCOUNT=`/usr/local/bin/aws sqs get-queue-attributes --queue-url "$QURL" --attribute-names "ApproximateNumberOfMessages" | /bin/jq -r .Attributes.ApproximateNumberOfMessages`
echo $QCOUNT

if [ "$QCOUNT" -gt 0 ]; then

  # Do something with the queue
  RAW=`/usr/local/bin/aws sqs receive-message \
    --message-attribute-names "All" \
    --max-number-of-messages 1 \
    --queue-url "$QURL" \
    --wait-time-seconds 20`;

  INPUT=`echo $RAW | /bin/jq -r .Messages[0].MessageAttributes.input.StringValue`;
  OUTPUT=`echo $RAW | /bin/jq -r .Messages[0].MessageAttributes.output.StringValue`;

  export INPUT
  export OUTPUT

  # PROD :: Submit a SLURM job using these values
  RCMD+="/bin/bash "
  RCMD+="$REMOTE_SCRIPT"
  /usr/bin/ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa $USERID@rivanna.hpc.virginia.edu $RCMD $INPUT $OUTPUT

  # Delete the message now
  RECEIPTHANDLE=`echo $RAW | /bin/jq -r .Messages[0].ReceiptHandle`;
  /usr/local/bin/aws sqs delete-message \
    --queue-url "$QURL" \
    --receipt-handle "$RECEIPTHANDLE";

else

  # Do nothing. No messages.
  echo "No files"
  exit 0

fi

exit 0
