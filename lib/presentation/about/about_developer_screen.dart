import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/developer_profile.dart';
import 'widgets/developer_bio_card.dart';
import 'widgets/developer_certificates_section.dart';
import 'widgets/developer_contact_section.dart';
import 'widgets/developer_education_card.dart';
import 'widgets/developer_header.dart';
import 'widgets/developer_projects_section.dart';
import 'widgets/developer_services_section.dart';
import 'widgets/developer_skills_section.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  void _shareProfile(BuildContext context, DeveloperProfile profile) {
    HapticFeedback.lightImpact();
    final shareText =
        '''
${profile.nameAr} (${profile.nameEn})
${profile.titleEn}
🎓 ${profile.education.degreeEn} - ${profile.education.universityEn}
🛡️ Specialization: ${profile.education.specializationEn}
💼 GitHub: ${profile.social.githubUrl}
🔗 LinkedIn: ${profile.social.linkedinUrl}
✉️ Email: ${profile.social.email}
📱 WhatsApp: ${profile.social.whatsappUrl}
''';
    // ignore: deprecated_member_use
    Share.share(
      shareText,
      subject: 'Ahmed Elmansy - Developer Profile',
    );
  }

  @override
  Widget build(BuildContext context) {
    const profile = DeveloperProfile.data;
    final textPrimary = AppColors.textPrimaryOf(context);
    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          AppStrings.aboutDeveloper,
          style: AppTypography.titleMedium(color: textPrimary)
              .copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          tooltip: 'رجوع',
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: textPrimary, size: 20),
            tooltip: 'مشاركة الملف المهني',
            onPressed: () => _shareProfile(context, profile),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Header
              const DeveloperHeader(profile: profile)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(
                    begin: -0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.md),

              // 2. Bio Card
              const DeveloperBioCard(profile: profile)
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.md),

              // 3. Education Section
              DeveloperEducationCard(education: profile.education)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.xl),

              // 4. What I Do Section
              DeveloperServicesSection(services: profile.services)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.xl),

              // 5. Skills & Expertise
              DeveloperSkillsSection(categories: profile.skillCategories)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.xl),

              // 6. Featured Projects
              DeveloperProjectsSection(projects: profile.featuredProjects)
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.xl),

              // 7. Certificates & Training
              DeveloperCertificatesSection(certificates: profile.certificates)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.xl),

              // 8. Contact & Social Section
              DeveloperContactSection(social: profile.social)
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppSpacing.xxl),

              // Footer Note
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'تم تطوير التطبيق بواسطة أحمد المنسي',
                      style: AppTypography.caption(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Crafted with passion using Flutter & Modern Architecture',
                      style: AppTypography.caption(
                        color: AppColors.textMutedOf(context),
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
