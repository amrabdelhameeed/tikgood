import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GridViewItemWidget extends StatelessWidget {
  final String title;
  final String value;
  final bool showDivider;
  const GridViewItemWidget(
      {super.key,
      required this.title,
      required this.value,
      this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      width: 0.4.sw,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 5.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
            showDivider
                ? Expanded(
                    child: Divider(
                    color: Colors.grey,
                  ))
                : SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}
