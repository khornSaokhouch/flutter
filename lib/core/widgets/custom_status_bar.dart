import 'package:flutter/material.dart';

class CustomStatusBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomStatusBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(40.0);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final String time = TimeOfDay.now().format(context);

    return Container(
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top > 0 ? mediaQuery.padding.top : 5.0,
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),
      color: Colors.white,

    );
  }
}
