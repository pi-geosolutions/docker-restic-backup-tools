# SSHD backup toolbox

Debian Docker container with `sshd` exposed and `restic` and a few useful tools installed.

Provides sufficient tools to restore data backup up using restic.

This is probably useable in most restic use-cases, although it is meant for specific use:
backup through SFTP on a synology NAS (see below for how to set the env var for this use-case)

## Environment variables

### Environment var (needed)

- `SSH_ROOT_AUTHORIZED_KEYS` or `SSH_ROOT_AUTHORIZED_KEYS_FILE` SSH public key(s) that will be allowed to connect as root to this service
- `HOST`: hostname as it will be remembered by restic backups.
- `SSHD_CONFIG_SECRET` (kubernetes secret, optional): path to a kubernetes secret, providing an SSH key pair to consistently identify this container
- `RESTIC_REPOSITORY` cf [restic's documentation](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html)
- `RESTIC_PASSWORD_FILE` cf [restic's documentation](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html)
- `RESTIC_OPTION` restic allows you to set some options. For SFTP connection, using an option, you can define tricky stuff on the ssh connection, like port, load password without exposing it, etc
- `SSH_RSA_PRIVATE_KEY_FILE` (optional) allows you to set the private RSA key file for the root user. Can be useful to allow push on some git repos
- `KEEP_POLICY`: policy for clearing old backups. See https://restic.readthedocs.io/en/stable/060_forget.html. Default is `--keep-daily 7 --keep-weekly 5 --keep-monthly 12` which means 1 snapshot for each one of the 7 last days + 1 snapshot for each one of the 4 following weeks + 1 snapshot for each of the 12 last months. Applies only to house-keeping.sh script, that does the cleaning (call the container with this script as command)

There are specific env vars, documented in the following section

### Backup through SFTP on a synology NAS.
It was a bit tricky because of the way a synology NAS handles paths. And also because I only had
password access (no ssh key access).

I'm using `sshpass` tool for this, to read the password from a file (actually a docker secret).
Here is a template of my configuration:
```
RESTIC_REPOSITORY=sftp:myusername@my.nas.server.syn:/georchestra/restic_bk
RESTIC_PASSWORD_FILE=/run/secrets/restic_passwd
RESTIC_OPTION=/run/secrets/restic_sftp_option
```
where the restic_sftp_option's content looks like
```
sftp.command="sshpass -f/run/secrets/my_ssh_passwd ssh -p 2222 -o StrictHostKeyChecking=no myusername@my.nas.server.syn -s sftp"
```

## Usage
### SSH console
This is the default behaviour. It creates a container into which you can ssh. From there, you will have a properly configured restic instance, allowing you to manipulate your backups, run manual backups etc.

### run-once crontabbed containers
You can also execute a container on a regular basis, as a run-once container. This can be used to automate backups. There are a few scripts available for

#### Volume backup
The command `bash -c /root/scripts/backup-using-restic.sh` runs, by default, a backup on all folders mounted in /mnt. You can add a parameter, that will be the base directory that is backed up (e.g. `bash -c /root/scripts/backup-using-restic.sh /DBS` will backup all folders under /DBS)

#### Database backups
**LDAP**
The command `bash -c /root/scripts/backup-georchestra-ldap.sh` runs a ldapsearch command. This is georchestra-specific, it backs-up orgs, roles and users.
You need to provide the following env vars:
- LDAP_HOST=ldap.georchestra
- LDAP_PORT=389
- LDAP_ADMIN=cn=admin,dc=georchestra,dc=org
- LDAP_PASSWORD_FILE=/run/secrets/slapd_passwd
- DUMP_ONLY: if set to "yes", it will only create the dump file, but won't back it up with restic.

The host needs to be accessible from this container.

**Postgresql**
The command `bash -c /root/scripts/backup-postgresql-db.sh` runs a pg_dumpall command, saving the whole database.
You need to provide the following env vars:
- POSTGRES_USER=georchestra
- POSTGRES_PASSWORD_FILE=/run/secrets/georchestra_postgresql_passwd
- POSTGRES_HOST=database.georchestra
- POSTGRES_PORT=5432
- DUMP_ONLY: if set to "yes", it will only create the dump file, but won't back it up with restic.

The host needs to be accessible from this container.

**Mysql**
The command `bash -c /root/scripts/backup-mysql-db.sh` runs a mysqldump command, saving the whole database.
You need to provide the following env vars:
- MYSQL_USER=root
- MYSQL_PASSWORD_FILE=/run/secrets/wp_db_root_password
- MYSQL_HOST=db.cms
- MYSQL_PORT=3306
- DUMP_ONLY: if set to "yes", it will only create the dump file, but won't back it up with restic.

The host needs to be accessible from this container.

### Restic excludes
You can customize the excludes by creating your own image on top of this one and overriding the `/root/root/.restic/restic-excludes.txt` file.

## Testing
To test this locally and make use of the secrets, you will need to create the files (see `secrets` section in the dockerfile)
and set the relevant information on them. **Don't commit** those files as they might contain sensitive information...

## Scripting
The configuration is written on /root/.resticrc file. It is sourced by .bashrc, so root should have access to it when connecting through ssh on
opening a bash session.
But for scripting, you need to load the configuration. You can start your scripts by this snippet:
```
shopt -s expand_aliases
source /root/.resticrc
```
