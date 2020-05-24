#!/bin/bash

# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
# https://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
NORMAL=$(tput sgr0)

function title() {
  printf "%-20s: " "${1}"
}

function entry() {
  # entry <title> <date> <version>
  printf "%-25s: %-37s: %s" "${MAGENTA}${1}" "${YELLOW}${2}" "${GREEN}${3}"
  echo -e "${NORMAL}"
}

function maintitle() {
  echo ""
  # use the -e flag for escapes
  echo -e "${RED}**** ${1} ****${NORMAL}"
}

function xml() {
  # $1 - URL
  # $2 - xpath
  # $3 - echo string
  entry "${3}" "" $(curl -s "${1}" 2>&1 | xmllint --xpath "${2}" -)
}

rss_atom_extract() {
  TITLE_XPATH="${3}"
  DATE_XPATH="${4}"
  OUTPUT=$(curl -s "${2}")
  DATE_OUTPUT=$(echo -n "${OUTPUT}" | xmllint --nocdata --xpath "${DATE_XPATH}" --xmlout -)
  TITLE_OUTPUT=$(echo -n "${OUTPUT}" | xmllint --nocdata --xpath "${TITLE_XPATH}" --xmlout -)

  entry "${1}" "${DATE_OUTPUT}" "${TITLE_OUTPUT}"
}

function rss() {
  TITLE_XPATH="/rss/channel/item[1]/title/text()"
  DATE_XPATH="/rss/channel/item[1]/pubDate/text()"

  rss_atom_extract "${2}" "${1}" "${TITLE_XPATH}" "${DATE_XPATH}"
}

function atom() {
  TITLE_XPATH="//*[local-name()='feed']/*[local-name()='entry'][1]/*[local-name()='title']/text()"
  DATE_XPATH="//*[local-name()='feed']/*[local-name()='entry'][1]/*[local-name()='updated']/text()"
  
  rss_atom_extract "${2}" "${1}" "${TITLE_XPATH}" "${DATE_XPATH}"  
}

function linux() { 
  maintitle "Linux Kernel Releases"
  curl -s "https://www.kernel.org/feeds/kdist.xml" 2>&1 | xmllint --xpath "//item/title/text()" -
}

function html() {
  # $1 - URL
  # $2 - xpath
  # $3 - echo string
  entry "${3}" "" $(curl -s "${1}" 2>&1 | tidy -q --show-warnings no | xmllint --html --xpath "${2}" 2>&1 -)
}

function java() {
  # linux-x64.tar.gz
  maintitle "JAVA"

  title "Oracle Java 8"
  curl -s "https://www.oracle.com/java/technologies/javase-jre8-downloads.html" 2>&1 | \
    tidy -q --show-warnings no | \
    xmllint --html --xpath "string(//a[contains(@href,\".zip\")]/text())" - 2>&1
}

function oracle() {
  maintitle "ORACLE"

  entry "ORDS" "" $(curl -s "https://www.oracle.com/database/technologies/appdev/rest-data-services-downloads.html" 2>&1 | \
    tidy -q --show-warnings no | \
	xmllint --html --xpath "string(//a[contains(@data-file,\".zip\")]/@data-file)" - 2>&1 | \
	grep -i ".zip" | \
	rev | cut -d '/' -f 1 | rev)

  rss "https://www.oracle.com/ocom/groups/public/@otn/documents/webcontent/rss-otn-sec.xml" "CPU"
}

function github() {
  # $1 - URL
  # $2 - echo string
  atom "https://github.com/${1}/releases.atom" "${2}"
}

function sqlite() {
  OUTPUT=$(curl -s "https://www.sqlite.org/chronology.html")
  entry "sqlite" "" $(echo -n ${OUTPUT} | \
    tidy -q --show-warnings no | \
	xmllint --html -xpath "//tr/td/a[contains(@href,\"releaselog\")]" - | \
	xmllint --html -xpath "//a[1]/text()" -)
}

function tomcat() {
  OUTPUT=$(curl -s "http://mirror.vorboss.net/apache/tomcat/tomcat-${1}/?C=M;O=D" 2>&1)
  entry "tomcat ${1}" "" $(echo -n ${OUTPUT} | \
     tidy -q --show-warnings no | \
	 xmllint --html --xpath "string(/html/body//a[starts-with(@href,\"v9.0\")][1]/@href)" - | \
	 cut -d '/' -f 1)
}

function pentest() {
  maintitle "PENTESTING TOOLS"
  xml "https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml" "/ZAP/core/version/text()" "OWASP ZAP"
  github "OWASP/Amass" "OWASP Amass"
  github "jeremylong/DependencyCheck" "Dependency-Check"
  github "NationalSecurityAgency/ghidra" "NSA Ghidra"
  github "virustotal/yara" "YARA"
  github "java-decompiler/jd-gui" "jd-gui"
  github "aircrack-ng/aircrack-ng" "aircrack-ng"
  rss "https://portswigger.net/burp/releases/rss" "BURP Suite"  
}

function jsframeworks() {
  maintitle "JS FRAMEWORKS"
  github "jquery/jquery" "jquery"
  github "jquery/jquery-ui" "jquery-ui"
  github "jquery/jquerymobile.com" "jquery-mobile"
  github "twbs/bootstrap" "Bootstrap"
  github "handlebars-lang/handlebars.js" "Handlebars"
  github "requirejs/requirejs" "Require"
  github "select2/select2" "Select2"
}

function apache() {
  maintitle "APACHE"
  html "https://mirrors.ukfast.co.uk/sites/ftp.apache.org/jmeter/binaries/" "string(/html/body/pre/a[3]/@href)" "jmeter"
  html "http://mirror.vorboss.net/apache/httpd/" "string(//a[contains(@href, \".tar.gz\")]/@href)" "httpd"
  tomcat 9
}

function nginx() {
  maintitle "NGINX"
  atom "http://hg.nginx.org/nginx/atom-tags" "nginx"
  github "nginx/unit" "nginx unit"
}

function misc() {
  maintitle "MISC"
  sqlite
  github "openssl/openssl" "OpenSSL"
  github "curl/curl" "cURL"
  github "kivy/buildozer" "Buildozer"
  github "kivy/kivy" "Kivy"
  github "intel/Intel-Linux-Processor-Microcode-Data-Files" "Intel ucode"
}

oracle
nginx
apache
jsframeworks
pentest
misc
linux

TMP=$(read -n 1)
