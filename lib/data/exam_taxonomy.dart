// Taxonomie des examens (Annales) — base statique, profondeur variable.
//
// Motif : Examen → [Subdivision] → Série / Spécialité / Matière.
// Un nœud SANS enfant est une « feuille » : c'est là que se rattachent les
// annales (épreuves). Une feuille de type SÉRIE porte en plus la liste de ses
// `subjects` (matières réellement composées à l'examen) ; une feuille de type
// MATIÈRE/SPÉCIALITÉ (GCE, CAP, BTS…) est elle-même la matière.
//
// Sources : Office du Baccalauréat du Cameroun (officedubac.cm), MINESEC,
// MINESUP (offre de formation BTS), Cameroon GCE Board (camgceb.org).
// NB : les listes de spécialités CAP/BT/BTS/HND couvrent les principales ;
// faciles à compléter.

class ExamNode {
  final String label;
  final String code; // ex. 'D', 'F2', 'CG' — vide si non pertinent
  final String? note; // sous-titre optionnel
  final List<ExamNode> children;
  final List<String> subjects; // matières d'une série feuille (épreuves)
  const ExamNode(this.label,
      {this.code = '', this.note, this.children = const [], this.subjects = const []});

  bool get isLeaf => children.isEmpty;
}

// Helpers de construction (taxonomie construite une fois au démarrage).
ExamNode _n(String code, String label, {String? note, List<String> subjects = const []}) =>
    ExamNode(label, code: code, note: note, subjects: subjects);
ExamNode _grp(String label, List<ExamNode> children, {String? note, List<String> subjects = const []}) =>
    ExamNode(label, note: note, children: children, subjects: subjects);

// ── Séries générales (ESG) — partagées Baccalauréat / Probatoire ────────────
// La Philosophie n'est composée qu'en Terminale (Bac) ; au Probatoire (1ʳᵉ)
// elle est absente. D'où le paramètre `bac`.
List<ExamNode> _esgSeries({required bool bac}) {
  final philo = bac ? const ['Philosophie'] : const <String>[];
  List<String> sci(List<String> spec) =>
      ['Mathématiques', ...spec, ...philo, 'Français', 'Anglais', 'Histoire', 'Géographie', 'ECM'];
  List<String> lettres(List<String> spec) => [
        'Français', 'Littérature', ...spec, ...philo,
        'Histoire', 'Géographie', 'Anglais', 'LV2', 'Mathématiques', 'ECM',
      ];
  return [
    _n('A1', 'A1 — Lettres-Langues anciennes', subjects: lettres(['Latin', 'Grec'])),
    _n('A2', 'A2 — Lettres-Langues vivantes', subjects: lettres(['LV3'])),
    _n('A3', 'A3 — Lettres-Arts', subjects: lettres(['Arts plastiques', 'Musique'])),
    _n('A4', 'A4 — Lettres-Langues', subjects: lettres(const [])),
    _n('A5', 'A5 — Lettres-Langues (allemand/espagnol)', subjects: lettres(const [])),
    _n('ABI', 'ABI — Bilingue', subjects: [...lettres(const []), 'Bilingual Studies']),
    _n('C', 'C — Mathématiques & Sciences physiques', subjects: sci(['Physique', 'Chimie', 'SVT'])),
    _n('D', 'D — Mathématiques & Sciences de la vie', subjects: sci(['SVT', 'Physique', 'Chimie'])),
    _n('E', 'E — Mathématiques & Techniques',
        subjects: sci(['Physique', 'Chimie', 'Technologie', 'Construction mécanique'])),
    _n('TI', 'TI — Technologies de l\'Information', subjects: sci(['Informatique', 'Physique', 'Chimie'])),
  ];
}

