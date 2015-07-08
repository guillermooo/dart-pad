// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dartpad.dialogs;

import 'dart:html';

import 'core/keys.dart';
import 'elements/elements.dart';
import 'sharing/gists.dart';
import 'sharing/mutable_gist.dart';
import 'src/util.dart';

/**
 * Show an OK / Cancel dialog, and return the option that the user selected.
 */

class OkCancelDialog extends DDialog {

  OkCancelDialog(String title, String message, Function okAction,
      {String okText: 'OK', String cancelText: 'Cancel'})
      : super(title: title) {
    element.classes.toggle('sharing-dialog', true);
    content.add(new ParagraphElement())
        ..text = message;

    DButton cancelButton = buttonArea.add(new DButton.button(text: cancelText));
    buttonArea.add(new SpanElement()..attributes['flex'] = '');
    cancelButton.onClick.listen((_) => hide());

    DButton okButton =
        buttonArea.add(new DButton.button(text: okText, classes: 'default'));
    okButton.onClick.listen((_) {
      okAction();
      hide();
    });
  }
}

class AboutDialog extends DDialog {
  AboutDialog([String version]) : super(title: 'About DartPad') {
    ParagraphElement p = content.add(new ParagraphElement());
    String text = privacyText;
    if (version != null) text += " Based on Dart SDK ${version}.";
    p.setInnerHtml(text, validator: new PermissiveNodeValidator());

    buttonArea.add(new SpanElement()..attributes['flex'] = '');
    DButton okButton =
        buttonArea.add(new DButton.button(text: "OK", classes: 'default'));
    okButton.onClick.listen((_) => hide());
  }
}

class EmbedDialog extends DDialog {
  final GistContainer gistContainer;
  final GistController gistController;

  ParagraphElement _text;
  ParagraphElement _controls;
  DButton _cancelButton;
  DElement _doc;
  DElement _html;
  DElement _inline;
  
  EmbedDialog(
      GistContainer this.gistContainer, GistController this.gistController)
      : super(title: 'Embedding Options') {
    element.classes.toggle('sharing-dialog', true);

    content.setAttr('layout');
    content.setAttr('vertical');

    _text = content.add(new ParagraphElement());
    _controls = content.add(new ParagraphElement());
    _doc = content.add(new DElement.tag('div')..layoutHorizontal());
    _html = content.add(new DElement.tag('div')..layoutHorizontal());
    _inline = content.add(new DElement.tag('div')..layoutHorizontal());

    _cancelButton = new DButton.button(text: 'Cancel');
    _cancelButton.onClick.listen((_) => hide());
  }

  void show() {
    _configure();
    super.show();
  }
  
  void generateExport() {
    MutableGist gist = gistContainer.mutableGist;
    Uri url = Uri.parse(window.location.toString());
    String home = url.host;
    _doc.add(new SpanElement()..text = 'Dart + Documentation: ' ..style.paddingRight = "12px");
    _doc.add(new InputElement()..value = '${home}/embed-dart.com?id=${gist.id}' ..attributes['flex'] = '');
    _html.add(new SpanElement()..text = "Dart + Html: " ..style.paddingRight = "12px");
    _html.add(new InputElement()..value = '${home}/embed-html.com?id=${gist.id}' ..attributes['flex'] = '');
    _inline.add(new SpanElement()..text = "Dart (Minimal): " ..style.paddingRight = "12px");
    _inline.add(new InputElement()..value = '${home}/embed-inline.com?id=${gist.id}' ..attributes['flex'] = '');
  }

  void _configure() {
    buttonArea.element.children.clear();
    _text.text = 'URL to an embeddable iframe source.';
    _controls.text = 'Query controls: horizontalRatio (0.1 to 0.9), verticalRatio (0.1 to 0.9), id (gist id)';
    generateExport();
    buttonArea.add(_cancelButton);
    buttonArea.add(new SpanElement()..attributes['flex'] = '');
  }
}

class SharingDialog extends DDialog {
  final GistContainer gistContainer;
  final GistController gistController;

  ParagraphElement _text;
  TextAreaElement _textArea;
  DButton _cancelButton;
  DButton _shareButton;
  DButton _closeButton;
  DButton _embedButton;
  DElement _div;
  DInput _padUrl;
  DInput _gistUrl;
  String _summary;

