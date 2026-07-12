# Jarvis Voice Assistant (Flutter)

একটা ভয়েস-কন্ট্রোলড AI অ্যাসিস্ট্যান্ট অ্যাপ। "Hello Jarvis" বললে অ্যাক্টিভ হয় (কোনো বিপ সাউন্ড ছাড়াই, Picovoice Porcupine wake word engine দিয়ে), প্রশ্ন শোনে, তোমার নিজের API endpoint-এ পাঠায়, উত্তর ভয়েসে বলে + স্ক্রিনে দেখায়।

## যা যা আছে
- Porcupine wake word engine — "Hello Jarvis" ডিটেকশন সাউন্ড/বিপ ছাড়াই, ব্যাটারি সাশ্রয়ী
- ডার্ক থিম, গ্লোয়িং orb অ্যানিমেশন + কাস্টম অ্যাপ আইকন
- **৪টা draggable প্যানেল** (TRANSCRIPT/STATUS/NEWS/QUICK ACTIONS) — স্ক্রিনের ৪ কোণায় ডিফল্ট থাকে
  - যেকোনো প্যানেল **টেনে অন্য কোণায় নিয়ে যাওয়া যায়** (drag করে ছেড়ে দিলে কাছের কোণায় স্ন্যাপ হয়ে যাবে)
  - **ডাবল-ট্যাপ** করলে প্যানেলটা বড় হয়ে স্ক্রিনের বেশিরভাগ জায়গা নেবে, আবার ডাবল-ট্যাপ করলে ছোট হয়ে কোণায় ফিরে যাবে
- অ্যাপ খুললেই সময় অনুযায়ী গ্রিটিং, উত্তরের আগে ছোট filler ("Give me a sec, boss")
- "Open YouTube" / "Open WhatsApp" ইত্যাদি — সরাসরি অ্যাপ খোলে
- "Set an alarm for 5 am" — Clock অ্যাপে অ্যালার্ম সেট করে
- "latest news" জিজ্ঞেস করলে আলাদা News API endpoint ব্যবহার করবে (কনফিগার করা থাকলে)
- ব্যাকগ্রাউন্ডে চলার জন্য foreground service (Android 14+ এর মাইক্রোফোন সার্ভিস টাইপ সহ)
- **অ্যাপের বাইরে থেকেও কাজ করবে** — অন্য অ্যাপ চালানোর সময় "Hello Jarvis" বললে একটা ছোট overlay window ভেসে উঠবে, উত্তর দেখাবে/বলবে (ইন্সটলের পর "Display over other apps" পারমিশন দিতে হবে)
- Settings screen — Picovoice key, main AI endpoint, news endpoint সব এক জায়গায়

## ইন্সটলের আগে যা যা জোগাড় করতে হবে

### ১. Picovoice Access Key (ফ্রি, wake word এর জন্য বাধ্যতামূলক)
- console.picovoice.ai এ গিয়ে ফ্রি অ্যাকাউন্ট বানাও
- Dashboard-এ তোমার **AccessKey** দেখতে পাবে, কপি করো

### ২. AI API (চ্যাটের জন্য)
- OpenRouter/Groq থেকে API key নাও (আগের মতো)

## Termux থেকে GitHub-এ পুশ করার ধাপ

```bash
pkg update && pkg install git -y
cd jarvis_app
git init
git add .
git commit -m "Initial Jarvis app"
git branch -M main
git remote add origin https://github.com/<তোমার-ইউজারনেম>/jarvis_app.git
git push -u origin main
```

## APK কীভাবে পাবে
push করার সাথে সাথে GitHub Actions অটোমেটিক APK বিল্ড শুরু করবে (৮-১২ মিনিট লাগতে পারে নতুন প্যাকেজের কারণে)।
1. GitHub রিপোতে **Actions** ট্যাব → "Build Jarvis APK" workflow
2. রান শেষ হলে (সবুজ ✓) নিচে **Artifacts** থেকে `jarvis-apk` ডাউনলোড করো
3. জিপ এক্সট্র্যাক্ট করে `app-release.apk` ইন্সটল করো

## অ্যাপ ওপেন করার পর (প্রথমবার)
1. মাইক্রোফোন, নোটিফিকেশন, ব্যাটারি অপটিমাইজেশন — সব পারমিশনে **Allow** দিও
2. Settings (গিয়ার আইকন) এ গিয়ে:
   - Picovoice Access Key বসাও
   - Main AI API URL/Key/Model বসাও
   - (ঐচ্ছিক) News API বসাও
3. Save করে মেইন স্ক্রিনে ফিরে "Hello Jarvis" বলো

## নোট — সততার সাথে বলা সীমাবদ্ধতা
- **রিয়েল ভিডিও-স্টাইল মাল্টি-মনিটর ড্যাশবোর্ড** মোবাইলে literally সম্ভব না — এই অ্যাপে বদলে ৪টা status panel দিয়ে প্রফেশনাল "control center" লুক দেওয়া হয়েছে, যেটা ফোনের স্ক্রিনে বাস্তবসম্মত
- **সম্পূর্ণ বন্ধ (recent apps থেকে swipe)** করার পর কাজ করবে না — এটা কোনো অ্যাপই পারে না (Google Assistant বাদে, যেটা সিস্টেম-লেভেল প্রি-ইনস্টলড সার্ভিস)। হোম বাটনে গেলে/মিনিমাইজ করলে ঠিকই চলবে (notification সহ)
- App size আগের চেয়ে কিছুটা বাড়বে (Porcupine + foreground service প্যাকেজের কারণে) — এটা প্রয়োজনীয় ফিচারের জন্য স্বাভাবিক ট্রেড-অফ
