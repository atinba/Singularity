import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class BoxSwitchTile extends StatelessWidget {
  const BoxSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.keyName,
    required this.defaultValue,
    this.isThreeLine,
    this.onChanged,
    this.contentPadding,
  });

  final Text title;
  final Text? subtitle;
  final String keyName;
  final bool defaultValue;
  final bool? isThreeLine;
  final EdgeInsetsGeometry? contentPadding;
  final Function({required bool val, required Box box})? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (BuildContext context, Box box, Widget? widget) {
        return MergeSemantics(
          child: ListTile(
            title: title,
            subtitle: subtitle,
            isThreeLine: isThreeLine ?? false,
            dense: true,
            contentPadding: contentPadding,
            trailing: CupertinoSwitch(
              activeTrackColor: Theme.of(context).colorScheme.secondary,
              value: box.get(keyName, defaultValue: defaultValue) as bool? ??
                  defaultValue,
              onChanged: (val) {
                box.put(keyName, val);
                onChanged?.call(val: val, box: box);
              },
            ),
            onTap: () {
              final bool currentValue =
                  box.get(keyName, defaultValue: defaultValue) as bool? ??
                      defaultValue;
              box.put(keyName, !currentValue);
              onChanged?.call(val: !currentValue, box: box);
            },
          ),
        );
      },
    );
  }
}
