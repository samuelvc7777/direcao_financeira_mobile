import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class RideDetailInfoCard extends StatelessWidget {
  const RideDetailInfoCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<RideDetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.sp(context, 18).clamp(14.0, 22.0)),
      decoration: BoxDecoration(
        color: AppColors.midnight,
        borderRadius: BorderRadius.circular(
          Responsive.sp(context, 24).clamp(20.0, 28.0),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.vp(context, 1.4).clamp(10.0, 14.0)),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(
                bottom: Responsive.vp(context, 1.2).clamp(8.0, 12.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.sp(context, 8).clamp(6.0, 10.0),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        Responsive.sp(context, 12).clamp(10.0, 14.0),
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: AppColors.royalBlue,
                      size: Responsive.sp(context, 18).clamp(16.0, 20.0),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.hp(context, 3.0).clamp(10.0, 14.0),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.vp(context, 0.3).clamp(2.0, 4.0),
                        ),
                        Text(
                          item.value,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RideDetailItem {
  const RideDetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
