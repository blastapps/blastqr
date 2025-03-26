import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  static const String projectUrl = 'https://github.com/cu-kha/blastqr';

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.help_title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: true,
              title: Text(
                '1. ${context.l10n.help_title_1}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text(context.l10n.help_message_1_1),
                const SizedBox(height: 16),
                Image.asset('assets/download-qr.png', height: 250),
                const SizedBox(height: 16),
                Text(context.l10n.help_message_1_2),
                const SizedBox(height: 12),
              ],
            ),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: true,
              title: Text(
                '2. ${context.l10n.help_title_2}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text(context.l10n.help_message_2),
                const SizedBox(height: 12),
              ],
            ),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: true,
              title: Text(
                '3. ${context.l10n.help_title_3}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text(context.l10n.help_message_3),
                const SizedBox(height: 12),
              ],
            ),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: true,
              title: Text(
                '4. ${context.l10n.help_title_4}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text('${context.l10n.help_message_4} ${HelpPage.projectUrl}'),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
