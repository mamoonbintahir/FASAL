/// Normalises Pakistani mobile numbers to E.164 (`+923XXXXXXXXX`).
/// Accepts `03XXXXXXXXX`, `3XXXXXXXXX`, `923XXXXXXXXX`, `+92 3XX XXXXXXX`,
/// `0092…`. Returns null if the input is not a Pakistani mobile number.
/// Shared by the app (instant validation) and the server (authoritative).
String? normalizePkPhone(String input) {
  var d = input.replaceAll(RegExp(r'[\s\-()]'), '');
  if (d.startsWith('+')) d = d.substring(1);
  if (d.startsWith('0092')) d = d.substring(2);
  if (d.startsWith('92')) {
    d = d.substring(2);
  } else if (d.startsWith('0')) {
    d = d.substring(1);
  }
  return RegExp(r'^3\d{9}$').hasMatch(d) ? '+92$d' : null;
}
