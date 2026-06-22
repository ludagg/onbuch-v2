// Schémas des collections gérées par l'admin. Ajouter une collection = ajouter
// une entrée ici : l'UI de liste + le formulaire sont générés automatiquement.

export type FieldType = 'text' | 'textarea' | 'number' | 'boolean' | 'datetime' | 'select';

export interface Field {
  key: string;
  label: string;
  type: FieldType;
  required?: boolean;
  options?: string[]; // pour type 'select'
  help?: string;
}

export interface Resource {
  id: string; // identifiant de route
  collectionId: string; // ID de collection Appwrite
  label: string; // pluriel, pour le menu
  singular: string; // pour « Nouveau … »
  icon: string; // emoji
  titleField: string; // champ affiché en titre dans la liste
  subtitleField?: string; // champ secondaire
  orderBy?: { field: string; dir: 'asc' | 'desc' };
  fields: Field[];
}

const order: Field = { key: 'order', label: 'Ordre', type: 'number', help: 'Tri croissant (0 en premier).' };

export const RESOURCES: Resource[] = [
  {
    id: 'users',
    collectionId: 'users',
    label: 'Utilisateurs',
    singular: 'utilisateur',
    icon: '👤',
    titleField: 'firstName',
    subtitleField: 'email',
    orderBy: { field: '$createdAt', dir: 'desc' },
    fields: [
      { key: 'firstName', label: 'Prénom', type: 'text' },
      { key: 'lastName', label: 'Nom', type: 'text' },
      { key: 'email', label: 'E-mail', type: 'text', help: 'Identifiant de connexion (ne pas modifier à la légère).' },
      { key: 'phoneNumber', label: 'Téléphone', type: 'text' },
      { key: 'classe', label: 'Classe', type: 'text', help: 'ex. Terminale, 1ère, 3ème' },
      { key: 'examen', label: 'Examen visé', type: 'text', help: 'ex. Baccalauréat' },
      { key: 'serie', label: 'Série', type: 'text', help: 'ex. D' },
      { key: 'school', label: 'Établissement', type: 'text' },
      { key: 'city', label: 'Ville', type: 'text' },
      { key: 'gender', label: 'Genre', type: 'select', options: ['', 'Fille', 'Garçon', 'Autre'] },
      { key: 'birthYear', label: 'Année de naissance', type: 'number' },
      { key: 'studyField', label: 'Filière souhaitée', type: 'text' },
      { key: 'careerGoal', label: 'Objectif (métier)', type: 'text' },
      { key: 'studyDestination', label: 'Destination d’études', type: 'text' },
      { key: 'role', label: 'Rôle', type: 'select', options: ['', 'user', 'admin'], help: 'Rôle applicatif (informatif).' }
    ]
  },
  {
    id: 'social_links',
    collectionId: 'social_links',
    label: 'Réseaux sociaux',
    singular: 'lien',
    icon: '🔗',
    titleField: 'label',
    subtitleField: 'url',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'platform', label: 'Plateforme', type: 'select', options: ['whatsapp', 'telegram', 'tiktok', 'facebook', 'youtube', 'instagram', 'other'], help: 'Pilote l’icône et la couleur dans l’app.' },
      { key: 'label', label: 'Nom affiché', type: 'text', required: true, help: 'ex. WhatsApp' },
      { key: 'description', label: 'Description', type: 'text', help: 'ex. Groupe d’entraide · 12k membres' },
      { key: 'url', label: 'Lien', type: 'text', required: true, help: 'https://, wa.me/…, t.me/…' },
      order,
      { key: 'active', label: 'Actif (cocher pour afficher)', type: 'boolean' }
    ]
  },
  {
    id: 'notifications',
    collectionId: 'notifications',
    label: 'Notifications',
    singular: 'notification',
    icon: '🔔',
    titleField: 'title',
    subtitleField: 'body',
    orderBy: { field: '$createdAt', dir: 'desc' },
    fields: [
      { key: 'title', label: 'Titre', type: 'text', required: true },
      { key: 'body', label: 'Message', type: 'textarea' },
      { key: 'type', label: 'Type', type: 'select', options: ['info', 'result', 'exam', 'credit', 'course', 'promo'] },
      {
        key: 'route',
        label: 'Ouvrir dans l’app',
        type: 'select',
        help: 'Écran ouvert quand l’élève tape la notification.',
        options: [
          '',
          '/home|🏠 Accueil',
          '/results|🎓 Résultats d’examens',
          '/annales|🗂️ Annales',
          '/tutor|🤖 Tuteur IA (Léo)',
          '/cours|📘 Cours',
          '/concours|🎯 Concours',
          '/mes-candidatures|📋 Mes candidatures',
          '/concours-progress|📈 Progression concours',
          '/concours-alertes|🔔 Alertes concours',
          '/campus|🏫 Campus',
          '/agenda|📆 Agenda scolaire',
          '/actualites|📰 Actualités',
          '/affiche|🪧 À l’affiche',
          '/communaute|💬 Communauté',
          '/credits|💳 Crédits',
          '/notifications|🔔 Notifications',
          '/parametres|⚙️ Paramètres',
          '/aide|❓ Aide',
          '/profile|👤 Profil',
          '/search|🔎 Recherche'
        ]
      },
      { key: 'imageUrl', label: "URL d'image", type: 'text' },
      { key: 'publishedAt', label: 'Publié le', type: 'datetime', help: 'Vide = maintenant. La notification part en push dès sa création.' }
    ]
  },
  {
    id: 'articles',
    collectionId: 'articles',
    label: 'Actualités',
    singular: 'article',
    icon: '📰',
    titleField: 'title',
    subtitleField: 'category',
    orderBy: { field: '$createdAt', dir: 'desc' },
    fields: [
      { key: 'title', label: 'Titre', type: 'text', required: true },
      { key: 'category', label: 'Catégorie', type: 'text', help: 'Examens, Bourses, Conseil…' },
      { key: 'source', label: 'Source', type: 'text', help: 'Défaut : OnBuch' },
      { key: 'imageUrl', label: "URL d'image", type: 'text' },
      { key: 'body', label: 'Contenu', type: 'textarea' },
      { key: 'featured', label: 'Mis en avant', type: 'boolean' },
      { key: 'publishedAt', label: 'Publié le', type: 'datetime' }
    ]
  },
  {
    id: 'concours',
    collectionId: 'concours',
    label: 'Concours',
    singular: 'concours',
    icon: '🎯',
    titleField: 'name',
    subtitleField: 'organizer',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'name', label: 'Nom', type: 'text', required: true },
      { key: 'organizer', label: 'Organisateur', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' },
      { key: 'communique', label: 'Lien communiqué', type: 'text' },
      { key: 'link', label: "Lien d'inscription", type: 'text' },
      { key: 'registrationDeadline', label: 'Clôture des inscriptions', type: 'datetime' },
      { key: 'examDate', label: 'Date des épreuves', type: 'datetime' },
      { key: 'resultsAvailable', label: 'Résultats disponibles', type: 'boolean' },
      { key: 'resultsLink', label: 'Lien résultats', type: 'text' },
      { key: 'resultsDate', label: 'Date des résultats', type: 'datetime' },
      { key: 'audience', label: 'Public visé', type: 'text' },
      order
    ]
  },
  {
    id: 'prep_centers',
    collectionId: 'prep_centers',
    label: 'Centres de prépa',
    singular: 'centre',
    icon: '🏫',
    titleField: 'name',
    subtitleField: 'city',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'name', label: 'Nom', type: 'text', required: true },
      { key: 'city', label: 'Ville', type: 'text', required: true },
      { key: 'description', label: 'Description', type: 'textarea' },
      { key: 'specialties', label: 'Spécialités', type: 'text', help: 'Séparées par des virgules : ENS, ENAM…' },
      { key: 'imageUrl', label: "URL d'image", type: 'text' },
      { key: 'phone', label: 'WhatsApp / téléphone', type: 'text' },
      { key: 'link', label: 'Lien', type: 'text' },
      { key: 'address', label: 'Adresse', type: 'text' },
      { key: 'eventTitle', label: 'Prochain événement', type: 'text' },
      { key: 'eventDate', label: "Date de l'événement", type: 'datetime' },
      order
    ]
  },
  {
    id: 'concours_resources',
    collectionId: 'concours_resources',
    label: 'Ressources concours',
    singular: 'ressource',
    icon: '📚',
    titleField: 'title',
    subtitleField: 'concours',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'title', label: 'Titre', type: 'text', required: true },
      { key: 'type', label: 'Type', type: 'select', options: ['annales', 'guide', 'video', 'fiche', 'site'] },
      { key: 'description', label: 'Description', type: 'textarea' },
      { key: 'url', label: 'Lien', type: 'text' },
      { key: 'concours', label: 'Concours ciblé', type: 'text' },
      order
    ]
  },
  {
    id: 'exam_results',
    collectionId: 'exam_results',
    label: "Résultats d'examens",
    singular: 'résultat',
    icon: '🎓',
    titleField: 'candidateName',
    subtitleField: 'tableNumber',
    orderBy: { field: '$createdAt', dir: 'desc' },
    fields: [
      { key: 'examType', label: "Type d'examen", type: 'text', required: true, help: 'Baccalauréat, BEPC, GCE O Level…' },
      { key: 'serie', label: 'Série', type: 'text' },
      { key: 'year', label: 'Année', type: 'text' },
      { key: 'tableNumber', label: 'N° de table', type: 'text', required: true },
      { key: 'candidateName', label: 'Candidat', type: 'text', required: true },
      { key: 'center', label: "Centre d'examen", type: 'text' },
      { key: 'city', label: 'Ville', type: 'text' },
      { key: 'admitted', label: 'Admis', type: 'boolean' },
      { key: 'mention', label: 'Mention', type: 'text' },
      { key: 'average', label: 'Moyenne', type: 'text', help: 'ex. 14,25/20' },
      { key: 'threshold', label: "Seuil d'admissibilité", type: 'text' }
    ]
  },
  {
    id: 'exams',
    collectionId: 'exams',
    label: 'Examens (accueil)',
    singular: 'examen',
    icon: '🗓️',
    titleField: 'label',
    subtitleField: 'status',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'label', label: 'Libellé', type: 'text', required: true, help: 'ex. Baccalauréat 2026' },
      { key: 'examDate', label: 'Date des épreuves', type: 'datetime' },
      { key: 'resultsDate', label: 'Date des résultats', type: 'datetime' },
      { key: 'status', label: 'Statut', type: 'select', options: ['', 'published'] },
      order
    ]
  },
  {
    id: 'exam_series',
    collectionId: 'exam_series',
    label: 'Séries / filières',
    singular: 'filière',
    icon: '🧩',
    titleField: 'name',
    subtitleField: 'subjects',
    orderBy: { field: 'sortOrder', dir: 'asc' },
    fields: [
      { key: 'exam', label: 'Examen', type: 'select', required: true, options: ['Baccalauréat', 'Probatoire', 'BEPC', 'GCE A Level', 'GCE O Level', 'CAP', 'BT', 'BTS', 'HND', 'Concours'], help: 'Cursus (même liste que les Annales).' },
      { key: 'category', label: 'Subdivision', type: 'text', help: 'ex. « Enseignement général (ESG) », « Industriel », « Écoles normales ». Vide si l’examen n’a pas de subdivision (BEPC, GCE).' },
      { key: 'name', label: 'Série / filière', type: 'text', required: true, help: 'Libellé EXACT, ex. « D — Mathématiques & Sciences de la vie », « Génie Civil », « Science ».' },
      { key: 'code', label: 'Code', type: 'text', help: 'Code éventuel de la série, ex. « D », « F2 », « ACA ». Vide pour les spécialités.' },
      { key: 'subjects', label: 'Matières', type: 'textarea', help: 'Matières de la filière, séparées par des virgules — ce sont elles qui serviront à classer les épreuves. Ex. : Mathématiques, Physique, Chimie, SVT, …' },
      { key: 'sortOrder', label: 'Ordre', type: 'number', help: 'Tri croissant.' },
      { key: 'active', label: 'Active (cocher pour afficher)', type: 'boolean', help: 'Décochée = masquée.' }
    ]
  },
  {
    id: 'subjects',
    collectionId: 'subjects',
    label: 'Matières (Cours)',
    singular: 'matière',
    icon: '📘',
    titleField: 'name',
    subtitleField: 'code',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'name', label: 'Nom', type: 'text', required: true, help: 'ex. Mathématiques' },
      { key: 'code', label: 'Code', type: 'text', help: 'Initiales, ex. Ma (l’icône est déduite du nom).' },
      { key: 'color', label: 'Couleur', type: 'text', help: 'Hex, ex. #F59321' },
      { key: 'levels', label: 'Classes concernées', type: 'text', help: 'ex. Terminale,1ère — vide = toutes' },
      order
    ]
  },
  {
    id: 'chapters',
    collectionId: 'chapters',
    label: 'Chapitres (Cours)',
    singular: 'chapitre',
    icon: '📑',
    titleField: 'title',
    subtitleField: 'subjectId',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'subjectId', label: 'ID de la matière', type: 'text', required: true, help: 'Copie l’ID depuis « Matières » (bouton ID).' },
      { key: 'title', label: 'Titre', type: 'text', required: true },
      { key: 'description', label: 'Description', type: 'textarea' },
      { key: 'level', label: 'Classe', type: 'text', help: 'ex. Terminale' },
      { key: 'videoUrl', label: 'Lien vidéo', type: 'text' },
      { key: 'pdfUrl', label: 'Lien PDF', type: 'text' },
      order
    ]
  },
  {
    id: 'annales',
    collectionId: 'annales',
    label: 'Annales (épreuves)',
    singular: 'épreuve',
    icon: '🗂️',
    titleField: 'title',
    subtitleField: 'subject',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'exam', label: 'Examen', type: 'select', required: true, options: ['BEPC', 'CAP', 'Probatoire', 'Baccalauréat', 'BT', 'BTS', 'HND', 'GCE O Level', 'GCE A Level', 'Concours'], help: 'Catégorie de la page Annales.' },
      { key: 'track', label: 'Série / spécialité', type: 'text', help: 'Libellé EXACT de la feuille, ex. « D — Maths & Sciences de la vie », « Génie Civil », « Science ». Vide pour BEPC.' },
      { key: 'subject', label: 'Matière', type: 'text', required: true, help: 'ex. Mathématiques (doit matcher une matière de la série).' },
      { key: 'year', label: 'Année', type: 'text', help: 'ex. 2024' },
      { key: 'session', label: 'Session', type: 'text', help: 'ex. Juin, Session normale' },
      { key: 'type', label: 'Type', type: 'select', options: ['sujet', 'corrige', 'video'], help: 'Sujet, corrigé ou vidéo.' },
      { key: 'title', label: 'Titre', type: 'text', required: true, help: 'ex. Bac D — Mathématiques 2024' },
      { key: 'fileUrl', label: 'Lien du document', type: 'text', help: 'PDF / vidéo (Appwrite Storage ou lien externe).' },
      { key: 'premium', label: 'Premium (payant)', type: 'boolean' },
      order
    ]
  },
  {
    id: 'school_calendar',
    collectionId: 'school_calendar',
    label: 'Calendrier (Campus)',
    singular: 'évènement',
    icon: '📆',
    titleField: 'title',
    subtitleField: 'type',
    orderBy: { field: 'startDate', dir: 'asc' },
    fields: [
      { key: 'title', label: 'Titre', type: 'text', required: true },
      { key: 'type', label: 'Type', type: 'select', options: ['rentree', 'composition', 'conge', 'examen', 'resultats', 'concours', 'info'] },
      { key: 'startDate', label: 'Début', type: 'datetime', required: true },
      { key: 'endDate', label: 'Fin', type: 'datetime' },
      { key: 'description', label: 'Description', type: 'textarea' },
      { key: 'link', label: 'Lien', type: 'text' },
      { key: 'audience', label: 'Public visé', type: 'text' }
    ]
  },
  {
    id: 'affiche',
    collectionId: 'affiche',
    label: 'À l’affiche (Accueil)',
    singular: 'affiche',
    icon: '🪧',
    titleField: 'title',
    subtitleField: 'type',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'type', label: 'Type', type: 'select', options: ['event', 'sponsored', 'info'] },
      { key: 'title', label: 'Titre', type: 'text', required: true },
      { key: 'subtitle', label: 'Sous-titre', type: 'text' },
      { key: 'imageUrl', label: "URL d'image", type: 'text' },
      { key: 'date', label: 'Date', type: 'datetime' },
      { key: 'location', label: 'Lieu', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' },
      { key: 'partnerName', label: 'Partenaire — nom', type: 'text' },
      { key: 'partnerLogo', label: 'Partenaire — logo (URL)', type: 'text' },
      { key: 'partnerDescription', label: 'Partenaire — description', type: 'textarea' },
      { key: 'link', label: 'Lien', type: 'text' },
      order
    ]
  }
];

export function resourceById(id: string): Resource | undefined {
  return RESOURCES.find((r) => r.id === id);
}
