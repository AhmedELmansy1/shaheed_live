# ⚽ شاهد لايف | Shahid Live

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State_Management-Riverpod-000000?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Cloud-Firebase_Firestore-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen)
![Design](https://img.shields.io/badge/Theme-Midnight_Stadium_Amber-F59E0B)

**تطبيق رياضي احترافي للبث المباشر ومتابعة نتائج وجداول مباريات كرة القدم لحظة بلحظة بتصميم عصري وأداء فائق السرعة.**

*A state-of-the-art Flutter mobile application for live sports coverage, real-time football scores, match schedules, and high-performance live streaming.*

</div>

---

## 🌟 أبرز المميزات (Key Features)

### 1. 🎯 تدفق المباريات والأولويات الذكي (Smart Priority Feed)
- **الأولوية الأولى (أنديتك المفضلة ⭐):** عرض مباريات الفرق التي يتابعها المستخدم في قمة الشاشة الرئيسية تلقائياً.
- **الأولوية الثانية (دورياتك المفضلة 🏆):** استعراض بطولاتك المفضلة الجارية والقادمة اليوم مباشرة أسفل أنديتك.
- **الأولوية الثالثة والبديل الذكي (أقوى قمم اليوم ⚽):** في حال عدم وجود مباريات لفرقك أو دورياتك المفضلة اليوم، يظهر تنبيه لطيف مع فلترة وعرض أقوى مباريات البطولات الكبرى فقط (دوري أبطال أوروبا، الدوري الإنجليزي، الإسباني، المصري، السعودي، دوري أبطال إفريقيا، إلخ).
- **طيّ البطولات الثانوية:** تنظيم الشاشة بإخفاء الدوريات غير الجماهيرية تحت زر أنيق لتوسيع القائمة عند الحاجة لمنع تشتت المستخدم.

### 2. ⚡ التغطية الحية وتفاصيل المباريات (Live Scores & Match Details)
- تحديث فوري لنتائج المباريات، الوقت المنقضي، وحالة اللقاء (مباشر، قادم، انتهت، تأجلت).
- مركز إحصائيات متكامل: التشكيلات الرسمية، الأحداث (أهداف، بطاقات، تبديلات)، المواجهات المباشرة (H2H)، وجداول ترتيب الدوريات.

### 3. 🕒 ضبط التوقيت التلقائي بدقة (Accurate Timezones & Kickoff)
- تحويل مواعيد المباريات تلقائياً لتوافق التوقيت المحلي لبلد المشترك مع معالجة دقيقة لاختلاف التوقيت الصيفي/الشتوي (Cairo / UTC / Local Timezones).
- معالجة حالات المباريات غير محددة الموعد (TBD) والتعامل الذكي مع صيغ التواريخ المختلفة.

### 4. 📺 مشغل البث المباشر فائق الأداء (Integrated Live Streaming)
- مشغل فيديو مدمج متطور يدعم بثوث HLS الأصلية (`.m3u8`) بالإضافة إلى البث المضمن عبر الويب تلقائياً مع معالجة ذكية لأي نوع رابط بث.
- دعم العرض في وضع ملء الشاشة الأفقي (Landscape)، انخفاض زمن التأخير، وإدارة متطورة للصوت بدون مقاطعات.

### 5. 🎛️ إدارة سحابية متقدمة (Remote Config & Instant Updates)
- ربط سحابي فوري مع لوحة التحكم (Dashboard) عبر Google Cloud Firestore.
- **التحكم بالتحديثات عن بعد:** ظهور رسالة التحديث الجديد وروابط التحميل المباشرة حصرياً عند تفعيلها من لوحة التحكم (Force Update / Soft Update)، مع إمكانية توجيه المشتركين لأحدث رابط APK بضغطة زر.
- تحكم لحظي في شريط الأخبار العاجلة (Ticker)، الإعلانات (AdMob / Sponsorships)، وإعدادات السيرفرات.

---

## 🎨 الهوية البصرية (Design System: Midnight Stadium — Amber Edition)

تم تصميم التطبيق وفق طراز رياضي مظلم فاخر ومستوحى من ملاعب كرة القدم ليلاً:
- **Obsidian Dark (`#080B11`):** خلفية داكنة مريحة للعين وموفرة للطاقة (AMOLED Friendly).
- **Electric Amber / Gold (`#F59E0B`):** لون التمييز الأساسي للأزرار والأيقونات والبطاقات المهمة.
- **Pitch Emerald (`#10B981`):** مؤشر المباريات المباشرة النارية (LIVE Badge).
- **Dark Slate Surfaces (`#0F1522` / `#161F30`):** بطاقات ثلاثية الأبعاد خفيفة بتأثير Glassmorphism وحواف مستديرة ناعمة.

---

## 🏗️ البنية البرمجية (Architecture)

يتبع المشروع أفضل ممارسات هندسة البرمجيات المعمارية باستخدام **Clean Architecture** بأسلوب **Feature-First**:

```text
lib/
├── core/                       # النواة المشتركة للتطبيق
│   ├── config/                 # إعدادات التطبيق والثوابت العامة (AppConstants)
│   ├── network/                # عميل الشبكة (Dio Client, Interceptors)
│   ├── routing/                # التنقل والحماية (GoRouter, Navigation Guards)
│   ├── services/               # الخدمات الأساسية (RemoteConfig, Battery, Updates)
│   ├── theme/                  # نظام التصميم، الألوان، الخطوط، والأحجام
│   └── utils/                  # الأدوات المساعدة للوقت، الفلترة، والمشاركة
├── data/                       # طبقة البيانات
│   ├── models/                 # نماذج البيانات (Match, Team, League, Config)
│   └── repositories/           # مستودعات جلب البيانات وتخزينها
├── domain/                     # طبقة الأعمال والنماذج المعرفية
│   └── entities/               # الكيانات النقية (Entities)
└── presentation/               # طبقة الواجهات وعرض البيانات (UI & State)
    ├── home/                   # الشاشة الرئيسية وجداول المباريات
    ├── match_details/          # شاشة تفاصيل وإحصائيات المباراة
    ├── player/                 # مشغل البث المباشر
    ├── leagues/                # شاشات الدوريات والترتيب
    ├── onboarding/             # شاشات الترحيب واختيار الفرق والدوريات
    ├── settings/               # إعدادات التطبيق والمظهر والتوقيت
    ├── update/                 # شاشات ونوافذ التحديث الإجباري والفرعي
    └── widgets/                # المكونات الرسومية القابلة لإعادة الاستخدام
```

---

## 🚀 التشغيل والتثبيت (Getting Started)

### المتطلبات الأساسية (Prerequisites):
- **Flutter SDK:** 3.24.0 أو أحدث
- **Dart SDK:** 3.5.0 أو أحدث
- **Android Studio** أو **VS Code** مع إضافات Flutter/Dart
- **JDK:** 17+

### خطوات التثبيت:

1. **استنساخ المستودع (Clone Repository):**
   ```bash
   git clone https://github.com/AhmedELmansy1/shaheed_live.git
   cd shaheed_live
   ```

2. **تثبيت الحزم والمكتبات (Get Dependencies):**
   ```bash
   flutter pub get
   ```

3. **تشغيل التطبيق في وضع التطوير (Debug Mode):**
   ```bash
   flutter run
   ```

4. **بناء النسخة النهائية (Build Production Release APK):**
   ```bash
   flutter build apk --release
   ```
   *ستجد ملف الـ APK النهائي في المسار:* `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 الاختبارات والجودة (Testing & Code Quality)

يحتوي المشروع على منظومة اختبارات تغطي طبقات البيانات، منطق الأولويات، واحتساب فروق التوقيت:

```bash
# تشغيل جميع الاختبارات
flutter test

# فحص جودة وشفرة الكود
flutter analyze
```

---

## 🔒 الخصوصية والأمان

- يتم تخزين تفضيلات المستخدم (الفرق والدوريات المختارة) محلياً داخل الهاتف بصورة مشفرة وآمنة.
- جميع الاتصالات الشبكية بالسيرفرات وقواعد بيانات Firebase مشفرة ببروتوكول HTTPS / TLS.

---

<div align="center">

صُنع بكل ❤️ وشغف لجمهور كرة القدم العربي.  
**شاهد لايف © 2026**

</div>
