// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Spinclip';

  @override
  String get stepReleaseType => 'Tipo de lançamento';

  @override
  String get stepFiles => 'Arquivos';

  @override
  String get stepVisualizer => 'Visualizador';

  @override
  String get stepCustomize => 'Personalizar';

  @override
  String get stepDuration => 'Duração';

  @override
  String get stepPlatforms => 'Plataformas';

  @override
  String get stepOutputPerformance => 'Saída e desempenho';

  @override
  String get stepReviewRender => 'Revisar e renderizar';

  @override
  String stepIndicator(int current, int total, String stepName) {
    return 'Etapa $current de $total: $stepName';
  }

  @override
  String get back => 'Voltar';

  @override
  String get next => 'Avançar';

  @override
  String get preview => 'Pré-visualização';

  @override
  String previewPresetLabel(String presetName, String aspectRatio) {
    return '$presetName ($aspectRatio)';
  }

  @override
  String get releaseModeSingle => 'Música única';

  @override
  String get releaseModeMultiSong => 'Várias músicas';

  @override
  String get releaseModeMedley => 'Medley';

  @override
  String get coverImageLabelSingle => 'Imagem de capa (PNG/JPG)';

  @override
  String get coverImageLabelMulti =>
      'Capa padrão (usada a menos que uma música tenha a própria)';

  @override
  String get audioFileLabel => 'Arquivo de áudio (WAV/MP3/FLAC...)';

  @override
  String get medleyExplanation =>
      'Cada música contribui com um trecho curto; eles tocam em sequência como um único vídeo combinado por plataforma.';

  @override
  String get multiSongExplanation =>
      'Cada música gera seu próprio vídeo independente, para cada plataforma selecionada.';

  @override
  String get singleExplanation =>
      'Uma capa e uma música geram um único vídeo, para cada plataforma selecionada.';

  @override
  String get positionAndRotate => 'Posição e rotação';

  @override
  String get positionCanvasHint =>
      'Arraste para posicionar. Toque em um elemento para ajustar sua rotação.';

  @override
  String rotationLabel(String label, int degrees) {
    return 'Rotação de $label: $degrees°';
  }

  @override
  String get elementCover => 'Capa';

  @override
  String get elementLogo => 'Logotipo';

  @override
  String get elementText => 'Texto';

  @override
  String get elementQrCode => 'Código QR';

  @override
  String backgroundBlurLabel(int value) {
    return 'Desfoque de fundo: $value';
  }

  @override
  String visualizerSmoothnessLabel(int percent) {
    return 'Suavização do visualizador: $percent%';
  }

  @override
  String get showCoverArt => 'Mostrar capa';

  @override
  String coverSizeLabel(int percent) {
    return 'Tamanho da capa: $percent%';
  }

  @override
  String get showLogo => 'Mostrar logotipo';

  @override
  String get logoImage => 'Imagem do logotipo';

  @override
  String get showTextOverlay => 'Mostrar texto sobreposto';

  @override
  String get overlayText => 'Texto sobreposto';

  @override
  String get showQrCode => 'Mostrar código QR';

  @override
  String get qrCodeSubtitle =>
      'Aponta para uma URL de sua escolha (ex.: um link do Spotify/streaming)';

  @override
  String get qrCodeContentLabel => 'Conteúdo do código QR (URL ou texto)';

  @override
  String get qrCaptionLabel =>
      'Legenda do QR (opcional, ex.: \"Escaneie para ouvir\")';

  @override
  String get qrCaptionPositionBelow => 'Abaixo do código QR';

  @override
  String get qrCaptionPositionAbove => 'Acima do código QR';

  @override
  String fadeInLabel(String seconds) {
    return 'Fade in: ${seconds}s';
  }

  @override
  String fadeOutLabel(String seconds) {
    return 'Fade out: ${seconds}s';
  }

  @override
  String dropFileHint(String label) {
    return '$label - clique ou arraste um arquivo aqui';
  }

  @override
  String get fullDuration => 'Duração completa';

  @override
  String get fullDurationSubtitle =>
      'Usa a faixa inteira (padrão). Desative para escolher um trecho.';

  @override
  String get probingTrackLength => 'Analisando duração da faixa...';

  @override
  String trimRangeLabel(String start, String end, String duration) {
    return '$start - $end (${duration}s)';
  }

  @override
  String get previewExcerptButton => 'Ouvir o trecho selecionado';

  @override
  String get addSong => 'Adicionar música';

  @override
  String get trackStartSeconds => 'Início (s)';

  @override
  String get trackExcerptDuration => 'Duração do trecho (s)';

  @override
  String get outputDirectoryDefault =>
      'Padrão (Documentos/Spinclip) - clique para alterar';

  @override
  String get hardwareAcceleration => 'Codificação acelerada por hardware';

  @override
  String get hardwareAccelerationSubtitle =>
      'Usa sua GPU (NVENC/Quick Sync/AMF) quando disponível; volta automaticamente para codificação por software se falhar.';

  @override
  String get losslessAudio => 'Áudio sem perdas (PCM)';

  @override
  String get losslessAudioSubtitle =>
      'Sem compressão de áudio - grava um arquivo .mov em vez de .mp4. O Spotify Canvas sempre usa AAC/MP4, pois a plataforma exige isso.';

  @override
  String get renderButton => 'Renderizar';

  @override
  String get renderingPreview => 'Renderizando pré-visualização...';

  @override
  String get renderingGeneric => 'Renderizando...';

  @override
  String get selectCoverAndAudioFirst =>
      'Selecione uma imagem de capa e um áudio primeiro';

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
    return 'Concluído! Salvo em: $path';
  }

  @override
  String renderError(String message) {
    return 'Erro: $message';
  }

  @override
  String get renderCancelled => 'Cancelado.';

  @override
  String get visualizerPlacementLabel => 'Posicionamento do visualizador';

  @override
  String get visualizerStyleLabel => 'Estilo do visualizador';

  @override
  String get placementBottomBand => 'Faixa Inferior';

  @override
  String get placementSideBorder => 'Borda Lateral';

  @override
  String get placementDualMirroredBottom => 'Espelhado Duplo Inferior';

  @override
  String get placementFullFrameBorder => 'Borda de Quadro Completo';

  @override
  String get placementAscendingCorner => 'Canto Ascendente';

  @override
  String get placementCenteredBehindText => 'Centralizado Atrás do Texto';

  @override
  String get placementCoverCenterDualBars => 'Capa no Centro + Barras Laterais';

  @override
  String get styleBars => 'Barras';

  @override
  String get styleLineSpectrum => 'Espectro de Linha';

  @override
  String get styleFluidWave => 'Onda Fluida';

  @override
  String get styleOscilloscope => 'Osciloscópio';

  @override
  String get reviewSummaryTitle => 'Resumo';

  @override
  String get reviewEditTooltip => 'Editar';

  @override
  String get summaryValueNotSet => 'Não definido';

  @override
  String summaryTrackCount(int count) {
    return '$count músicas';
  }

  @override
  String get summaryElementsNone => 'Nenhum';

  @override
  String get summaryOn => 'Ativado';

  @override
  String get summaryOff => 'Desativado';

  @override
  String get summaryPlatformsNone => 'Nenhuma selecionada';

  @override
  String get openOutputFolder => 'Abrir pasta';

  @override
  String get resetPositions => 'Redefinir posições';

  @override
  String get visualizerColorLabel => 'Cor do visualizador';

  @override
  String get colorThemeAuto => 'Automático (da capa)';

  @override
  String get colorThemeDark => 'Escuro';

  @override
  String get colorThemeSparkling => 'Cintilante';

  @override
  String get extractingColor => 'Extraindo cor...';

  @override
  String get vintageEffectLabel => 'Efeito vintage';

  @override
  String get vintageEffectSubtitle =>
      'Envelhecimento leve: tom quente, vinheta suave, granulado de filme leve.';

  @override
  String get filesStepRequiredHint =>
      'É necessário selecionar uma imagem de capa e um áudio para continuar.';

  @override
  String get advancedModeLabel => 'Configurações avançadas';

  @override
  String get advancedModeSubtitle =>
      'Ajuste o visualizador, as sobreposições, o tempo e as opções de exportação. Desativado usa padrões adequados para tudo isso.';

  @override
  String get customResolutionTitle => 'Resolução personalizada';

  @override
  String get resolutionWidthLabel => 'Largura';

  @override
  String get resolutionHeightLabel => 'Altura';

  @override
  String get resetResolutionTooltip => 'Restaurar resolução padrão';

  @override
  String get trackDefaultCoverHint => 'Usa a capa padrão';

  @override
  String get trackSetCover => 'Definir capa';

  @override
  String get trackClearCoverTooltip => 'Remover capa personalizada';

  @override
  String get loadTemplateButton => 'Carregar modelo';

  @override
  String get saveAsTemplateButton => 'Salvar como modelo';

  @override
  String get templateNameLabel => 'Nome do modelo';

  @override
  String get noTemplatesSaved => 'Nenhum modelo salvo ainda';

  @override
  String get deleteTemplateTooltip => 'Excluir modelo';

  @override
  String get save => 'Salvar';
}