// ── Séries techniques industrielles (série F) — Bac / Probatoire technique ───
List<ExamNode> _industrielSeries({required bool bac}) {
  final philo = bac ? const ['Philosophie'] : const <String>[];
  List<String> tech(List<String> spec) =>
      ['Mathématiques', 'Physique', ...spec, ...philo, 'Français', 'Anglais'];
  return [
    _n('F1', 'F1 — Fabrication mécanique',
        subjects: tech(['Construction mécanique', 'Technologie', 'Fabrication', 'Automatisme'])),
    _n('F2', 'F2 — Électronique', subjects: tech(['Électronique', 'Technologie', 'Automatisme'])),
    _n('F3', 'F3 — Électrotechnique', subjects: tech(['Électrotechnique', 'Technologie', 'Mesures électriques'])),
    _n('F4', 'F4 — Génie civil (Bâtiment / Travaux publics)',
        subjects: tech(['Béton armé', 'Construction', 'Topographie', 'Résistance des matériaux'])),
    _n('F5', 'F5 — Froid et climatisation', subjects: tech(['Froid et climatisation', 'Thermodynamique', 'Technologie'])),
    _n('F6', 'F6 — Génie chimique', subjects: tech(['Chimie', 'Génie chimique', 'Chimie industrielle'])),
    _n('F7', 'F7 — Sciences biologiques & médico-sanitaires',
        subjects: tech(['Chimie', 'Biochimie', 'Microbiologie', 'SVT'])),
    _n('F8', 'F8 — Sciences de la santé & du social',
        subjects: tech(['Sciences sanitaires', 'Biologie', 'Sciences sociales'])),
    _n('MEM', 'MEM — Maintenance des équipements',
        subjects: tech(['Maintenance', 'Construction mécanique', 'Électrotechnique'])),
  ];
}

// ── Séries tertiaires/commerciales (STT) ────────────────────────────────────
List<ExamNode> _sttSeries({required bool bac}) {
  final philo = bac ? const ['Philosophie'] : const <String>[];
  List<String> com(List<String> spec) =>
      ['Mathématiques', 'Économie', 'Droit', ...spec, ...philo, 'Français', 'Anglais'];
  return [
    _n('ACA', 'ACA — Action & Communication Administratives',
        subjects: com(['Communication administrative', 'Organisation & Gestion'])),
    _n('ACC', 'ACC — Action & Communication Commerciales',
        subjects: com(['Communication commerciale', 'Mercatique'])),
    _n('CG', 'CG — Comptabilité & Gestion', subjects: com(['Comptabilité', 'Mathématiques financières'])),
    _n('FIG', 'FIG — Fiscalité & Informatique de Gestion',
        subjects: com(['Fiscalité', 'Informatique de gestion', 'Comptabilité'])),
    _n('SES', 'SES — Sciences économiques & sociales', subjects: com(['Sciences sociales'])),
    _n('IH', 'IH — Industries hôtelières', subjects: com(['Hôtellerie', 'Restauration', 'Gestion hôtelière'])),
  ];
}

// Matières GCE (Ordinary Level) — 21 subjects, regroupées Science / Arts.
List<ExamNode> _gceOLevel() => [
      _grp('Science', [
        _n('', 'Mathematics'),
        _n('', 'Additional Mathematics'),
        _n('', 'Physics'),
        _n('', 'Chemistry'),
        _n('', 'Biology'),
        _n('', 'Human Biology'),
        _n('', 'Geology'),
        _n('', 'Computer Science'),
        _n('', 'Geography'),
        _n('', 'Food and Nutrition'),
      ]),
      _grp('Arts & Social', [
        _n('', 'English Language'),
        _n('', 'Literature in English'),
        _n('', 'French'),
        _n('', 'Special Bilingual Education (French)'),
        _n('', 'History'),
        _n('', 'Economics'),
        _n('', 'Commerce'),
        _n('', 'Accounting'),
        _n('', 'Citizenship Education'),
        _n('', 'Religious Studies'),
        _n('', 'Logic'),
      ]),
    ];

// Matières GCE (Advanced Level).
List<ExamNode> _gceALevel() => [
      _grp('Science', [
        _n('', 'Mathematics'),
        _n('', 'Further Mathematics'),
        _n('', 'Physics'),
        _n('', 'Chemistry'),
        _n('', 'Biology'),
        _n('', 'Geology'),
        _n('', 'Computer Science'),
        _n('', 'Geography'),
        _n('', 'Food Science & Nutrition'),
      ]),
      _grp('Arts & Social', [
        _n('', 'English Literature'),
        _n('', 'French'),
        _n('', 'History'),
        _n('', 'Economics'),
        _n('', 'Geography'),
        _n('', 'Commerce'),
        _n('', 'Accounting'),
        _n('', 'Management'),
        _n('', 'Philosophy'),
        _n('', 'Religious Studies'),
        _n('', 'Logic'),
      ]),
    ];

