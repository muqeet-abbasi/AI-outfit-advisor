// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../theme/app_theme.dart';

// class OutfitCard extends StatelessWidget {
//   final String title;
//   final String content;
//   final IconData icon;

//   const OutfitCard({
//     super.key,
//     required this.title,
//     required this.content,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 16, color: AppTheme.accent),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: GoogleFonts.dmSans(
//                   color: AppTheme.textSecondary,
//                   fontSize: 11,
//                   letterSpacing: 1.5,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Text(
//             content,
//             style: GoogleFonts.dmSans(
//               color: AppTheme.textPrimary,
//               fontSize: 14,
//               height: 1.6,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
