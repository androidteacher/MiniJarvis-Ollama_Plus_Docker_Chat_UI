#!/bin/bash

# ANSI color codes for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}                 Ollama Quick Setup Script                      ${NC}"
echo -e "${CYAN}================================================================${NC}"
echo -e "${YELLOW}Disclaimer:${NC} This script will deploy an Ollama Docker container"
echo -e "and then download a 1 Gigabyte Large Language Model (llama3.2:1b)."
echo -e "${CYAN}================================================================${NC}"
echo -ne "\n${YELLOW}Do you want to proceed? [y/N]: ${NC}"
read proceed

if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborting setup.${NC}"
    exit 0
fi

echo -e "\n${CYAN}[*] Checking for Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[!] Docker is not installed or not in your PATH.${NC}"
    echo -e "Please install Docker first to proceed. You can gracefully install it by running:"
    echo -e "  ${YELLOW}sudo apt update && sudo apt install docker.io -y${NC}"
    echo -e "After installing Docker, please re-run this script."
    exit 1
fi
echo -e "${GREEN}[+] Docker is installed.${NC}"

echo -e "\n${CYAN}[*] Starting Ollama container...${NC}"
# Run Ollama in detached mode with persistent volume and exposed port
docker run -d \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  -e OLLAMA_ORIGINS="*" \
  --name ollama \
  --name ollama \
  ollama/ollama

if [ $? -ne 0 ]; then
    echo -e "${RED}[!] Failed to start the Ollama container.${NC}"
    echo -e "It might already exist, or port 11434 might be in use."
    exit 1
fi

echo -e "${GREEN}[+] Ollama container started in background.${NC}"

echo -e "\n${CYAN}[*] Waiting for Ollama service to become ready...${NC}"
sleep 5 # Give the service inside the container a few seconds to start

# ---- Model Selection ----
echo -e "\n${CYAN}================================================================${NC}"
echo -e "${GREEN}                    Model Selection                             ${NC}"
echo -e "${CYAN}================================================================${NC}"
echo -e ""
echo -e "  ${GREEN}1) llama3.2:1b${NC}       — General Purpose           ${YELLOW}(~1 GB) ★ RECOMMENDED${NC}"
echo -e "  ${CYAN}2)${NC} qwen2.5:1.5b      — Excellent for Coding/Math  (~1 GB)"
echo -e "  ${CYAN}3)${NC} deepseek-r1:1.5b   — Optimized for Reasoning    (~1 GB)"
echo -e "  ${CYAN}4)${NC} gemma2:2b          — Google's efficient model   (~1.6 GB)"
echo -e "  ${CYAN}5)${NC} stablelm2:1.6b     — Very lightweight and fast  (~1 GB)"
echo -e "  ${CYAN}6)${NC} phi3.5:latest      — Larger but very capable    (~2.2 GB)"
echo -e ""
echo -e "${YELLOW}We STRONGLY advise you type 'y' here and use the default LLM${NC}"
echo -e "${YELLOW}as it is small and will most likely perform the best in your${NC}"
echo -e "${YELLOW}virtual machine. (You are running a virtual machine, aren't you!)${NC}"
echo -e ""
echo -ne "${YELLOW}Type 'y' for the default or enter a number [1-6]: ${NC}"
read model_choice

# Map selection to model name
case "$model_choice" in
    2)  MODEL="qwen2.5:1.5b" ;;
    3)  MODEL="deepseek-r1:1.5b" ;;
    4)  MODEL="gemma2:2b" ;;
    5)  MODEL="stablelm2:1.6b" ;;
    6)  MODEL="phi3.5:latest" ;;
    *)  MODEL="llama3.2:1b" ;;
esac

echo -e "\n${CYAN}[*] Downloading ${GREEN}${MODEL}${CYAN} (This may take a while depending on your connection)...${NC}"
docker exec -it ollama ollama pull "$MODEL"

if [ $? -ne 0 ]; then
    echo -e "${RED}[!] Failed to pull the model.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Model ${MODEL} downloaded successfully!${NC}"

# ---- Build and launch the Chat Web UI ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\n${CYAN}[*] Building the Chat Web UI container...${NC}"
docker build -t ollama-chat-ui "$SCRIPT_DIR/web"

if [ $? -ne 0 ]; then
    echo -e "${RED}[!] Failed to build the Chat UI image.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Chat UI image built.${NC}"

echo -e "\n${CYAN}[*] Starting the Chat Web UI on port 8888...${NC}"
docker run -d \
  --name ollama-chat \
  -p 8888:80 \
  --add-host=host.docker.internal:host-gateway \
  ollama-chat-ui

if [ $? -ne 0 ]; then
    echo -e "${RED}[!] Failed to start the Chat UI container.${NC}"
    echo -e "It might already exist, or port 8888 might be in use."
    exit 1
fi

echo -e "${GREEN}[+] Chat UI is running!${NC}"

echo ""
echo -e "${CYAN}    ****************************************************${NC}"
echo -e "${CYAN}    *                                                  *${NC}"
echo -e "${CYAN}    *${NC}   ${GREEN}Setup complete! Everything is up and running.${NC}  ${CYAN}*${NC}"
echo -e "${CYAN}    *                                                  *${NC}"
echo -e "${CYAN}    *${NC}      ${YELLOW}Access your Chat interface at:${NC}             ${CYAN}*${NC}"
echo -e "${CYAN}    *${NC}                                                  ${CYAN}*${NC}"
echo -e "${CYAN}    *${NC}         ${GREEN}http://localhost:8888${NC}                    ${CYAN}*${NC}"
echo -e "${CYAN}    *                                                  *${NC}"
echo -e "${CYAN}    ****************************************************${NC}"
echo ""