// ── CAP : tronc commun + technologie/pratique propres au métier ─────────────
List<ExamNode> _capIndustriel() {
  ExamNode m(String label, List<String> spec) => _n('', label,
      subjects: ['Français', 'Mathématiques', 'Anglais', ...spec, 'Travaux pratiques', 'Législation & Économie']);
  return [
    m('Menuiserie / Ébénisterie', ['Technologie du bois', 'Dessin technique']),
    m('Maçonnerie / Construction', ['Technologie du bâtiment', 'Dessin technique']),
    m('Installation sanitaire / Plomberie', ['Technologie sanitaire', 'Dessin technique']),
    m('Électricité (installation)', ['Électrotechnique', 'Installations électriques', 'Dessin technique']),
    m('Électronique', ['Électronique', 'Mesures électriques']),
    m('Froid et climatisation', ['Technologie du froid', 'Dessin technique']),
    m('Mécanique automobile', ['Technologie automobile', 'Moteurs & systèmes']),
    m('Mécanique (ajustage / tournage)', ['Technologie mécanique', 'Usinage', 'Dessin technique']),
    m('Structures métalliques / Métaux en feuille', ['Technologie des métaux', 'Chaudronnerie & soudure', 'Dessin technique']),
    m('Maintenance', ['Technologie de maintenance', 'Mécanique appliquée']),
    m('Habillement / Couture', ['Technologie de l\'habillement', 'Coupe & confection']),
    m('Coiffure / Esthétique', ['Technologie professionnelle', 'Soins & techniques']),
    m('Informatique', ['Informatique', 'Bureautique & maintenance']),
  ];
}

List<ExamNode> _capTertiaire() {
  ExamNode m(String label, List<String> spec) => _n('', label,
      subjects: ['Français', 'Mathématiques', 'Anglais', ...spec, 'Travaux pratiques', 'Économie & Législation']);
  return [
    m('Comptabilité', ['Comptabilité', 'Économie d\'entreprise']),
    m('Secrétariat / Sténo-dactylo', ['Sténo-dactylographie', 'Bureautique', 'Correspondance']),
    m('Aide-comptable', ['Comptabilité', 'Gestion']),
    m('Employé de commerce', ['Techniques commerciales', 'Économie d\'entreprise']),
    m('Hôtellerie / Restauration', ['Techniques hôtelières', 'Service & accueil']),
    m('Cuisine', ['Techniques culinaires', 'Hygiène alimentaire']),
  ];
}

// ── BT (Brevet de Technicien) ───────────────────────────────────────────────
List<ExamNode> _btIndustriel() {
  ExamNode m(String label, List<String> spec) => _n('', label, subjects: [
        'Français', 'Mathématiques', 'Anglais', 'Physique', ...spec,
        'Dessin technique', 'Travaux pratiques', 'Économie & Législation',
      ]);
  return [
    m('Électrotechnique', ['Électrotechnique', 'Mesures électriques', 'Automatisme']),
    m('Électronique', ['Électronique', 'Mesures', 'Systèmes numériques']),
    m('Fabrication mécanique', ['Construction mécanique', 'Fabrication & usinage']),
    m('Froid et climatisation', ['Technologie du froid', 'Thermodynamique']),
    m('Génie civil', ['Béton armé', 'Construction', 'Topographie']),
    m('Maintenance industrielle', ['Maintenance', 'Mécanique appliquée']),
    m('Topographie', ['Topographie', 'Dessin & cartographie']),
  ];
}

List<ExamNode> _btTertiaire() {
  ExamNode m(String label, List<String> spec) => _n('', label,
      subjects: ['Français', 'Mathématiques', 'Anglais', ...spec, 'Économie', 'Droit', 'Travaux pratiques']);
  return [
    m('Comptabilité et gestion', ['Comptabilité', 'Gestion']),
    m('Secrétariat / Bureautique', ['Bureautique', 'Correspondance & sténo']),
    m('Action commerciale', ['Techniques commerciales', 'Mercatique']),
  ];
}

