import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('How to use BLASTQR')),
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
                '1. Download the BLASTQR app',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text(
                  'Download the BLASTQR app on any device where you want to receive or send files. Both devices need to have the BLASTQR app.',
                ),
                const SizedBox(height: 8),
                const Placeholder(fallbackHeight: 300),
                const SizedBox(height: 8),
                Text(
                  'Scan this QR code to download BLASTQR on another device.',
                ),
                const SizedBox(height: 12),
              ],
            ),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                '2. Transfering a file',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text(
                  'From the app\'s main screen, select the file or picture that you want to send.\n\nThe file will be encoded into an animated sequence of QR codes that you can then scan from another device that has BLASTQR installed.',
                ),
                const SizedBox(height: 12),
              ],
            ),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                '3. Receiving a file',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text(
                  'On another device, scan the animated QR code using the BLASTQR app by selecting the \'Receive\' tab.\n\nThe files you receive are stored in the \'Files\' tab within the app.',
                ),
                const SizedBox(height: 12),
              ],
            ),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                '4. Additional information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                Text(
                  'BLASTQR file transfers work completely offline.\n\nDue to the nature of the technology BLASTQR file transfers are slow (peaking at around 40kB/s). I recommend transferring small files or compressing them in advance.\n\nFor higher speeds you can play with the \'Chunk length\' setting in the Settings screen. A higher value can result in higher speeds but not all devices might be able to handle it.',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
