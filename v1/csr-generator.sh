filename=sample

while true
do
  echo "1. Email DV"
  echo "2. Email OV"
  echo "3. TLS"
  read -p "Choice: " choice

  case $choice in
    "1") TYPE="email-dv" ;;
    "2") TYPE="email-ov" ;;
    "3") TYPE="tls" ;;
    "4") break ;;
    *) continue ;;
  esac

  openssl req -newkey rsa:2048 -keyout ${filename}.key -out ${filename}.csr -config conf/${TYPE}-openssl.conf -nodes
  echo -e "\nCSR for ${TYPE} certificate:\n"
  cat ${filename}.csr

  break

done
