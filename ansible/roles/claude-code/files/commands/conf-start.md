---
description: Démarrer la prise de notes d'une journée de conférence. Crée la note brute dans Inbox/ à partir du template.
argument-hint: <nom-conf> <url-programme>
---

L'utilisateur démarre une journée de conférence et veut que tu crées la **note brute** qui servira de tampon pour la capture en direct.

Arguments reçus : `$ARGUMENTS`

Le premier mot est le **nom court de la conférence** (par exemple `AlpesCraft` ou `DevoxxFR`). Le reste est l'**URL du programme** de la conférence.

## Ce que tu dois faire

1. **Récupère la date du jour** (frontmatter `cree` et `maj`, et nom du fichier).
2. **Fetch l'URL du programme** pour avoir le contexte général de la conférence (nom complet, lieu, dates, éventuellement liste des sessions).
3. **Crée la note brute** dans `Inbox/` :
   - Nom de fichier : `AAAA-MM-JJ - {Nom conf} (brut).md`
   - Frontmatter : `type: note`, `cree`, `maj`, `tags: [conference, {slug-kebab-case-de-la-conf}]`
   - Titre H1 : `# {Nom conf} {année} — capture brute ({AAAA-MM-JJ})`
   - Blockquote d'introduction avec : note tampon, capture en vrac, lien vers le programme
   - Section H2 vide `## En vrac` à la fin (pour les notes inclassables)
4. **Applique les conventions** de la mémoire `prise-notes-conf` (puces, mots-clés en gras, notes perso en italique).
5. **Confirme** à l'utilisateur la création de la note avec son chemin, et **demande à quel talk il assiste en premier** (lui rappeler qu'il peut utiliser `/talk-add <url>` pour ajouter chaque section).

## Convention

Le template de référence est `Meta/Templates/Template — note brute de conférence.md`. Adapte-le aux infos récupérées via le fetch — ne plaque pas les `{{placeholders}}` brut, remplis-les vraiment.

Si l'URL ne charge pas ou si tu ne trouves pas d'infos exploitables, signale-le et crée la note avec ce que tu as (au minimum le nom de la conf et la date).
