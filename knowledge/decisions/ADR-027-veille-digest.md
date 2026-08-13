# ADR-027 — Un digest de veille quotidien, et le token qui n'était pas nécessaire

**Date**: 2026-08-13
**Status**: accepted — implemented, pending first scheduled run

## Contexte

Miniflux tourne depuis aujourd'hui (ADR-026) avec **121 flux**. Ce nombre est
délibérément trop grand pour une lecture humaine : l'objectif n'a jamais été de lire,
mais de disposer d'une base assez large pour qu'une synthèse quotidienne ait de quoi
recouper. Marc a été explicite — « je ne compte pas lire tout ça, je voudrais créer une
tâche automatique pour qu'une IA le fasse à ma place ».

Ce sous-projet figure dans l'issue #15 depuis le 2026-07-19 et avait été délibérément
sorti du périmètre de la PR Miniflux (#86) pour ne pas mélanger deux sujets.

## Décision

Un timer systemd quotidien fait lire Miniflux par **Claude Code en mode `-p`**, écrit une
note dans le vault Obsidian, puis marque les entrées lues.

### Le token OAuth de la spéc n'était pas nécessaire

L'issue #15 prévoyait un token OAuth longue durée obtenu par `claude setup-token`,
valable environ un an et rangé dans le vault Ansible. C'était la pièce la plus fragile du
projet : un secret qui expire silencieusement une fois par an, sur un job que personne ne
regarde.

Mesure faite avant d'écrire la moindre ligne :

```
sudo -u claude /home/claude/.local/bin/claude -p "Réponds exactement: OK"
→ OK
```

`claude -p` fonctionne en non-interactif avec les **identifiants de session déjà présents**
dans `~claude/.claude`, ceux que le login claude.ai de Remote Control a déposés. Aucun
token supplémentaire, aucun secret à faire tourner. La spéc de #15 est corrigée sur ce
point.

### Le script écrit la note, pas le modèle

Claude reçoit les entrées sur l'entrée standard et n'émet que du markdown sur la sortie
standard. C'est le script shell qui compose le frontmatter et écrit le fichier.

Deux bénéfices, et le second est le vrai : le frontmatter est déterministe et conforme au
`CLAUDE.md` du vault, et **le job n'a besoin d'aucun outil d'écriture**. Un digest qui
écrirait lui-même dans le vault demanderait des permissions que la surface de ce job ne
justifie pas.

### Le prompt vit dans son propre fichier

`veille-digest-prompt.md.j2` est séparé du script parce que c'est la partie destinée à
être ajustée. Régler le ton d'une synthèse ne devrait pas obliger à relire du shell.

Le prompt encode la ligne éditoriale réelle, lue dans le vault : les cinq créneaux
hebdomadaires, et les règles du profil de voix qui comptent ici — viser la thèse et non
l'exemple, ne rien affirmer que Marc ne puisse assumer, préférer une mesure à une autorité
citée. Il impose surtout que **zéro angle de post est une réponse valable** : la plupart
des journées n'en produisent pas, et un digest qui en invente pour remplir devient du
bruit qu'on cesse de lire.

### Ce qui est plafonné est signalé

Le job envoie au plus 400 entrées par passage. Au-delà, les entrées **restent non lues**
pour le passage suivant, et le nombre reporté apparaît dans la note et dans le message
Kuma. Un digest tronqué en silence se lit exactement comme un digest exhaustif ; c'est le
pire des deux mondes.

### Trois gardes, dont deux nées d'incidents du jour

- **`TimeoutStartSec=900`.** Le 2026-08-13, six sessions `claude` abandonnées retenaient
  1,5 Go de RAM et 525 Mo de swap sur cet hôte, certaines depuis onze jours, et avaient
  saturé le swap. Elles étaient interactives, donc quelqu'un a fini par le voir. Un job
  déclenché par timer qui ne sortirait jamais ferait la même chose sans témoin.

  **La première version écrivait `RuntimeMaxSec`, que systemd ignore avec
  `Type=oneshot`** — un avertissement dans le journal, noyé entre les lignes de
  démarrage. Et comme `Type=oneshot` fixe `TimeoutStartSec` à l'infini par défaut, le
  garde le plus mis en avant de cet ADR ne bornait strictement rien tout en prétendant le
  contraire. Attrapé au premier passage manuel, par la lecture du journal. Un service
  oneshot est « en démarrage » toute sa vie : c'est le timeout de démarrage qui le borne.
- **La garde `/proc/mounts`.** Reprise telle quelle de `claude-remote-control.service`.
  Quand le montage rclone n'est pas là, le point de montage existe comme répertoire local
  vide : sans cette garde, la note serait écrite sur la carte SD au lieu de Nextcloud, et
  rien ne signalerait l'erreur. Même raison pour le `Wants=` souple plutôt qu'un
  `Requires=` — documentée par une panne de 54 h en juillet.
- **Dead-man's switch Kuma.** Un job quotidien qui cesse de tourner est invisible par
  construction.

### La note va dans `Domaines/`, pas dans `Inbox/`

Le `CLAUDE.md` du vault applique PARA et prévient que l'Inbox ne doit pas devenir un
débarras. Un dépôt automatique quotidien en ferait un en deux semaines. Une veille est une
responsabilité continue sans fin, donc `Domaines/Veille technologique/`, avec sa note de
présentation comme tous les dossiers du vault et des notes datées `AAAA-MM-JJ - veille.md`.

## Conséquences

- Miniflux devient **une base de données, pas une boîte de réception**. Les entrées sont
  marquées lues après synthèse : la note quotidienne est le seul point d'entrée, et les
  liens qu'elle contient sont le seul chemin vers les articles.
- Le job consomme l'abonnement Claude Code de Marc, pas une clé d'API facturée à l'usage.
- Deux étapes manuelles subsistent, toutes deux irréductibles : créer la clé d'API dans
  Miniflux (l'API ne sait pas se créer une clé) et le moniteur Kuma (v2 n'a pas
  d'automatisation supportée).
- Le prompt est un artefact vivant. S'il dérape, c'est lui qu'on reprend, pas la note.

## Liens

Issue #15 (sous-projet digest), ADR-026 (Miniflux), ADR-023 (Dozzle), ADR-011 (secrets sur
LUKS), ADR-016 (secrets hors environnement), `docs/05-services/claude-code.md`.
