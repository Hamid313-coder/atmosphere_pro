import 'package:at_common_flutter/services/size_config.dart';
import 'package:atsign_atmosphere_pro/utils/colors.dart';
import 'package:atsign_atmosphere_pro/view_models/welcome_screen_view_model.dart';
import 'package:flutter/material.dart';

class SideBarItem extends StatelessWidget {
  final String image;
  final String title;
  final String routeName;
  final Map<String, dynamic> arguments;
  final bool showIconOnly;
  final WelcomeScreenProvider _welcomeScreenProvider = WelcomeScreenProvider();
  final Color displayColor;
  bool isScale;
  SideBarItem(
      {Key key,
      this.image,
      this.title,
      this.routeName,
      this.arguments,
      this.showIconOnly = false,
      this.isScale = false,
      this.displayColor = ColorConstants.fadedText})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (SizeConfig().isMobile(context)) {
      isScale = false;
    }

    return InkWell(
      onTap: () {
        if (SizeConfig().isMobile(context) ||
            _welcomeScreenProvider.isExpanded) {
          Navigator.pop(context);
        }
        Navigator.pushNamed(context, routeName, arguments: arguments ?? {});
      },
      child: Container(
        height: 50,
        child: Row(
          children: [
            Transform.scale(
              scale: isScale ? 1.2 : 1,
              child: Image.asset(
                image,
                height: SizeConfig().isTablet(context) ? 24 : 22.toHeight,
                color: displayColor,
              ),
            ),
            SizedBox(width: 10),
            !showIconOnly
                ? Text(
                    title,
                    softWrap: true,
                    style: TextStyle(
                      color: displayColor,
                      letterSpacing: 0.1,
                      fontSize: 14.toFont,
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
