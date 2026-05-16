import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22.r,
      backgroundColor: AppColors.highlight,
      backgroundImage: null,
      child: Icon(Icons.person,
          size: 38.sp, color: AppColors.light),
    );
  }
}
