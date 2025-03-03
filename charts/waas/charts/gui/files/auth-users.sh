#!/usr/bin/env bash

# Validations
[ -z $GUI_USER ] && echo "ERROR: GUI_USER is empty or not defined" && exit 1
[ -z $GUI_PASSWORD ] && echo "ERROR: GUI_PASSWORD is empty or not defined" && exit 1

function create_identity_svc_configuration(){
    mkdir -p ${KEYS_FOLDER}

    # Generate Private/Public RSA keys pair
    openssl genrsa -out ${KEYS_FOLDER}/id.key 4096
    openssl rsa -in ${KEYS_FOLDER}/id.key -pubout -outform PEM -out ${KEYS_FOLDER}/id.key.pub
    echo "${GUI_AUTH_PASSPHRASE}" > ${KEYS_FOLDER}/passphrase
}

# Create htpasswd
mkdir -p ${USERS_FOLDER}
htpasswd -b -c ${USERS_FOLDER}/.htpasswd "${GUI_USER}" "${GUI_PASSWORD}" || exit 2
create_identity_svc_configuration

exit 0