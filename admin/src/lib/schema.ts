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
      { key: 'route', label: 'Lien interne', type: 'text', help: 'ex. /results, /notifications, /annales' },
      { key: 'imageUrl', label: "URL d'image", type: 'text' },
      { key: 'publishedAt', label: 'Publié le', type: 'datetime', help: 'Vide = maintenant.' }
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
  }
];

export function resourceById(id: string): Resource | undefined {
  return RESOURCES.find((r) => r.id === id);
}
