#!/bin/bash

################################################################################
# Interactive Security Fix Script with Risk Assessment
# هر fix را جداگانه با ارزیابی خطر نشان می‌دهد
# شما هر مرحله را تایید می‌کنید
################################################################################

set -euo pipefail

# Configuration
LOG_DIR="/var/log/security-audit"
FIX_LOG="$LOG_DIR/fix-history-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/var/backups/security-fixes-$(date +%Y%m%d_%H%M%S)"
COMPLETED_FIXES="$LOG_DIR/completed-fixes.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Statistics
TOTAL_FIXES=0
APPLIED_FIXES=0
SKIPPED_FIXES=0

################################################################################
# Risk Assessment Functions
################################################################################

assess_risk_level() {
    local cmd=$1
    local risk_score=0
    local risk_reasons=()
    
    # Critical risk patterns (10 points each)
    if echo "$cmd" | grep -qiE '\brm\b.*-rf|\bdd\b.*if=|>\s*/dev/|format|mkfs'; then
        risk_score=$((risk_score + 10))
        risk_reasons+=("⚠️  دستور حذف یا فرمت دائمی")
    fi
    
    if echo "$cmd" | grep -qiE 'chmod\s+777|chmod\s+666'; then
        risk_score=$((risk_score + 10))
        risk_reasons+=("⚠️  اجازه دسترسی کامل به همه")
    fi
    
    # High risk patterns (7 points each)
    if echo "$cmd" | grep -qiE '\brm\b|\bmv\b.*-f|unlink|shred'; then
        risk_score=$((risk_score + 7))
        risk_reasons+=("🔥 حذف فایل یا دایرکتوری")
    fi
    
    if echo "$cmd" | grep -qiE 'iptables.*-F|ufw.*reset|systemctl.*stop.*ssh'; then
        risk_score=$((risk_score + 7))
        risk_reasons+=("🔥 تغییر امنیتی حیاتی - ممکن است دسترسی قطع شود")
    fi
    
    # Medium risk patterns (5 points each)
    if echo "$cmd" | grep -qiE 'apt.*remove|apt.*purge|dpkg.*-r'; then
        risk_score=$((risk_score + 5))
        risk_reasons+=("⚡ حذف نرم‌افزار")
    fi
    
    if echo "$cmd" | grep -qiE 'systemctl|service.*stop|service.*restart'; then
        risk_score=$((risk_score + 5))
        risk_reasons+=("⚡ تغییر وضعیت سرویس")
    fi
    
    if echo "$cmd" | grep -qiE 'sed.*-i|perl.*-i|awk.*-i\.bak'; then
        risk_score=$((risk_score + 5))
        risk_reasons+=("⚡ تغییر مستقیم فایل")
    fi
    
    if echo "$cmd" | grep -qiE 'chmod|chown|chgrp'; then
        risk_score=$((risk_score + 4))
        risk_reasons+=("📝 تغییر مالکیت یا دسترسی")
    fi
    
    # Medium-low risk patterns (3 points each)
    if echo "$cmd" | grep -qiE 'apt.*install|apt.*upgrade|yum.*install'; then
        risk_score=$((risk_score + 3))
        risk_reasons+=("📦 نصب یا به‌روزرسانی نرم‌افزار")
    fi
    
    if echo "$cmd" | grep -qiE 'ufw|iptables.*-A|firewall'; then
        risk_score=$((risk_score + 3))
        risk_reasons+=("🛡️  تغییر قوانین فایروال")
    fi
    
    # Low risk patterns (1 point each)
    if echo "$cmd" | grep -qiE 'echo|cat|grep|find|ls|ps|top'; then
        risk_score=$((risk_score + 1))
        risk_reasons+=("✅ فقط خواندن اطلاعات")
    fi
    
    # Return results
    if [ $risk_score -ge 10 ]; then
        echo "CRITICAL|$risk_score|${risk_reasons[*]}"
    elif [ $risk_score -ge 7 ]; then
        echo "HIGH|$risk_score|${risk_reasons[*]}"
    elif [ $risk_score -ge 4 ]; then
        echo "MEDIUM|$risk_score|${risk_reasons[*]}"
    elif [ $risk_score -ge 2 ]; then
        echo "LOW|$risk_score|${risk_reasons[*]}"
    else
        echo "INFO|$risk_score|${risk_reasons[*]}"
    fi
}

