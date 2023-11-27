#!/bin/sh

source ./validators.sh
validateEnvvars

fullregex='.*:[^/]+/.*\.git$'
reporegex='.*:[^/]+\/(.*)\.git$'

concat() {
  arg="$1"
  arg="${arg%/}"
  echo "${COPY_DIR%/}/${arg#/}"
}

replace() {
  token="$1"
  value="$2"
  file="/root/.msmtprc"

  sed -i "s/$token/$value/g" "$file"
}

replace '${SMTP_HOST}' "${SMTP_HOST}"
replace '${SMTP_PORT}' "${SMTP_PORT}"
replace '${MAIL_SENDER}' "${MAIL_SENDER}"
replace '${MAIL_PASSWORD}' "${MAIL_PASSWORD}"
replace '${MAIL_DOMAIN}' "${MAIL_DOMAIN}"

sendNotification() {
  echo -e "Subject: ${MAIL_SUBJECT}\nTo:${RECIPIENT_MAILS}\nCC:${CC_MAILS}\n\n${MAIL_CONTENT}" | msmtp --file="/root/.msmtprc" -a custom ${RECIPIENT_MAILS} ${CC_MAILS}
}

mkdir -p "${COPY_DIR}"
doIfPrevWas --error 'printerr "ERROR CREATING COPY DIR: $COPY_DIR"; sendNotification; exit 1' --success "printok \"COPY DIR '$COPY_DIR' CREATED SUCCESSFULLY\""

# Import keys
printinf "IMPORTING KEYS"
gpg --batch --passphrase "${KEY_PASS}" --import "${BACKUP_KEY_FILE}"
doIfPrevWas --error 'printerr "ERROR IMPORTING KEYS"; sendNotification; exit 1' --success 'printok "KEYS IMPORTED SUCCESSFULLY"'
echo -e "trust\n5\ny\n" | gpg --command-fd 0 --batch --edit-key "${KEY_MAIL}"
doIfPrevWas --error 'printerr "ERROR TRUSTING KEYS"; sendNotification; exit 1' --success 'printok "KEYS TRUSTED SUCCESSFULLY"'
printinf "KEYS IMPORTED AND TRUSTED SUCCESSFULLY"

# Create file to upload
printinf "COPYING ${APP_DATA_DIR} TO ${COPY_DIR}"
cp -a "${APP_DATA_DIR}" "${COPY_DIR}"
doIfPrevWas --error 'printerr "ERROR COPYING FILES"; sendNotification; exit 1' --success 'printok "FILES COPIED SUCCESSFULLY"'
printinf "DOING MYSQL BACKUP"
MYSQL_PWD="${DB_PASSWORD}" mysqldump -h "${DB_HOST}" -u "${DB_USER}" -P "${DB_PORT}" --routines --all-databases --flush-privileges --single-transaction --add-drop-database --add-drop-table --add-drop-trigger --result-file="$(concat "${DUMP_FILE_NAME}")" --verbose
doIfPrevWas --error 'printerr "ERROR DOING MYSQL BACKUP"; sendNotification; exit 1' --success 'printok "MYSQL BACKUP DONE SUCCESSFULLY"'
printinf "CREATING TARFILE"
tar -czvf "${TAR_FILE_NAME}" -C "${COPY_DIR}" .
doIfPrevWas --error 'printerr "ERROR CREATING TARFILE"; sendNotification; exit 1' --success 'printok "TARFILE CREATED SUCCESSFULLY"'
printinf "ENCRYPTING TARFILE"
gpg --recipient "${KEY_MAIL}" --batch --encrypt "${TAR_FILE_NAME}"
doIfPrevWas --error 'printerr "ERROR ENCRYPTING TARFILE"; sendNotification; exit 1' --success 'printok "TARFILE ENCRYPTED SUCCESSFULLY"'

# Clone project and substitute file

if [ $(echo "${REPOSITORY_URL}" | grep -E "$fullregex") ]
then
  reponame=$(echo "${REPOSITORY_URL}" | sed -rn "s/$reporegex/\1/p")
else
  printerr "Could not extract repository name from the url."
  exit 1
fi

printinf "PREPARING TO UPDATE TO GITHUB"

mkdir -p "${SSHDIR}" && cp "${PRIVATE_SSH_KEY_FILE}" "${SSHDIR}/id_rsa" && chmod 500 "${SSHDIR}/id_rsa"
doIfPrevWas --success 'printok "SSH KEY COPIED SUCCESSFULLY"' --error 'printerr "ERROR COPYING SSH KEY"; sendNotification; exit 1'
eval "$(ssh-agent -s)" && ssh-add "${SSHDIR}/id_rsa"
doIfPrevWas --success 'printok "SSH KEY ADDED SUCCESSFULLY"' --error 'printerr "ERROR ADDING SSH KEY"; sendNotification; exit 1'
git config --global user.email "${GIT_EMAIL}"
doIfPrevWas --success 'printok "GIT CONFIGURED user.email SUCCESSFULLY"' --error 'printerr "ERROR CONFIGURING GIT user.email"; sendNotification; exit 1'
git config --global user.name "${GIT_USERNAME}"
doIfPrevWas --success 'printok "GIT CONFIGURED user.name SUCCESSFULLY"' --error 'printerr "ERROR CONFIGURING GIT user.name"; sendNotification; exit 1'
git clone -v "${REPOSITORY_URL}"
doIfPrevWas --success 'printok "GIT CLONED SUCCESSFULLY"' --error 'printerr "ERROR CLONING GIT"; sendNotification; exit 1'
cp "${TAR_FILE_NAME}.gpg" "$reponame"
doIfPrevWas --success 'printok "TARFILE COPIED SUCCESSFULLY INTO GIT REPO DIR"' --error 'printerr "ERROR COPYING TARFILE INTO GIT REPO DIR"; sendNotification; exit 1'
cd $reponame && git add . && git commit -m "test" && git push
doIfPrevWas --success 'printok "GIT PUSHED SUCCESSFULLY"' --error 'printerr "ERROR PUSHING GIT"; sendNotification; exit 1'
