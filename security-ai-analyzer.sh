#!/bin/bash

################################################################################
# AI Security Analysis Script
# Works with Ollama local models
################################################################################

# Configuration
LOG_DIR="/var/log/security-audit"
OUTPUT_DIR="$LOG_DIR/ai-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create output directory
mkdir -p "$OUTPUT_DIR"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
}

print_status() {
    echo -e "${YELLOW}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

check_ollama() {
    if ! command -v ollama &> /dev/null; then
        print_error "Ollama not found!"
        echo ""
        echo "Install Ollama:"
        echo "  curl -fsSL https://ollama.com/install.sh | sh"
        echo ""
        echo "Then install a model:"
        echo "  ollama pull qwen2.5-coder:1.5b-instruct"
        exit 1
    fi
    print_success "Ollama is installed"
}

list_available_models() {
    echo -e "${BLUE}Available models on your system:${NC}"
    ollama list
    echo ""
}

detect_best_model() {
    MODELS=$(ollama list | awk 'NR>1 {print $1}')
    
    if echo "$MODELS" | grep -q "qwen2.5-coder:1.5b-instruct"; then
        echo "qwen2.5-coder:1.5b-instruct"
    elif echo "$MODELS" | grep -q "qwen2.5-coder:1.5b"; then
        echo "qwen2.5-coder:1.5b"
    elif echo "$MODELS" | grep -q "qwen2.5-coder:7b"; then
        echo "qwen2.5-coder:7b"
    elif echo "$MODELS" | grep -q "mistral:7b"; then
        echo "mistral:7b"
    elif echo "$MODELS" | grep -q "llama3.2:3b"; then
        echo "llama3.2:3b"
    elif echo "$MODELS" | grep -q "gemma2:2b"; then
        echo "gemma2:2b"
    else
        echo ""
    fi
}

quick_summary() {
    local audit_log=$1
    
    echo -e "${BLUE}Quick Statistics:${NC}"
    echo "  Warnings in rkhunter: $(grep -c "Warning" "$audit_log" 2>/dev/null || echo "0")"
    echo "  INFECTED in chkrootkit: $(grep -c "INFECTED" "$audit_log" 2>/dev/null || echo "0")"
    echo "  Lynis warnings: $(grep -c "Warning" "$audit_log" 2>/dev/null || echo "0")"
    echo "  Lynis suggestions: $(grep -c "Suggestion" "$audit_log" 2>/dev/null || echo "0")"
    echo ""
}

################################################################################
# Main
################################################################################

clear
print_header "🤖 AI Security Analysis"

check_ollama
list_available_models

LATEST_AUDIT=$(ls -t "$LOG_DIR"/ai-analysis-ready-*.txt 2>/dev/null | head -1)

if [ -z "$LATEST_AUDIT" ]; then
    print_error "No audit file found in $LOG_DIR"
    echo ""
    echo "Run the security audit first:"
    echo "  sudo ~/security-tools/security-audit.sh"
    exit 1
fi

print_success "Found audit file: $LATEST_AUDIT"
echo "  Size: $(du -h "$LATEST_AUDIT" | awk '{print $1}')"
echo ""

quick_summary "$LATEST_AUDIT"

BEST_MODEL=$(detect_best_model)

if [ -z "$BEST_MODEL" ]; then
    print_error "No suitable model found!"
    echo ""
    echo "Install a recommended model:"
    echo "  ollama pull qwen2.5-coder:1.5b-instruct  # Best for you (1GB)"
    echo "  ollama pull mistral:7b                   # Alternative (4.1GB)"
    exit 1
fi

print_status "Best available model: $BEST_MODEL"
echo ""

read -p "Start analysis with $BEST_MODEL? [Enter] " -r

OUTPUT="$OUTPUT_DIR/analysis-$BEST_MODEL-$TIMESTAMP.txt"

print_status "Starting analysis (this may take 2-5 minutes)..."
echo ""

# AI Prompt
PROMPT="تحلیل Security Audit دبیان - لطفاً به فارسی و با جزئیات پاسخ بده:

این خروجی یک Security Audit کامل از سیستم دبیان است.

لطفاً موارد زیر را ارائه بده:

🚨 1. CRITICAL ISSUES (مسائل بحرانی):
   - مشکلات امنیتی واقعی که نیاز به رفع فوری دارند
   - خطر هر کدام را توضیح بده

✅ 2. FALSE POSITIVES:
   - هشدارهایی که می‌توان ignore کرد
   - دلیل false positive بودن

🔧 3. FIX COMMANDS:
   - دستورات دقیق bash برای رفع هر مشکل
   - هر command را توضیح بده

📊 4. SECURITY SCORE:
   - نمره امنیتی کلی از 10
   - نقاط ضعف اصلی

🛡️ 5. HARDENING RECOMMENDATIONS:
   - بهبودهای امنیتی پیشنهادی
   - اولویت‌بندی شده

---

LOG FILE:
$(cat "$LATEST_AUDIT")

---

تحلیل جامع و فنی ارائه بده."

# Run AI analysis
echo "$PROMPT" | ollama run "$BEST_MODEL" > "$OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    print_success "Analysis completed!"
else
    print_error "Analysis failed"
    exit 1
fi

################################################################################
# Display Results
################################################################################

echo ""
print_header "📊 Analysis Complete"

echo -e "${GREEN}Report saved to: $OUTPUT${NC}"
echo ""

echo -e "${BLUE}Preview (first 50 lines):${NC}"
echo "----------------------------------------"
head -n 50 "$OUTPUT"
echo "----------------------------------------"
echo ""

read -p "View full report? [y/N]: " view
if [[ $view =~ ^[Yy]$ ]]; then
    less "$OUTPUT"
fi

echo ""
echo -e "${CYAN}Quick commands:${NC}"
echo "  View full report:   cat $OUTPUT"
echo "  Search in report:   grep -i 'critical' $OUTPUT"
echo ""

echo -e "${BLUE}All available reports:${NC}"
ls -lht "$OUTPUT_DIR" | head -n 5

echo ""
print_success "Done! 🎉"
echo ""
echo "Next step: Apply fixes interactively"
echo "  sudo ~/security-tools/security-fix-interactive.sh"
