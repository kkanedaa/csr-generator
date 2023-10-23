#!/bin/bash
#
#-----------------------------------#
# Configure the values below        # 
#-----------------------------------#

# Config for Email DV
dv_email="kei.kaneda@swisssign.com"

# Config for Email OV:
ov_email="kei.kaneda@swisssign.com"
ov_cn="Kei Kaneda"

# Config for TLS:
tls_cn="kaneda.ch"
tls_san1="kaneda.ch"
tls_san2="www.kaneda.ch"

#-----------------------------------#

function generate_config() {

  cat <<EOF > tmp.conf
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    prompt = no

    [req_distinguished_name]
    C = CH
    ST = Glattbrugg
    L = ZH
    O = MPKI5000003 - Firma Muster AG
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
      sed -i "s/CN =/CN = $dv_email/g" tmp.conf
      sed -i "s/emailAddress =/emailAddress = $dv_email/g" tmp.conf
      sed "3d;13,19d" tmp.conf > tmp_edit.conf
      rm tmp.conf
    ;;
    "email-ov")
      sed -i "s/CN =/CN = $ov_cn/g" tmp.conf
      sed -i "s/emailAddress =/emailAddress = $ov_email/g" tmp.conf
      sed "3d;13,19d" tmp.conf > tmp_edit.conf
      rm tmp.conf
    ;;
    "tls")
      sed -i "s/CN =/CN = $tls_cn/g" tmp.conf
      sed -i "s/DNS.1 =/DNS.1 = $tls_san1/g" tmp.conf
      sed -i "s/DNS.2 =/DNS.2 = $tls_san2/g" tmp.conf
      sed "12d" tmp.conf > tmp_edit.conf
      rm tmp.conf
    ;;
    "custom") 
      mv tmp.conf tmp_edit.conf
    ;;
  esac

  # Remove leading whitespaces
  # sed -e "s/^[ \t]*//" tmp_edit.conf
}

function current_config() {

  conf_file=tmp_edit.conf

  # Get values in the config file
  conf_cn=$(grep -i cn ${conf_file})
  conf_san1=$(grep -i DNS.1 ${conf_file})
  conf_san2=$(grep -i DNS.2 ${conf_file})
  conf_email=$(grep -i email ${conf_file})

  # check if var is not empty and print value
  [ -n "$conf_cn" ] && echo -e "${conf_cn}"
  [ -n "$conf_san1" ] && echo -e "${conf_san1}"
  [ -n "$conf_san2" ] && echo -e "${conf_san2}"
  [ -n "$conf_email" ] && echo -e "${conf_email}"
  echo -e "\n"
}

function generate_csr() {
  
  openssl req -newkey rsa:2048 -keyout ${filename}.key -out ${filename}.csr -config tmp_edit.conf -nodes
  echo -e "\nCSR for ${TYPE} certificate:\n"

  current_config

  cat ${filename}.csr
  rm ${conf_file}
  echo -e "\n"
}

function edit_conf() {

  conf_file=tmp_edit.conf  

  echo -e ""
  read -p "CN: " set_cn
  read -p "SAN 1: " set_san1
  read -p "SAN 2: " set_san2
  read -p "Email: " set_email

  sed -i "s/CN =/CN = $set_cn/g" $conf_file
  sed -i "s/DNS.1 =/DNS.1 = $set_san1/g" $conf_file
  sed -i "s/DNS.2 =/DNS.2 = $set_san2/g" $conf_file
  sed -i "s/emailAddress =/emailAddress = $set_email/g" $conf_file

  generate_csr
}

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
    "4") TYPE="custom"; generate_config; edit_conf ;;
    *) continue ;;
  esac

  break

done
