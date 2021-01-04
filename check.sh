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

function github_entry() {
  # entry <title> <date> <latest version> <latest tag>
  printf "%-27s: %-37s: %s (%s)" "${MAGENTA}${1}" "${YELLOW}${2}" "${GREEN}${3:0:60}" "${4:0:30}"
  echo -e "${NORMAL}"
}

function github() {
  # $1 - URL
  # $2 - echo string
  # $3 - use github api? (N)

  source creds.config 

  GITHUB_RELEASES_URL="https://api.github.com/repos/${1}/releases/latest"
  GITHUB_TAGS_URL="https://api.github.com/repos/${1}/tags"

  # Only use the GITHUB api if specified to do so
  if [ "${3}" = "Y" ]
  then
    curl -s -u "${GITHUB_USERNAME}:${GITHUB_TOKEN}" -o github_releases.json "${GITHUB_RELEASES_URL}"

    LATEST_RELEASE_VERSION=$(jq -r ".tag_name" github_releases.json)
    LATEST_RELEASE_DATE=$(jq -r ".created_at" github_releases.json)

    curl -s -u "${GITHUB_USERNAME}:${GITHUB_TOKEN}" -o github_tags.json "${GITHUB_TAGS_URL}"

    # Unfortunately, github do not have a "get the latest tag" (even though tags have timestamps!)
    # Tag names in github follow the semver rules (https://semver.org/)
    # TODO: This should omit all "non-semver" tags really
    LATEST_TAG=$(jq -r ".[0].name" github_tags.json)

    #rm github_releases.json github_tags.json

    github_entry "$2" "${LATEST_RELEASE_DATE}" "${LATEST_RELEASE_VERSION}" "${LATEST_TAG}"
  else
    atom "https://github.com/${1}/releases.atom" "${2}"
  fi
}

function entry() {
  # entry <title> <date> <latest version>
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
  curl -s "https://www.kernel.org/feeds/kdist.xml" 2>&1 | xmllint --xpath "//item/title/text()" -
}

function html() {
  # $1 - URL
  # $2 - xpath
  # $3 - echo string
  entry "${3}" "" $(curl -s "${1}" 2>&1 | tidy -q --show-warnings no | xmllint --html --xpath "${2}" 2>&1 -)
}

