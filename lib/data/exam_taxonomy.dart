// Taxonomie des examens (Annales) — base statique, profondeur variable.
//
// Motif : Examen → [Subdivision] → Série / Spécialité / Matière.
// Un nœud SANS enfant est une « feuille » : c'est là que se rattachent les
// annales (épreuves), filtrées ensuite par matière + année.
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
  const ExamNode(this.label, {this.code = '', this.note, this.children = const []});

  bool get isLeaf => children.isEmpty;
}

// Helpers de construction (taxonomie construite une fois au démarrage).
ExamNode _n(String code, String label, {String? note}) => ExamNode(label, code: code, note: note);
ExamNode _grp(String label, List<ExamNode> children, {String? note}) =>
    ExamNode(label, note: note, children: children);

// Séries générales (ESG) partagées par Baccalauréat et Probatoire.
List<ExamNode> _esgSeries() => [
      _n('A1', 'A1 — Lettres-Langues anciennes'),
      _n('A2', 'A2 — Lettres-Langues vivantes'),
      _n('A3', 'A3 — Lettres-Arts'),
      _n('A4', 'A4 — Lettres-Langues'),
      _n('A5', 'A5 — Lettres-Langues (allemand/espagnol)'),
      _n('ABI', 'ABI — Bilingue'),
      _n('C', 'C — Mathématiques & Sciences physiques'),
      _n('D', 'D — Mathématiques & Sciences de la vie'),
      _n('E', 'E — Mathématiques & Techniques'),
      _n('TI', 'TI — Technologies de l\'Information'),
    ];

// Séries techniques industrielles (série F) partagées Bac/Probatoire technique.
List<ExamNode> _industrielSeries() => [
      _n('F1', 'F1 — Fabrication mécanique'),
      _n('F2', 'F2 — Électronique'),
      _n('F3', 'F3 — Électrotechnique'),
      _n('F4', 'F4 — Génie civil (Bâtiment / Travaux publics)'),
      _n('F5', 'F5 — Froid et climatisation'),
      _n('F6', 'F6 — Génie chimique'),
      _n('F7', 'F7 — Sciences biologiques & médico-sanitaires'),
      _n('F8', 'F8 — Sciences de la santé & du social'),
      _n('MEM', 'MEM — Maintenance des équipements'),
    ];

// Séries tertiaires/commerciales (STT).
List<ExamNode> _sttSeries() => [
      _n('ACA', 'ACA — Action & Communication Administratives'),
      _n('ACC', 'ACC — Action & Communication Commerciales'),
      _n('CG', 'CG — Comptabilité & Gestion'),
      _n('FIG', 'FIG — Fiscalité & Informatique de Gestion'),
      _n('SES', 'SES — Sciences économiques & sociales'),
      _n('IH', 'IH — Industries hôtelières'),
    ];

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

