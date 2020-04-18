function title() {
  printf "%-20s: " "${1}"
}

function xml() {
  # $1 - URL
  # $2 - xpath
  # $3 - echo string
  title "${3}"
  #echo -n "${3}="
  curl -s "${1}" 2>&1 | xmllint --xpath "${2}" -
}

function linux() { 
  echo ""
  echo "Linux Kernel Releases"
  echo "*********************"
  curl -s "https://www.kernel.org/feeds/kdist.xml" 2>&1 | xmllint --xpath "//item/title/text()" -
}

function html() {
  # $1 - URL
  # $2 - xpath
  # $3 - echo string
  title "${3}"
  curl -s "${1}" 2>&1 | tidy -q --show-warnings no | xmllint --html --xpath "${2}" 2>&1 -  
}

function ords() {
  title "ORDS"
  curl -s "https://www.oracle.com/database/technologies/appdev/rest-data-services-downloads.html" 2>&1 | \
    tidy -q --show-warnings no | \
	xmllint --html --xpath "string(//a[contains(@data-file,\".zip\")]/@data-file)" - 2>&1 | \
	grep -i ".zip" | \
	rev | cut -d '/' -f 1 | rev
}

function atom() {
  title "${2}"
  curl -s "${1}" 2>&1 | \
      xmllint --xpath "//*[local-name()='feed']/*[local-name()='entry']/*[local-name()=\"title\"]" --xmlout - | \
      tidy -q --show-warnings no | \
	  xmllint --html --xpath "//title[1]/text()" - 
}

function github() {
  # $1 - URL
  # $2 - echo string
  atom "https://github.com/${1}/releases.atom" "${2}"
}

function sqlite() {
  title "sqlite"
  curl -s "https://www.sqlite.org/chronology.html" | \
    tidy -q --show-warnings no | \
	xmllint --html -xpath "//tr/td/a[contains(@href,\"releaselog\")]" - | \
	xmllint --html -xpath "//a[1]/text()" -
}

function tomcat() {
title "Tomcat ${1}"
curl -s "http://mirror.vorboss.net/apache/tomcat/tomcat-${1}/?C=M;O=D" 2>&1 | \
     tidy -q --show-warnings no | \
	 xmllint --html --xpath "string(/html/body//a[starts-with(@href,\"v9.0\")][1]/@href)" - | \
	 cut -d '/' -f 1
}

ords
sqlite
html "https://mirrors.ukfast.co.uk/sites/ftp.apache.org/jmeter/binaries/" "string(/html/body/pre/a[3]/@href)" "jmeter"
html "http://mirror.vorboss.net/apache/httpd/" "string(//a[contains(@href, \".tar.gz\")]/@href)" "httpd"
github "jquery/jquery" "jquery"
github "jquery/jquery-ui" "jquery-ui"
github "jquery/jquerymobile.com" "jquery-mobile"
xml "https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml" "/ZAP/core/version/text()" "OWASP ZAP"
github "OWASP/Amass" "OWASP Amass"
github "virustotal/yara" "YARA"
github "java-decompiler/jd-gui" "jd-gui"
github "aircrack-ng/aircrack-ng" "aircrack-ng"
github "openssl/openssl" "OpenSSL"
atom "http://hg.nginx.org/nginx/atom-log" "nginx"
tomcat 9
linux
