#!/bin/bash

################################################################################
# Security Audit Script for Debian 13
# Runs multiple security tools and generates consolidated logs for AI analysis
################################################################################

# Configuration
LOG_DIR="/var/log/security-audit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$LOG_DIR/consolidated-report-$TIMESTAMP.txt"
SUMMARY_FILE="$LOG_DIR/ai-analysis-ready-$TIMESTAMP.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create log directory if not exists
mkdir -p "$LOG_DIR"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_status() {
    echo -e "${YELLOW}[*] $1${NC}"
}

print_error() {
    echo -e "${RED}[!] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

################################################################################
# Main Script
################################################################################

# Start report
{
    echo "========================================"
    echo "SECURITY AUDIT REPORT"
    echo "========================================"
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "========================================"
    echo ""
} > "$REPORT_FILE"

print_header "Starting Comprehensive Security Audit"

################################################################################
# 1. rkhunter
################################################################################

if command -v rkhunter &> /dev/null; then
    print_status "Running rkhunter..."
    {
        echo "========== RKHUNTER SCAN =========="
        echo "Started: $(date)"
        echo ""
        
        rkhunter --update --quiet 2>&1
        rkhunter --propupd --quiet 2>&1
        rkhunter --check --skip-keypress --report-warnings-only 2>&1
        
        echo ""
        echo "Completed: $(date)"
        echo ""
    } >> "$REPORT_FILE" 2>&1
    print_success "rkhunter completed"
else
    print_error "rkhunter not installed"
    echo "Install: sudo apt install rkhunter"
fi

################################################################################
# 2. chkrootkit
################################################################################

if command -v chkrootkit &> /dev/null; then
    print_status "Running chkrootkit..."
    {
        echo "========== CHKROOTKIT SCAN =========="
        echo "Started: $(date)"
        echo ""
        
        chkrootkit 2>&1 | grep -E "INFECTED|WARNING|Searching"
        
        echo ""
        echo "Completed: $(date)"
        echo ""
    } >> "$REPORT_FILE" 2>&1
    print_success "chkrootkit completed"
else
    print_error "chkrootkit not installed"
    echo "Install: sudo apt install chkrootkit"
fi

################################################################################
# 3. Lynis
################################################################################

if command -v lynis &> /dev/null; then
    print_status "Running Lynis audit..."
    {
        echo "========== LYNIS AUDIT =========="
        echo "Started: $(date)"
        echo ""
        
        lynis audit system --quick --quiet 2>&1 | grep -E "Warning|Suggestion|\[.*\]"
        
        echo ""
        echo "Completed: $(date)"
        echo ""
    } >> "$REPORT_FILE" 2>&1
    print_success "Lynis completed"
else
    print_error "Lynis not installed"
    echo "Install: sudo apt install lynis"
fi

################################################################################
# 4. AIDE (if initialized)
################################################################################

if [ -f /var/lib/aide/aide.db ]; then
    print_status "Running AIDE check (this may take a while)..."
    {
        echo "========== AIDE FILE INTEGRITY CHECK =========="
        echo "Started: $(date)"
        echo ""
        
        nice -n 19 ionice -c 3 aide --check 2>&1 | head -n 500
        
        echo ""
        echo "Completed: $(date)"
        echo "Note: Full AIDE log available at /var/log/aide/aide.log"
        echo ""
    } >> "$REPORT_FILE" 2>&1
    print_success "AIDE check completed"
else
    print_status "AIDE not initialized, skipping..."
    echo "========== AIDE NOT INITIALIZED ==========" >> "$REPORT_FILE"
    echo "To initialize: sudo aideinit"
fi

################################################################################
# 5. System Information
################################################################################

print_status "Gathering system information..."
{
    echo "========== SYSTEM SECURITY STATUS =========="
    echo ""
    
    echo "--- Active Network Connections ---"
    ss -tunap 2>/dev/null | grep ESTABLISHED | head -n 20
    echo ""
    
    echo "--- Recent Failed Login Attempts ---"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 20
    echo ""
    
    echo "--- Users with UID 0 (root privileges) ---"
    awk -F: '($3 == "0") {print}' /etc/passwd
    echo ""
    
    echo "--- Open Ports ---"
    ss -tuln 2>/dev/null | grep LISTEN
    echo ""
    
    echo "--- Firewall Status ---"
    ufw status 2>/dev/null || iptables -L -n 2>/dev/null | head -n 30
    echo ""
    
    echo "--- Recently Modified System Files (last 24h) ---"
    find /etc /bin /sbin /usr/bin /usr/sbin -type f -mtime -1 2>/dev/null | head -n 20
    echo ""
    
    echo "--- SUID/SGID Files (potential security risk) ---"
    find / -perm /6000 -type f 2>/dev/null | head -n 30
    echo ""
    
} >> "$REPORT_FILE" 2>&1

print_success "System information gathered"

################################################################################
# 6. Generate AI-Ready Summary
################################################################################

print_status "Generating AI-ready summary..."

{
    echo "========================================"
    echo "AI ANALYSIS PROMPT"
    echo "========================================"
    echo ""
    echo "Please analyze this security audit report and provide:"
    echo "1. Critical issues that need immediate attention"
    echo "2. False positives that can be safely ignored"
    echo "3. Specific commands to fix real issues"
    echo "4. Security hardening recommendations"
    echo "5. Priority ranking (Critical/High/Medium/Low)"
    echo ""
    echo "========================================"
    echo "AUDIT RESULTS"
    echo "========================================"
    echo ""
    cat "$REPORT_FILE"
} > "$SUMMARY_FILE"

################################################################################
# Final Report
################################################################################

print_header "Audit Complete!"

echo ""
echo "Reports generated:"
echo "  - Full report: $REPORT_FILE"
echo "  - AI-ready summary: $SUMMARY_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the summary: cat $SUMMARY_FILE"
echo "  2. Run AI analysis: sudo ~/security-tools/security-ai-analyzer.sh"
echo "  3. Apply fixes: sudo ~/security-tools/security-fix-interactive.sh"
echo ""

echo "Report sizes:"
ls -lh "$REPORT_FILE" "$SUMMARY_FILE" 2>/dev/null | awk '{print "  - " $9 ": " $5}'
echo ""

print_header "Quick Summary"
echo "Warnings found in rkhunter:"
grep -c "Warning" "$REPORT_FILE" 2>/dev/null || echo "0"
echo "Infected items in chkrootkit:"
grep -c "INFECTED" "$REPORT_FILE" 2>/dev/null || echo "0"
echo "Lynis suggestions:"
grep -c "Suggestion" "$REPORT_FILE" 2>/dev/null || echo "0"

echo ""
print_success "All done! Ready for AI analysis."
