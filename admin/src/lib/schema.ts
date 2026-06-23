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
  // Champs interrogés par la recherche (substring, sans index). Par défaut :
  // [titleField, subtitleField]. Mettre [] pour désactiver la recherche.
  searchFields?: string[];
  // Affichage en arborescence repliable (examen → subdivision → filière →
  // matières) au lieu d'une liste plate. Spécifique aux séries/filières.
  tree?: boolean;
  // ID de document = valeur de ce champ à la création (au lieu d'un ID auto).
  // Utile quand l'app retrouve le doc par une clé métier (ex. lessons/quizzes
  // keyés par `chapterId`).
  idField?: string;
  // Vue lecture seule : pas de création / édition / suppression (suivi/audit de
  // données utilisateur comme les candidatures ou les achats).
  readOnly?: boolean;
}

const order: Field = { key: 'order', label: 'Ordre', type: 'number', help: 'Tri croissant (0 en premier).' };

export const RESOURCES: Resource[] = [
  {
    id: 'app_config',
    collectionId: 'app_config',
    label: 'Configuration',
    singular: 'paramètre',
    icon: '⚙️',
    titleField: 'key',
    subtitleField: 'value',
    orderBy: { field: 'key', dir: 'asc' },
    fields: [
      { key: 'key', label: 'Clé', type: 'text', required: true, help: 'ex. playStoreUrl, appStoreUrl (ne pas renommer les clés existantes).' },
      { key: 'value', label: 'Valeur', type: 'text', help: 'ex. lien Google Play / App Store de l’app.' }
    ]
  },
  {
    id: 'payment_requests',
    collectionId: 'payment_requests',
    label: 'Paiements (crédits)',
    singular: 'paiement',
    icon: '💳',
    titleField: 'telegramUsername',
    subtitleField: 'status',
    orderBy: { field: '$createdAt', dir: 'desc' },
    fields: [
      { key: 'status', label: 'Statut', type: 'select', options: ['draft', 'pending', 'approved', 'rejected', 'redeemed', 'expired'], help: 'Audit fraude : tu peux rejeter manuellement une demande approuvée à tort (avant rachat).' },
      { key: 'operator', label: 'Opérateur', type: 'text' },
      { key: 'amount', label: 'Montant (FCFA)', type: 'number' },
      { key: 'credits', label: 'Crédits', type: 'number' },
      { key: 'telegramUsername', label: 'Telegram @', type: 'text' },
      { key: 'telegramUserId', label: 'Telegram ID', type: 'text' },
      { key: 'code', label: 'Code émis', type: 'text' },
      { key: 'txnId', label: 'ID transaction', type: 'text' },
      { key: 'senderNumber', label: 'Numéro émetteur', type: 'text' },
      { key: 'rawMessage', label: 'SMS collé (preuve)', type: 'textarea' },
      { key: 'reviewedBy', label: 'Validé par', type: 'text' },
      { key: 'reviewedAt', label: 'Validé le', type: 'text' },
      { key: 'redeemedByUid', label: 'Racheté par (UID)', type: 'text' },
      { key: 'redeemedAt', label: 'Racheté le', type: 'text' },
      { key: 'expiresAt', label: 'Expire le', type: 'text' }
    ]
  },
  {
    id: 'users',
    collectionId: 'users',
    label: 'Utilisateurs',
    singular: 'utilisateur',
    icon: '👤',
    titleField: 'firstName',
    subtitleField: 'email',
    orderBy: { field: '$createdAt', dir: 'desc' },
    searchFields: ['firstName', 'lastName', 'email', 'phoneNumber', 'school', 'city'],
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
    id: 'home_announcements',
    collectionId: 'home_announcements',
    label: 'Annonces (Accueil)',
    singular: 'annonce',
    icon: '📣',
    titleField: 'title',
    subtitleField: 'eyebrow',
    orderBy: { field: 'order', dir: 'asc' },
    fields: [
      { key: 'active', label: 'Active (cocher pour afficher)', type: 'boolean', help: 'Décochée = masquée du carrousel.' },
      { key: 'order', label: 'Ordre', type: 'number', help: 'Tri croissant. Les annonces s’affichent AVANT les examens (position 1, 2, …).' },
      { key: 'eyebrow', label: 'Sur-titre', type: 'text', help: 'Petit label en capitales, ex. « NOUVEAU », « ANNONCE », « PROMO ». Optionnel.' },
      { key: 'title', label: 'Titre', type: 'text', required: true, help: 'Titre principal (2 lignes max).' },
      { key: 'body', label: 'Texte', type: 'textarea', help: 'Texte de soutien (3 lignes max). Optionnel.' },
      { key: 'imageUrl', label: "Image de fond (URL)", type: 'text', help: 'Image plein cadre (un voile sombre est ajouté pour la lisibilité si texte clair). Optionnel — sinon couleur de fond.' },
      { key: 'bgColor', label: 'Couleur de fond (hex)', type: 'text', help: 'ex. #1B1712, #E8590C. Utilisée si pas d’image. Vide = dégradé sombre par défaut.' },
      { key: 'textColor', label: 'Couleur du texte', type: 'select', options: ['light', 'dark'], help: '« light » (texte blanc, fonds sombres/images) ou « dark » (texte foncé, fonds clairs).' },
      { key: 'ctaLabel', label: 'Bouton — texte', type: 'text', help: 'ex. « Découvrir », « J’en profite ». Vide = pas de bouton.' },
      { key: 'ctaTarget', label: 'Bouton — destination', type: 'text', help: 'Route interne (ex. /annales, /concours, /credits) OU lien externe (https://…, wa.me/…, tel:…, onbuch://…).' },
      { key: 'startAt', label: 'Afficher à partir du', type: 'datetime', help: 'Optionnel — l’annonce n’apparaît qu’à partir de cette date.' },
      { key: 'endAt', label: 'Masquer après le', type: 'datetime', help: 'Optionnel — l’annonce disparaît après cette date.' }
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
      { key: 'excerpt', label: 'Aperçu', type: 'textarea', help: 'Court résumé affiché dans la liste (optionnel ; sinon début du contenu).' },
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
    tree: true,
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
      { key: 'exam', label: 'Examen', type: 'text', help: 'Rattachement (comme les annales). ex. Baccalauréat — vide = tous' },
      { key: 'track', label: 'Série', type: 'text', help: 'Série/filière, ex. D — vide = toutes les séries' },
      { key: 'premium', label: 'Pack premium', type: 'boolean', help: 'Coché = payant (en crédits). Décoché = gratuit.' },
      { key: 'priceCredits', label: 'Prix (crédits)', type: 'number', help: 'Prix du pack en crédits OnBuch (si premium).' },
      { key: 'coef', label: 'Coefficient', type: 'number', help: 'Coef de la matière (affiché sur la fiche).' },
      { key: 'freeChapters', label: 'Chapitres en aperçu', type: 'number', help: 'Nb de chapitres consultables gratuitement avant achat.' },
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
  },
  {
    id: 'lessons',
    collectionId: 'lessons',
    label: 'Leçons (Cours)',
    singular: 'leçon',
    icon: '📖',
    titleField: 'chapterId',
    subtitleField: 'content',
    orderBy: { field: '$createdAt', dir: 'desc' },
    idField: 'chapterId',
    searchFields: ['chapterId'],
    fields: [
      { key: 'chapterId', label: 'ID du chapitre', type: 'text', required: true, help: 'Copie l’ID depuis « Chapitres » (bouton ID). Une seule leçon par chapitre — réenregistrer remplace la version IA.' },
      { key: 'content', label: 'Contenu (Markdown)', type: 'textarea', help: 'Texte de la leçon en Markdown (titres ##, listes -, **gras**, formules). C’est ce que l’élève lit.' }
    ]
  },
  {
    id: 'quizzes',
    collectionId: 'quizzes',
    label: 'Quiz (Cours)',
    singular: 'quiz',
    icon: '❓',
    titleField: 'chapterId',
    subtitleField: 'content',
    orderBy: { field: '$createdAt', dir: 'desc' },
    idField: 'chapterId',
    searchFields: ['chapterId'],
    fields: [
      { key: 'chapterId', label: 'ID du chapitre', type: 'text', required: true, help: 'Copie l’ID depuis « Chapitres » (bouton ID). Un seul quiz par chapitre.' },
      { key: 'content', label: 'Questions (JSON)', type: 'textarea', required: true, help: 'Format : {"questions":[{"q":"Énoncé ?","options":["A","B","C","D"],"answer":0,"explanation":"Pourquoi"}]}. « answer » = index (0 = 1ʳᵉ option) de la bonne réponse.' }
    ]
  },
  {
    id: 'concours_applications',
    collectionId: 'concours_applications',
    label: 'Candidatures concours',
    singular: 'candidature',
    icon: '📋',
    titleField: 'concoursName',
    subtitleField: 'status',
    orderBy: { field: '$createdAt', dir: 'desc' },
    readOnly: true,
    searchFields: ['concoursName', 'userId', 'examLabel', 'receiptNo'],
    fields: [
      { key: 'concoursName', label: 'Concours', type: 'text' },
      { key: 'status', label: 'Statut', type: 'text', help: 'submitted · validated · exam · result' },
      { key: 'userId', label: 'Utilisateur (UID)', type: 'text' },
      { key: 'examLabel', label: 'Centre / épreuve', type: 'text' },
      { key: 'receiptNo', label: 'N° de reçu', type: 'text' },
      { key: 'concoursId', label: 'ID concours', type: 'text' },
      { key: 'createdAt', label: 'Déposée le', type: 'text' }
    ]
  },
  {
    id: 'pack_purchases',
    collectionId: 'pack_purchases',
    label: 'Achats de packs',
    singular: 'achat',
    icon: '🧾',
    titleField: 'subjectId',
    subtitleField: 'uid',
    orderBy: { field: '$createdAt', dir: 'desc' },
    readOnly: true,
    searchFields: ['uid', 'subjectId'],
    fields: [
      { key: 'subjectId', label: 'ID de la matière (pack)', type: 'text' },
      { key: 'uid', label: 'Utilisateur (UID)', type: 'text' },
      { key: 'priceCredits', label: 'Prix (crédits)', type: 'number' },
      { key: 'createdAt', label: 'Acheté le', type: 'text' }
    ]
  }
];

export function resourceById(id: string): Resource | undefined {
  return RESOURCES.find((r) => r.id === id);
}
