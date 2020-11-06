#!/bin/bash

# Syntax: ./check.sh OR ./check.sh LINUX

SECTION="$1"

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
  printf "%-27s: %-37s: %s" "${MAGENTA}${1}" "${YELLOW}${2}" "${GREEN}${3:0:60}"
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

  github "utPLSQL/utPLSQL-SQLDeveloper" "utPLSQL SQLDeveloper"
  github "utPLSQL/utPLSQL" "utPLSQL"
  github "Trivadis/plsql-unwrapper-sqldev" "PL/SQL Unwrapper"

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
	 xmllint --html --xpath "string(/html/body//a[starts-with(@href,\"v${1}\")][1]/@href)" - | \
	 cut -d '/' -f 1)
}

function fuse() {
  maintitle "FUSE FS"
  github "cryfs/cryfs" "cryfs"
  github "libfuse/sshfs" "sshfs"
  github "rfjakob/gocryptfs" "gocryptfs"
  github "thkala/fuseflt" "fuseflt"
}

function pentest() {
  maintitle "PENTESTING"
  github "NationalSecurityAgency/ghidra" "NSA Ghidra"
  github "virustotal/yara" "YARA"
  github "OSUSecLab/InputScope" "InputScope"
  github "java-decompiler/jd-gui" "jd-gui"
  github "aircrack-ng/aircrack-ng" "aircrack-ng"
  github "skylot/jadx" "jadx"
  github "sqlmapproject/sqlmap" "sqlmap"
  github "rapid7/metasploit-framework" "MetaSploit"
  github "apache/jmeter" "Apache Jmeter"  
  github "cloudlinux/kcare-uchecker" "Uchecker"
  github "insidersec/insider" "Insider"
  rss "https://portswigger.net/burp/releases/rss" "BURP Suite"

  # IDS
  github "snort3/snort3" "Snort 3"

  # OWASP tools
  xml "https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml" "/ZAP/core/version/text()" "OWASP ZAP"
  github "OWASP/Amass" "OWASP Amass"
  github "SpiderLabs/owasp-modsecurity-crs" "OWASP Core Rule Set"
  github "OWASP/ASVS" "OWASP ASVS"
  github "OWASP/wstg" "OWASP WSTG"
  github "jeremylong/DependencyCheck" "OWASP Dependency Check"
  github "DependencyTrack/dependency-track" "OWASP Dependency Track"
}

function js() {
  maintitle "JS FRAMEWORKS"
  github "denoland/deno" "Deno"
  github "jquery/jquery" "jquery"
  github "jquery/jquery-ui" "jquery-ui"
  github "jquery/jquerymobile.com" "jquery-mobile"
  github "twbs/bootstrap" "Bootstrap"
  github "handlebars-lang/handlebars.js" "Handlebars"
  github "requirejs/requirejs" "Require"
  github "select2/select2" "Select2"
  github "jsplumb/jsPlumb" "jsplumb"
}

function python() {
  maintitle "Python"
  github "Legrandin/pycryptodome" "pycryptodome"
  github "Demonware/jose" "jose"
  github "jpadilla/pyjwt" "pyjwt"
  github "kivy/buildozer" "Buildozer"
  github "kivy/kivy" "Kivy"
  github "psf/requests" "PSF requests"
  github "psf/requests-html" "PSF Requests-HTML"
  github "datastax/python-driver" "cassandra-driver"
  github "pinterest/pymemcache" "pymemcache"
}

function misc() {
  maintitle "MISC"
  sqlite
  github "pivpn/pivpn" "PiVPN"
  github "openssl/openssl" "OpenSSL"  
  github "jenkinsci/jenkins" "Jenkins"
  github "swagger-api/swagger-editor" "Swagger Editor"
  github "swagger-api/swagger-ui" "Swagger UI"
  github "Kong/kong" "Kong"
  github "intel/Intel-Linux-Processor-Microcode-Data-Files" "Intel ucode"
  github "RetroPie/RetroPie-Setup" "RetroPie"
}

function http() {
  maintitle "HTTP"
  github "allinurl/goaccess" "goaccess"
  github "curl/curl" "curl"
  html "http://mirror.vorboss.net/apache/httpd/" "string(//a[contains(@href, \".tar.gz\")]/@href)" "httpd"
  tomcat 8
  tomcat 9
  tomcat 10
  atom "http://hg.nginx.org/nginx/atom-tags" "nginx"
  github "nginx/unit" "nginx unit"  
  github "openresty/openresty" "openresty"
}

case "$SECTION" in
  ORACLE)
    oracle
    ;;
  HTTP)
    http
    ;;
  PYTHON)
    python
    ;;
  PENTEST)
    pentest
    ;;
  JS)
    js
    ;;
  FUSE)
    fuse 
    ;;
  MISC)
    misc
    ;;
  LINUX)
    linux
    ;;
  *)
    oracle
    http
    python 
    js
    fuse
    pentest
    misc
    linux
    ;;
esac

TMP=$(read -n 1)