// ── BTS (supérieur — culture générale + spécialité + étude de cas) ──────────
List<ExamNode> _btsTertiaire() {
  ExamNode m(String label, List<String> spec) => _n('', label, subjects: [
        'Culture générale & Expression', 'Anglais', 'Mathématiques appliquées',
        'Économie générale', 'Économie d\'entreprise', 'Droit', ...spec, 'Informatique', 'Étude de cas professionnelle',
      ]);
  return [
    m('Comptabilité & Gestion des Entreprises (CGE)',
        ['Comptabilité générale', 'Comptabilité analytique', 'Fiscalité', 'Mathématiques financières']),
    m('Gestion Logistique & Transport', ['Logistique & transport', 'Gestion des stocks']),
    m('Commerce International', ['Commerce international', 'Techniques du commerce extérieur']),
    m('Marketing-Commerce-Vente', ['Mercatique', 'Techniques de vente']),
    m('Banque & Finance', ['Techniques bancaires', 'Finance']),
    m('Assurance', ['Techniques d\'assurance', 'Droit des assurances']),
    m('Gestion des Ressources Humaines', ['Gestion des ressources humaines', 'Droit du travail']),
    m('Secrétariat de Direction / Bureautique', ['Bureautique', 'Communication professionnelle']),
    m('Communication des Organisations', ['Communication', 'Relations publiques']),
    m('Fiscalité / Gestion fiscale', ['Fiscalité', 'Comptabilité']),
    m('Gestion des PME-PMI', ['Gestion des PME-PMI', 'Comptabilité']),
    m('Informatique de Gestion', ['Algorithmique & programmation', 'Bases de données', 'Réseaux']),
    m('Tourisme', ['Techniques du tourisme', 'Géographie touristique']),
    m('Hôtellerie-Restauration', ['Techniques hôtelières', 'Gestion hôtelière']),
  ];
}

List<ExamNode> _btsIndustriel() {
  ExamNode m(String label, List<String> spec) => _n('', label, subjects: [
        'Culture générale & Expression', 'Anglais', 'Mathématiques appliquées', 'Physique appliquée',
        ...spec, 'Informatique', 'Projet professionnel',
      ]);
  return [
    m('Génie Civil', ['Béton armé', 'Résistance des matériaux', 'Topographie', 'Construction']),
    m('Génie Électrique / Électrotechnique', ['Électrotechnique', 'Machines électriques', 'Automatisme']),
    m('Électronique', ['Électronique', 'Systèmes numériques', 'Mesures']),
    m('Froid et Climatisation', ['Technologie du froid', 'Thermodynamique']),
    m('Maintenance Industrielle & Productique', ['Maintenance', 'Mécanique', 'Automatisme']),
    m('Mécatronique', ['Mécanique', 'Électronique', 'Automatisme']),
    m('Informatique Industrielle & Automatisme', ['Automatisme', 'Systèmes embarqués', 'Programmation']),
    m('Génie Mécanique / Fabrication', ['Construction mécanique', 'Fabrication & usinage']),
    m('Génie Chimique', ['Chimie industrielle', 'Génie des procédés']),
    m('Réseaux & Télécommunications', ['Réseaux', 'Télécommunications', 'Transmission']),
    m('Génie Logiciel', ['Programmation', 'Bases de données', 'Génie logiciel']),
    m('Bâtiment', ['Construction', 'Béton armé', 'Dessin du bâtiment']),
    m('Maintenance Automobile', ['Technologie automobile', 'Diagnostic & maintenance']),
    m('Énergies Renouvelables', ['Énergie solaire', 'Électrotechnique', 'Thermique']),
  ];
}

List<ExamNode> _btsSante() {
  ExamNode m(String label, List<String> spec) => _n('', label, subjects: [
        'Culture générale & Expression', 'Anglais', 'Biologie', 'Anatomie-Physiologie', ...spec, 'Pratique professionnelle',
      ]);
  return [
    m('Sciences Infirmières', ['Soins infirmiers', 'Pharmacologie', 'Santé publique']),
    m('Analyses Biomédicales', ['Biochimie', 'Microbiologie', 'Hématologie']),
    m('Imagerie Médicale / Radiologie', ['Techniques d\'imagerie', 'Anatomie radiologique']),
    m('Agriculture / Production Végétale', ['Agronomie', 'Production végétale', 'Phytotechnie']),
    m('Production Animale', ['Zootechnie', 'Production animale', 'Santé animale']),
  ];
}

