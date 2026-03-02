#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  MiniJarvis — Full Cleanup${NC}"
echo -e "${CYAN}================================================${NC}"

stop_and_remove() {
  local name=$1
  if docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
    echo -e "${CYAN}[*] Stopping container: ${name}${NC}"
    docker stop "$name" 2>/dev/null
    echo -e "${CYAN}[*] Removing container: ${name}${NC}"
    docker rm "$name" 2>/dev/null
  else
    echo -e "    Container '${name}' not found — skipping."
  fi
}

remove_image() {
  local image=$1
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${image}$"; then
    echo -e "${CYAN}[*] Removing image: ${image}${NC}"
    docker rmi "$image" 2>/dev/null
  elif docker images --format '{{.Repository}}' | grep -q "^${image}$"; then
    echo -e "${CYAN}[*] Removing image: ${image}${NC}"
    docker rmi "$image" 2>/dev/null
  else
    echo -e "    Image '${image}' not found — skipping."
  fi
}

stop_and_remove "ollama-chat"
stop_and_remove "ollama"

remove_image "ollama-chat-ui"
remove_image "ollama/ollama"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}  Done! All MiniJarvis containers and images${NC}"
echo -e "${GREEN}  have been removed.${NC}"
echo -e "${GREEN}================================================${NC}"
