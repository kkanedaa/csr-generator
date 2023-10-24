#!/bin/bash
#
#-----------------------------------#
#    Configure the values below     # 
#-----------------------------------#

# Company information

conf_org="MPKI5000003 - Firma Muster AG"
conf_state="Glattbrugg"
conf_locality="Zurich"
conf_country="CH"

# Config for Email DV
dv_email="email@email.com"

# Config for Email OV:
ov_email="email@email.com"
ov_cn="Name Surname" #Can also be "pseudo: XYZ"

# Config for TLS:
tls_cn="kaneda.ch"
tls_san1="kaneda.ch"
tls_san2="www.kaneda.ch"

#-----------------------------------#

function generate_config() {

  cat <<EOF > ${conf_file}
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    prompt = no

    [req_distinguished_name]
    C = ${conf_country}
    ST = ${conf_state}
    L = ${conf_locality}
    O = ${conf_org}
    CN =
    emailAddress =

    [v3_req]
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 =
    DNS.2 =
EOF

  case ${TYPE} in
    "email-dv")
      sed -i "s/CN =/CN = $dv_email/g" ${conf_file}
      sed -i "s/emailAddress =/emailAddress = $dv_email/g" ${conf_file}
      sed -i -e "3d;13,19d" ${conf_file}
    ;;
    "email-ov")
      sed -i "s/CN =/CN = $ov_cn/g" ${conf_file}
      sed -i "s/emailAddress =/emailAddress = $ov_email/g" ${conf_file}
      sed -i -e "3d;13,19d" ${conf_file}
    ;;
    "tls")
      sed -i "s/CN =/CN = $tls_cn/g" ${conf_file}
      sed -i "s/DNS.1 =/DNS.1 = $tls_san1/g" ${conf_file}
      sed -i "s/DNS.2 =/DNS.2 = $tls_san2/g" ${conf_file}
      sed -i -e "12d" ${conf_file}
    ;;
    "custom") : ;;
  esac

  # Remove leading whitespaces
  # sed -e "s/^[ \t]*//" tmp_edit.conf
}

function current_config() {

  # Get values in the config file
  from_conf_cn=$(grep -i "CN =" ${conf_file})
  from_conf_san1=$(grep -i "DNS.1 =" ${conf_file})
  from_conf_san2=$(grep -i "DNS.2 =" ${conf_file})
  from_conf_email=$(grep -i "emailAddress =" ${conf_file})

  # check if var is not empty and print value
  [ -n "$from_conf_cn" ] && echo -e "${from_conf_cn}"
  [ -n "$from_conf_san1" ] && echo -e "${from_conf_san1}"
  [ -n "$from_conf_san2" ] && echo -e "${from_conf_san2}"
  [ -n "$from_conf_email" ] && echo -e "${from_conf_email}"
  echo -e "\n"
}

function generate_csr() {
  
  openssl req -newkey rsa:2048 -keyout ${filename}.key -out ${filename}.csr -config ${conf_file} -nodes
  echo -e "\nCSR for ${TYPE} certificate:\n"

  current_config

  cat ${filename}.csr
  echo -e "\n"
}

function edit_conf() {

while true
  do
    echo -e ""
    read -p "CN: " set_cn
    read -p "SAN 1: " set_san1
    read -p "SAN 2: " set_san2
    read -p "Email: " set_email

    if [ -n "$set_cn" ]; then sed -i "s/CN =/CN = ${set_cn}/g" ${conf_file}; else echo -e "\nC'mon dawg, CN cannot be empty."; continue; fi
    # If SAN1 (DNS.1) is not set, the vlaue will be the one specified in CN
    [ -n "$set_san1" ] && sed -i "s/DNS.1 =/DNS.1 = ${set_san1}/g" ${conf_file} || sed -i "s/DNS.1 =/DNS.1 = ${set_cn}/g" ${conf_file}
    [ -n "$set_san2" ] && sed -i "s/DNS.2 =/DNS.2 = ${set_san2}/g" ${conf_file} || sed -i -e "/DNS.2 =/d" ${conf_file}
    [ -n "$set_email" ] && sed -i "s/emailAddress =/emailAddress = ${set_email}/g" ${conf_file} || sed -i -e "/emailAddress =/d" ${conf_file}
    break
  done
}

conf_file=/tmp/openssl.conf
filename=sample

while true
do
  echo "1. Email DV"
  echo "2. Email OV"
  echo "3. TLS"
  echo -e "4. Custom\n"
  read -p "Choice: " choice

  case $choice in
    "1") TYPE="email-dv"; generate_config; generate_csr ${TYPE} ;;
    "2") TYPE="email-ov"; generate_config; generate_csr ${TYPE} ;;
    "3") TYPE="tls"; generate_config; generate_csr ${TYPE} ;;
    "4") TYPE="custom"; generate_config; edit_conf; generate_csr ${TYPE} ;;
    *) continue ;;
  esac

  break

done
