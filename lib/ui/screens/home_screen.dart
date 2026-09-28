import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../l10n/generated/app_localizations.dart';
import '../../models/platform_preset.dart';
import '../../models/release_mode.dart';
import '../../models/render_progress.dart';
import '../../models/render_settings.dart';
import '../../models/visualizer_placement.dart';
import '../../models/visualizer_style.dart';
import '../../state/providers.dart';
import '../widgets/audio_preview_player.dart';
import '../widgets/audio_trim_slider.dart';
import '../widgets/customization_panel.dart';
import '../widgets/desktop_title_bar.dart';
import '../widgets/file_drop_target.dart';
import '../widgets/load_template_button.dart';
import '../widgets/output_directory_picker.dart';
import '../widgets/performance_panel.dart';
import '../widgets/platform_preset_picker.dart';
import '../widgets/position_canvas.dart';
import '../widgets/preview_panel.dart';
import '../widgets/render_progress_view.dart';
import '../widgets/review_summary_row.dart';
import '../widgets/track_list_editor.dart';
import '../widgets/visualizer_placement_picker.dart';
import '../widgets/visualizer_style_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // "Save as template" on the Review & render step: a name typed here is
  // captured as a template alongside starting the render, not immediately -
  // so unchecking it or never pressing Render never saves anything.
  bool _saveAsTemplate = false;
  final _templateNameController = TextEditingController();

  static const _pageTransitionDuration = Duration(milliseconds: 320);
  static const _pageTransitionCurve = Curves.easeInOutCubic;

  @override
  void dispose() {
    _pageController.dispose();
    _templateNameController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: _pageTransitionDuration,
      curve: _pageTransitionCurve,
    );
  }

  /// A settings snapshot for the live preview: the actual RenderSettings
  /// that would produce this look, or null until enough is selected to
  /// render one. In multi-song/medley mode, previews the first track -
  /// which may supply its own cover image instead of the shared default.
  RenderSettings? _previewSettings(DraftSettings draft) {
    if (draft.releaseMode == ReleaseMode.single) {
      if (draft.imagePath == null || draft.audioPath == null) return null;
      return draft.toRenderSettings();
    }
    if (draft.tracks.isEmpty) return null;
    final firstTrack = draft.tracks.first;
    final effectiveImage = firstTrack.imagePath ?? draft.imagePath;
    if (effectiveImage == null) return null;
    return draft.toTemplateSettings().forTrack(
      firstTrack,
      defaultImagePath: effectiveImage,
    );
  }

  /// Whether the Files step has everything it needs before the wizard lets
  /// the user move on: a cover image and audio (single mode), or at least
  /// the required number of tracks each with a resolvable cover - either its
  /// own or the shared default (multi-song/medley mode).
  bool _filesStepComplete(DraftSettings draft) {
    switch (draft.releaseMode) {
      case ReleaseMode.single:
        return draft.imagePath != null && draft.audioPath != null;
      case ReleaseMode.multiSong:
        return draft.tracks.isNotEmpty &&
            (draft.imagePath != null ||
                draft.tracks.every((t) => t.imagePath != null));
      case ReleaseMode.medley:
        return draft.tracks.length >= 2 &&
            (draft.imagePath != null ||
                draft.tracks.every((t) => t.imagePath != null));
    }
  }

  String _releaseModeSummary(AppLocalizations l10n, DraftSettings draft) {
    switch (draft.releaseMode) {
      case ReleaseMode.single:
        return l10n.releaseModeSingle;
      case ReleaseMode.multiSong:
        return l10n.releaseModeMultiSong;
      case ReleaseMode.medley:
        return l10n.releaseModeMedley;
    }
  }

  String _filesSummary(AppLocalizations l10n, DraftSettings draft) {
    final cover = draft.imagePath != null
        ? p.basename(draft.imagePath!)
        : l10n.summaryValueNotSet;
    if (draft.releaseMode == ReleaseMode.single) {
      final audio = draft.audioPath != null
          ? p.basename(draft.audioPath!)
          : l10n.summaryValueNotSet;
      return '$cover · $audio';
    }
    return '$cover · ${l10n.summaryTrackCount(draft.tracks.length)}';
  }

  String _customizeSummary(AppLocalizations l10n, DraftSettings draft) {
    final elements = <String>[
      if (draft.showCover) l10n.elementCover,
      if (draft.showLogo) l10n.elementLogo,
      if (draft.showText) l10n.elementText,
      if (draft.showQrCode) l10n.elementQrCode,
      if (draft.vintageEffect) l10n.vintageEffectLabel,
    ];
    return elements.isEmpty ? l10n.summaryElementsNone : elements.join(', ');
  }

  String _durationSummary(AppLocalizations l10n, DraftSettings draft) {
    if (draft.fullDuration) return l10n.fullDuration;
    final start = draft.trimStartSeconds;
    final duration = draft.trimDurationSeconds ?? 0;
    String fmt(double seconds) {
      final m = (seconds ~/ 60).toString().padLeft(2, '0');
      final s = (seconds.round() % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return l10n.trimRangeLabel(
      fmt(start),
      fmt(start + duration),
      duration.toStringAsFixed(1),
    );
  }

  String _platformsSummary(AppLocalizations l10n, DraftSettings draft) {
    final presets = draft.selectedPresets;
    if (presets.isEmpty) return l10n.summaryPlatformsNone;
    return presets.map((preset) => preset.name).join(', ');
  }

  String _outputSummary(AppLocalizations l10n, DraftSettings draft) {
    final dir = draft.outputDirectory ?? l10n.outputDirectoryDefault;
    final hw = draft.useHardwareAcceleration ? l10n.summaryOn : l10n.summaryOff;
    final lossless = draft.losslessAudio ? l10n.summaryOn : l10n.summaryOff;
    return '$dir · ${l10n.hardwareAcceleration}: $hw · ${l10n.losslessAudio}: $lossless';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(draftSettingsProvider);
    final draftNotifier = ref.read(draftSettingsProvider.notifier);
    final progress = ref.watch(renderJobProvider);
    final renderNotifier = ref.read(renderJobProvider.notifier);
    final templates = ref.watch(templatesProvider);
    final templatesNotifier = ref.read(templatesProvider.notifier);

    final isRendering =
        progress.phase == RenderPhase.rendering ||
        progress.phase == RenderPhase.probing;
    final previewSettings = _previewSettings(draft);
    final previewPreset = draft.selectedPresets.isNotEmpty
        ? draft.selectedPresets.first
        : PlatformPreset.youtube;

    // Fixed step order (see the `pages` list below): Release type, Files,
    // Visualizer, Customize, [Duration - single mode only], Platforms,
    // Output & performance, Review & render. Tracked explicitly so the
    // summary's "edit" links can jump straight to the right page.
    const stepReleaseTypeIndex = 0;
    const stepFilesIndex = 1;
    const stepVisualizerIndex = 2;
    const stepCustomizeIndex = 3;
    final hasDurationStep = draft.releaseMode == ReleaseMode.single;
    final stepDurationIndex = hasDurationStep ? 4 : null;
    final stepPlatformsIndex = hasDurationStep ? 5 : 4;
    final stepOutputIndex = stepPlatformsIndex + 1;

    final pages = <(String, Widget)>[
      (
        l10n.stepReleaseType,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadTemplateButton(
              templates: templates,
              onApply: draftNotifier.applyTemplate,
              onDelete: templatesNotifier.delete,
            ),
            const SizedBox(height: 16),
            SegmentedButton<ReleaseMode>(
              segments: [
                ButtonSegment(
                  value: ReleaseMode.single,
                  label: Text(l10n.releaseModeSingle),
                ),
                ButtonSegment(
                  value: ReleaseMode.multiSong,
                  label: Text(l10n.releaseModeMultiSong),
                ),
                ButtonSegment(
                  value: ReleaseMode.medley,
                  label: Text(l10n.releaseModeMedley),
                ),
              ],
              selected: {draft.releaseMode},
              onSelectionChanged: (s) => draftNotifier.setReleaseMode(s.first),
            ),
          ],
        ),
      ),
      (
        l10n.stepFiles,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FileDropTarget(
              label: draft.releaseMode == ReleaseMode.single
                  ? l10n.coverImageLabelSingle
                  : l10n.coverImageLabelMulti,
              selectedPath: draft.imagePath,
              allowedExtensions: const ['png', 'jpg', 'jpeg'],
              onFileSelected: draftNotifier.setImagePath,
            ),
            const SizedBox(height: 12),
            if (draft.releaseMode == ReleaseMode.single)
              FileDropTarget(
                label: l10n.audioFileLabel,
                selectedPath: draft.audioPath,
                allowedExtensions: const [
                  'wav',
                  'mp3',
                  'flac',
                  'ogg',
                  'aiff',
                  'm4a',
                ],
                onFileSelected: draftNotifier.setAudioPath,
              )
            else ...[
              if (draft.releaseMode == ReleaseMode.medley) ...[
                Text(
                  l10n.medleyExplanation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ] else
                Text(
                  l10n.multiSongExplanation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              TrackListEditor(
                tracks: draft.tracks,
                isMedley: draft.releaseMode == ReleaseMode.medley,
                defaultSnippetDuration: draft.snippetDurationSeconds,
                defaultImagePath: draft.imagePath,
                onAddTracks: draftNotifier.addTracks,
                onRemoveTrack: draftNotifier.removeTrackAt,
                onUpdateTrack: draftNotifier.updateTrackAt,
              ),
            ],
          ],
        ),
      ),
      (
        l10n.stepVisualizer,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VisualizerPlacementPicker(
              value: draft.placement,
              onChanged: draftNotifier.setPlacement,
            ),
            const SizedBox(height: 8),
            VisualizerStylePicker(
              value: draft.style,
              onChanged: draftNotifier.setStyle,
            ),
          ],
        ),
      ),
      (
        l10n.stepCustomize,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomizationPanel(
              blurRadius: draft.blurRadius,
              onBlurChanged: draftNotifier.setBlurRadius,
              visualizerSmoothness: draft.visualizerSmoothness,
              onVisualizerSmoothnessChanged:
                  draftNotifier.setVisualizerSmoothness,
              visualizerColorHex: draft.visualizerColorHex,
              onVisualizerColorChanged: draftNotifier.setColor,
              coverImagePath: draft.imagePath,
              vintageEffect: draft.vintageEffect,
              onVintageEffectChanged: draftNotifier.setVintageEffect,
              showCover: draft.showCover,
              onShowCoverChanged: draftNotifier.setShowCover,
              coverSizeFraction: draft.coverSizeFraction,
              onCoverSizeFractionChanged: draftNotifier.setCoverSizeFraction,
              showLogo: draft.showLogo,
              onShowLogoChanged: draftNotifier.setShowLogo,
              logoImagePath: draft.logoImagePath,
              onLogoPathChanged: draftNotifier.setLogoImagePath,
              showText: draft.showText,
              onShowTextChanged: draftNotifier.setShowText,
              textContent: draft.textContent,
              onTextContentChanged: draftNotifier.setTextContent,
              showQrCode: draft.showQrCode,
              onShowQrCodeChanged: draftNotifier.setShowQrCode,
              qrCodeContent: draft.qrCodeContent,
              onQrCodeContentChanged: draftNotifier.setQrCodeContent,
              qrCaptionText: draft.qrCaptionText,
              onQrCaptionTextChanged: draftNotifier.setQrCaptionText,
              qrCaptionPosition: draft.qrCaptionPosition,
              onQrCaptionPositionChanged: draftNotifier.setQrCaptionPosition,
              fadeInSeconds: draft.fadeInSeconds,
              onFadeInChanged: draftNotifier.setFadeInSeconds,
              fadeOutSeconds: draft.fadeOutSeconds,
              onFadeOutChanged: draftNotifier.setFadeOutSeconds,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.positionAndRotate,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                TextButton.icon(
                  onPressed: draftNotifier.resetTransforms,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: Text(l10n.resetPositions),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PositionCanvas(
              frameWidth: previewPreset.width,
              frameHeight: previewPreset.height,
              items: [
                PositionableItem(
                  id: 'cover',
                  label: l10n.elementCover,
                  icon: Icons.image_outlined,
                  color: Colors.blueAccent,
                  transform: draft.coverTransform,
                  enabled: draft.showCover,
                  supportsRotation: false,
                ),
                PositionableItem(
                  id: 'logo',
                  label: l10n.elementLogo,
                  icon: Icons.branding_watermark_outlined,
                  color: Colors.deepPurpleAccent,
                  transform: draft.logoTransform,
                  enabled: draft.showLogo,
                ),
                PositionableItem(
                  id: 'text',
                  label: l10n.elementText,
                  icon: Icons.text_fields,
                  color: Colors.orangeAccent,
                  transform: draft.textTransform,
                  enabled: draft.showText,
                  supportsRotation: false,
                ),
                PositionableItem(
                  id: 'qr',
                  label: l10n.elementQrCode,
                  icon: Icons.qr_code,
                  color: Colors.teal,
                  transform: draft.qrTransform,
                  enabled: draft.showQrCode,
                ),
              ],
              onChanged: (id, transform) {
                switch (id) {
                  case 'cover':
                    draftNotifier.setCoverTransform(transform);
                    break;
                  case 'logo':
                    draftNotifier.setLogoTransform(transform);
                    break;
                  case 'text':
                    draftNotifier.setTextTransform(transform);
                    break;
                  case 'qr':
                    draftNotifier.setQrTransform(transform);
                    break;
                }
              },
            ),
          ],
        ),
      ),
      if (draft.releaseMode == ReleaseMode.single)
        (
          l10n.stepDuration,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AudioTrimSlider(
                fullDuration: draft.fullDuration,
                onFullDurationChanged: draftNotifier.setFullDuration,
                trimStartSeconds: draft.trimStartSeconds,
                trimDurationSeconds: draft.trimDurationSeconds,
                probedDurationSeconds: draft.probedAudioDurationSeconds,
                onStartChanged: draftNotifier.setTrimStart,
                onDurationChanged: draftNotifier.setTrimDuration,
              ),
              if (!draft.fullDuration &&
                  draft.audioPath != null &&
                  draft.probedAudioDurationSeconds != null) ...[
                const SizedBox(height: 16),
                AudioPreviewPlayer(
                  audioPath: draft.audioPath!,
                  startSeconds: draft.trimStartSeconds,
                  endSeconds: draft.trimDurationSeconds != null
                      ? draft.trimStartSeconds + draft.trimDurationSeconds!
                      : null,
                  totalDurationSeconds: draft.probedAudioDurationSeconds!,
                ),
              ],
            ],
          ),
        ),
      (
        l10n.stepPlatforms,
        PlatformPresetPicker(
          selectedIds: draft.selectedPresetIds,
          onToggle: draftNotifier.togglePreset,
        ),
      ),
      (
        l10n.stepOutputPerformance,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutputDirectoryPicker(
              selectedPath: draft.outputDirectory,
              onDirectorySelected: draftNotifier.setOutputDirectory,
            ),
            const SizedBox(height: 16),
            PerformancePanel(
              useHardwareAcceleration: draft.useHardwareAcceleration,
              onHardwareAccelerationChanged:
                  draftNotifier.setUseHardwareAcceleration,
              losslessAudio: draft.losslessAudio,
              onLosslessAudioChanged: draftNotifier.setLosslessAudio,
            ),
          ],
        ),
      ),
      (
        l10n.stepReviewRender,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reviewSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ReviewSummaryRow(
              label: l10n.stepReleaseType,
              value: _releaseModeSummary(l10n, draft),
              onEdit: () => _goTo(stepReleaseTypeIndex),
            ),
            ReviewSummaryRow(
              label: l10n.stepFiles,
              value: _filesSummary(l10n, draft),
              onEdit: () => _goTo(stepFilesIndex),
            ),
            ReviewSummaryRow(
              label: l10n.stepVisualizer,
              value:
                  '${draft.placement.label(l10n)} · ${draft.style.label(l10n)}',
              onEdit: () => _goTo(stepVisualizerIndex),
            ),
            ReviewSummaryRow(
              label: l10n.stepCustomize,
              value: _customizeSummary(l10n, draft),
              onEdit: () => _goTo(stepCustomizeIndex),
            ),
            if (stepDurationIndex != null)
              ReviewSummaryRow(
                label: l10n.stepDuration,
                value: _durationSummary(l10n, draft),
                onEdit: () => _goTo(stepDurationIndex),
              ),
            ReviewSummaryRow(
              label: l10n.stepPlatforms,
              value: _platformsSummary(l10n, draft),
              onEdit: () => _goTo(stepPlatformsIndex),
            ),
            ReviewSummaryRow(
              label: l10n.stepOutputPerformance,
              value: _outputSummary(l10n, draft),
              onEdit: () => _goTo(stepOutputIndex),
            ),
            const SizedBox(height: 16),
            const Divider(),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _saveAsTemplate,
              onChanged: (v) => setState(() => _saveAsTemplate = v ?? false),
              title: Text(l10n.saveAsTemplateButton),
            ),
            if (_saveAsTemplate)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _templateNameController,
                  decoration: InputDecoration(
                    labelText: l10n.templateNameLabel,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            RenderProgressView(
              progress: progress,
              onCancel: renderNotifier.cancel,
            ),
          ],
        ),
      ),
    ];

    final lastStep = pages.length - 1;
    if (_currentStep > lastStep) {
      _currentStep = lastStep;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(lastStep);
      });
    }

    return Scaffold(
      body: Column(
        children: [
          const DesktopTitleBar(title: 'Spinclip'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: the wizard. Every step's changes are visible immediately
                // in the persistent preview on the right, rather than the preview
                // only showing up on the couple of steps that used to embed it.
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.stepIndicator(
                                _currentStep + 1,
                                pages.length,
                                pages[_currentStep].$1,
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_currentStep + 1) / pages.length,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          // Swiping would let the user skip past a step
                          // whose required fields aren't filled in yet -
                          // Back/Next (and the review summary's edit links)
                          // are the only way to move between pages.
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) =>
                              setState(() => _currentStep = i),
                          children: [
                            for (final page in pages)
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: page.$2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_currentStep == stepFilesIndex &&
                                !_filesStepComplete(draft))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  l10n.filesStepRequiredHint,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              ),
                            Row(
                              children: [
                                if (_currentStep > 0)
                                  OutlinedButton.icon(
                                    onPressed: () => _goTo(_currentStep - 1),
                                    icon: const Icon(Icons.arrow_back),
                                    label: Text(l10n.back),
                                  ),
                                const Spacer(),
                                if (_currentStep < lastStep)
                                  FilledButton.icon(
                                    onPressed:
                                        (_currentStep == stepFilesIndex &&
                                            !_filesStepComplete(draft))
                                        ? null
                                        : () => _goTo(_currentStep + 1),
                                    icon: const Icon(Icons.arrow_forward),
                                    label: Text(l10n.next),
                                  )
                                else
                                  FilledButton.icon(
                                    onPressed:
                                        (draft.isReadyToRender && !isRendering)
                                        ? () {
                                            final templateName =
                                                _templateNameController.text
                                                    .trim();
                                            if (_saveAsTemplate &&
                                                templateName.isNotEmpty) {
                                              templatesNotifier.save(
                                                draftNotifier.captureTemplate(
                                                  templateName,
                                                ),
                                              );
                                            }
                                            renderNotifier.startRender();
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.movie_creation_outlined,
                                    ),
                                    label: Text(l10n.renderButton),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right: the persistent live preview, always visible regardless of
                // which wizard step is active.
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.preview,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: PreviewPanel(
                              settings: previewSettings,
                              width: previewPreset.width,
                              height: previewPreset.height,
                            ),
                          ),
                        ),
                        Text(
                          l10n.previewPresetLabel(
                            previewPreset.name,
                            previewPreset.aspectRatioLabel,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
