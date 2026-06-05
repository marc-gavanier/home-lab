---
description: Lancer le cycle de curation post-conférence guidé (CODE complet) à partir de la note brute du jour.
argument-hint: (optionnel) <nom-fichier-note-brute>
---

L'utilisateur a fini sa journée de conférence et veut faire la **curation** des notes brutes. Tu vas guider le cycle CODE complet en phases distinctes, **avec confirmation explicite à chaque phase clé**.

Argument optionnel : `$ARGUMENTS` — nom de la note brute à curer (si non fourni, prendre la plus récente note brute dans `Inbox/`).

## Phase 1 — Relecture surlignée

Lis la note brute en entier. Pour chaque talk, propose à l'utilisateur :
- les **concepts qui méritent une note atomique** (`type: reference`) — ne propose que ce qui survit au filtre `[[Purifier la capture]]` (envie / pourquoi / 2min / déléguer) ;
- les **idées à garder comme fils rouges transverses** (pour la phase Express, pas pour des notes individuelles) ;
- les **idées à laisser dans l'archive sans extraction** (trop spécifique, anecdotique, déjà couvert ailleurs).

Présente une analyse claire par talk et **demande validation** avant de passer à la phase 2.

## Phase 2 — Distillation atomique (avec audit fidélité dès la création)

Pour chaque note atomique validée :
1. Crée la note dans `Ressources/` (ou sous-dossier pertinent) à partir du **Template — note atomique reference**.
2. **IMMÉDIATEMENT** invoque le subagent `note-fidelity` pour vérifier que la note est strictement fidèle aux notes brutes et aux sources canoniques sourcées. Corrige les passages flaggés **avant** de passer à la note suivante.
3. Ajoute le backlink dans la note brute : `→ Note atomique extraite : [[Nom de la note]].`

**Règle d'or** (cf. `prise-notes-conf`) : pas de sections « Pourquoi c'est utile / Comment l'appliquer » de ton cru dans la `reference`. Pas de connexions transversales avec d'autres talks. Tout ce contenu va dans la synthèse de la phase 3.

## Phase 3 — Express (synthèse)

Crée la note de synthèse dans `Archives/{Nom conf} {Année}/synthèse — fils rouges et actions.md` à partir du **Template — synthèse de journée**.

Structure :
- **Fils rouges transversaux** (2 à 5 lignes de force qui traversent plusieurs talks).
- **Notes atomiques produites** (liste avec wikilinks et speakers).
- **Approfondissements / apports perso** (élaborations pédagogiques qui dépassent le strict contenu des talks).
- **À explorer / actions concrètes** (intentions concrètes à suivre).
- **Position perso (à confronter / corriger)** — section où tu **assumes** tes interprétations, à confronter avec l'utilisateur.

**Présente un pré-audit** des passages de la synthèse qui sont **de ton interprétation** (vs ce qui vient des notes brutes), et demande à l'utilisateur de valider/biffer ligne par ligne ou en bloc.

## Phase 4 — Archive

1. Crée le dossier `Archives/{Nom conf} {Année}/` s'il n'existe pas.
2. Mets à jour le frontmatter de la note brute (retire le tag `a-trier` s'il y est, garde `maj` à jour).
3. **Déplace** la note brute de `Inbox/` vers `Archives/{Nom conf} {Année}/`.
4. Vérifie qu'aucun wikilink entrant n'est cassé (les liens `[[2026-XX-XX - {Nom conf} (brut)]]` doivent continuer à résoudre par nom de fichier — c'est le cas en Obsidian par défaut).

## Phase 5 — Enrichissement bidirectionnel

Pour chaque note atomique créée, identifie les notes existantes du vault qui devraient maintenant **pointer vers elle** (notamment `[[La méthode CODE]]`, `[[Qu'est-ce qu'un second brain]]`, ou les MOC des dossiers concernés). Étends ces notes existantes pour qu'elles mentionnent les nouvelles ressources.

## Phase 6 — Sauvegarde mémoire

Identifie les **convictions** et **intentions concrètes** validées par l'utilisateur pendant la curation et sauve-les en mémoire dédiée (type `user` pour les positions, `project` pour les intentions). Cf. mémoires existantes : [[funnel-conference-qr]], [[interet-barad-dur]], [[position-open-source-pouvoir]], [[conviction-equipe-tous-lead-dev]].

## Format de progression

À chaque phase, **affiche un statut clair** (✅ phase X terminée, ⏳ phase Y en cours, ⏳ phases restantes). Cf. mémoire `prise-notes-conf` pour les conventions générales.
