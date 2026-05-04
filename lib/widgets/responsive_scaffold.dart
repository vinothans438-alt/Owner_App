import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget? filters;
  final Widget body;
  final List<Widget>? actions;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    this.filters,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 900;

    final appBar = AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: actions,
      flexibleSpace: Container(
        decoration: isDesktop ? null : const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003D73), Color(0xFF005096)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filters != null) 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: filters,
          ),
        Expanded(child: body),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            const SizedBox(
              width: 280,
              child: AppDrawer(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Scaffold(
                appBar: appBar,
                body: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      drawer: const AppDrawer(),
      body: content,
    );
  }
}
