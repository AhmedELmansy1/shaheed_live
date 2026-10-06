import 'package:flutter/material.dart';

class DeveloperProfile {
  final String nameAr;
  final String nameEn;
  final String titleAr;
  final String titleEn;
  final String bioAr;
  final String bioEn;
  final EducationInfo education;
  final List<ServiceInfo> services;
  final List<SkillCategory> skillCategories;
  final List<ProjectInfo> featuredProjects;
  final List<CertificateInfo> certificates;
  final SocialLinks social;

  const DeveloperProfile({
    required this.nameAr,
    required this.nameEn,
    required this.titleAr,
    required this.titleEn,
    required this.bioAr,
    required this.bioEn,
    required this.education,
    required this.services,
    required this.skillCategories,
    required this.featuredProjects,
    required this.certificates,
    required this.social,
  });

  static const DeveloperProfile data = DeveloperProfile(
    nameAr: 'أحمد المنسي',
    nameEn: 'Ahmed Elmansy',
    titleAr: 'مطور Flutter • ذكاء اصطناعي • أمن سيبراني',
    titleEn: 'Flutter Developer • AI • Cybersecurity',
    bioAr: 'أحمد المنسي مطور برمجيات وخريج علوم حاسب، متخصص في تطوير تطبيقات Flutter والحلول المعتمدة على الذكاء الاصطناعي، مع اهتمام بالأمن السيبراني والأدلة الجنائية الرقمية. يهتم بتحويل الأفكار إلى تطبيقات عملية، حديثة وسهلة الاستخدام.',
    bioEn: 'Ahmed Elmansy is a Computer Science graduate and software developer focused on building modern Flutter applications, AI-powered solutions, cybersecurity, and digital forensics. He enjoys turning ideas into practical, scalable, and user-friendly software.',
    education: EducationInfo(
      degreeAr: 'بكالوريوس الحاسبات والمعلومات',
      degreeEn: 'Bachelor’s Degree in Computer Science and Information',
      universityAr: 'جامعة بنها',
      universityEn: 'Benha University',
      specializationAr: 'أمن المعلومات والأدلة الجنائية الرقمية',
      specializationEn: 'Information Security & Digital Forensics',
      overallGradeAr: 'جيد جداً (Very Good)',
      overallGradeEn: 'Very Good',
      graduationProjectAr:
          'نظام كشف التزييف والتلاعب بالأدلة الرقمية (Forgery Detection)',
      graduationProjectEn: 'Forgery Detection System',
      projectGradeAr: 'امتياز (Excellent 🌟)',
      projectGradeEn: 'Excellent',
    ),
    services: [
      ServiceInfo(
        titleAr: 'تطوير تطبيقات Flutter',
        titleEn: 'Flutter Development',
        descriptionAr: 'تطوير تطبيقات أندرويد حديثة وعالية الأداء باستخدام Flutter وDart بواجهات مستخدم عصرية وسلسة.',
        icon: Icons.phone_android_rounded,
        tag: 'Mobile',
      ),
      ServiceInfo(
        titleAr: 'تطبيقات مدعومة بالذكاء الاصطناعي',
        titleEn: 'AI-Powered Applications',
        descriptionAr: 'دمج تقنيات ونماذج الذكاء الاصطناعي ورؤية الحاسوب والتحليل الذكي في الحلول البرمجية العملية.',
        icon: Icons.psychology_rounded,
        tag: 'AI / ML',
      ),
      ServiceInfo(
        titleAr: 'الأمن السيبراني',
        titleEn: 'Cybersecurity',
        descriptionAr: 'حلول ومشاريع مرتبطة بأمن المعلومات، حماية البيانات، والتحليل الأمني للأنظمة والتطبيقات.',
        icon: Icons.security_rounded,
        tag: 'Security',
      ),
      ServiceInfo(
        titleAr: 'الأدلة الجنائية الرقمية',
        titleEn: 'Digital Forensics',
        descriptionAr: 'تحليل الملفات والوسائط الرقمية واكتشاف التلاعب والتزييف (Forgery & Deepfakes) والتحقق الجنائي.',
        icon: Icons.manage_search_rounded,
        tag: 'Forensics',
      ),
      ServiceInfo(
        titleAr: 'حلول الويب والـ Desktop',
        titleEn: 'Desktop & Web Solutions',
        descriptionAr: 'تطوير برمجيات متعددة المنصات وقابلة للتوسع تلبي متطلبات المشاريع المتقدمة بكفاءة.',
        icon: Icons.laptop_chromebook_rounded,
        tag: 'Cross-Platform',
      ),
    ],
    skillCategories: [
      SkillCategory(
        categoryNameAr: 'تطوير البرمجيات (Development)',
        categoryNameEn: 'Development',
        icon: Icons.code_rounded,
        accentColor: Color(0xFFD4AF37),
        skills: [
          'Flutter',
          'Dart',
          'Android Development',
          'Responsive UI',
          'REST APIs',
          'State Management',
        ],
      ),
      SkillCategory(
        categoryNameAr: 'الذكاء الاصطناعي وتعلم الآلة (AI & ML)',
        categoryNameEn: 'AI & Machine Learning',
        icon: Icons.auto_awesome_rounded,
        accentColor: Color(0xFF00B0FF),
        skills: [
          'AI Integration',
          'Computer Vision',
          'Image Analysis',
          'Audio Analysis',
          'Deepfake Detection',
          'AI-powered Applications',
        ],
      ),
      SkillCategory(
        categoryNameAr: 'الأمن السيبراني والأدلة الرقمية (Security)',
        categoryNameEn: 'Cybersecurity & Digital Forensics',
        icon: Icons.shield_rounded,
        accentColor: Color(0xFFFFC94D),
        skills: [
          'Digital Forensics',
          'Information Security',
          'File & Metadata Analysis',
          'Forgery Detection',
          'Security Analysis',
          'Hashing / SHA-256',
        ],
      ),
      SkillCategory(
        categoryNameAr: 'الأدوات والتقنيات (Tools & Tech)',
        categoryNameEn: 'Tools & Technologies',
        icon: Icons.build_circle_rounded,
        accentColor: Color(0xFFB388FF),
        skills: [
          'Git',
          'GitHub',
          'Firebase',
          'REST APIs',
          'Android Studio',
          'VS Code',
        ],
      ),
    ],
    featuredProjects: [
      ProjectInfo(
        titleAr: 'AI-Powered Digital Forensics System',
        titleEn: 'AI-Powered Digital Forensics System',
        categoryAr: 'مشروع التخرج • تقدير امتياز 🌟',
        categoryEn: 'Graduation Project • Excellent Grade',
        descriptionAr: 'مشروع تخرج متخصص في تحليل الأدلة الرقمية واكتشاف التلاعب والتزييف في الصور والصوت والفيديو باستخدام تقنيات الذكاء الاصطناعي والتحليل الجنائي المتقدم.',
        icon: Icons.fingerprint_rounded,
        highlighted: true,
        tags: [
          'Image Forgery Detection',
          'Audio Deepfake Analysis',
          'Video Analysis',
          'Error Level Analysis (ELA)',
          'Metadata Analysis',
          'Noise Analysis',
          'Grad-CAM',
          'Spectrogram Analysis',
          'SHA-256',
          'AI Confidence',
        ],
      ),
      ProjectInfo(
        titleAr: 'Shoot Live',
        titleEn: 'Shoot Live',
        categoryAr: 'تطبيق رياضي مباشر • Flutter',
        categoryEn: 'Sports & Live Scores App • Flutter',
        descriptionAr: 'تطبيق شامل لمتابعة مباريات كرة القدم والنتائج والتشكيلات والإحصائيات في الوقت الفعلي، بواجهة حديثة ونظام تنبيهات متقدم وسريع.',
        icon: Icons.sports_soccer_rounded,
        highlighted: false,
        tags: [
          'Flutter',
          'Riverpod',
          'REST APIs',
          'FCM Notifications',
          'Tactical Lineups',
          'Dark/Light Themes',
        ],
      ),
      ProjectInfo(
        titleAr: 'Forests Team',
        titleEn: 'Forests Team',
        categoryAr: 'إدارة المهام والعمل الجماعي',
        categoryEn: 'Task & Team Management App',
        descriptionAr: 'تطبيق Flutter لإدارة ومتابعة المهام والمشاريع المشتركة بإنتاجية عالية، مع دعم اللغتين العربية والإنجليزية وتوافق كامل مع اتجاه RTL.',
        icon: Icons.groups_rounded,
        highlighted: false,
        tags: [
          'Flutter',
          'State Management',
          'RTL & Multilingual',
          'Task Board',
          'UI/UX',
        ],
      ),
      ProjectInfo(
        titleAr: 'Mansy Store',
        titleEn: 'Mansy Store',
        categoryAr: 'منصة تجارة إلكترونية',
        categoryEn: 'E-Commerce Platform',
        descriptionAr: 'مشروع Flutter للتجارة الإلكترونية وتجربة عرض وتصفح المنتجات وإدارتها وتجربة دفع وشراء متكاملة وسلسة.',
        icon: Icons.shopping_bag_rounded,
        highlighted: false,
        tags: [
          'Flutter',
          'E-Commerce',
          'Product Catalog',
          'Cart Flow',
          'Clean Architecture',
        ],
      ),
      ProjectInfo(
        titleAr: 'مشاريع تدريب ITI (ITI Projects)',
        titleEn: 'ITI Flutter Projects',
        categoryAr: 'تطبيقات تدريبية متقدمة',
        categoryEn: 'Advanced Training Projects',
        descriptionAr: 'مجموعة مشاريع وتطبيقات تم تطويرها خلال التدريب المكثف بمعهد تكنولوجيا المعلومات ITI باستخدام أحدث ممارسات Flutter وDart.',
        icon: Icons.school_rounded,
        highlighted: false,
        tags: [
          'Flutter',
          'Dart',
          'API Integration',
          'Architecture Patterns',
          'Best Practices',
        ],
      ),
    ],
    certificates: [
      CertificateInfo(
        title: 'Cisco CCNA — Introduction to Networks',
        issuer: 'Cisco Networking Academy',
        icon: Icons.hub_rounded,
      ),
      CertificateInfo(
        title: 'Cisco CCNA — Switching, Routing & Wireless Essentials',
        issuer: 'Cisco Networking Academy',
        icon: Icons.router_rounded,
      ),
      CertificateInfo(
        title: 'Huawei HCIA-Datacom V1.0',
        issuer: 'Huawei ICT Academy',
        icon: Icons.cloud_done_rounded,
      ),
      CertificateInfo(
        title: 'Huawei HCIA-Datacom Learning Course',
        issuer: 'Huawei ICT Academy',
        icon: Icons.cast_for_education_rounded,
      ),
      CertificateInfo(
        title: 'Cybertalents — Linux Practitioner',
        issuer: 'CyberTalents',
        icon: Icons.terminal_rounded,
      ),
      CertificateInfo(
        title: 'Database Fundamentals',
        issuer: 'Professional Training',
        icon: Icons.storage_rounded,
      ),
      CertificateInfo(
        title: 'HTML & CSS / PHP & MySQL',
        issuer: 'Web Fundamentals',
        icon: Icons.web_rounded,
      ),
      CertificateInfo(
        title: 'WordPress Website Development',
        issuer: 'Web Development',
        icon: Icons.view_quilt_rounded,
      ),
    ],
    social: SocialLinks(
      githubUrl: 'https://github.com/AhmedELmansy1',
      githubUsername: 'AhmedELmansy1',
      linkedinUrl: 'https://www.linkedin.com/in/ahmed-elmansy-a6b494346',
      linkedinUsername: 'Ahmed Elmansy',
      email: 'ahmedelmansy1311@gmail.com',
      whatsappUrl: 'https://wa.me/201067995211',
    ),
  );
}

