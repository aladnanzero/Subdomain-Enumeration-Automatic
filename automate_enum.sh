#!/bin/bash

# checking inpute
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

domain=$1

# Make output folder
output_dir="$domain/recon"
mkdir -p $output_dir/{httprobe,potential_takeovers,wayback}

# Step 1: Subdomain Enumeration with Assetfinder
echo "[+] Finding subdomains with assetfinder..."
assetfinder $domain | sort -u > $output_dir/subdomains.txt
echo "[+] Subdomains saved to $output_dir/subdomains.txt"

# Step 2: Filtering Alive Domains with Httprobe
echo "[+] Probing for alive domains..."
cat $output_dir/subdomains.txt | httprobe | sort -u > $output_dir/httprobe/alive.txt
echo "[+] Alive domains saved to $output_dir/httprobe/alive.txt"

# Step 3: Checking for Subdomain Takeover with Subjack
echo "[+] Checking for subdomain takeover..."
subjack -w $output_dir/subdomains.txt -t 100 -timeout 30 -ssl -v 3 -o $output_dir/potential_takeovers/takeovers.txt
echo "[+] Subdomain takeover results saved to $output_dir/potential_takeovers/takeovers.txt"

# Step 4: Scraping Wayback Data
echo "[+] Scraping Wayback Machine data..."
cat $output_dir/subdomains.txt | waybackurls | sort -u > $output_dir/wayback/urls.txt
echo "[+] Wayback URLs saved to $output_dir/wayback/urls.txt"

# Step 5: Extracting Parameters from Wayback Data
echo "[+] Extracting parameters from Wayback data..."
cat $output_dir/wayback/urls.txt | grep '?*=' | cut -d '=' -f 1 | sort -u > $output_dir/wayback/params.txt
echo "[+] Parameters saved to $output_dir/wayback/params.txt"

# Step 6: Extracting Files with Specific Extensions
echo "[+] Extracting JS, JSON, PHP, and ASPX files..."
for url in $(cat $output_dir/wayback/urls.txt); do
  ext="${url##*.}"
  case $ext in
    js) echo $url >> $output_dir/wayback/js_files.txt ;;
    json) echo $url >> $output_dir/wayback/json_files.txt ;;
    php) echo $url >> $output_dir/wayback/php_files.txt ;;
    aspx) echo $url >> $output_dir/wayback/aspx_files.txt ;;
  esac
done
echo "[+] File extraction completed. Check $output_dir/wayback/ for results."

# Final Output Summary
echo "---------------------------------------"
echo "Enumeration Completed!"
echo "Subdomains: $output_dir/subdomains.txt"
echo "Alive domains: $output_dir/httprobe/alive.txt"
echo "Takeover checks: $output_dir/potential_takeovers/takeovers.txt"
echo "Wayback URLs: $output_dir/wayback/urls.txt"
echo "Wayback Params: $output_dir/wayback/params.txt"
echo "---------------------------------------"