  SharingDialog(
      GistContainer this.gistContainer, GistController this.gistController,
      {String summary: ""})
      : super(title: 'Sharing') {
    element.classes.toggle('sharing-dialog', true);
    _summary = summary;

    content.setAttr('layout');
    content.setAttr('vertical');

    _text = content.add(new ParagraphElement());
    _textArea = content.add(new TextAreaElement());
    _textArea.className = 'sharingSummaryText';
    _textArea.setAttribute('flex', '');

    // About to share.
    _cancelButton = new DButton.button(text: 'Cancel');
    _cancelButton.onClick.listen((_) => hide());
    _shareButton = new DButton.button(text: 'Share it!', classes: 'default');
    _shareButton.onClick.listen((_) => _performShare());

    // Already sharing.
    _closeButton = new DButton.button(text: 'Close', classes: 'default');
    _closeButton.onClick.listen((_) => hide());
    _div = new DElement.tag('div')..layoutVertical();
    _embedButton = new DButton.button(text: 'Embed', classes: 'default');
    _embedButton.onClick.listen((_) {
      EmbedDialog exportDialog = new EmbedDialog(gistContainer, gistController);
      exportDialog.show();
      hide();
    });
    DElement div =
        _div.add(new DElement.tag('div', classes: 'row')..layoutHorizontal());
    div.add(new DElement.tag('span', classes: 'sharinglabel'))
      ..text = 'DartPad:';
    DElement inputGroup = div.add(new DElement.tag('div'))
      ..layoutHorizontal()
      ..flex();
    _padUrl = inputGroup.add(new DInput.input(type: 'text'))
      ..flex()
      ..readonly();
    _padUrl.onClick.listen((_) => _padUrl.selectAll());

    div = _div.add(new DElement.tag('div', classes: 'row')..layoutHorizontal());
    div.add(new DElement.tag('span', classes: 'sharinglabel'))
      ..text = 'gist.github.com:';
    inputGroup = div.add(new DElement.tag('div'))
      ..layoutHorizontal()
      ..flex();
    _gistUrl = inputGroup.add(new DInput.input(type: 'text'))
      ..flex()
      ..readonly();
    _gistUrl.onClick.listen((_) => _gistUrl.selectAll());
  }

  void showWithSummary(String summary) {
    this._summary = summary;
    show();
  }

  void show() {
    _configure(gistContainer.mutableGist);
    super.show();
  }

  void _configure(MutableGist gist) {
    if (!gist.hasId || gist.dirty) {
      _switchTo(aboutToShare: true);
    } else {
      _switchTo(aboutToShare: false);
    }
  }

  void _switchTo({bool aboutToShare: true}) {
    buttonArea.element.children.clear();
    _div.dispose();

    if (aboutToShare) {
      // Show 'about to share'.
      _text.text = 'Sharing this pad will create a permanent, publicly visible '
          'copy on gist.github.com.';
      _textArea.defaultValue = _summary == null ? '' : _summary;
      _textArea.style.display = 'block';

      buttonArea.add(_cancelButton);
      buttonArea.add(new SpanElement()..attributes['flex'] = '');
      buttonArea.add(_shareButton);
    } else {
      // Show the existing sharing info.
      _text.text =
          'Share the DartPad link or view the source at gist.github.com.';
      _textArea.style.display = 'none';

      MutableGist gist = gistContainer.mutableGist;

      content.add(_div);
      _padUrl.value = 'https://dartpad.dartlang.org/${gist.id}';
      _gistUrl.value = gist.html_url;
      buttonArea.add(_closeButton);
      buttonArea.add(new SpanElement()..attributes['flex'] = '');
      buttonArea.add(_embedButton);
    }
  }

  void _performShare() {
    _shareButton.disabled = true;

    // TODO: Show a spinner.
    gistController.shareAnon(summary: _textArea.value).then((_) {
      _switchTo(aboutToShare: false);
    }).whenComplete(() {
      _shareButton.disabled = false;
    });
  }
}

class KeysDialog extends DDialog {
  Map<Action, Set<String>> keyMap;

  KeysDialog(this.keyMap) : super(title: 'Keyboard shortcuts') {
    element.classes.toggle('keys-dialog', true);
    content.add(keyMapToHtml);
  }

  DListElement get keyMapToHtml {
    DListElement dl = new DListElement();
    keyMap.forEach((Action action, Set<String> keys) {
      if (!action.hidden) {
        String string = "";
        keys.forEach((key) {
          if (makeKeyPresentable(key) != null) {
            string += "<span>${makeKeyPresentable(key)}</span>";
          }
        });
        dl.innerHtml += "<dt>${action}</dt><dd>${string}</dd>";
      }
    });
    return dl;
  }

  // TODO: expose options
  //  DListElement get optionMapToHtml {
  //    DListElement dl = new DListElement();
  //    optionMap.forEach((key, value) {
  //      dl.innerHtml += "<dt>${capitalize(key.replaceAll("_"," "))}</dt>"
  //      '<dd><input type="checkbox" id="$key" ${options.getValueBool(key) ? "checked" : ""}></dd>';
  //    });
  //    return dl;
  //  }
}
