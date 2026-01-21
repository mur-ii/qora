import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/profile_entity.dart';

/// Section 1: Profile & Level
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with level ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: profile.levelProgress,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getLevelColor(profile.currentLevel),
                  ),
                ),
              ),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profile.avatarUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: 164,
                    memCacheWidth: 164,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getLevelColor(profile.currentLevel),
                        _getLevelColor(
                          profile.currentLevel,
                        ).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    'Lv ${profile.currentLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            profile.email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),

          const SizedBox(height: 12),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getLevelColor(profile.currentLevel).withValues(alpha: 0.15),
                  _getLevelColor(profile.currentLevel).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: _getLevelColor(profile.currentLevel),
                ),
                const SizedBox(width: 8),
                Text(
                  profile.levelTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getLevelColor(profile.currentLevel),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress bar with XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress ke Level ${profile.currentLevel + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    '${((profile.levelProgress) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getLevelColor(profile.currentLevel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: profile.levelProgress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getLevelColor(profile.currentLevel),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${NumberFormat('#,###').format(profile.currentXP)} XP',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(profile.xpToNextLevel)} XP',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Edit Profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to edit profile
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Edit Profil',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level < 5) return const Color(0xFF42A5F5);
    if (level < 10) return const Color(0xFF43A047);
    if (level < 20) return const Color(0xFF8E24AA);
    if (level < 30) return const Color(0xFFF4511E);
    return const Color(0xFFF57C00);
  }
}

/// Section 2: Payment Information
class PaymentInformationSection extends StatelessWidget {
  const PaymentInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Informasi Pembayaran',
      icon: Icons.credit_card_outlined,
      children: [
        _MenuItem(
          icon: Icons.payment_outlined,
          title: 'Metode Pembayaran',
          subtitle: '2 kartu tersimpan',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Riwayat Transaksi',
          subtitle: 'Lihat semua transaksi',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Pembayaran Aktif',
          subtitle: 'Tidak ada pembayaran tertunda',
          onTap: () {},
          showBadge: false,
        ),
      ],
    );
  }
}

/// Section 3: Account Management
class AccountManagementSection extends StatelessWidget {
  const AccountManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Manajemen Akun',
      icon: Icons.manage_accounts_outlined,
      children: [
        _MenuItem(
          icon: Icons.lock_outline,
          title: 'Ubah Kata Sandi',
          subtitle: 'Perbarui kata sandi Anda',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.security_outlined,
          title: 'Keamanan Akun',
          subtitle: 'Autentikasi dua faktor',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.logout_outlined,
          title: 'Keluar',
          subtitle: 'Keluar dari akun Anda',
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Keluar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AuthBloc>().add(LogoutEvent());
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE57373),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
          },
          iconColor: const Color(0xFFE57373),
          showChevron: false,
        ),
      ],
    );
  }
}

/// Section 4: Preferences
class PreferencesSection extends StatelessWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Preferensi',
      icon: Icons.settings_outlined,
      children: [
        _MenuItem(
          icon: Icons.language_outlined,
          title: 'Bahasa',
          subtitle: 'Indonesia',
          onTap: () {},
        ),
        _MenuItemWithToggle(
          icon: Icons.notifications_outlined,
          title: 'Notifikasi',
          subtitle: 'Notifikasi push',
          value: true,
          onChanged: (value) {},
        ),
        _MenuItemWithToggle(
          icon: Icons.email_outlined,
          title: 'Notifikasi Email',
          subtitle: 'Pembaruan pemesanan & penawaran',
          value: true,
          onChanged: (value) {},
        ),
        _MenuItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Pengaturan Privasi',
          subtitle: 'Kelola privasi Anda',
          onTap: () {},
        ),
      ],
    );
  }
}

/// Section 5: Help & Support
class HelpSupportSection extends StatelessWidget {
  const HelpSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Bantuan & Dukungan',
      icon: Icons.help_outline,
      children: [
        _MenuItem(
          icon: Icons.help_center_outlined,
          title: 'Pusat Bantuan',
          subtitle: 'FAQ dan panduan',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.contact_support_outlined,
          title: 'Hubungi Kami',
          subtitle: 'Hubungi dukungan pelanggan',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.description_outlined,
          title: 'Syarat & Ketentuan',
          subtitle: 'Baca syarat kami',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.policy_outlined,
          title: 'Kebijakan Privasi',
          subtitle: 'Bagaimana kami melindungi data Anda',
          onTap: () {},
        ),
      ],
    );
  }
}

/// Reusable section card widget
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

/// Reusable menu item widget
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.showChevron = true,
    this.showBadge = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showChevron;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? Colors.grey[700]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// Menu item with toggle switch
class _MenuItemWithToggle extends StatelessWidget {
  const _MenuItemWithToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
