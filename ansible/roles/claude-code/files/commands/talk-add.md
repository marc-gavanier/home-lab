---
description: Ajouter une section pour un nouveau talk dans la note brute de conférence en cours.
argument-hint: <url-du-talk>
---

L'utilisateur est en conférence et passe à un nouveau talk. Il te donne l'URL de la page programme du talk. Tu dois ajouter une section dans la note brute en cours.

URL du talk : `$ARGUMENTS`

## Ce que tu dois faire

1. **Identifie la note brute en cours**. C'est la note la plus récemment modifiée dans `Inbox/` qui matche le pattern `AAAA-MM-JJ - * (brut).md`. Si plusieurs sont datées d'aujourd'hui, prends la plus récente. Si aucune n'existe pour aujourd'hui, signale-le à l'utilisateur et propose `/conf-start` d'abord.
2. **Fetch l'URL du talk** pour extraire : titre exact, speaker(s), format (durée, salle si indiqué), abstract complet, thèmes/sujets abordés.
3. **Ajoute une section H2 dans la note brute**, insérée **juste avant la section `## En vrac`** :
   ```
   ## {Titre court ou sujet} ({Speaker})

   > **Titre complet** : {Titre exact du talk}
   > **Speaker** : {Prénom Nom} — {détail si pertinent}.
   > **Format** : {format, horaire, salle}.
   > **Abstract** : {abstract — recopier l'abstract officiel, en respectant le ton}.
   > **Source** : [Programme — {slug}]({URL du talk})

   - 
   ```
4. **La puce vide** signale que la capture va commencer. Confirme à l'utilisateur que la section est prête et invite-le à dicter.

## Conventions

- Préfère systématiquement les **Prénom + Nom** complets (pas seulement le nom) dans les références.
- Si l'abstract est en anglais, garde-le en anglais (ne pas traduire).
- Si l'URL ne charge pas, signale-le et crée la section avec ce que l'utilisateur connaît du talk.
- Cf. mémoire `prise-notes-conf` pour le style.
