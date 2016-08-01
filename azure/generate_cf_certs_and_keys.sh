#!/bin/bash
set -ex

generate_certs_and_keys () {
  country_name="US"
  state="New York"
  locality="New York"
  organisation="Pivotal"
  organisational_unit="Cloud Foundry"
  subdomain="pcf-gemfire.com"
  env_name="${2}"
  common_name="${env_name}.${subdomain}"

  openssl genrsa -out private.key 2048 &&
    echo -e "\n\n\n\n\n\n\n"
    openssl req \
            -sha256 \
            -new \
            -key private.key \
            -out public_cert.pem \
            -subj "/C=${country_name}/ST=${state}/L=${locality}/O=${organisation}/OU=${organisational_unit}/CN=*.${common_name}"

    openssl x509 -req \
            -days 5000 \
            -in public_cert.pem \
            -signkey private.key \
            -out public_cert.pem \
            -extfile <(
            cat <<-EOF
                basicConstraints=critical,CA:true,pathlen:0
                subjectAltName=DNS:*.system.${env_name}.pcf-gemfire.com,DNS:*.apps.${env_name}.pcf-gemfire.com,DNS:*.uaa.system.${env_name}.pcf-gemfire.com,DNS:*.login.system.${env_name}.pcf-gemfire.com
EOF
      )
  cat public_cert.pem private.key > "${1}"
  rm public_cert.pem private.key
}

if [[ -z $1 ]]; then
  echo "Usage: ./generate_cf_certs_and_keys.sh [options] <PATH TO DIR>"
  echo "Options:"
  echo "    -y|--yes    Always overwrite files"
  echo "    -n|--no     Never overwrite files"
  exit 1
fi

MODE=ask
while true
do
  case $1 in
    -y|--yes)
      MODE=overwrite
      shift
      ;;
    -n|--no)
      MODE=keep
      shift
      ;;
    *)
      break
      ;;
  esac
done

certs_and_keys_dir=$1

mkdir -p $certs_and_keys_dir/cf
pushd $certs_and_keys_dir/cf


for file in ha_proxy_ssl_pem loginha_proxy_ssl_pem jwt_signing_key; do
  var=${file}_flag
  declare "${var}=false"
  if [ -f $file ]; then
    action=
    [ "$MODE" == "overwrite" ] && action=y
    [ "$MODE" == "keep" ] && action=n
    if [ -z "$action" ]
    then
      echo -n "$file already exists. Do you want to recreate it? (y/n)"
      read action
    fi

    if [[ $action == 'y' ]]; then
     declare "${var}=true"
    fi
  else
    declare "${var}=true"
  fi
done

if [[ $ha_proxy_ssl_pem_flag == true ]]; then
  echo -e "\n\n=== GENERATING HAPROXY CERT ===\n"
  generate_certs_and_keys ha_proxy_ssl_pem
fi

if [[ $loginha_proxy_ssl_pem_flag == true ]]; then
  echo -e "\n\n=== GENERATING LOGIN HAPROXY CERT ===\n"
  generate_certs_and_keys loginha_proxy_ssl_pem
fi

if [[ $jwt_signing_key_flag == true ]]; then
  echo -e "\n\n=== GENERATING JWT KEY ===\n"
  rm -f jwt_signing_key jwt_verification_key
  openssl genrsa -out jwt_signing_key  2048
  openssl rsa -pubout -in jwt_signing_key -out jwt_verification_key
fi

ls -l

popd

echo -e "\n\nFinished generating certs and keys."
