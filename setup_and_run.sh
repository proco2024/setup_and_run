#!/bin/bash

echo "--- اسکریپت راه‌اندازی و اجرای V2Ray Tester CLI ---"
echo "این اسکریپت نیازمندی‌های سیستمی و پایتون را نصب کرده و ابزار تست کانفیگ را اجرا می‌کند."
echo "لطفاً در طول فرآیند، اگر درخواستی برای تأیید دیدید (مثلاً [Y/n])، 'Y' را وارد کرده و Enter بزنید."

# 0. تنظیم میرور Termux به صورت خودکار برای اطمینان از نصب موفق
echo ""
echo "در حال تنظیم میرور Termux به یک میرور پایدار..."
# از یک میرور مشخص و قابل اعتماد استفاده می‌کنیم.
# این دستور فایل sources.list را مستقیماً ویرایش می‌کند.
echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list
echo "deb https://packages-cf.termux.dev/apt/termux-root stable root" >> $PREFIX/etc/apt/sources.list
echo "deb https://packages-cf.termux.dev/apt/termux-x11 x11 main" >> $PREFIX/etc/apt/sources.list
# پس از تغییر sources.list، حتماً pkg update را اجرا کنید.
pkg update -y || { echo "خطا در به‌روزرسانی پکیج‌ها پس از تنظیم میرور. لطفاً اتصال اینترنت خود را بررسی کنید."; exit 1; }
echo "میرور با موفقیت تنظیم شد."

# 1. به‌روزرسانی پکیج‌های Termux
echo ""
echo "در حال به‌روزرسانی پکیج‌های Termux..."
pkg upgrade -y || { echo "خطا در به‌روزرسانی پکیج‌های Termux. لطفاً اتصال اینترنت خود را بررسی کنید."; exit 1; }

# 2. نصب پایتون، Git و Xray اگر قبلاً نصب نشده باشند
echo ""
echo "در حال نصب پایتون، Git و Xray..."
pkg install python -y || { echo "خطا در نصب پایتون. لطفاً مطمئن شوید Termux به درستی کار می‌کند."; exit 1; }
pkg install git -y || { echo "خطا در نصب Git. لطفاً مطمئن شوید Termux به درستی کار می‌کند."; exit 1; }
pkg install xray -y || { echo "خطا در نصب Xray. لطفاً مطمئن شوید Termux به درستی کار می‌کند و Xray در مخازن موجود است."; exit 1; }

# 3. اعطای دسترسی به حافظه (اگر قبلاً اعطا نشده باشد)
echo ""
echo "در حال تنظیم دسترسی Termux به حافظه..."
termux-setup-storage || { echo "خطا در تنظیم دسترسی به حافظه. لطفاً به Termux اجازه دسترسی به حافظه را بدهید."; }

# 4. از کاربر می‌خواهد آدرس مخزن گیت‌هاب پروژه را وارد کند
echo ""
read -p "لطفاً آدرس کامل مخزن گیت‌هاب پروژه (مثلاً https://github.com/yourusername/your-repo.git) را وارد کنید: " GITHUB_REPO_URL

# استخراج نام دایرکتوری از URL مخزن
REPO_NAME=$(basename "$GITHUB_REPO_URL" .git)

# 5. کلون کردن مخزن گیت‌هاب یا به‌روزرسانی آن
echo ""
echo "در حال کلون کردن/به‌روزرسانی پروژه از گیت‌هاب..."
if [ -d "$REPO_NAME" ]; then
    echo "دایرکتوری '$REPO_NAME' از قبل وجود دارد. در حال به‌روزرسانی..."
    cd "$REPO_NAME" && git pull || { echo "خطا در به‌روزرسانی مخزن گیت. لطفاً دسترسی‌ها را بررسی کنید."; exit 1; }
else
    git clone "$GITHUB_REPO_URL" || { echo "خطا در کلون کردن مخزن گیت‌هاب. لطفاً آدرس URL را بررسی کنید."; exit 1; }
    cd "$REPO_NAME" || { echo "خطا در ورود به دایرکتوری '$REPO_NAME'"; exit 1; }
fi

# 6. نصب وابستگی‌های پایتون از requirements.txt
echo ""
echo "در حال نصب وابستگی‌های پایتون از requirements.txt..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt || { echo "خطا در نصب وابستگی‌های پایتون. لطفاً اتصال اینترنت خود را بررسی کنید."; exit 1; }
else
    echo "فایل requirements.txt یافت نشد. نصب دستی requests و tqdm..."
    pip install requests tqdm || { echo "خطا در نصب دستی پکیج‌ها. لطفاً اتصال اینترنت خود را بررسی کنید."; exit 1; }
fi

# 7. اجرای اسکریپت پایتون
echo ""
echo "در حال شروع ابزار V2Ray Tester CLI..."
echo "برای توقف، Ctrl+C را در این جلسه Termux فشار دهید."
echo ""

# اطمینان از اینکه Xray processes قبل از شروع کشته می شوند (لایه اضافی)
pkill -f xray || true # '|| true' ensures script doesn't exit if no xray process is found

python vpn_cli.py || { echo "خطا در اجرای اسکریپت پایتون. لطفاً لاگ‌ها را بررسی کنید."; exit 1; }

echo "اسکریپت به پایان رسید."