class EducationInfo {
  final String degreeAr;
  final String degreeEn;
  final String universityAr;
  final String universityEn;
  final String specializationAr;
  final String specializationEn;
  final String overallGradeAr;
  final String overallGradeEn;
  final String graduationProjectAr;
  final String graduationProjectEn;
  final String projectGradeAr;
  final String projectGradeEn;

  const EducationInfo({
    required this.degreeAr,
    required this.degreeEn,
    required this.universityAr,
    required this.universityEn,
    required this.specializationAr,
    required this.specializationEn,
    required this.overallGradeAr,
    required this.overallGradeEn,
    required this.graduationProjectAr,
    required this.graduationProjectEn,
    required this.projectGradeAr,
    required this.projectGradeEn,
  });
}

class ServiceInfo {
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final IconData icon;
  final String tag;

  const ServiceInfo({
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.icon,
    required this.tag,
  });
}

class SkillCategory {
  final String categoryNameAr;
  final String categoryNameEn;
  final IconData icon;
  final Color accentColor;
  final List<String> skills;

  const SkillCategory({
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.icon,
    required this.accentColor,
    required this.skills,
  });
}

class ProjectInfo {
  final String titleAr;
  final String titleEn;
  final String categoryAr;
  final String categoryEn;
  final String descriptionAr;
  final IconData icon;
  final bool highlighted;
  final List<String> tags;

  const ProjectInfo({
    required this.titleAr,
    required this.titleEn,
    required this.categoryAr,
    required this.categoryEn,
    required this.descriptionAr,
    required this.icon,
    required this.highlighted,
    required this.tags,
  });
}

class CertificateInfo {
  final String title;
  final String issuer;
  final IconData icon;

  const CertificateInfo({
    required this.title,
    required this.issuer,
    required this.icon,
  });
}

class SocialLinks {
  final String githubUrl;
  final String githubUsername;
  final String linkedinUrl;
  final String linkedinUsername;
  final String email;
  final String whatsappUrl;

  const SocialLinks({
    required this.githubUrl,
    required this.githubUsername,
    required this.linkedinUrl,
    required this.linkedinUsername,
    required this.email,
    required this.whatsappUrl,
  });
}
