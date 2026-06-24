# Textes Play Store — OnBuch (FR)

> Tous les textes prêts à coller dans la Google Play Console.
> Package : `cm.luvvix.onbuch` · Marché : Cameroun (français) · Catégorie : Éducation.
> Limites respectées : titre ≤ 30 car., description courte ≤ 80 car., description complète ≤ 4000 car.

---

## 1. Nom de l'application (≤ 30 caractères)

```
OnBuch : Réussir au Cameroun
```

> Alternatives (≤ 30 car.) :
> - `OnBuch — École & Examens` (24)
> - `OnBuch : Tuteur IA & Cours` (26)
> - `OnBuch` (court, si la marque suffit)

---

## 2. Description courte (≤ 80 caractères)

```
Résultats d'examens, Tuteur IA, cours, annales et concours pour les élèves.
```

> Alternatives :
> - `Tuteur IA, cours, résultats du Bac/BEPC et concours du Cameroun.` (62)
> - `Révise, corrige tes devoirs avec l'IA et suis tes résultats d'examens.` (69)

---

## 3. Description complète (≤ 4000 caractères)

```
OnBuch, c'est l'application qui accompagne les élèves et étudiants camerounais tout au long de l'année scolaire. Résultats d'examens, tuteur intelligent, cours, annales, concours et actualités : tout est réuni dans une seule application, pensée pour le programme camerounais (MINESEC) et conçue pour fonctionner même avec une connexion limitée.

★ LÉO, TON TUTEUR INTELLIGENT
Bloqué sur un exercice ? Prends ton devoir en photo, écris ta question ou importe un PDF : Léo lit, corrige et t'explique étape par étape, dans un langage clair.
• Correction de devoirs par photo, texte ou PDF
• Explications détaillées et chat de suivi pour approfondir
• Fiches de révision générées automatiquement
• Export PDF propre de tes corrections et fiches
• 3 corrections gratuites par jour, fiches de révision illimitées

★ RÉSULTATS D'EXAMENS
Consulte les résultats officiels du Baccalauréat, du BEPC et du Probatoire dès leur publication. Recherche par nom ou numéro, et partage facilement la bonne nouvelle.

★ COURS & QUIZ
Révise par matière, chapitre et leçon, avec des quiz interactifs et un suivi de ta progression pour rester motivé tout au long de l'année.

★ ANNALES
Retrouve les annales pour t'entraîner dans les conditions de l'examen et arriver prêt le jour J.

★ CONCOURS
Ne rate plus jamais un concours. Recherche en direct, filtres par statut, fiches détaillées, dates d'inscription, centres de préparation et concours blancs pour t'évaluer.

★ AGENDA & CAMPUS
Garde un œil sur le calendrier scolaire et les dates importantes de l'année.

★ ACTUALITÉS
Suis l'actualité de l'éducation au Cameroun : annonces officielles, conseils et informations utiles, directement dans l'application.

POURQUOI ONBUCH ?
• 100 % pensée pour le Cameroun et le programme MINESEC
• Interface simple, rapide et agréable, en français
• Mode sombre pour réviser confortablement, de jour comme de nuit
• Conçue pour les connexions lentes ou coupées
• Gratuite, avec des options pour aller plus loin

Que tu prépares le BEPC, le Probatoire, le Baccalauréat ou un concours, OnBuch est ton partenaire de réussite. Télécharge l'application, révise mieux et vise le haut !

Une question, une suggestion ? Écris-nous, ton avis nous aide à améliorer OnBuch.
```

---

## 4. Nouveautés / Notes de version (≤ 500 caractères par langue)

### Version 1.0.0 (première publication)

```
Bienvenue sur OnBuch ! Première version :
• Léo, ton tuteur IA : corrige tes devoirs par photo, texte ou PDF
• Fiches de révision et export PDF
• Résultats du Bac, BEPC et Probatoire
• Cours, quiz et suivi de progression
• Annales, concours et agenda scolaire
• Mode sombre
Merci de tester OnBuch et de nous faire part de tes retours !
```

### Modèle pour les mises à jour suivantes

```
Merci d'utiliser OnBuch ! Cette mise à jour apporte :
• [nouveauté 1]
• [nouveauté 2]
• Corrections de bugs et améliorations de performance
Continue de nous envoyer tes retours pour rendre OnBuch encore meilleure !
```

---

## 5. Catégorisation & coordonnées

- **Catégorie d'application** : Éducation
- **Tags** (jusqu'à 5, à choisir dans la liste Google) : Éducation, Apprentissage, Aide aux devoirs, Examens, Outils d'étude
- **Email développeur** : à renseigner (ex. `support@onbuch.cm`)
- **Site web** : à renseigner (ex. `https://onbuch.cm`)
- **Politique de confidentialité (URL)** : OBLIGATOIRE — à héberger (ex. `https://onbuch.cm/confidentialite`)

---

## 6. Classification du contenu (questionnaire IARC)

Réponses attendues pour une app éducative :
- Violence, contenu sexuel, langage grossier, drogues : **Non**
- L'application contient-elle un **chat / contenu généré par l'IA ou les utilisateurs** : **Oui** (Tuteur IA Léo) → prévoir une mention de modération
- Achats intégrés : **Oui** (crédits Tuteur)
- Partage de localisation : **Non**
- Classification visée : **PEGI 3 / Tout public**

---

## 7. Sécurité des données (Data safety)

Données collectées et leur usage (à confirmer côté Appwrite) :
- **Compte** : adresse e-mail / identifiant (création de compte, authentification)
- **Contenu utilisateur** : photos/PDF de devoirs envoyés au Tuteur IA (traitement de la correction)
- **Identifiants d'appareil / push** : jeton FCM (notifications « c'est prêt »)
- **Activité dans l'app** : événements d'analyse (amélioration du produit)
- **Achats** : reçus Google Play (vérification et crédit des quotas)

Points à déclarer :
- Données chiffrées **en transit** : Oui (HTTPS)
- L'utilisateur peut-il **demander la suppression** de ses données : Oui (à mettre en place / documenter)
- Données **partagées avec des tiers** : préciser NVIDIA (traitement IA serveur), Google (FCM/Play), Appwrite (hébergement backend)

> ⚠️ À vérifier avec l'implémentation réelle avant de soumettre le formulaire Data safety.

---

## 8. Mots-clés / ASO (pour le titre, la description et les réponses aux avis)

OnBuch, Cameroun, Bac, BEPC, Probatoire, GCE, MINESEC, résultats examens, tuteur IA,
aide aux devoirs, correction devoir, cours, quiz, révision, annales, concours,
lycée, collège, élève, étudiant, éducation Cameroun.

---

## 9. Assets graphiques requis (rappel — à fournir séparément)

- **Icône** : 512 × 512 px, PNG 32 bits
- **Image de présentation (Feature graphic)** : 1024 × 500 px
- **Captures d'écran téléphone** : min. 2 (jusqu'à 8), 16:9 ou 9:16, côté ≥ 320 px
- (Optionnel) Captures tablette 7" et 10"
- (Optionnel) Vidéo promotionnelle YouTube

### Idées de légendes pour les captures d'écran
1. « Corrige tes devoirs avec Léo, ton tuteur IA »
2. « Tes résultats du Bac, BEPC et Probatoire en un instant »
3. « Des cours et quiz pour progresser chaque jour »
4. « Tous les concours du Cameroun au même endroit »
5. « Des fiches de révision prêtes à imprimer »
6. « Révise de jour comme de nuit avec le mode sombre »
