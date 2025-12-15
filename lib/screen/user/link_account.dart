import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../server/aba_service.dart';


class LinkAccountScreen extends StatelessWidget {
  const LinkAccountScreen({super.key});

  Future<void> linkAccount(BuildContext context) async {
    final result = await AbaService.requestAof();

    if (result['status']['code'] == '00') {
      final deeplink = result['deeplink'];

      final uri = Uri.parse(deeplink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ABA Mobile not installed")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['status']['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link ABA Account")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => linkAccount(context),
          child: const Text("Link ABA Account"),
        ),
      ),
    );
  }
}