display_risk() {
    local risk_level=$1
    local risk_score=$2
    local risk_reasons=$3
    
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               📊 ارزیابی سطح خطر                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    case $risk_level in
        CRITICAL)
            echo -e "${RED}${BOLD}🚨 سطح خطر: بحرانی (CRITICAL)${NC}"
            echo -e "${RED}امتیاز خطر: $risk_score/10+${NC}"
            echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║  این دستور می‌تواند آسیب جدی به سیستم وارد کند!        ║${NC}"
            echo -e "${RED}║  با دقت بسیار بالا بررسی کنید.                          ║${NC}"
            echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
            ;;
        HIGH)
            echo -e "${RED}⚠️  سطح خطر: بالا (HIGH)${NC}"
            echo -e "${RED}امتیاز خطر: $risk_score/10${NC}"
            echo -e "${YELLOW}توصیه: با دقت بررسی کنید${NC}"
            ;;
        MEDIUM)
            echo -e "${YELLOW}⚡ سطح خطر: متوسط (MEDIUM)${NC}"
            echo -e "${YELLOW}امتیاز خطر: $risk_score/10${NC}"
            ;;
        LOW)
            echo -e "${BLUE}📝 سطح خطر: پایین (LOW)${NC}"
            echo -e "${BLUE}امتیاز خطر: $risk_score/10${NC}"
            ;;
        INFO)
            echo -e "${GREEN}✅ سطح خطر: اطلاعاتی (INFO)${NC}"
            echo -e "${GREEN}امتیاز خطر: $risk_score/10${NC}"
            ;;
    esac
    
    if [ -n "$risk_reasons" ]; then
        echo ""
        echo -e "${BOLD}دلایل این ارزیابی:${NC}"
        IFS=' ' read -ra REASONS <<< "$risk_reasons"
        for reason in "${REASONS[@]}"; do
            echo "  $reason"
        done
    fi
    echo ""
}

################################################################################
# Backup Functions
################################################################################

create_backup() {
    local file=$1
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -a "$file" "$BACKUP_DIR/" 2>/dev/null || true
        echo -e "${GREEN}[✓] Backup: $file → $BACKUP_DIR/${NC}"
    fi
}

smart_backup() {
    local cmd=$1
    
    # Detect files that will be modified
    if echo "$cmd" | grep -qE 'sed.*-i|vi |nano |echo.*>'; then
        local files=$(echo "$cmd" | grep -oE '/[a-zA-Z0-9/_.-]+')
        for file in $files; do
            if [ -f "$file" ]; then
                create_backup "$file"
            fi
        done
    fi
    
    # Backup important config files
    if echo "$cmd" | grep -qiE '/etc/|sshd_config|ufw|iptables|fstab|passwd|shadow'; then
        echo -e "${YELLOW}[*] Creating backup of system configs...${NC}"
        tar -czf "$BACKUP_DIR/etc-backup-$(date +%s).tar.gz" /etc/ 2>/dev/null || true
    fi
}

################################################################################
# AI Analysis
################################################################################

analyze_security_issues() {
    local audit_file=$1
    local model="qwen2.5-coder:1.5b-instruct"
    
    echo -e "${CYAN}[*] تحلیل مشکلات امنیتی با AI...${NC}"
    
    # Check model
    if ! ollama list | grep -q "$model"; then
        echo -e "${YELLOW}[!] Model not found: $model${NC}"
        echo -e "${YELLOW}[*] Checking alternatives...${NC}"
        
        if ollama list | grep -q "qwen2.5-coder:1.5b"; then
            model="qwen2.5-coder:1.5b"
        elif ollama list | grep -q "qwen2.5-coder:7b"; then
            model="qwen2.5-coder:7b"
        elif ollama list | grep -q "mistral:7b"; then
            model="mistral:7b"
        elif ollama list | grep -q "gemma2:2b"; then
            model="gemma2:2b"
        else
            echo -e "${RED}[!] No suitable model found!${NC}"
            echo "Install: ollama pull qwen2.5-coder:1.5b-instruct"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}[✓] Using model: $model${NC}"
    echo ""
    
    local prompt="You are a Debian security expert. Analyze this security audit and provide fixes.

RULES:
1. Provide ONLY bash commands (one per line)
2. Add # comment before each command explaining what it does
3. Skip false positives
4. Use safe commands with proper checks
5. Include validation before dangerous operations
6. Format strictly as:
   # Purpose: what this fixes
   command here
   