// ── HND (supérieur anglophone — professional + related + project) ────────────
List<ExamNode> _hndBusiness() {
  ExamNode m(String label, List<String> spec) => _n('', label,
      subjects: ['English', 'French', 'Business Law', 'Economics', 'Entrepreneurship', ...spec, 'ICT', 'Research Project']);
  return [
    m('Accountancy', ['Financial Accounting', 'Cost Accounting', 'Taxation', 'Auditing']),
    m('Banking & Finance', ['Banking Operations', 'Financial Management']),
    m('Marketing', ['Marketing Management', 'Sales & Distribution']),
    m('Management', ['Principles of Management', 'Human Resource Management']),
    m('Human Resource Management', ['Human Resource Management', 'Labour Law']),
    m('Logistics & Transport Management', ['Logistics', 'Supply Chain Management']),
    m('Insurance', ['Principles of Insurance', 'Risk Management']),
    m('Procurement & Supply Chain', ['Procurement', 'Supply Chain Management']),
    m('Project Management', ['Project Planning', 'Project Management']),
    m('Secretarial / Office Management', ['Office Management', 'Communication']),
    m('Communication', ['Mass Communication', 'Public Relations']),
    m('Hospitality Management', ['Hospitality Management', 'Catering & Accommodation']),
    m('Tourism', ['Tourism Management', 'Travel Operations']),
  ];
}

List<ExamNode> _hndEngineering() {
  ExamNode m(String label, List<String> spec) => _n('', label,
      subjects: ['English', 'French', 'Mathematics', 'Entrepreneurship', ...spec, 'ICT', 'Project']);
  return [
    m('Civil Engineering', ['Structural Analysis', 'Reinforced Concrete', 'Surveying', 'Construction']),
    m('Electrical Power Systems', ['Electrical Machines', 'Power Systems', 'Electrotechnics']),
    m('Telecommunications', ['Telecommunications', 'Signal Transmission', 'Networks']),
    m('Computer Engineering / Networks', ['Computer Networks', 'Operating Systems', 'Hardware']),
    m('Software Engineering', ['Programming', 'Databases', 'Software Engineering']),
    m('Mechanical Engineering', ['Mechanics', 'Manufacturing', 'Thermodynamics']),
    m('Mechatronics', ['Mechanics', 'Electronics', 'Automation']),
    m('Automotive Engineering', ['Automotive Technology', 'Engines & Systems', 'Diagnostics']),
    m('Building & Construction', ['Construction Technology', 'Building Drawing', 'Estimation']),
    m('Air Conditioning & Refrigeration', ['Refrigeration', 'Thermodynamics', 'HVAC Systems']),
    m('Woodwork', ['Wood Technology', 'Furniture Design & Construction']),
  ];
}

List<ExamNode> _hndAgriHealth() {
  ExamNode m(String label, List<String> spec) => _n('', label,
      subjects: ['English', 'French', 'Biology', 'Chemistry', 'Entrepreneurship', ...spec, 'Project']);
  return [
    m('Agribusiness', ['Agribusiness Management', 'Crop & Animal Production', 'Agricultural Economics']),
    m('Aquaculture', ['Aquaculture', 'Fish Production', 'Water Quality']),
    m('Nursing', ['Nursing Practice', 'Pharmacology', 'Anatomy & Physiology']),
    m('Medical Laboratory Sciences', ['Biochemistry', 'Microbiology', 'Haematology']),
  ];
}

// ── Concours : épreuves d'admissibilité par école ───────────────────────────
List<ExamNode> _concoursNormales() => [
      _n('', 'ENS — École Normale Supérieure',
          subjects: ['Culture générale', 'Épreuve de spécialité', 'Dissertation', 'Anglais']),
      _n('', 'ENSET — Enseignement technique',
          subjects: ['Culture générale', 'Mathématiques', 'Épreuve de spécialité technique', 'Anglais']),
      _n('', 'ENIEG — Instituteurs (général)',
          subjects: ['Culture générale', 'Français', 'Mathématiques', 'Connaissance du métier']),
      _n('', 'ENIET — Instituteurs (technique)',
          subjects: ['Culture générale', 'Mathématiques', 'Épreuve technique', 'Connaissance du métier']),
    ];

List<ExamNode> _concoursGrandes() => [
      _n('', 'ENAM — Administration & Magistrature',
          subjects: ['Culture générale', 'Note de synthèse', 'Droit', 'Économie', 'Anglais']),
      _n('', 'IRIC — Relations Internationales',
          subjects: ['Culture générale', 'Relations internationales', 'Droit international', 'Économie', 'Anglais']),
      _n('', 'Polytechnique (ENSP)', subjects: ['Mathématiques', 'Physique', 'Chimie']),
      _n('', 'ENSPT — Postes & Télécommunications', subjects: ['Mathématiques', 'Physique', 'Culture générale']),
      _n('', 'IUT — Instituts Universitaires de Technologie',
          subjects: ['Mathématiques', 'Physique', 'Chimie', 'Culture générale']),
      _n('', 'FASA — Agronomie', subjects: ['Biologie', 'Chimie', 'Mathématiques', 'Physique']),
    ];

