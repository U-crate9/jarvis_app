# Jarvis Voice Assistant (Flutter)

একটা ভয়েস-কন্ট্রোলড AI অ্যাসিস্ট্যান্ট অ্যাপ। "Hello Jarvis" বললে অ্যাক্টিভ হয়, তোমার প্রশ্ন শোনে, তোমার নিজের API endpoint-এ পাঠায়, আর উত্তর ভয়েসে বলে + স্ক্রিনে দেখায়।

## যা যা আছে
- ডার্ক থিম, গ্লোয়িং orb অ্যানিমেশন (listening/thinking/speaking state অনুযায়ী বদলায়)
- Wake phrase: "Hello Jarvis" (কোড এ বদলানো যাবে `home_screen.dart`-এর `_wakePhrase` ভ্যারিয়েবলে)
- চ্যাট transcript UI
- Settings screen — এখানে তোমার API URL, key, আর model name বসাবে (OpenRouter/Groq/নিজের Colab server — যেকোনো OpenAI-compatible endpoint)

## Termux থেকে GitHub-এ পুশ করার ধাপ

```bash
pkg update && pkg install git -y
cd jarvis_app          # এই ফোল্ডারে (যেটা তুমি ডাউনলোড করেছ)
git init
git add .
git commit -m "Initial Jarvis app"
git branch -M main
git remote add origin https://github.com/<তোমার-ইউজারনেম>/jarvis_app.git
git push -u origin main
```

(প্রথমবার GitHub-এ একটা নতুন empty repo বানিয়ে নিও নাম `jarvis_app` দিয়ে, তারপর উপরের `<তোমার-ইউজারনেম>` জায়গায় নিজের ইউজারনেম বসাও।)

## APK কীভাবে পাবে
push করার সাথে সাথে GitHub Actions অটোমেটিক APK বিল্ড শুরু করবে (৫-৮ মিনিট লাগে)।
1. GitHub রিপোতে যাও → **Actions** ট্যাব
2. "Build Jarvis APK" workflow-এ ক্লিক করো, রান শেষ হওয়া পর্যন্ত অপেক্ষা করো (সবুজ ✓ চিহ্ন দেখাবে)
3. রানের ভেতরে নিচে **Artifacts** সেকশনে `jarvis-apk` নামে একটা ফাইল থাকবে — ওটা ডাউনলোড করো
4. জিপ ফাইলটা এক্সট্র্যাক্ট করলে `app-release.apk` পাবে — ওটা ফোনে ইন্সটল করো (Unknown sources অন করতে হতে পারে)

## অ্যাপ ওপেন করার পর
1. প্রথমে **Settings** (উপরে ডানদিকে গিয়ার আইকন) এ গিয়ে তোমার API URL, key, আর model name বসাও → Save
2. মেইন স্ক্রিনে ফিরে "Hello Jarvis" বললেই অ্যাক্টিভ হবে
3. মাইক্রোফোন পারমিশন চাইলে Allow দিও

## নোট
- প্রতিটা প্রোভাইডারের রেট লিমিট নিজের নিয়মে কাজ করে — Settings-এ URL বদলে যেকোনো সময় প্রোভাইডার সুইচ করতে পারবে
- সরাসরি "নিউজ" জিজ্ঞেস করলে মডেল নিজে থেকে রিয়েল-টাইম খবর জানবে না (এটা একটা future upgrade — চাইলে পরে একটা News API যোগ করে দিতে পারি)
