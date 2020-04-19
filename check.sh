function title() {
  printf "%-20s: " "${1}"
}

function maintitle() {
  echo "**** ${1} ****"
}

function xml() {
  # $1 - URL
  # $2 - xpath
  # $3 - echo string
  title "${3}"
  curl -s "${1}" 2>&1 | xmllint --xpath "${2}" -
}

function linux() { 
  maintitle "Linux Kernel Releases"
  curl -s "https://www.kernel.org/feeds/kdist.xml" 2>&1 | xmllint --xpath "//item/title/text()" -
}

function html() {
  # $1 - URL
  # $2 - xpath
  # $3 - echo string
  title "${3}"
  curl -s "${1}" 2>&1 | tidy -q --show-warnings no | xmllint --html --xpath "${2}" 2>&1 -  
}

function oracle() {
  maintitle "ORACLE"
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
      tidy -q --show-warnings no  -w 100000 | \
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
title "tomcat ${1}"
curl -s "http://mirror.vorboss.net/apache/tomcat/tomcat-${1}/?C=M;O=D" 2>&1 | \
     tidy -q --show-warnings no | \
	 xmllint --html --xpath "string(/html/body//a[starts-with(@href,\"v9.0\")][1]/@href)" - | \
	 cut -d '/' -f 1
}

function owasp() {
  maintitle "OWASP"
  xml "https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml" "/ZAP/core/version/text()" "ZAP"
  github "OWASP/Amass" "Amass"
  github "jeremylong/DependencyCheck" "Dependency-Check"
}

function jsframeworks() {
  maintitle "JS FRAMEWORKS"
  github "jquery/jquery" "jquery"
  github "jquery/jquery-ui" "jquery-ui"
  github "jquery/jquerymobile.com" "jquery-mobile"
  github "twbs/bootstrap" "Bootstrap"
  github "handlebars-lang/handlebars.js" "Handlebars"
  github "requirejs/requirejs" "Require"
}

function apache() {
  maintitle "APACHE"
  html "https://mirrors.ukfast.co.uk/sites/ftp.apache.org/jmeter/binaries/" "string(/html/body/pre/a[3]/@href)" "jmeter"
  html "http://mirror.vorboss.net/apache/httpd/" "string(//a[contains(@href, \".tar.gz\")]/@href)" "httpd"
  tomcat 9
}

function nginx() {
  maintitle "NGINX"
  atom "http://hg.nginx.org/nginx/atom-log" "nginx"
}

function misc() {
  maintitle "MISC"
  sqlite
  github "virustotal/yara" "YARA"
  github "java-decompiler/jd-gui" "jd-gui"
  github "aircrack-ng/aircrack-ng" "aircrack-ng"
  github "openssl/openssl" "OpenSSL"
}

oracle
nginx
apache
jsframeworks
owasp
misc
linux
