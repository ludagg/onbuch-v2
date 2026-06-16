import 'dart:typed_data';

/// Paramètres passés à l'écran de correction du Tuteur IA.
///
/// Trois modes :
/// - [image] : correction à partir d'une photo.
/// - [question] : correction à partir d'un texte saisi.
/// - [jobId] : réouverture d'une correction déjà calculée (corrections récentes).
class TutorRequest {
  final Uint8List? image;
  final String? question;
  final String? subject;
  final String? jobId;
  final String? titleHint;
  final String? mode; // ex. 'lesson' pour générer un cours
  final String? chapterId; // pour la mise en cache d'une fiche de cours
  final String? presetAnswer; // contenu déjà disponible (cache) -> pas d'appel IA

  const TutorRequest({
    this.image,
    this.question,
    this.subject,
    this.jobId,
    this.titleHint,
    this.mode,
    this.chapterId,
    this.presetAnswer,
  });
}