7. Only fix REAL security issues

Security Audit (first 300 lines):
$(head -n 300 "$audit_file")

Provide fix commands:"

    # Generate fixes
    local temp_output=$(mktemp)
    echo "$prompt" | ollama run "$model" > "$temp_output" 2>&1
    
    # Extract commands (lines with # or actual commands)
    grep -E '^(#|[a-zA-Z]|sudo|apt|systemctl|ufw|chmod|chown|echo|cp|mv|rm|sed|awk|grep|find)' "$temp_output" || true
    
    rm -f "$temp_output"
}

################################################################################
# Interactive Fix Application
################################################################################

ask_confirmation() {
    local cmd=$1
    local risk_info=$2
    
    IFS='|' read -r risk_level risk_score risk_reasons <<< "$risk_info"
    
    echo ""
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}دستور پیشنهادی:${NC}"
    echo ""
    echo -e "${CYAN}$cmd${NC}"
    echo ""
    
    display_risk "$risk_level" "$risk_score" "$risk_reasons"
    
    echo -e "${YELLOW}گزینه‌های شما:${NC}"
    echo "  ${GREEN}y${NC} - اجرا (Yes)"
    echo "  ${RED}n${NC} - رد کردن (No)"
    echo "  ${BLUE}s${NC} - نمایش توضیحات بیشتر (Show details)"
    echo "  ${MAGENTA}t${NC} - تست بدون اجرا (Test/dry-run)"
    echo "  ${CYAN}q${NC} - خروج (Quit)"
    echo ""
    
    while true; do
        read -p "انتخاب شما [y/n/s/t/q]: " -n 1 -r choice
        echo ""
        
        case $choice in
            [Yy])
                return 0
                ;;
            [Nn])
                echo -e "${YELLOW}⊘ رد شد${NC}"
                return 1
                ;;
            [Ss])
                echo ""
                echo -e "${BLUE}📖 توضیحات تکمیلی:${NC}"
                man $(echo "$cmd" | awk '{print $1}') 2>/dev/null | head -n 30 || echo "Manual not available"
                echo ""
                ;;
            [Tt])
                echo ""
                echo -e "${CYAN}🧪 حالت تست (فقط نمایش، بدون اجرا):${NC}"
                echo "$cmd"
                echo ""
                echo -e "${BLUE}این دستور اجرا نشد. می‌خواهید واقعاً اجرا شود؟${NC}"
                ;;
            [Qq])
                echo -e "${RED}خروج از برنامه...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}گزینه نامعتبر! لطفاً y/n/s/t/q را انتخاب کنید.${NC}"
                ;;
        esac
    done
}

