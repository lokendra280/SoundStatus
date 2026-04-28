import 'package:flutter/material.dart';
import 'package:soundstatus/dashboard/widget/dashboard_widget.dart';
import 'package:soundstatus/widgets/update_wrapper.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UpdateWrapper(child: const DashboardWidget());
  }
}
