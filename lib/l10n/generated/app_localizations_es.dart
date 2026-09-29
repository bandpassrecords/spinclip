// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Spinclip';

  @override
  String get stepReleaseType => 'Tipo de lanzamiento';

  @override
  String get stepFiles => 'Archivos';

  @override
  String get stepVisualizer => 'Visualizador';

  @override
  String get stepCustomize => 'Personalizar';

  @override
  String get stepDuration => 'Duración';

  @override
  String get stepPlatforms => 'Plataformas';

  @override
  String get stepOutputPerformance => 'Salida y rendimiento';

  @override
  String get stepReviewRender => 'Revisar y renderizar';

  @override
  String stepIndicator(int current, int total, String stepName) {
    return 'Paso $current de $total: $stepName';
  }

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get preview => 'Vista previa';

  @override
  String previewPresetLabel(String presetName, String aspectRatio) {
    return '$presetName ($aspectRatio)';
  }

  @override
  String get releaseModeSingle => 'Canción única';

  @override
  String get releaseModeMultiSong => 'Varias canciones';

  @override
  String get releaseModeMedley => 'Popurrí';

  @override
  String get coverImageLabelSingle => 'Imagen de portada (PNG/JPG)';

  @override
  String get coverImageLabelMulti =>
      'Portada predeterminada (se usa a menos que una canción tenga la suya)';

  @override
  String get audioFileLabel => 'Archivo de audio (WAV/MP3/FLAC...)';

  @override
  String get medleyExplanation =>
      'Cada canción aporta un fragmento corto; se reproducen en secuencia como un único vídeo combinado por plataforma.';

  @override
  String get multiSongExplanation =>
      'Cada canción genera su propio vídeo independiente, para cada plataforma seleccionada.';

  @override
  String get singleExplanation =>
      'Una portada y una canción producen un solo vídeo, para cada plataforma seleccionada.';

  @override
  String get positionAndRotate => 'Posición y rotación';

  @override
  String get positionCanvasHint =>
      'Arrastra para posicionar. Toca un elemento para ajustar su rotación.';

  @override
  String rotationLabel(String label, int degrees) {
    return 'Rotación de $label: $degrees°';
  }

  @override
  String get elementCover => 'Portada';

  @override
  String get elementLogo => 'Logotipo';

  @override
  String get elementText => 'Texto';

  @override
  String get elementQrCode => 'Código QR';

  @override
  String backgroundBlurLabel(int value) {
    return 'Desenfoque de fondo: $value';
  }

  @override
  String visualizerSmoothnessLabel(int percent) {
    return 'Suavizado del visualizador: $percent%';
  }

  @override
  String visualizerSensitivityLabel(String value) {
    return 'Sensibilidad del visualizador: ${value}x';
  }

  @override
  String visualizerBarCountLabel(int count) {
    return 'Número de barras: $count';
  }

  @override
  String get visualizerBarCountAuto => 'Número de barras: Automático';

  @override
  String get visualizerBarCountAutoShort => 'Auto';

  @override
  String get showCoverArt => 'Mostrar portada';

  @override
  String coverSizeLabel(int percent) {
    return 'Tamaño de la portada: $percent%';
  }

  @override
  String get showLogo => 'Mostrar logotipo';

  @override
  String get logoImage => 'Imagen del logotipo';

  @override
  String get showTextOverlay => 'Mostrar texto superpuesto';

  @override
  String get overlayText => 'Texto superpuesto';

  @override
  String get showQrCode => 'Mostrar código QR';

  @override
  String get qrCodeSubtitle =>
      'Enlaza a una URL de tu elección (p. ej., un enlace de Spotify/streaming)';

  @override
  String get qrCodeContentLabel => 'Contenido del código QR (URL o texto)';

  @override
  String get qrCaptionLabel =>
      'Leyenda del QR (opcional, p. ej., \"Escanea para escuchar\")';

  @override
  String get qrCaptionPositionBelow => 'Debajo del código QR';

  @override
  String get qrCaptionPositionAbove => 'Encima del código QR';

  @override
  String fadeInLabel(String seconds) {
    return 'Fundido de entrada: ${seconds}s';
  }

  @override
  String fadeOutLabel(String seconds) {
    return 'Fundido de salida: ${seconds}s';
  }

  @override
  String dropFileHint(String label) {
    return '$label - haz clic o arrastra un archivo aquí';
  }

  @override
  String get fullDuration => 'Duración completa';

  @override
  String get fullDurationSubtitle =>
      'Usa toda la pista (predeterminado). Desactívalo para elegir un fragmento.';

  @override
  String get probingTrackLength => 'Analizando duración de la pista...';

  @override
  String trimRangeLabel(String start, String end, String duration) {
    return '$start - $end (${duration}s)';
  }

  @override
  String get previewExcerptButton => 'Escuchar el fragmento seleccionado';

  @override
  String get songInfoLoading => 'Leyendo detalles de la canción...';

  @override
  String get songInfoError =>
      'No se pudo leer este archivo. Comprueba que sea un archivo de audio compatible.';

  @override
  String get playSongButton => 'Reproducir canción';

  @override
  String get channelsMono => 'Mono';

  @override
  String get channelsStereo => 'Estéreo';

  @override
  String channelsCount(int count) {
    return '$count canales';
  }

  @override
  String get audioLossless => 'Sin pérdida';

  @override
  String get audioLossy => 'Con pérdida';

  @override
  String get addSong => 'Añadir canción';

  @override
  String get trackStartSeconds => 'Inicio (s)';

  @override
  String get trackExcerptDuration => 'Duración del fragmento (s)';

  @override
  String get outputDirectoryDefault =>
      'Predeterminado (Documentos/Spinclip) - haz clic para cambiar';

  @override
  String get hardwareAcceleration => 'Codificación acelerada por hardware';

  @override
  String get hardwareAccelerationSubtitle =>
      'Usa tu GPU (NVENC/Quick Sync/AMF) cuando esté disponible; vuelve automáticamente a la codificación por software si falla.';

  @override
  String get losslessAudio => 'Audio sin pérdidas (PCM)';

  @override
  String get losslessAudioSubtitle =>
      'Sin compresión de audio: escribe un archivo .mov en lugar de .mp4. Spotify Canvas siempre usa AAC/MP4, ya que esa plataforma lo requiere.';

  @override
  String get renderButton => 'Renderizar';

  @override
  String get renderingPreview => 'Renderizando vista previa...';

  @override
  String get renderingGeneric => 'Renderizando...';

  @override
  String get selectCoverAndAudioFirst =>
      'Selecciona primero una imagen de portada y un audio';

  @override
  String renderProgressLabel(
    int index,
    int count,
    String presetName,
    String percent,
  ) {
    return '[$index/$count] $presetName: $percent%';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String renderDone(String path) {
    return '¡Listo! Guardado en: $path';
  }

  @override
  String renderError(String message) {
    return 'Error: $message';
  }

  @override
  String get renderCancelled => 'Cancelado.';

  @override
  String get visualizerPlacementLabel => 'Ubicación del visualizador';

  @override
  String get visualizerStyleLabel => 'Estilo del visualizador';

  @override
  String get placementBottomBand => 'Banda Inferior';

  @override
  String get placementSideBorder => 'Borde Lateral';

  @override
  String get placementDualMirroredBottom => 'Espejo Doble Inferior';

  @override
  String get placementFullFrameBorder => 'Borde de Cuadro Completo';

  @override
  String get placementAscendingCorner => 'Esquina Ascendente';

  @override
  String get placementCenteredBehindText => 'Centrado Detrás del Texto';

  @override
  String get placementCoverCenterDualBars =>
      'Portada Central + Barras Laterales';

  @override
  String get styleBars => 'Barras';

  @override
  String get styleLineSpectrum => 'Espectro de Línea';

  @override
  String get styleFluidWave => 'Onda Fluida';

  @override
  String get styleOscilloscope => 'Osciloscopio';

  @override
  String get styleNeonGlow => 'Neón Brillante';

  @override
  String get styleCartoon => 'Dibujo Animado';

  @override
  String get reviewSummaryTitle => 'Resumen';

  @override
  String get reviewEditTooltip => 'Editar';

  @override
  String get summaryValueNotSet => 'No establecido';

  @override
  String summaryTrackCount(int count) {
    return '$count canciones';
  }

  @override
  String get summaryElementsNone => 'Ninguno';

  @override
  String get summaryOn => 'Activado';

  @override
  String get summaryOff => 'Desactivado';

  @override
  String get summaryPlatformsNone => 'Ninguna seleccionada';

  @override
  String get openOutputFolder => 'Abrir carpeta';

  @override
  String get resetPositions => 'Restablecer posiciones';

  @override
  String get visualizerColorLabel => 'Color del visualizador';

  @override
  String get colorThemeAuto => 'Automático (de la portada)';

  @override
  String get colorThemeDark => 'Oscuro';

  @override
  String get colorThemeSparkling => 'Chispeante';

  @override
  String get extractingColor => 'Extrayendo color...';

  @override
  String get colorCustom => 'Personalizado…';

  @override
  String get colorPickerTitle => 'Elige un color';

  @override
  String get colorPickerApply => 'Aplicar';

  @override
  String get visualizerGradientLabel => 'Degradado';

  @override
  String get visualizerGradientHint =>
      'Mezcla desde el borde hacia un segundo color en las puntas';

  @override
  String get visualizerGradientColorLabel => 'Color de las puntas';

  @override
  String get vintageEffectLabel => 'Efecto vintage';

  @override
  String get vintageEffectSubtitle =>
      'Envejecimiento leve: tono cálido, viñeta suave, grano de película ligero.';

  @override
  String get filesStepRequiredHint =>
      'Se requiere una imagen de portada y audio para continuar.';

  @override
  String get advancedModeLabel => 'Ajustes avanzados';

  @override
  String get advancedModeSubtitle =>
      'Ajusta el visualizador, las superposiciones, el tiempo y las opciones de exportación. Desactivado usa valores predeterminados razonables para todo esto.';

  @override
  String get customResolutionTitle => 'Resolución personalizada';

  @override
  String get resolutionWidthLabel => 'Ancho';

  @override
  String get resolutionHeightLabel => 'Alto';

  @override
  String get resetResolutionTooltip => 'Restablecer resolución predeterminada';

  @override
  String get outputSubfolderLabel =>
      'Nombre de la subcarpeta de salida (opcional)';

  @override
  String outputSubfolderHint(String name) {
    return 'Usa \"$name\" de forma predeterminada, a partir de la imagen de portada';
  }

  @override
  String get overwriteConfirmTitle => 'La carpeta ya tiene archivos';

  @override
  String overwriteConfirmMessage(String path) {
    return '\"$path\" ya contiene archivos de una renderización anterior. Renderizar de nuevo los sobrescribirá.';
  }

  @override
  String get overwriteConfirmButton => 'Sobrescribir';

  @override
  String get trackDefaultCoverHint => 'Usa la portada predeterminada';

  @override
  String get trackSetCover => 'Definir portada';

  @override
  String get trackClearCoverTooltip => 'Quitar portada personalizada';

  @override
  String get loadTemplateButton => 'Cargar plantilla';

  @override
  String get builtInDefaultTemplateLabel =>
      'Predeterminado de Spinclip (Barras 48)';

  @override
  String get saveAsTemplateButton => 'Guardar como plantilla';

  @override
  String get templateNameLabel => 'Nombre de la plantilla';

  @override
  String get noTemplatesSaved => 'Aún no hay plantillas guardadas';

  @override
  String get deleteTemplateTooltip => 'Eliminar plantilla';

  @override
  String get save => 'Guardar';
}
