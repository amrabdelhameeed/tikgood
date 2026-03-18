import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  const EmptyStateWidget(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/empty.svg'),
            SizedBox(
              height: 10,
            ),
            Text(
              this.title.tr(),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
            )
          ],
        ),
      ),
    );
  }
}
