import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import 'viewer_common.dart';

/// Screen 17: PDF erst komplett in den Cache laden (mit Fortschritt), dann
/// lokal mit pdfrx rendern – Seiten-Scroll, Zoom, Seitensprung, Text-Suche.
class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({super.key, required this.entry, this.local});

  final NasEntry entry;
  final LocalFile? local;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final _controller = PdfViewerController();

  /// Erst mit geladenem Dokument (braucht einen fertigen Controller).
  PdfTextSearcher? _searcher;
  final _pageInput = TextEditingController();
  int _page = 1;
  int _pages = 0;
  bool _searching = false;

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searcher
      ?..removeListener(_update)
      ..dispose();
    _pageInput.dispose();
    super.dispose();
  }

  void _setPage(int page) {
    _page = page;
    _pageInput.text = '$page';
  }

  void _goTo(int page) {
    if (_pages == 0) return;
    final target = page.clamp(1, _pages);
    _controller.goToPage(pageNumber: target);
    setState(() => _setPage(target));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    final searcher = _searching ? _searcher : null;
    return Scaffold(
      appBar: searcher != null
          ? AppBar(
              titleSpacing: 0,
              leading: BackButton(
                onPressed: () {
                  searcher.resetTextSearch();
                  setState(() => _searching = false);
                },
              ),
              title: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchInDocument,
                  border: InputBorder.none,
                ),
                onChanged: searcher.startTextSearch,
              ),
              actions: [
                Center(
                  child: Text(
                    searcher.matches.isEmpty
                        ? (searcher.isSearching || searcher.pattern == null
                              ? ''
                              : l10n.noMatches)
                        : '${(searcher.currentIndex ?? 0) + 1}/'
                              '${searcher.matches.length}',
                    style: AppTheme.mono(),
                  ),
                ),
                IconButton(
                  tooltip: l10n.previousMatch,
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: searcher.matches.isEmpty
                      ? null
                      : searcher.goToPrevMatch,
                ),
                IconButton(
                  tooltip: l10n.nextMatch,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: searcher.matches.isEmpty
                      ? null
                      : searcher.goToNextMatch,
                ),
              ],
            )
          : AppBar(
              titleSpacing: 0,
              title: ViewerTitle(entry.name, entrySubtitle(entry, l10n)),
              actions: [
                IconButton(
                  tooltip: l10n.searchInDocument,
                  icon: const Icon(Icons.search),
                  onPressed: _searcher == null
                      ? null
                      : () => setState(() => _searching = true),
                ),
                ShareButton(entry, local: widget.local),
                const SizedBox(width: 8),
              ],
            ),
      body: CachedFileView(
        entry: entry,
        local: widget.local,
        builder: (context, file) => PdfViewer.file(
          file.path,
          controller: _controller,
          params: PdfViewerParams(
            backgroundColor: AppColors.background,
            onViewerReady: (document, controller) => setState(() {
              _pages = document.pages.length;
              _setPage(controller.pageNumber ?? 1);
              _searcher ??= PdfTextSearcher(controller)..addListener(_update);
            }),
            onPageChanged: (page) {
              if (page != null) setState(() => _setPage(page));
            },
            pagePaintCallbacks: [
              (canvas, rect, page) =>
                  _searcher?.pageTextMatchPaintCallback(canvas, rect, page),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _pages == 0 ? null : _pageBar(l10n),
    );
  }

  Widget _pageBar(AppLocalizations l10n) {
    final mono = AppTheme.mono(const TextStyle(fontSize: 16));
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: LinearProgressIndicator(
                  value: _page / _pages,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.pdfPrevious,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
                  ),
                  const Spacer(),
                  Text(l10n.pdfPage, style: mono),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _pageInput,
                      textAlign: TextAlign.center,
                      style: mono,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (v) => _goTo(int.tryParse(v) ?? _page),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.pdfOfTotal('$_pages'), style: mono),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.pdfNext,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _page < _pages ? () => _goTo(_page + 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
