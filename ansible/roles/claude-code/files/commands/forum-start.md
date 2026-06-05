---
description: Démarrer la prise de notes d'une journée de Forum ouvert / Open Space (pas de programme prédéfini).
argument-hint: <nom-evenement> [url-optionnelle]
---

L'utilisateur démarre une journée d'**Open Space / Forum ouvert** : pas de programme web à fetcher, les sujets sont construits le matin par les participants en marketplace.

Arguments : `$ARGUMENTS`

Le premier mot (ou la chaîne avant la première URL) est le **nom de l'événement** (par exemple `AlpesCraft 2026 — Forum ouvert`). Tu peux recevoir optionnellement une URL d'accueil de l'événement, à inclure en lien dans la note si présente.

## Ce que tu dois faire

1. **Récupère la date du jour** (frontmatter `cree`, `maj`, et nom du fichier).
2. **Crée la note brute** dans `Inbox/` :
   - Nom de fichier : `AAAA-MM-JJ - {Nom événement} (brut).md`
   - Frontmatter : `type: note`, `cree`, `maj`, `tags: [conference, {slug-de-l-événement}, open-space]`
   - Titre H1 : `# {Nom} — capture brute ({AAAA-MM-JJ})`
   - Blockquote d'intro qui **mentionne explicitement le format Open Space** (pas de programme prédéfini, sujets construits par les participants).
   - Section H2 `## Marketplace / Agenda du jour` avec un commentaire HTML qui rappelle de la remplir dès le matin (liste des sujets, créneaux, salles).
   - Section H2 `## En vrac` à la fin avec les conventions Open Space en commentaire HTML (loi des deux pieds, format conversation, etc.).
3. **Confirme** à l'utilisateur :
   - le chemin de la note,
   - qu'il peut utiliser `/session-add <sujet>` pour chaque session,
   - lui demande s'il veut **déjà saisir la marketplace** maintenant (et si oui, l'aider à la structurer).

## Convention

Template de référence : `Meta/Templates/Template — note brute d'open space.md`. Adapte-le aux infos de l'événement — ne plaque pas les `{{placeholders}}` bruts, remplis-les. Cf. mémoire `prise-notes-conf` pour le style général.

Si une URL est fournie, l'inclure en lien dans le blockquote d'intro (« Page d'accueil : … »).