List<ExamNode> _concoursSante() => [
      _n('', 'FMSB — Médecine', subjects: ['Biologie', 'Chimie', 'Physique']),
      _n('', 'Pharmacie', subjects: ['Biologie', 'Chimie', 'Physique']),
      _n('', 'Sciences infirmières', subjects: ['Biologie', 'Chimie', 'Physique', 'Culture générale']),
    ];

List<ExamNode> _concoursSecurite() => [
      _n('', 'Police (ENSP / ENAP)', subjects: ['Culture générale', 'Dissertation', 'Mathématiques', 'Anglais']),
      _n('', 'Gendarmerie / EMIA', subjects: ['Culture générale', 'Dissertation', 'Mathématiques', 'Anglais']),
      _n('', 'Douanes', subjects: ['Culture générale', 'Dissertation', 'Mathématiques', 'Économie']),
      _n('', 'Armée', subjects: ['Culture générale', 'Dissertation', 'Mathématiques']),
    ];

/// Taxonomie — clés = libellés des cartes de la page d'accueil Annales.
final Map<String, ExamNode> examTaxonomy = {
  // ── BEPC : pas de subdivision ni de série — épreuves par matière ───────────
  'BEPC': _grp('BEPC', const [], note: 'Collège · 3ᵉ', subjects: const [
    'Français', 'Anglais', 'Mathématiques', 'SVT', 'Physique-Chimie',
    'Histoire', 'Géographie', 'ECM', 'LV2', 'Informatique',
  ]),

  // ── CAP : spécialités-métiers (Industriel / Tertiaire) ────────────────────
  'CAP': _grp('CAP', [
    _grp('Industriel', _capIndustriel()),
    _grp('Tertiaire', _capTertiaire()),
  ]),

  // ── Probatoire : ESG / Industriel / Commercial (STT) ──────────────────────
  'Probatoire': _grp('Probatoire', [
    _grp('Enseignement général (ESG)', _esgSeries(bac: false)),
    _grp('Technique industriel', _industrielSeries(bac: false)),
    _grp('Technique commercial (STT)', _sttSeries(bac: false)),
  ]),

  // ── Baccalauréat : ESG / STT / Industriel ─────────────────────────────────
  'Baccalauréat': _grp('Baccalauréat', [
    _grp('Enseignement général (ESG)', _esgSeries(bac: true)),
    _grp('Technique commercial (STT)', _sttSeries(bac: true)),
    _grp('Technique industriel', _industrielSeries(bac: true)),
  ]),

  // ── BT (Brevet de Technicien) ─────────────────────────────────────────────
  'BT': _grp('BT', [
    _grp('Industriel', _btIndustriel()),
    _grp('Tertiaire', _btTertiaire()),
  ]),

  // ── BTS (supérieur — MINESUP) ─────────────────────────────────────────────
  'BTS': _grp('BTS', [
    _grp('Tertiaire / Commercial', _btsTertiaire()),
    _grp('Industriel', _btsIndustriel()),
    _grp('Santé & Agro', _btsSante()),
  ]),

  // ── HND (supérieur — anglophone) ──────────────────────────────────────────
  'HND': _grp('HND', [
    _grp('Business', _hndBusiness()),
    _grp('Engineering', _hndEngineering()),
    _grp('Agriculture & Health', _hndAgriHealth()),
  ]),

  // ── GCE (anglophone) : par matières ───────────────────────────────────────
  'GCE O Level': _grp('GCE O Level', _gceOLevel(), note: 'Ordinary Level'),
  'GCE A Level': _grp('GCE A Level', _gceALevel(), note: 'Advanced Level'),

  // ── Concours : les écoles / concours ──────────────────────────────────────
  'Concours': _grp('Concours', [
    _grp('Écoles normales', _concoursNormales()),
    _grp('Grandes écoles', _concoursGrandes()),
    _grp('Santé', _concoursSante()),
    _grp('Sécurité & Défense', _concoursSecurite()),
  ]),
};