function oracle() {
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

function sqlite() {
  OUTPUT=$(curl -s "https://www.sqlite.org/chronology.html")
  entry "sqlite" "" $(echo -n ${OUTPUT} | \
    tidy -q --show-warnings no | \
	xmllint --html -xpath "//tr/td/a[contains(@href,\"releaselog\")]" - | \
	xmllint --html -xpath "//a[1]/text()" -)
}

function httpd() {
  html "http://mirror.vorboss.net/apache/httpd/" "string(//a[contains(@href, \".tar.gz\")]/@href)" "httpd"
}

function tomcat() {
  OUTPUT=$(curl -s "http://mirror.vorboss.net/apache/tomcat/tomcat-${1}/?C=M;O=D" 2>&1)
  entry "tomcat ${1}" "" $(echo -n ${OUTPUT} | \
     tidy -q --show-warnings no | \
	 xmllint --html --xpath "string(/html/body//a[starts-with(@href,\"v${1}\")][last()]/@href)" - | \
	 cut -d '/' -f 1)
}

function fuse() {
  github "cryfs/cryfs" "cryfs"
  github "libfuse/sshfs" "sshfs"
  github "rfjakob/gocryptfs" "gocryptfs"
  github "thkala/fuseflt" "fuseflt"
}

function owasp() {
  xml "https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml" "/ZAP/core/version/text()" "OWASP ZAP"
  github "OWASP/Amass" "OWASP Amass"
  github "coreruleset/coreruleset" "OWASP Core Rule Set"
  github "OWASP/ASVS" "OWASP ASVS"
  github "OWASP/owasp-masvs" "OWASP MASVS" "Y"
  github "OWASP/wstg" "OWASP WSTG"
  github "jeremylong/DependencyCheck" "OWASP Dependency Check"
  github "DependencyTrack/dependency-track" "OWASP Dependency Track"
}

function pentest() {
  github "NationalSecurityAgency/ghidra" "NSA Ghidra"
  github "virustotal/yara" "YARA"
  github "OSUSecLab/InputScope" "InputScope"
  github "libinjection/libinjection" "libinjection"
  github "SpiderLabs/ModSecurity" "ModSecurity"
  github "SpiderLabs/ModSecurity-nginx" "ModSecurity-nginx"
  github "java-decompiler/jd-gui" "jd-gui"
  github "aircrack-ng/aircrack-ng" "aircrack-ng"
  github "skylot/jadx" "jadx"
  github "sqlmapproject/sqlmap" "sqlmap"
  github "rapid7/metasploit-framework" "MetaSploit"
  github "apache/jmeter" "Apache Jmeter"  
  github "cloudlinux/kcare-uchecker" "Uchecker"
  github "insidersec/insider" "Insider"
  github "pmd/pmd" "PMD"
  rss "https://portswigger.net/burp/releases/rss" "BURP Suite"

  # IDS
  github "snort3/snort3" "Snort 3"

  owasp
}

function python() {
  github "Legrandin/pycryptodome" "pycryptodome" "Y"
  github "Demonware/jose" "jose"
  github "jpadilla/pyjwt" "pyjwt"
  github "kivy/buildozer" "Buildozer"
  github "kivy/kivy" "Kivy"
  github "psf/requests" "PSF requests"
  github "psf/requests-html" "PSF Requests-HTML"
  github "datastax/python-driver" "cassandra-driver"
  github "pinterest/pymemcache" "pymemcache"
  github "ytdl-org/youtube-dl" "youtube-dl"
  github "aio-libs/aiohttp" "aiohttp"
  github "certifi/python-certifi" "certifi"
}

function nps() {
  github "jquery/jquery" "jquery"
  github "jquery/jquery-ui" "jquery-ui"
  github "jquery/jquerymobile.com" "jquery-mobile"
  github "jquery/jquery-mousewheel" "jquery-mousewheel"

  # This project is not maintained and superceded by js-cookie/js-cookie
  # but this is used in s4atb
  github "carhartl/jquery-cookie" "jquery-cookie"

  github "hammerjs/hammer.js" "hammer"
  github "twbs/bootstrap" "Bootstrap" "Y"
  github "handlebars-lang/handlebars.js" "Handlebars"
  github "requirejs/requirejs" "Require"
  github "requirejs/almond" "Almond"
  github "requirejs/i18n" "Require i18n"
  github "select2/select2" "Select2" "Y"
  github "jsplumb/jsPlumb" "jsplumb"
  github "davidshimjs/qrcodejs" "qrcode.js" "Y"
  github "jeffreykemp/jk64-plugin-simplemap" "Simple Google Map"
  github "RonnyWeiss/Apex-Fancy-Tree-Select" "Apex Fancy Tree"
  github "antonscheffer/excel2collections" "Excel2Collection"
  github "Dani3lSun/apex-plugin-timeline" "Timeline"
  github "Pretius/apex-nested-reports" "Nested Reports" "Y"
  github "glebovpavel/IR_to_MSExcel" "IR to MSExcel"
  github "guillaumepotier/Parsley.js" "Parsley JS"
  oracle
  tomcat 9
  github "eclipse/jetty.project" "Eclipse Jetty"
  github "curl/curl" "curl"
  github "swagger-api/swagger-editor" "Swagger Editor"
}

function misc() {
  sqlite
  github "denoland/deno" "Deno"
  github "pivpn/pivpn" "PiVPN"
  github "openssl/openssl" "OpenSSL"  
  github "jenkinsci/jenkins" "Jenkins"
  github "swagger-api/swagger-editor" "Swagger Editor"
  github "swagger-api/swagger-ui" "Swagger UI"
  github "Kong/kong" "Kong"
  github "hockeypuck/hockeypuck" "HockeyPuck (HKP)"
  github "intel/Intel-Linux-Processor-Microcode-Data-Files" "Intel ucode"
}

function emu() {
  github "midwan/amiberry" "Amiberry"
  github "RetroPie/RetroPie-Setup" "RetroPie" "Y"
}

function http() {
#  maintitle "HTTP"
  github "allinurl/goaccess" "goaccess"
  github "curl/curl" "curl"
  httpd
  tomcat 8
  tomcat 9
  tomcat 10
  atom "http://hg.nginx.org/nginx/atom-tags" "nginx"
  github "nginx/unit" "nginx unit"  
  github "openresty/openresty" "openresty"
  github "eclipse/jetty.project" "Eclipse Jetty"
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
  OWASP)
    owasp
    ;;
  PENTEST)
    pentest
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
  NPS)
    nps
    ;;
  EMU)
    emu
    ;;
  *)
    maintitle "ORACLE"
    oracle
    maintitle "HTTP"
    http
    maintitle "PYTHON"
    python 
    maintitle "FUSE FS"
    fuse
    maintitle "PENTESTING"
    pentest
    maintitle "MISC"
    misc
    maintitle "EMU"
    emu
    maintitle "Linux Kernel Releases"
    linux
    ;;
esac

TMP=$(read -n 1)
