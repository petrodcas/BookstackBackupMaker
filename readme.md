# BookstackBackupMaker

Image to backup my K8S Bookstack's data (compressed and encrypted with gpg) to a privated git repository.

## Build Variables

|Variable|Description|Required|Default Value|
|:------:|:----------|:------:|:-----------:|
|`TAG`|Alpine's tag|No|`latest`|

## Environment Variables

|Variable|Description|Required|Default Value|
|:------:|:----------|:------:|:-----------:|
|`APP_DATA_DIR`|Path to Bookstack's App Data that must be mounted on this container|No|`/appdata`|
|`BACKUP_KEY_FILE`|Path to the gpg key backup file|Yes|--|
|`CC_MAILS`|`,`, `;` or ` ` separated list of CC mails|No|--|
|`COPY_DIR`|Path to the copy directory|No|`/copy`|
|`DB_HOST`|Database host|Yes|--|
|`DB_PASSWORD`|Database password|Yes|--|
|`DB_PORT`|Database port|No|`3306`|
|`DB_USER`|Database user. Root prefered, since it is a full database backup|Yes|--|
|`DUMP_FILE_NAME`|Name of the dump file|No|`dump.sql`|
|`GIT_EMAIL`|Git user.email. Only used for git config|Yes|--|
|`GIT_USERNAME`|Git user.name. Only used for git config|Yes|--|
|`KEY_MAIL`|GPG key's mail|Yes|--|
|`KEY_PASS`|GPG Key's password|Yes|--|
|`MAIL_CONTENT`|Mail content|No|--|
|`MAIL_DOMAIN`|Mail domain|Yes|--|
|`MAIL_PASSWORD`|Mail password. It does not accept MFA, so create an app password if needed (on gmail or microsoft365)|No|--|
|`MAIL_SENDER`|Mail sender|Yes|--|
|`MAIL_SUBJECT`|Mail subject|Yes|--|
|`PRIVATE_SSH_KEY_FILE`|Path to the private ssh key file used for git repository|Yes|--|
|`RECIPIENT_MAILS`|`,` or `;` separated list of recipient mails|Yes|--|
|`REPOSITORY_URL`|Git repository url (SSH one). It's on the form git@github*.git|Yes|--|
|`SMTP_HOST`|SMTP server|Yes|--|
|`SMTP_PORT`|SMTP port|No|`587`|
|`SSHDIR`|Path to the ssh directory|No|`~/.ssh`|
|`TAR_FILE_NAME`|Name of the tar file. The name of the file updated to github will be derived from the tar file's name|No|`backup.tar.gz`|

## Create the Backup Key

```bash
gpg --full-generate-key
```

## Export the Backup Key

```bash
gpg --output output-file-name --armor --export-secret-keys --export-options export-backup user@email
```

## Restore the File Pushed to Github

```bash
gpg --recipient <key-mail> --output <output-file-name> --decrypt <input-file-name> | tar -xzvf -
```
