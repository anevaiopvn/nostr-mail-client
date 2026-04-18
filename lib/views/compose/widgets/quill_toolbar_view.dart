import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostr_mail_client/controllers/compose_controller.dart';

class QuillToolbarView extends StatelessWidget {
  const QuillToolbarView({super.key});

  @override
  Widget build(BuildContext context) {
    final iconTheme = QuillIconTheme(
      iconButtonSelectedData: IconButtonData(
        color: Theme.of(context).colorScheme.primary,
        style: const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      iconButtonUnselectedData: const IconButtonData(),
    );

    return QuillSimpleToolbar(
      controller: ComposeController.to.quillController,
      config: QuillSimpleToolbarConfig(
        buttonOptions: QuillSimpleToolbarButtonOptions(
          bold: QuillToolbarToggleStyleButtonOptions(iconTheme: iconTheme),
          italic: QuillToolbarToggleStyleButtonOptions(iconTheme: iconTheme),
          underLine: QuillToolbarToggleStyleButtonOptions(iconTheme: iconTheme),
          strikeThrough: QuillToolbarToggleStyleButtonOptions(
            iconTheme: iconTheme,
          ),
          listNumbers: QuillToolbarToggleStyleButtonOptions(
            iconTheme: iconTheme,
          ),
          listBullets: QuillToolbarToggleStyleButtonOptions(
            iconTheme: iconTheme,
          ),
        ),
        showAlignmentButtons: false,
        showBackgroundColorButton: false,
        showCenterAlignment: false,
        showClearFormat: false,
        showCodeBlock: false,
        showColorButton: false,
        showDirection: false,
        showFontFamily: false,
        showFontSize: false,
        showHeaderStyle: false,
        showIndent: false,
        showInlineCode: false,
        showJustifyAlignment: false,
        showLeftAlignment: false,
        showListBullets: true,
        showListCheck: false,
        showListNumbers: true,
        showQuote: false,
        showRightAlignment: false,
        showSearchButton: false,
        showSmallButton: false,
        showStrikeThrough: true,
        showSubscript: false,
        showSuperscript: false,
        showUndo: false,
        showRedo: false,
        showClipboardCopy: false,
        showClipboardCut: false,
        showClipboardPaste: false,
        multiRowsDisplay: false,
      ),
    );
  }
}
