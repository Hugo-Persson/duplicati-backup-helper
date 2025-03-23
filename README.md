# About

A simple helper to quickly setup backups with duplicati cli

## Setup

First run `install.sh` to setup dependencies

## Getting Duplicati URL

1. Go to Azure
2. Storage accounts
3. Create a new storage account, store the name
4. Go to blob containers and create a new container
5. Go to Access keys and copy the key
6. URL Encode the key
7. Replace in this url: `azure://<CONTAINER_NAME>?auth-username=<STORAGE_ACCOUNT_NAME>&auth-password=<URL_ENCODED_KEY>`

## Setting up .env

Copy the `example.env` to `.env` and fill in the values.

## Running the script

Add the backup.sh to your cronjobs or run it manually.
A cron job should look like this

```
0 4 * * * /path/to/backup.sh # Run the backup every day at 4am
```