/// Taxonomie — clés = libellés des cartes de la page d'accueil Annales.
final Map<String, ExamNode> examTaxonomy = {
  // ── BEPC : pas de subdivision ni de série (épreuves par matière) ──────────
  'BEPC': _grp('BEPC', const [], note: 'Collège · 3ᵉ'),

  // ── CAP : spécialités-métiers (Industriel / Tertiaire) ────────────────────
  'CAP': _grp('CAP', [
    _grp('Industriel', [
      _n('', 'Menuiserie / Ébénisterie'),
      _n('', 'Maçonnerie / Construction'),
      _n('', 'Installation sanitaire / Plomberie'),
      _n('', 'Électricité (installation)'),
      _n('', 'Électronique'),
      _n('', 'Froid et climatisation'),
      _n('', 'Mécanique automobile'),
      _n('', 'Mécanique (ajustage / tournage)'),
      _n('', 'Structures métalliques / Métaux en feuille'),
      _n('', 'Maintenance'),
      _n('', 'Habillement / Couture'),
      _n('', 'Coiffure / Esthétique'),
      _n('', 'Informatique'),
    ]),
    _grp('Tertiaire', [
      _n('', 'Comptabilité'),
      _n('', 'Secrétariat / Sténo-dactylo'),
      _n('', 'Aide-comptable'),
      _n('', 'Employé de commerce'),
      _n('', 'Hôtellerie / Restauration'),
      _n('', 'Cuisine'),
    ]),
  ]),

  // ── Probatoire : ESG / Industriel / Commercial (STT) ──────────────────────
  'Probatoire': _grp('Probatoire', [
    _grp('Enseignement général (ESG)', _esgSeries()),
    _grp('Technique industriel', _industrielSeries()),
    _grp('Technique commercial (STT)', _sttSeries()),
  ]),

  // ── Baccalauréat : ESG / STT / Industriel ─────────────────────────────────
  'Baccalauréat': _grp('Baccalauréat', [
    _grp('Enseignement général (ESG)', _esgSeries()),
    _grp('Technique commercial (STT)', _sttSeries()),
    _grp('Technique industriel', _industrielSeries()),
  ]),

  // ── BT (Brevet de Technicien) ─────────────────────────────────────────────
  'BT': _grp('BT', [
    _grp('Industriel', [
      _n('', 'Électrotechnique'),
      _n('', 'Électronique'),
      _n('', 'Fabrication mécanique'),
      _n('', 'Froid et climatisation'),
      _n('', 'Génie civil'),
      _n('', 'Maintenance industrielle'),
      _n('', 'Topographie'),
    ]),
    _grp('Tertiaire', [
      _n('', 'Comptabilité et gestion'),
      _n('', 'Secrétariat / Bureautique'),
      _n('', 'Action commerciale'),
    ]),
  ]),

  // ── BTS (supérieur — MINESUP) ─────────────────────────────────────────────
  'BTS': _grp('BTS', [
    _grp('Tertiaire / Commercial', [
      _n('', 'Comptabilité & Gestion des Entreprises (CGE)'),
      _n('', 'Gestion Logistique & Transport'),
      _n('', 'Commerce International'),
      _n('', 'Marketing-Commerce-Vente'),
      _n('', 'Banque & Finance'),
      _n('', 'Assurance'),
      _n('', 'Gestion des Ressources Humaines'),
      _n('', 'Secrétariat de Direction / Bureautique'),
      _n('', 'Communication des Organisations'),
      _n('', 'Fiscalité / Gestion fiscale'),
      _n('', 'Gestion des PME-PMI'),
      _n('', 'Informatique de Gestion'),
      _n('', 'Tourisme'),
      _n('', 'Hôtellerie-Restauration'),
    ]),
    _grp('Industriel', [
      _n('', 'Génie Civil'),
      _n('', 'Génie Électrique / Électrotechnique'),
      _n('', 'Électronique'),
      _n('', 'Froid et Climatisation'),
      _n('', 'Maintenance Industrielle & Productique'),
      _n('', 'Mécatronique'),
      _n('', 'Informatique Industrielle & Automatisme'),
      _n('', 'Génie Mécanique / Fabrication'),
      _n('', 'Génie Chimique'),
      _n('', 'Réseaux & Télécommunications'),
      _n('', 'Génie Logiciel'),
      _n('', 'Bâtiment'),
      _n('', 'Maintenance Automobile'),
      _n('', 'Énergies Renouvelables'),
    ]),
    _grp('Santé & Agro', [
      _n('', 'Sciences Infirmières'),
      _n('', 'Analyses Biomédicales'),
      _n('', 'Imagerie Médicale / Radiologie'),
      _n('', 'Agriculture / Production Végétale'),
      _n('', 'Production Animale'),
    ]),
  ]),

  // ── HND (supérieur — anglophone) ──────────────────────────────────────────
  'HND': _grp('HND', [
    _grp('Business', [
      _n('', 'Accountancy'),
      _n('', 'Banking & Finance'),
      _n('', 'Marketing'),
      _n('', 'Management'),
      _n('', 'Human Resource Management'),
      _n('', 'Logistics & Transport Management'),
      _n('', 'Insurance'),
      _n('', 'Procurement & Supply Chain'),
      _n('', 'Project Management'),
      _n('', 'Secretarial / Office Management'),
      _n('', 'Communication'),
      _n('', 'Hospitality Management'),
      _n('', 'Tourism'),
    ]),
    _grp('Engineering', [
      _n('', 'Civil Engineering'),
      _n('', 'Electrical Power Systems'),
      _n('', 'Telecommunications'),
      _n('', 'Computer Engineering / Networks'),
      _n('', 'Software Engineering'),
      _n('', 'Mechanical Engineering'),
      _n('', 'Mechatronics'),
      _n('', 'Automotive Engineering'),
      _n('', 'Building & Construction'),
      _n('', 'Air Conditioning & Refrigeration'),
      _n('', 'Woodwork'),
    ]),
    _grp('Agriculture & Health', [
      _n('', 'Agribusiness'),
      _n('', 'Aquaculture'),
      _n('', 'Nursing'),
      _n('', 'Medical Laboratory Sciences'),
    ]),
  ]),

  // ── GCE (anglophone) : par matières ───────────────────────────────────────
  'GCE O Level': _grp('GCE O Level', _gceOLevel(), note: 'Ordinary Level'),
  'GCE A Level': _grp('GCE A Level', _gceALevel(), note: 'Advanced Level'),

  // ── Concours : les écoles / concours ──────────────────────────────────────
  'Concours': _grp('Concours', [
    _grp('Écoles normales', [
      _n('', 'ENS — École Normale Supérieure'),
      _n('', 'ENSET — Enseignement technique'),
      _n('', 'ENIEG — Instituteurs (général)'),
      _n('', 'ENIET — Instituteurs (technique)'),
    ]),
    _grp('Grandes écoles', [
      _n('', 'ENAM — Administration & Magistrature'),
      _n('', 'IRIC — Relations Internationales'),
      _n('', 'Polytechnique (ENSP)'),
      _n('', 'ENSPT — Postes & Télécommunications'),
      _n('', 'IUT — Instituts Universitaires de Technologie'),
      _n('', 'FASA — Agronomie'),
    ]),
    _grp('Santé', [
      _n('', 'FMSB — Médecine'),
      _n('', 'Pharmacie'),
      _n('', 'Sciences infirmières'),
    ]),
    _grp('Sécurité & Défense', [
      _n('', 'Police (ENSP / ENAP)'),
      _n('', 'Gendarmerie / EMIA'),
      _n('', 'Douanes'),
      _n('', 'Armée'),
    ]),
  ]),
};
