function current_config() {
    conf_file=conf/${TYPE}-openssl.conf

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
    openssl req -newkey rsa:2048 -keyout ${filename}.key -out ${filename}.csr -config conf/${TYPE}-openssl.conf -nodes
    echo -e "\nCSR for ${TYPE} certificate:\n"

    current_config

    cat ${filename}.csr
    echo -e "\n"
}

function edit_conf() {

    current_config
  
    read -p "CN: " set_cn
    read -p "SAN 1: " set_san1
    read -p "SAN 2: " set_san2
    read -p "Email: " set_email
 
    #search_email=$(grep -E -o "CN = \b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" ${conf_file})

    sed -i "s/$conf_cn/CN = $set_cn/g" $conf_file
    sed -i "s/$conf_san1/DNS.1 = $set_san1/g" $conf_file
    sed -i "s/$conf_san2/DNS.2 = $set_san2/g" $conf_file
    sed -i "s/$conf_email/emailAddress = $set_email/g" $conf_file

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
    "1") TYPE="email-dv"; generate_csr ${TYPE} ;;
    "2") TYPE="email-ov"; generate_csr ${TYPE} ;;
    "3") TYPE="tls"; generate_csr ${TYPE} ;;
    "4") TYPE="custom"; edit_conf ;;
    *) continue ;;
  esac

  break

done