execute_fix() {
    local cmd=$1
    local description=$2
    
    echo ""
    echo -e "${CYAN}▶ در حال اجرا...${NC}"
    
    # Create backups if needed
    smart_backup "$cmd"
    
    # Execute and capture output
    local output
    local exit_code
    
    if output=$(eval "$cmd" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Log the action
    {
        echo "═════════════════════════════════════════"
        echo "Timestamp: $(date)"
        echo "Command: $cmd"
        echo "Description: $description"
        echo "Exit Code: $exit_code"
        echo "Output:"
        echo "$output"
        echo ""
    } >> "$FIX_LOG"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ اجرا موفق${NC}"
        if [ -n "$output" ]; then
            echo -e "${BLUE}خروجی:${NC}"
            echo "$output" | head -n 10
        fi
        
        # Mark as completed
        echo "$cmd" >> "$COMPLETED_FIXES"
        
        return 0
    else
        echo -e "${RED}❌ خطا در اجرا (exit code: $exit_code)${NC}"
        echo -e "${RED}خروجی خطا:${NC}"
        echo "$output"
        return 1
    fi
}

################################################################################
# Main Process
################################################################################

process_fixes() {
    local fixes_data=$1
    
    local current_comment=""
    local command_buffer=""
    
    while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        if [[ "$line" =~ ^# ]]; then
            # This is a comment/description
            current_comment="$line"
        else
            # This is a command
            command_buffer="$line"
            
            if [ -n "$command_buffer" ]; then
                
                # Check if already completed
                if grep -Fxq "$command_buffer" "$COMPLETED_FIXES" 2>/dev/null; then
                    echo ""
                    echo -e "${GREEN}⏭️  این fix قبلاً انجام شده است (skip)${NC}"
                    echo -e "${CYAN}دستور: $command_buffer${NC}"
                    echo ""
                    SKIPPED_FIXES=$((SKIPPED_FIXES + 1))
                    current_comment=""
                    command_buffer=""
                    sleep 1
                    continue
                fi
                
                TOTAL_FIXES=$((TOTAL_FIXES + 1))
                
                echo ""
                echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
                echo -e "${MAGENTA}║  Fix #$TOTAL_FIXES${NC}"
                echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
                
                if [ -n "$current_comment" ]; then
                    echo -e "${BLUE}توضیحات: $current_comment${NC}"
                fi
                
                # Risk assessment
                local risk_info=$(assess_risk_level "$command_buffer")
                
                # Ask for confirmation
                if ask_confirmation "$command_buffer" "$risk_info"; then
                    if execute_fix "$command_buffer" "$current_comment"; then
                        APPLIED_FIXES=$((APPLIED_FIXES + 1))
                    fi
                else
                    SKIPPED_FIXES=$((SKIPPED_FIXES + 1))
                fi
                
                # Reset for next iteration
                current_comment=""
                command_buffer=""
                
                # Pause between fixes
                echo ""
                read -p "فشار Enter برای ادامه... (یا Ctrl+C برای خروج)" -r
                clear
            fi
        fi
    done <<< "$fixes_data"
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     🛡️  Security Fix Assistant with Risk Assessment 🛡️       ║
║                                                               ║
║  این ابزار مشکلات امنیتی را با ارزیابی خطر نشان می‌دهد   ║
║  و هر تغییر را پیش از اجرا از شما تایید می‌گیرد          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Check root
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}[!] این اسکریپت نیاز به دسترسی root دارد${NC}"
        echo "    اجرا با: sudo $0"
        exit 1
    fi
    
    # Create directories
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"
    
    # Create completed fixes file if not exists
    touch "$COMPLETED_FIXES"
    
    # Find latest audit
    local audit_file=$(ls -t "$LOG_DIR"/ai-analysis-ready-*.txt 2>/dev/null | head -1)
    
    if [ -z "$audit_file" ]; then
        echo -e "${RED}[!] فایل audit پیدا نشد${NC}"
        echo "ابتدا security audit را اجرا کنید:"
        echo "  sudo ~/security-tools/security-audit.sh"
        exit 1
    fi
    
    echo -e "${GREEN}[✓] فایل audit: $audit_file${NC}"
    echo -e "${GREEN}[✓] پشتیبان‌ها: $BACKUP_DIR${NC}"
    echo -e "${GREEN}[✓] لاگ: $FIX_LOG${NC}"
    echo -e "${GREEN}[✓] Completed fixes: $COMPLETED_FIXES${NC}"
    
    # Show completed fixes count
    local completed_count=$(wc -l < "$COMPLETED_FIXES" 2>/dev/null || echo 0)
    if [ "$completed_count" -gt 0 ]; then
        echo ""
        echo -e "${BLUE}📋 تعداد fixes قبلی: $completed_count${NC}"
        echo -e "${YELLOW}این fixes skip می‌شوند (قبلاً انجام شده)${NC}"
    fi
    
    echo ""
    
    read -p "آماده شروع تحلیل؟ [Enter]" -r
    
    # Analyze and get fixes
    echo ""
    echo -e "${CYAN}[*] شروع تحلیل...${NC}"
    local fixes=$(analyze_security_issues "$audit_file")
    
    if [ -z "$fixes" ]; then
        echo -e "${YELLOW}[!] هیچ fix پیشنهادی پیدا نشد${NC}"
        exit 0
    fi
    
    echo -e "${GREEN}[✓] تحلیل کامل شد${NC}"
    echo ""
    
    # Process fixes interactively
    process_fixes "$fixes"
    
    # Final summary
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                    📊 خلاصه نهایی                        ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  کل fixes پیشنهادی:     ${BOLD}$TOTAL_FIXES${NC}"
    echo -e "  ${GREEN}اجرا شده:              $APPLIED_FIXES${NC}"
    echo -e "  ${YELLOW}رد شده:                $SKIPPED_FIXES${NC}"
    echo ""
    echo -e "  📁 پشتیبان‌ها:          $BACKUP_DIR"
    echo -e "  📝 لاگ کامل:           $FIX_LOG"
    echo ""
    echo -e "${GREEN}✅ تمام! ${NC}"
}

# Run
main
