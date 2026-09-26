/// Papierkorb eines Shares: DSM verschiebt Gelöschtes nach
/// `/<share>/#recycle/<Pfad im Share>` und behält die Ordnerstruktur.
String recycleFolder(String share) => '${shareOf(share)}/#recycle';

/// Shared Folder eines Pfads: `/music/Alben/x.flac` → `/music`.
String shareOf(String path) => '/${path.split('/')[1]}';

/// Ursprungspfad eines Eintrags im Papierkorb:
/// `/dokumente/#recycle/Verträge/a.pdf` → `/dokumente/Verträge/a.pdf`.
/// `null`, wenn [path] nicht unterhalb eines `#recycle` liegt.
String? restorePathOf(String path) {
  final parts = path.split('/');
  // ['', share, '#recycle', ...rest]; rest darf nicht leer sein.
  if (parts.length < 4 || parts[0].isNotEmpty || parts[2] != '#recycle') {
    return null;
  }
  return '/${parts[1]}/${parts.skip(3).join('/')}';
}
