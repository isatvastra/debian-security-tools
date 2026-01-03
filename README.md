# 🛡️ Security Tools for Debian 13

[English](#english) | [فارسی](#persian)

---

<a name="english"></a>
## 🇬🇧 English Documentation

### 📋 Overview

A comprehensive security audit and fix toolkit for Debian 13, powered by AI. This toolset automates security scanning, provides intelligent analysis, and offers interactive fix application with risk assessment.

### ✨ Features

- **🔍 Comprehensive Security Audit**: Integrates multiple security tools (rkhunter, chkrootkit, Lynis, AIDE)
- **🤖 AI-Powered Analysis**: Uses local LLM (Ollama) for intelligent security analysis
- **⚡ Interactive Fix Application**: Each fix requires manual approval with risk assessment
- **🔄 Resume Capability**: Can resume from where you left off if interrupted
- **💾 Automatic Backups**: Creates backups before any system changes
- **📊 Risk Scoring**: Rates each fix from INFO to CRITICAL
- **📝 Complete Audit Trail**: Logs all actions and decisions

### 🚀 Quick Start

#### Prerequisites

```bash
# Install security tools
sudo apt update
sudo apt install rkhunter chkrootkit lynis

# Optional: AIDE (file integrity monitoring - slower)
sudo apt install aide
sudo aideinit

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Install AI model
ollama pull qwen2.5-coder:1.5b-instruct
```

#### Installation

All scripts are located in `~/security-tools/`:

```bash
cd ~/security-tools
ls -lh
# security-audit.sh
# security-ai-analyzer.sh
# security-fix-interactive.sh
# README.md
```

Make sure all scripts are executable:
```bash
chmod +x ~/security-tools/*.sh
```

### 📖 Usage

#### Step 1: Security Audit (10-45 minutes)

Collect security information from your system:

```bash
sudo ~/security-tools/security-audit.sh
```

**What it does:**
- Runs rkhunter, chkrootkit, Lynis
- Checks for AIDE changes (if initialized)
- Gathers system security information
- Generates AI-ready summary

**Output location:**
- Full report: `/var/log/security-audit/consolidated-report-TIMESTAMP.txt`
- AI summary: `/var/log/security-audit/ai-analysis-ready-TIMESTAMP.txt`

#### Step 2: AI Analysis (2-5 minutes) - Optional

Analyze audit results with AI:

```bash
sudo ~/security-tools/security-ai-analyzer.sh
```

**What it does:**
- Reads audit logs
- Analyzes with local LLM
- Identifies real issues vs false positives
- Provides security recommendations

**Output location:**
- `/var/log/security-audit/ai-reports/analysis-MODEL-TIMESTAMP.txt`

#### Step 3: Interactive Fix (15-60 minutes)

Apply fixes with manual approval:

```bash
sudo ~/security-tools/security-fix-interactive.sh
```

**What it does:**
- AI analyzes security issues
- Proposes fix commands
- Shows risk assessment for each fix
- Waits for your approval (y/n/t/s/q)
- Creates backups before changes
- Executes approved fixes
- Tracks completed fixes

**Interactive Options:**
- `y` - Execute the fix
- `n` - Skip this fix
- `t` - Test mode (show command without executing)
- `s` - Show detailed information (man page)
- `q` - Quit

**Safety Features:**
- Each fix requires manual approval
- Risk assessment (CRITICAL/HIGH/MEDIUM/LOW/INFO)
- Automatic backups before changes
- Complete audit trail
- Resume capability (Ctrl+C safe)

### 🎯 Typical Workflow

```bash
# Day 1: Run audit (can take time)
sudo ~/security-tools/security-audit.sh

# Day 2: Review and fix
sudo ~/security-tools/security-ai-analyzer.sh  # Optional
sudo ~/security-tools/security-fix-interactive.sh
```

### 📊 Risk Levels

| Level | Score | Examples |
|-------|-------|----------|
| 🚨 **CRITICAL** | 10+ | `rm -rf`, `chmod 777`, disk formatting |
| ⚠️ **HIGH** | 7-9 | File deletion, stopping SSH |
| ⚡ **MEDIUM** | 4-6 | Package removal, service restart, config editing |
| 📝 **LOW** | 2-3 | Installing packages, firewall changes |
| ✅ **INFO** | 0-1 | Read-only commands |

### 🔄 Resume Feature

If interrupted with Ctrl+C, the script remembers completed fixes:

```bash
# First run - complete 5 fixes, then Ctrl+C
sudo ~/security-tools/security-fix-interactive.sh

# Second run - automatically skips completed fixes
sudo ~/security-tools/security-fix-interactive.sh
```

Completed fixes are tracked in:
```
/var/log/security-audit/completed-fixes.txt
```

To start fresh:
```bash
sudo rm /var/log/security-audit/completed-fixes.txt
```

### 📁 File Locations

```
~/security-tools/                          # Scripts location
├── security-audit.sh                      # Audit script
├── security-ai-analyzer.sh                # AI analysis
├── security-fix-interactive.sh            # Interactive fix
└── README.md                              # This file

/var/log/security-audit/                   # Logs and reports
├── consolidated-report-*.txt              # Full audit reports
├── ai-analysis-ready-*.txt                # AI-ready summaries
├── completed-fixes.txt                    # Completed fixes tracker
├── fix-history-*.log                      # Fix execution logs
└── ai-reports/                            # AI analysis reports

/var/backups/security-fixes-*/             # Automatic backups
```

### 🛠️ Troubleshooting

**No audit file found:**
```bash
sudo ~/security-tools/security-audit.sh
```

**No suitable model found:**
```bash
ollama pull qwen2.5-coder:1.5b-instruct
```

**Permission denied:**
```bash
chmod +x ~/security-tools/*.sh
```

**Package interrupted during fix:**
```bash
sudo dpkg --configure -a
sudo apt --fix-broken install
```

**Restore from backup:**
```bash
sudo cp /var/backups/security-fixes-*/FILE /original/location/
```

### 💡 Tips

- Use `t` (test mode) to preview commands before execution
- Press Ctrl+C anytime - it's safe and you can resume later
- Review `/var/log/security-audit/fix-history-*.log` for audit trail
- Start with CRITICAL and HIGH priority fixes only
- Keep backups for at least 30 days

### 📦 Recommended Models

| Model | Size | Speed | Quality | Recommendation |
|-------|------|-------|---------|----------------|
| qwen2.5-coder:1.5b-instruct | 1GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Best for daily use |
| qwen2.5-coder:7b | 4.7GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Best quality |
| mistral:7b | 4.1GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Good alternative |

### 🔐 Security Considerations

- All scripts require root privileges
- AI analysis runs locally (no cloud)
- Audit logs contain sensitive system information
- Keep logs directory (`/var/log/security-audit/`) secured
- Review all fixes before approval

### 📄 License

These scripts are provided as-is for educational and security hardening purposes.

### 🤝 Contributing

Feel free to improve these scripts and share your enhancements!

---

<a name="persian"></a>
## 🇮🇷 مستندات فارسی

### 📋 معرفی

مجموعه‌ای جامع برای ممیزی امنیتی و رفع مشکلات در دبیان ۱۳، با قدرت هوش مصنوعی. این ابزارها اسکن امنیتی را خودکار می‌کنند، تحلیل هوشمند ارائه می‌دهند، و رفع تعاملی مشکلات با ارزیابی خطر را فراهم می‌کنند.

### ✨ ویژگی‌ها

- **🔍 ممیزی امنیتی جامع**: ترکیب چندین ابزار امنیتی (rkhunter, chkrootkit, Lynis, AIDE)
- **🤖 تحلیل هوشمند با AI**: استفاده از LLM محلی (Ollama) برای تحلیل امنیتی
- **⚡ رفع تعاملی مشکلات**: هر fix نیاز به تایید دستی با ارزیابی خطر دارد
- **🔄 قابلیت ادامه**: می‌توانید از جایی که قطع شده ادامه دهید
- **💾 پشتیبان‌گیری خودکار**: قبل از هر تغییری backup می‌گیرد
- **📊 امتیازدهی خطر**: هر fix را از INFO تا CRITICAL رتبه‌بندی می‌کند
- **📝 ثبت کامل**: تمام اقدامات و تصمیمات را لاگ می‌کند

### 🚀 شروع سریع

#### پیش‌نیازها

```bash
# نصب ابزارهای امنیتی
sudo apt update
sudo apt install rkhunter chkrootkit lynis

# اختیاری: AIDE (نظارت بر یکپارچگی فایل - کندتر)
sudo apt install aide
sudo aideinit

# نصب Ollama
curl -fsSL https://ollama.com/install.sh | sh

# نصب مدل AI
ollama pull qwen2.5-coder:1.5b-instruct
```

#### نصب

تمام اسکریپت‌ها در `~/security-tools/` قرار دارند:

```bash
cd ~/security-tools
ls -lh
# security-audit.sh
# security-ai-analyzer.sh
# security-fix-interactive.sh
# README.md
```

مطمئن شوید همه اسکریپت‌ها قابل اجرا هستند:
```bash
chmod +x ~/security-tools/*.sh
```

### 📖 نحوه استفاده

#### مرحله ۱: ممیزی امنیتی (۱۰-۴۵ دقیقه)

جمع‌آوری اطلاعات امنیتی از سیستم:

```bash
sudo ~/security-tools/security-audit.sh
```

**چه کاری انجام می‌دهد:**
- rkhunter، chkrootkit، Lynis را اجرا می‌کند
- تغییرات AIDE را بررسی می‌کند (اگر مقداردهی شده باشد)
- اطلاعات امنیتی سیستم را جمع‌آوری می‌کند
- خلاصه آماده برای AI تولید می‌کند

**محل خروجی:**
- گزارش کامل: `/var/log/security-audit/consolidated-report-TIMESTAMP.txt`
- خلاصه AI: `/var/log/security-audit/ai-analysis-ready-TIMESTAMP.txt`

#### مرحله ۲: تحلیل AI (۲-۵ دقیقه) - اختیاری

تحلیل نتایج ممیزی با AI:

```bash
sudo ~/security-tools/security-ai-analyzer.sh
```

**چه کاری انجام می‌دهد:**
- لاگ‌های ممیزی را می‌خواند
- با LLM محلی تحلیل می‌کند
- مشکلات واقعی را از false positive جدا می‌کند
- توصیه‌های امنیتی ارائه می‌دهد

**محل خروجی:**
- `/var/log/security-audit/ai-reports/analysis-MODEL-TIMESTAMP.txt`

#### مرحله ۳: رفع تعاملی (۱۵-۶۰ دقیقه)

اعمال fixها با تایید دستی:

```bash
sudo ~/security-tools/security-fix-interactive.sh
```

**چه کاری انجام می‌دهد:**
- AI مشکلات امنیتی را تحلیل می‌کند
- دستورات رفع مشکل پیشنهاد می‌دهد
- ارزیابی خطر برای هر fix نمایش می‌دهد
- منتظر تایید شما می‌ماند (y/n/t/s/q)
- قبل از تغییرات backup می‌گیرد
- fixهای تایید شده را اجرا می‌کند
- fixهای انجام شده را ردیابی می‌کند

**گزینه‌های تعاملی:**
- `y` - اجرای fix
- `n` - رد کردن این fix
- `t` - حالت تست (نمایش دستور بدون اجرا)
- `s` - نمایش اطلاعات تکمیلی (man page)
- `q` - خروج

**ویژگی‌های ایمنی:**
- هر fix نیاز به تایید دستی دارد
- ارزیابی خطر (بحرانی/بالا/متوسط/پایین/اطلاعاتی)
- پشتیبان‌گیری خودکار قبل از تغییرات
- ثبت کامل اقدامات
- قابلیت ادامه (Ctrl+C ایمن است)

### 🎯 جریان کار معمول

```bash
# روز ۱: اجرای ممیزی (ممکن است زمان ببرد)
sudo ~/security-tools/security-audit.sh

# روز ۲: بررسی و رفع
sudo ~/security-tools/security-ai-analyzer.sh  # اختیاری
sudo ~/security-tools/security-fix-interactive.sh
```

### 📊 سطوح خطر

| سطح | امتیاز | مثال‌ها |
|-----|--------|---------|
| 🚨 **بحرانی** | ۱۰+ | `rm -rf`، `chmod 777`، فرمت کردن دیسک |
| ⚠️ **بالا** | ۷-۹ | حذف فایل، متوقف کردن SSH |
| ⚡ **متوسط** | ۴-۶ | حذف بسته، راه‌اندازی مجدد سرویس، ویرایش تنظیمات |
| 📝 **پایین** | ۲-۳ | نصب بسته، تغییر فایروال |
| ✅ **اطلاعاتی** | ۰-۱ | دستورات فقط خواندنی |

### 🔄 قابلیت ادامه

اگر با Ctrl+C قطع شود، اسکریپت fixهای انجام شده را به خاطر می‌سپارد:

```bash
# اجرای اول - ۵ fix انجام دادید، سپس Ctrl+C
sudo ~/security-tools/security-fix-interactive.sh

# اجرای دوم - fixهای انجام شده را خودکار skip می‌کند
sudo ~/security-tools/security-fix-interactive.sh
```

fixهای انجام شده در اینجا ردیابی می‌شوند:
```
/var/log/security-audit/completed-fixes.txt
```

برای شروع از نو:
```bash
sudo rm /var/log/security-audit/completed-fixes.txt
```

### 📁 محل فایل‌ها

```
~/security-tools/                          # محل اسکریپت‌ها
├── security-audit.sh                      # اسکریپت ممیزی
├── security-ai-analyzer.sh                # تحلیل AI
├── security-fix-interactive.sh            # رفع تعاملی
└── README.md                              # این فایل

/var/log/security-audit/                   # لاگ‌ها و گزارش‌ها
├── consolidated-report-*.txt              # گزارش‌های کامل ممیزی
├── ai-analysis-ready-*.txt                # خلاصه‌های آماده AI
├── completed-fixes.txt                    # ردیاب fixهای انجام شده
├── fix-history-*.log                      # لاگ اجرای fixها
└── ai-reports/                            # گزارش‌های تحلیل AI

/var/backups/security-fixes-*/             # پشتیبان‌های خودکار
```

### 🛠️ عیب‌یابی

**فایل ممیزی پیدا نشد:**
```bash
sudo ~/security-tools/security-audit.sh
```

**مدل مناسب پیدا نشد:**
```bash
ollama pull qwen2.5-coder:1.5b-instruct
```

**دسترسی رد شد:**
```bash
chmod +x ~/security-tools/*.sh
```

**بسته در حین fix قطع شد:**
```bash
sudo dpkg --configure -a
sudo apt --fix-broken install
```

**بازگردانی از پشتیبان:**
```bash
sudo cp /var/backups/security-fixes-*/FILE /original/location/
```

### 💡 نکات

- از `t` (حالت تست) برای پیش‌نمایش دستورات قبل از اجرا استفاده کنید
- هر زمان Ctrl+C بزنید - ایمن است و می‌توانید بعداً ادامه دهید
- `/var/log/security-audit/fix-history-*.log` را برای ردیابی بررسی کنید
- ابتدا فقط fixهای بحرانی و با اولویت بالا را انجام دهید
- پشتیبان‌ها را حداقل ۳۰ روز نگه دارید

### 📦 مدل‌های پیشنهادی

| مدل | حجم | سرعت | کیفیت | توصیه |
|-----|------|-------|--------|-------|
| qwen2.5-coder:1.5b-instruct | ۱GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | بهترین برای استفاده روزانه |
| qwen2.5-coder:7b | 4.7GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | بهترین کیفیت |
| mistral:7b | 4.1GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | جایگزین خوب |

### 🔐 ملاحظات امنیتی

- همه اسکریپت‌ها نیاز به دسترسی root دارند
- تحلیل AI به صورت محلی اجرا می‌شود (بدون cloud)
- لاگ‌های ممیزی حاوی اطلاعات حساس سیستم هستند
- دایرکتوری لاگ‌ها (`/var/log/security-audit/`) را امن نگه دارید
- همه fixها را قبل از تایید بررسی کنید

### 📄 مجوز

این اسکریپت‌ها برای اهداف آموزشی و تقویت امنیتی به صورت as-is ارائه می‌شوند.

### 🤝 مشارکت

خوشحال می‌شویم این اسکریپت‌ها را بهبود دهید و پیشرفت‌هایتان را به اشتراک بگذارید!

---

## 📞 Support / پشتیبانی

For issues or questions:
- Check troubleshooting section above
- Review log files in `/var/log/security-audit/`
- Ensure all prerequisites are installed

برای مشکلات یا سوالات:
- بخش عیب‌یابی بالا را بررسی کنید
- فایل‌های لاگ در `/var/log/security-audit/` را بررسی کنید
- مطمئن شوید همه پیش‌نیازها نصب شده‌اند

---

**Version:** 1.0.0  
**Last Updated:** January 2026  
**Compatible with:** Debian 13 (Trixie)