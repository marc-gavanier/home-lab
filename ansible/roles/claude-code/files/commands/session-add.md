---
description: Ajouter une section pour une nouvelle session de Forum ouvert / Open Space dans la note brute en cours.
argument-hint: <sujet> [-- par X] [-- horaire HH:MM-HH:MM] [-- salle Y]
---

L'utilisateur passe à une nouvelle session d'Open Space. Tu ajoutes une section dans la note brute en cours.

Arguments : `$ARGUMENTS` — le **sujet** de la session, éventuellement suivi de précisions séparées par `--`.

## Ce que tu dois faire

1. **Identifie la note brute en cours** : la note la plus récemment modifiée dans `Inbox/` qui matche le pattern `AAAA-MM-JJ - * (brut).md` **et qui a `open-space` dans ses tags**. Si aucune n'existe pour aujourd'hui, signale-le et propose `/forum-start` d'abord.
2. **Parse `$ARGUMENTS`** :
   - Texte avant le premier `--` (s'il y en a) = **sujet**.
   - `-- par X` ou `-- by X` → **proposé par** = X.
   - `-- horaire HH:MM-HH:MM` ou `-- de HH:MM à HH:MM` → **horaire**.
   - `-- salle Y` ou `-- en Y` → **salle**.
   - Si aucun `--`, tout l'argument est le sujet, les autres champs restent vides.
3. **Ajoute la section H2** dans la note brute, insérée **juste avant la section `## En vrac`** :
   ```
   ## {Sujet}

   > **Sujet** : {sujet complet}.
   > **Proposé par** : {nom ou collectif, sinon « non précisé »}.
   > **Format** : {horaire et salle si fournis, sinon « non précisé »}.

   - 
   ```
4. **Confirme** que la section est prête et invite l'utilisateur à dicter.

## Conventions Open Space

- Format **conversation**, pas talk : notes plus discursives, parfois reprendre des **interventions par auteur** (« — X dit que… »).
- **Loi des deux pieds** : si l'utilisateur change de session en route, il rappellera `/session-add` — la session précédente reste capturée dans la note brute (rien à clore explicitement).
- Cf. mémoire `prise-notes-conf` pour le style général.
