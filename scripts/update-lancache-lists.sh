#!/bin/bash

echo ""
echo "============================================"
echo "Updating LANCache CDN lists"
echo "============================================"

CUR_DIR=$(pwd)
REPO_DIR=${HOME}/git/cache-domains/scripts/
DNSMASQ_DIR=${HOME}/docker/pihole/dnsmasq.d/
HOSTS_DIR=${HOME}/docker/pihole/dnsmasq/hosts/
DOCKER_NAME=pihole
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Fetch master branch from uklans
cd "${REPO_DIR}"
{
  git fetch origin
  git diff master origin/master
} &> /dev/null

# Check for changes with local master branch
if git merge-base --is-ancestor origin/master master; then
  echo "No update required."
else
  echo "Updating CDN lists..."
  {
    # Update master
    git checkout master
    git pull origin master
    # Rebase fixes branch on new master
    git checkout fixes
    git rebase master
    # Rebase custom branch on fixes branch
    git checkout DragonQ
    git rebase fixes
    # Push custom branch to github fork
    git push -f DragonQ master
    git push -f DragonQ fixes
    git push -f DragonQ DragonQ
    # Update pihole dnsmasq
    ./create-dnsmasq.sh
    sudo cp -rf ./output/dnsmasq/*.conf ${DNSMASQ_DIR}
    sudo cp -rf ./output/dnsmasq/hosts/* ${HOSTS_DIR}
  } &> /dev/null
  # Restart pihole to update lancache domains
  echo "Restarting Pi-hole DNS..."
  PATH="${PATH}" docker exec ${DOCKER_NAME} pihole restartdns
  echo "Done!"
fi

cd "${CUR_DIR}"
