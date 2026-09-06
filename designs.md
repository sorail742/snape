# Designs premium pour Serpents & Échelles Party

Ce fichier liste **8 pistes de design premium**, inspirées de styles et de tendances réels observés dans le monde entier (Inde, Maroc, Scandinavie, Japon, Mexique, industrie du jeu mobile grand public, néon/cyberpunk, papier artisanal). Pour chaque piste, tu trouves :

- **D'où ça vient** : le style/la tradition/la tendance réelle qui inspire ce design, avec des liens vers des galeries où en voir des exemples.
- **Palette de couleurs** : des couleurs prêtes à copier-coller dans le code (fichier [`lib/models/board_theme.dart`](lib/models/board_theme.dart)), pour créer un nouveau thème de plateau.
- **Le prompt détaillé** : un texte long, écrit simplement, qui décrit exactement à quoi le design doit ressembler. Il est utilisable de 3 façons :
  1. Le donner tel quel à un·e designer graphique (humain).
  2. Le coller dans un générateur d'images IA (Midjourney, DALL·E, Stable Diffusion...) pour obtenir des visuels d'inspiration.
  3. Le donner à un développeur (ou à moi) comme cahier des charges pour coder un nouveau `BoardTheme` + ajuster `board_painter.dart` et `dice_widget.dart`.

> **Note honnête** : les liens Dribbble/Behance ci-dessous sont des points de départ pour *regarder* le style de la catégorie (beaucoup de designers publient dans ces styles) — ce ne sont pas des captures que j'ai inspectées pixel par pixel. Les prompts qui suivent sont des créations originales, écrites pour ce projet précis, en s'appuyant sur les codes visuels documentés de chaque style.

---

## Sommaire

**Partie 1 — Univers visuels (thèmes de plateau)**

1. [Inde royale — l'ancêtre du jeu (Gyan Chaupar)](#1-inde-royale--lancêtre-du-jeu-gyan-chaupar)
2. [Maroc — mosaïque Zellige](#2-maroc--mosaïque-zellige)
3. [Scandinavie — minimalisme pastel](#3-scandinavie--minimalisme-pastel)
4. [Japon — kawaii pastel](#4-japon--kawaii-pastel)
5. [Mexique — fiesta papel picado](#5-mexique--fiesta-papel-picado)
6. [Studio mobile premium (style King / Voodoo / Supercell)](#6-studio-mobile-premium-style-king--voodoo--supercell)
7. [Néon futuriste haut de gamme](#7-néon-futuriste-haut-de-gamme)
8. [Papier artisanal premium (version haut de gamme du thème actuel)](#8-papier-artisanal-premium-version-haut-de-gamme-du-thème-actuel)

**Partie 2 — Système d'interface moderne (comment tout doit se comporter, pour rivaliser avec le monde moderne)**

9. [Onboarding : comment l'animer pour attirer plus d'utilisateurs](#9-onboarding--comment-lanimer-pour-attirer-plus-dutilisateurs)
10. [Deux boutons ou plus sur un écran : comment bien les organiser](#10-deux-boutons-ou-plus-sur-un-écran--comment-bien-les-organiser)
11. [Style des boutons](#11-style-des-boutons)
12. [Style des cartes (cards)](#12-style-des-cartes-cards)
13. [Style des icônes](#13-style-des-icônes)
14. [Le dé : comment le rendre vraiment "cube" en 3D](#14-le-dé--comment-le-rendre-vraiment-cube-en-3d)
15. [Grille d'espacement : pour que tout se ressemble](#15-grille-despacement--pour-que-tout-se-ressemble)
16. [Application écran par écran](#16-application-écran-par-écran)

**Partie 3 — Mise en œuvre**

17. [Comment utiliser ce fichier dans le code](#17-comment-utiliser-ce-fichier-dans-le-code)
18. [Sources consultées](#sources-consultées)

---

## 1. Inde royale — l'ancêtre du jeu (Gyan Chaupar)

**D'où ça vient** : Serpents & Échelles vient d'un vrai jeu indien très ancien, le *Gyan Chaupar* (aussi appelé *Moksha Patam*), un "jeu de la connaissance" utilisé pour enseigner des leçons spirituelles. Les plateaux d'époque étaient peints à la main sur tissu ou papier, avec des couleurs riches (safran, rouge, or, bleu paon), des bordures décoratives et des motifs inspirés des miniatures indiennes. Certains plateaux historiques sont conservés dans des musées (par ex. le Victoria & Albert Museum) et ont même la forme d'un fort.
Sources : [Sahapedia — Gyan Chaupar](http://www.sahapedia.org/gyan-chaupar-game-became-snakes-and-ladders-british-india), [The Print — l'ancêtre spirituel du jeu](https://theprint.in/pageturner/excerpt/gyan-chaupar-the-spiritual-ancestor-of-snakes-and-ladders/2159905/), [Asia Research News](https://www.asiaresearchnews.com/content/gyan-chaupar%E2%80%94-ancient-board-game-inspired-snakes-and-ladders-0), [V&A Museum — plateau ancien](https://collections.vam.ac.uk/item/O26005).

**Palette de couleurs** (à utiliser dans `BoardTheme`) :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Ivoire chaud | `#FBF0DA` |
| `paperColor` | Parchemin doré | `#F6E3B4` |
| `woodTone` | Bois de rose foncé | `#5A2E1D` |
| `lightCell` / `darkCell` | Ivoire crème | `#FDF6E3` |
| `gridLine` | Brun encre | `#4A2C1A` |
| `finishCell` | Or | `#E6B325` |
| `bonusText` | Vert paon | `#0B6E4F` |
| `malusText` | Rouge grenat | `#A6192E` |
| `ladderRail` / `ladderRung` | Or antique | `#C9942B` / `#8C5E15` |
| `snakeBody` | Bleu paon | `#0F7173` |
| `snakeOutline` | Bleu nuit | `#0A3D3F` |
| `snakeHead` | Turquoise | `#17A398` |
| `accent` | Safran | `#F2913D` |
| `accentDark` | Terracotta brûlée | `#B85C1E` |

**Le prompt détaillé (à copier-coller) :**

> Dessine un plateau de jeu de serpents et échelles qui ressemble à une peinture miniature indienne du XVIIIe siècle, peinte à la main sur un tissu ancien couleur ivoire/parchemin. Chaque case est bordée d'un fin trait à l'encre brune, un peu irrégulier comme un vrai coup de pinceau, jamais parfaitement droit. Le fond du plateau est un jaune doré chaud avec de très légères taches et un aspect "vieux papier" (petites variations de texture, pas de blanc pur). Autour du plateau entier, ajoute une bordure décorative façon frise indienne : petites fleurs de lotus stylisées et motifs géométriques répétés, en fils d'or et rouge grenat. Les échelles ne sont pas en bois simple : ce sont des échelles dorées ornées, avec des barreaux qui ressemblent à des bracelets ou des colonnes finement gravées. Les serpents sont peints comme de vrais cobras stylisés à l'indienne : corps bleu paon avec des écailles en forme de petits croissants dorés, tête triangulaire avec un capuchon élargi (comme un cobra royal), yeux dorés, langue rouge fourchue qui dépasse légèrement. La case d'arrivée (FINISH) est décorée comme un temple miniature doré, avec un petit dôme et un motif de lotus en dessous. Les cases bonus sont marquées d'un petit paon stylisé vert émeraude, les cases malus d'un petit scorpion rouge grenat. Le dé du jeu devrait ressembler à un petit cube d'ivoire sculpté avec des points peints à la main en rouge et or, posé sur un coussin de velours bordeaux avec un pompon doré. Les pions des joueurs sont de petites figurines façon miniature moghole : un éléphant, un paon, un tigre, un cheval, chacun peint avec des couleurs vives et des motifs dorés. L'ambiance générale doit évoquer un objet précieux, presque un bijou de musée, chaud et doré, jamais froid ni numérique — de la lumière tamisée de bougie, pas de néon.

**Version courte pour IA générative** : `ornate Indian miniature painting style board game, Gyan Chaupar Moksha Patam aesthetic, gold leaf borders, peacock blue cobra snakes with hooded heads, golden ornate ladders, ivory parchment background, saffron and garnet color palette, hand-painted texture, museum artifact quality, warm candlelight mood, intricate lotus flower border pattern, highly detailed, royal Mughal miniature art style`

---

## 2. Maroc — mosaïque Zellige

**D'où ça vient** : le *zellige* est l'art marocain de la mosaïque géométrique — des petits carreaux de céramique taillés à la main et assemblés en étoiles et polygones qui s'étendent à l'infini à partir d'un motif central. C'est un artisanat toujours vivant aujourd'hui, très présent dans les riads, les fontaines et l'architecture marocaine.
Sources : [Wikipedia — Zellij](https://en.wikipedia.org/wiki/Zellij), [Zouaq — générateur de motifs marocains](https://zouaq.floot.app/).

**Palette de couleurs** :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Sable clair | `#F1E4CF` |
| `paperColor` | Blanc craie | `#FAF6EF` |
| `woodTone` | Cèdre foncé | `#4B3222` |
| `lightCell` | Blanc cassé | `#FCFAF4` |
| `darkCell` | Bleu Majorelle clair | `#E3ECF7` |
| `gridLine` | Bleu nuit marocain | `#1B3A5C` |
| `finishCell` | Jaune moutarde | `#E0A93A` |
| `bonusText` | Vert menthe | `#1E8A6E` |
| `malusText` | Rouge brique | `#C1440E` |
| `ladderRail` / `ladderRung` | Cuivre / cuivre foncé | `#B5713B` / `#7A4A22` |
| `snakeBody` | Bleu Majorelle | `#2C5F9C` |
| `snakeOutline` | Bleu nuit | `#122A44` |
| `snakeHead` | Turquoise zellige | `#2E9E9E` |
| `accent` | Terracotta | `#D2691E` |
| `accentDark` | Terracotta brûlée | `#9C4A14` |

**Le prompt détaillé (à copier-coller) :**

> Crée un plateau de jeu où chaque case ressemble à un carreau de zellige marocain individuel : des petites mosaïques géométriques avec des étoiles à 8 branches, entrelacées de lignes bleu Majorelle, blanc et terracotta. Le contour de chaque case est fait de petits carreaux carrés et triangulaires assemblés, comme un vrai mur de riad marocain, avec de fines lignes de joint gris clair entre chaque carreau. Le fond général du plateau est un sable chaud avec une texture de tadelakt (enduit marocain lissé à la main, légèrement brillant). Les échelles sont remplacées visuellement par des escaliers de fontaine marocaine en zellige bleu et blanc, avec de petits filets d'eau stylisés qui coulent entre les marches. Les serpents ont un corps couvert d'un motif de mosaïque en écailles hexagonales bleu et turquoise, la tête ornée d'un petit motif floral doré entre les yeux, comme un bijou berbère. La case d'arrivée est dessinée comme une porte de riad (arche en fer à cheval) entourée de zellige doré et bleu. Les cases bonus portent un petit motif d'étoile à 8 branches dorée, les cases malus un petit motif de croissant rouge brique. Le dé ressemble à un petit coffret en bois de cèdre sculpté avec des incrustations de nacre pour les points. Les pions des joueurs sont des petites lanternes marocaines colorées (rouge, bleu, vert, jaune) avec des découpes géométriques qui laissent passer la lumière. L'ambiance générale est chaude, ensoleillée, avec des ombres nettes comme en plein soleil marocain, des couleurs saturées mais jamais criardes, une sensation d'artisanat précieux fait main.

**Version courte pour IA générative** : `Moroccan zellige mosaic board game design, geometric star tile patterns, Majorelle blue and terracotta palette, tadelakt plaster texture, horseshoe arch finish tile, mosaic-scaled snakes, riad fountain style ladders, warm sunlit shadows, handcrafted artisan tilework, highly detailed geometric pattern`

---

## 3. Scandinavie — minimalisme pastel

**D'où ça vient** : le design scandinave (Suède, Danemark, Norvège, Finlande) est connu pour ses lignes épurées, ses couleurs douces et sa fonctionnalité avant tout — "moins mais mieux". C'est le style qu'on retrouve dans le mobilier IKEA haut de gamme ou les jeux de société nordiques modernes.
Sources : [Wikipedia — Scandinavian design](https://en.wikipedia.org/wiki/Scandinavian_design), [Finnish Design Shop — jeux](https://www.finnishdesignshop.com/en-us/lifestyle-housekeeping/games), [UX Collective — minimalisme dans les jeux](https://uxdesign.cc/board-game-ux-minimalist-design-ab812ee5412d).

**Palette de couleurs** :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Blanc cassé nordique | `#F7F5F2` |
| `paperColor` | Blanc | `#FFFFFF` |
| `woodTone` | Bois de hêtre clair | `#D8C6A8` |
| `lightCell` | Blanc | `#FFFFFF` |
| `darkCell` | Gris très clair | `#EDEBE7` |
| `gridLine` | Gris anthracite doux | `#3A3A3A` |
| `finishCell` | Jaune moutarde doux | `#EAC54F` |
| `bonusText` | Vert sauge | `#7BA88A` |
| `malusText` | Terracotta doux | `#D98871` |
| `ladderRail` / `ladderRung` | Bois clair / bois moyen | `#C9A876` / `#A9825A` |
| `snakeBody` | Bleu poudré | `#8FB4C9` |
| `snakeOutline` | Bleu ardoise | `#3E5C6B` |
| `snakeHead` | Bleu poudré foncé | `#6E9DB5` |
| `accent` | Corail doux | `#E58C6C` |
| `accentDark` | Terracotta | `#B85C40` |

**Le prompt détaillé (à copier-coller) :**

> Dessine un plateau de jeu ultra épuré, dans l'esprit du design scandinave : des formes géométriques simples, beaucoup d'espace blanc/crème, aucune décoration superflue. Chaque case est un carré aux coins légèrement arrondis, avec un contour fin gris anthracite et un intérieur blanc ou gris très pâle en alternance (comme un damier discret). Pas de texture de papier froissé, pas d'ombres dramatiques : tout est plat, propre, avec juste une très légère ombre portée douce sous chaque case pour donner un peu de profondeur (style "flat design" moderne). Les échelles sont dessinées comme du mobilier en bois clair scandinave (bois de hêtre), avec des lignes très droites et simples, sans ornement. Les serpents sont stylisés de façon très minimaliste : une simple courbe épaisse bleu poudré avec des extrémités arrondies, presque abstraite, avec juste deux petits points blancs pour les yeux — pas d'écailles détaillées, pas de réalisme, juste une forme élégante et reconnaissable. La case d'arrivée est marquée d'un simple drapeau triangulaire jaune moutarde sur un mât fin. Les cases bonus/malus sont indiquées par un simple petit rond de couleur (vert sauge ou terracotta) avec un chiffre à l'intérieur, sans icône compliquée. Le dé est un cube blanc mat aux coins arrondis avec des points gris anthracite, sans brillance ni reflet exagéré — sobre comme un objet de designer. Les pions des joueurs sont de simples formes géométriques colorées (un rond, un triangle, un carré, un hexagone) dans des couleurs pastel douces, chacun avec un petit visage minimaliste optionnel (deux points et un trait). L'ambiance générale doit être calme, aérée, lumineuse, reposante — l'opposé d'un jeu criard, plutôt un objet qu'on a envie de garder posé sur la table basse du salon.

**Version courte pour IA générative** : `Scandinavian minimalist board game design, flat clean geometric shapes, soft pastel palette, light beech wood accents, abstract simplified snake shapes, muted sage green and terracotta, generous white space, subtle soft shadows, Nordic hygge aesthetic, clean sans-serif typography feel`

---

## 4. Japon — kawaii pastel

**D'où ça vient** : le style "kawaii" (mignon) japonais utilise des couleurs pastel douces, des formes arrondies et des expressions attendrissantes. On le retrouve énormément dans les jeux mobiles japonais et dans des interfaces de jeux occasionnels très soignées.
Sources : [Wikipedia — Kawaii](https://en.wikipedia.org/wiki/Kawaii), [Dribbble — Kawaii UI](https://dribbble.com/tags/kawaii-ui), [Dribbble — Cute UI](https://dribbble.com/tags/cute-ui).

**Palette de couleurs** :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Rose très pâle | `#FDEFF3` |
| `paperColor` | Blanc crème | `#FFFBFC` |
| `woodTone` | Lavande pâle | `#E4D6EE` |
| `lightCell` | Blanc rosé | `#FFF6F8` |
| `darkCell` | Rose bonbon très clair | `#FCE4EC` |
| `gridLine` | Prune doux | `#6B4A5A` |
| `finishCell` | Jaune pastel | `#FFE59A` |
| `bonusText` | Menthe pastel | `#7ED9C3` |
| `malusText` | Corail pastel | `#FF9AA2` |
| `ladderRail` / `ladderRung` | Lilas / lilas foncé | `#C9A8E0` / `#9B6FC4` |
| `snakeBody` | Vert pastel | `#B5E8C9` |
| `snakeOutline` | Vert forêt doux | `#5FA789` |
| `snakeHead` | Vert menthe | `#8FE0B8` |
| `accent` | Rose bonbon | `#FF8FAB` |
| `accentDark` | Rose fuchsia doux | `#E85D8A` |

**Le prompt détaillé (à copier-coller) :**

> Crée un plateau de jeu tout doux et mignon façon "kawaii" japonais. Le fond est rose très pâle, presque blanc, avec de tout petits motifs discrets d'étoiles et de cœurs semés dessus. Chaque case est un carré aux coins très arrondis (presque un rond), avec un contour épais couleur prune douce, comme dessiné au feutre à pointe ronde. Les cases alternent entre blanc rosé et rose bonbon très clair. Les échelles ne sont pas des échelles classiques : ce sont des arcs-en-ciel pastel (lilas, rose, jaune, menthe) sur lesquels on grimpe, avec des petits nuages ronds et souriants aux extrémités. Les serpents sont adorables plutôt qu'effrayants : un corps vert pastel tout rond et bouclé comme un ressort, avec de grands yeux ronds brillants (un point noir dans un grand cercle blanc), des joues roses rondes, et un petit sourire timide au lieu d'une langue fourchue — on doit avoir envie de le câliner, pas peur de lui. La case d'arrivée (FINISH) est décorée d'un petit cadeau enrubanné et de confettis en forme d'étoiles. Les cases bonus affichent un petit smiley content jaune pastel avec un "+", les cases malus un petit smiley qui pleure une larme bleue avec un "-". Le dé est un gros cube tout doux façon peluche/oreiller, rose pastel avec des points blancs à bords arrondis, presque en 3D "squishy" (qui donne envie d'être pressé). Les pions des joueurs sont de petits animaux ronds et mignons façon mascotte : un chaton, un lapin, un ourson, un chiot, chacun avec de grands yeux brillants et des couleurs pastel différentes. L'ambiance générale doit être douce, joyeuse, un peu "bonbon", avec de légères animations qui rebondissent (comme de la gélatine) plutôt que des mouvements rigides.

**Version courte pour IA générative** : `kawaii cute board game design, soft pastel pink and mint palette, rounded chibi shapes, adorable smiling snake character with big sparkly eyes, rainbow cloud ladders, squishy plush-style dice, cute animal mascot player tokens, Japanese kawaii aesthetic, soft bouncy jelly feel, sanrio-inspired`

---

## 5. Mexique — fiesta papel picado

**D'où ça vient** : le *papel picado* est l'art mexicain du papier découpé en dentelle colorée, utilisé lors des fêtes (Jour des Morts, fiestas). Associé aux couleurs vives du Mexique (rose mexicain, orange marigold, turquoise), il donne une ambiance festive et chaleureuse.

**Palette de couleurs** :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Turquoise profond | `#0E7C86` |
| `paperColor` | Blanc papier | `#FFFDF5` |
| `woodTone` | Bois brun chaud | `#7A4A2B` |
| `lightCell` | Crème | `#FFF7E8` |
| `darkCell` | Jaune marigold clair | `#FDECC8` |
| `gridLine` | Violet foncé | `#4A1E5C` |
| `finishCell` | Rose mexicain | `#E91E8C` |
| `bonusText` | Vert perroquet | `#2E9E4E` |
| `malusText` | Rouge piment | `#D62828` |
| `ladderRail` / `ladderRung` | Orange marigold / orange brûlé | `#F4900C` / `#C15E0A` |
| `snakeBody` | Vert perroquet | `#2FAE60` |
| `snakeOutline` | Violet foncé | `#3B1550` |
| `snakeHead` | Jaune soleil | `#FFC93C` |
| `accent` | Rose mexicain | `#E91E8C` |
| `accentDark` | Magenta foncé | `#A3126A` |

**Le prompt détaillé (à copier-coller) :**

> Dessine un plateau de jeu qui ressemble à une fiesta mexicaine haute en couleur. Le fond général est turquoise vif, et au-dessus du plateau flottent de petites guirlandes de papel picado (papier découpé en dentelle colorée : rose, orange, jaune, vert) suspendues comme des fanions de fête. Chaque case du plateau est bordée d'un trait épais violet foncé, avec un intérieur crème/jaune pâle décoré d'un tout petit motif floral peint à la main dans un coin (fleur de souci/marigold). Les échelles sont peintes comme des guirlandes de fleurs marigold orange vif, tressées en forme d'échelle, avec des pétales qui débordent légèrement sur les côtés. Les serpents sont colorés et festifs plutôt que menaçants : corps vert perroquet avec des motifs géométriques aztèques peints dessus en jaune et rouge, tête ornée d'une petite crête de plumes colorées façon quetzal, grands yeux expressifs. La case d'arrivée est décorée comme un autel de fête avec des fleurs de souci en cercle et des petits drapeaux colorés qui rayonnent autour. Les cases bonus sont marquées d'un petit piment rouge souriant, les cases malus d'un petit cactus qui pique. Le dé est un cube en bois peint à la main façon artisanat mexicain (alebrije), avec des motifs floraux colorés peints sur chaque face autour des points. Les pions des joueurs sont de petites figurines "alebrijes" (créatures fantastiques mexicaines peintes de couleurs vives et de motifs géométriques) : un jaguar bleu à pois, un dragon rose à rayures, un oiseau orange à motifs, un lézard vert à spirales. L'ambiance générale doit être chaleureuse, festive, vibrante, comme un marché coloré en plein soleil, avec des couleurs saturées qui se marient bien ensemble sans être criardes.

**Version courte pour IA générative** : `Mexican fiesta board game design, vibrant papel picado paper-cut banners, turquoise and marigold orange palette, alebrije folk art style snake with feathered crest, marigold flower garland ladders, hand-painted wooden dice, colorful alebrije animal player tokens, festive warm saturated colors, Day of the Dead inspired ornamentation`

---

## 6. Studio mobile premium (style King / Voodoo / Supercell)

**D'où ça vient** : c'est le niveau de finition des plus grands jeux mobiles gratuits du monde (Candy Crush de King, les hyper-casual de Voodoo, Clash Royale de Supercell). Leur signature : des interfaces "juteuses" (gros boutons rebondissants, brillance en dégradé, ombres portées marquées), des animations très réactives, et des couleurs bonbon très saturées qui donnent envie de toucher l'écran.
Sources : [Candy Crush Saga UI (Dribbble)](https://dribbble.com/shots/21285246-Candy-Crush-Game-UI), [Game UI Database — Candy Crush](https://www.gameuidatabase.com/gameData.php?id=147), [Pixune — meilleurs exemples d'UI de jeux mobiles 2026](https://pixune.com/blog/best-examples-mobile-game-ui-design/), [Tubik Studio — tendances UI 2026](https://tubikstudio.com/blog/ui-design-trends-2026/).

**Palette de couleurs** :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Violet-bleu dégradé (base) | `#4A3FB5` |
| `paperColor` | Blanc pur | `#FFFFFF` |
| `woodTone` | Violet foncé | `#2A2166` |
| `lightCell` | Blanc | `#FFFFFF` |
| `darkCell` | Lavande très clair | `#EDEBFF` |
| `gridLine` | Violet foncé | `#3D2E7C` |
| `finishCell` | Jaune bonbon | `#FFD23F` |
| `bonusText` | Vert bonbon | `#2ECC71` |
| `malusText` | Rouge bonbon | `#FF4757` |
| `ladderRail` / `ladderRung` | Bleu ciel bonbon / bleu franc | `#4FC3F7` / `#1E88E5` |
| `snakeBody` | Rose bonbon | `#FF6FA5` |
| `snakeOutline` | Magenta foncé | `#C2185B` |
| `snakeHead` | Rose vif | `#FF3D82` |
| `accent` | Orange bonbon | `#FF8A00` |
| `accentDark` | Orange brûlé | `#E65100` |

**Le prompt détaillé (à copier-coller) :**

> Dessine un plateau de jeu avec le niveau de finition d'un très grand jeu mobile gratuit à succès (type Candy Crush ou Clash Royale). Chaque case est un bonbon-bouton en 3D avec un dégradé de couleur du clair (en haut) vers le foncé (en bas), un gros contour blanc épais tout autour, une ombre portée nette qui donne l'impression que la case "flotte" légèrement au-dessus du fond, et un petit reflet brillant en haut à gauche façon plastique glacé. Le fond du plateau est un dégradé violet-bleu profond avec de grosses formes floues et lumineuses en arrière-plan (comme des confettis de lumière hors-focus), pour donner de la profondeur sans distraire. Les échelles ressemblent à des tubes 3D bleu ciel très brillants avec des reflets blancs qui glissent dessus, des barreaux épais et arrondis façon bonbon. Les serpents sont stylisés comme un personnage de mascotte de jeu mobile : corps rose bonbon avec un dégradé brillant, des segments bien définis façon "ver gélifié", grands yeux cartoon expressifs avec des sourcils qui montrent une émotion claire (surprise, malice), une bouche ouverte avec une petite langue qui dépasse de façon amusante plutôt qu'effrayante. La case FINISH explose visuellement : un gros trophée doré en 3D avec des rayons de lumière dorés qui partent dans toutes les directions et des étincelles autour. Les cases bonus/malus sont de gros badges ronds brillants avec un "+" vert ou un "-" rouge en relief. Le dé est un cube 3D ultra brillant avec des faces qui semblent en verre poli, des points en relief façon perles, une ombre de contact nette au sol et un léger rebond "squash and stretch" (s'aplatit légèrement à l'impact) quand il atterrit. Les pions des joueurs sont des mascottes rondes et expressives avec de grands yeux, façon personnage de jeu mobile premium (pas des simples pions plats). Chaque élément interactif (le dé, les boutons) doit sembler "cliquable" instinctivement grâce au relief et à la brillance. L'ambiance générale : ultra polie, saturée, gratifiante visuellement, avec beaucoup de "jus" (particules, étincelles, rebonds) à chaque interaction.

**Version courte pour IA générative** : `premium mobile game UI, candy-glossy 3D board tiles with gradient and rim light, juicy bouncy design, vibrant saturated purple and pink palette, cartoon mascot snake character with expressive eyes, glossy 3D dice with squash-and-stretch, golden trophy finish tile with light rays, polished AAA free-to-play mobile game aesthetic, particle effects, satisfying tactile feel`

---

## 7. Néon futuriste haut de gamme

**D'où ça vient** : évolution premium du thème "Néon" déjà présent dans l'app (`BoardTheme.neon`), inspirée des interfaces de jeux cyberpunk haut de gamme et de l'esthétique synthwave (grilles lumineuses, dégradés violet/cyan, halos lumineux).

**Palette de couleurs** :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Noir bleuté profond | `#08060F` |
| `paperColor` | Bleu nuit translucide | `#12102A` |
| `woodTone` | Noir pur | `#020103` |
| `lightCell` | Bleu-violet sombre | `#1B1640` |
| `darkCell` | Bleu-violet plus sombre | `#140F30` |
| `gridLine` | Cyan électrique | `#00F5FF` |
| `finishCell` | Jaune néon | `#F9FF21` |
| `bonusText` | Vert néon | `#39FF14` |
| `malusText` | Rouge néon | `#FF073A` |
| `ladderRail` / `ladderRung` | Cyan / bleu électrique | `#00E5FF` / `#2979FF` |
| `snakeBody` | Magenta néon | `#FF00E5` |
| `snakeOutline` | Violet profond | `#5B0BB5` |
| `snakeHead` | Rose néon | `#FF4DD8` |
| `accent` | Violet électrique | `#9D00FF` |
| `accentDark` | Indigo profond | `#5B00B5` |

**Le prompt détaillé (à copier-coller) :**

> Dessine un plateau de jeu futuriste façon interface holographique de vaisseau spatial. Le fond est un dégradé noir bleuté avec une grille de lignes fines cyan qui s'étend à l'infini façon "synthwave", comme un sol digital dans un film de science-fiction. Chaque case du plateau est un panneau de verre sombre semi-transparent avec un contour lumineux cyan qui pulse doucement (léger effet de lueur/glow autour du trait, pas juste une ligne plate). L'intérieur des cases est bleu-violet très sombre, presque noir, pour que les couleurs néon ressortent fort par contraste. Les échelles sont des faisceaux de lumière cyan solides, comme des rampes lumineuses de piste d'atterrissage, avec des barreaux qui clignotent légèrement en séquence du bas vers le haut pour suggérer le mouvement. Les serpents sont des flux d'énergie magenta/rose néon : un corps qui ressemble à un ruban de lumière fluide plutôt qu'à un vrai serpent organique, avec une traînée lumineuse (comme une comète) derrière la tête quand il "glisse", et une tête simplifiée en forme de triangle lumineux avec deux points cyan pour les yeux. La case FINISH est un portail circulaire lumineux jaune néon avec des anneaux concentriques qui semblent tourner, façon téléportation. Les cases bonus/malus sont de simples hexagones lumineux vert néon (+) ou rouge néon (-) qui pulsent. Le dé n'est pas un cube physique classique mais un hologramme cyan filaire (wireframe) qui flotte légèrement au-dessus du plateau avec des particules de lumière qui s'en échappent quand il tourne. Les pions des joueurs sont des orbes lumineux de couleurs différentes (cyan, magenta, jaune, vert) avec un halo doux autour, façon "avatar énergie" plutôt que personnage figuratif. Toute la scène doit avoir une légère brume/bloom lumineux autour de chaque source de lumière (comme un vrai néon dans le noir), avec des reflets sur une surface qui semble légèrement humide/réfléchissante en dessous. L'ambiance générale est premium, immersive, un peu mystérieuse, comme l'interface d'un jeu de course futuriste haut de gamme.

**Version courte pour IA générative** : `futuristic neon holographic board game UI, dark synthwave grid background, glowing cyan tile outlines, glass panel tiles, magenta energy ribbon snake with light trail, cyan light-beam ladders, wireframe hologram dice with particle effects, glowing orb player tokens, bloom lighting, cyberpunk premium sci-fi aesthetic, ultra detailed glow effects`

---

## 8. Papier artisanal premium (version haut de gamme du thème actuel)

**D'où ça vient** : le thème "Classique" actuel du jeu ([`board_painter.dart`](lib/widgets/board_painter.dart)) dessine déjà un plateau "façon feuille de papier dessinée à la main" avec des bords légèrement irréguliers. Cette piste consiste à pousser ce même concept vers un rendu beaucoup plus premium/illustré, dans l'esprit des meilleures illustrations Dribbble/Behance pour jeux de plateau physiques haut de gamme (aquarelle, gouache, papier texturé).
Sources : [Dribbble — Snakes and Ladders Game UI](https://dribbble.com/shots/17238556-Snakes-and-Ladders-Game-UI), [Behance — Snake and Ladder Mobile UI Design](https://www.behance.net/gallery/161283855/Snake-and-Ladder-Mobile-UI-Design), [Behance — Snake and Ladder Game UI Design](https://www.behance.net/gallery/145261429/Snake-and-Ladder-Game-UI-Design).

**Palette de couleurs** :

| Rôle dans le code | Couleur | Code hexadécimal |
|---|---|---|
| `background` | Beige atelier | `#F0E6D6` |
| `paperColor` | Papier aquarelle | `#FBF6EC` |
| `woodTone` | Bois de noyer | `#6B4226` |
| `lightCell` | Papier clair | `#FDF9F0` |
| `darkCell` | Papier légèrement teinté | `#F3EBDA` |
| `gridLine` | Sépia foncé | `#3E2C1E` |
| `finishCell` | Or vieilli | `#E0AA4E` |
| `bonusText` | Vert forêt aquarelle | `#3F7D50` |
| `malusText` | Rouge brique aquarelle | `#B5482E` |
| `ladderRail` / `ladderRung` | Bois miel / bois foncé | `#B5824A` / `#7A5527` |
| `snakeBody` | Vert olive aquarelle | `#7A8B4A` |
| `snakeOutline` | Vert forêt foncé | `#3E4D26` |
| `snakeHead` | Vert mousse | `#8FA85E` |
| `accent` | Orange safran doux | `#E08E3D` |
| `accentDark` | Terracotta | `#A85A22` |

**Le prompt détaillé (à copier-coller) :**

> Dessine un plateau de jeu qui ressemble à une illustration à l'aquarelle et à l'encre, peinte à la main par un illustrateur professionnel pour un beau livre pour enfants haut de gamme. Le fond est une feuille de papier aquarelle texturée (grain visible, légères variations de teinte comme du vrai papier absorbant l'eau différemment par endroits), posée sur une table en bois de noyer visible tout autour avec un léger flou (profondeur de champ). Chaque case est peinte avec un contour à l'encre de Chine légèrement tremblant (jamais une ligne parfaitement droite ou nette, comme un vrai trait de plume), et l'intérieur est teinté d'une touche d'aquarelle très légère qui déborde délicatement au-delà du trait par endroits (effet de fuite d'aquarelle). Les échelles sont peintes comme du vrai bois avec des veines de grain visibles, des ombres portées douces sous chaque barreau, un rendu presque photoréaliste mais avec la texture picturale de l'aquarelle. Les serpents sont de vrais serpents illustrés avec un souci du détail naturaliste : écailles individuelles visibles peintes une par une avec de légères variations de teinte (vert olive qui va du clair au foncé), une texture de peau qui brille légèrement là où la lumière tape, une tête bien dessinée avec des yeux qui ont une vraie pupille et un reflet de lumière dedans, une langue fourchue fine et précise. La case FINISH est ornée d'un ruban doré peint qui flotte et d'une petite couronne de laurier illustrée à la main. Les cases bonus/malus ont un petit sceau à la cire (rouge pour malus, vert pour bonus) avec le chiffre gravé dedans, comme sur une vieille lettre. Le dé est un vrai cube en bois sculpté à la main avec des points incrustés en nacre, posé sur un petit coussin de velours avec des plis réalistes. Les pions des joueurs sont de petites figurines en bois peintes à la main, chacune avec un visage simple mais expressif et des habits de couleurs différentes peints à l'aquarelle. L'ambiance générale doit donner l'impression de tenir un objet précieux et intemporel — un jeu qu'on garderait toute sa vie —, chaleureux, artisanal, jamais froid ni généré par ordinateur.

**Version courte pour IA générative** : `premium watercolor and ink illustration board game, textured watercolor paper background, walnut wood table surface, hand-drawn trembling ink outlines with watercolor bleed, naturalistic detailed painted snake with visible scales, hand-carved wooden ladder with wood grain, wax seal bonus/malus markers, mother-of-pearl inlaid wooden dice, hand-painted wooden figurine player tokens, children's book illustration quality, warm heirloom object feel`

---

## 9. Onboarding : comment l'animer pour attirer plus d'utilisateurs

**Le constat (chiffres réels)** : la plupart des applications perdent 70 à 90 % de leurs nouveaux utilisateurs dès la toute première session, et le taux de retour au jour 1 tombe en moyenne à 25 %. Mais les apps qui ont un onboarding bien fait retiennent 20 % (contre 16 %) au jour 1, et un onboarding qui **personnalise** l'expérience dès le début augmente la rétention de **35 %**. Le facteur le plus déterminant : le temps avant la première "action qui a du sens" (rouler le dé, gagner une case) — s'il est inférieur à 30 secondes, les utilisateurs reviennent beaucoup plus au jour 30.
Sources : [UXCam — 12 apps avec un super onboarding](https://uxcam.com/blog/10-apps-with-great-user-onboarding/), [VWO — guide onboarding 2026](https://vwo.com/blog/mobile-app-onboarding-guide/), [UserGuiding — statistiques onboarding 2026](https://userguiding.com/blog/user-onboarding-statistics), [Eleken — bonnes pratiques onboarding](https://www.eleken.co/blog-posts/mobile-app-onboarding-best-practices).

**Ce que ça veut dire concrètement pour ce jeu :**

1. **Montrer, pas raconter.** L'onboarding actuel ([`onboarding_screen.dart`](lib/screens/onboarding_screen.dart)) affiche une icône statique dans un cercle (`Icon(s.icon, size: 76)`) à chaque étape. Une icône figée n'apprend rien : il faut une **mini-animation en boucle douce** qui montre le vrai geste — un dé qui rebondit vraiment pour l'étape 1, un pion qui grimpe une échelle et un autre qui glisse sur un serpent pour l'étape 2, une main qui secoue un téléphone pour une future étape "secouer pour lancer". Une boucle de 2-3 secondes, jamais saccadée, jamais trop rapide.
2. **Aller à l'action vraie le plus vite possible.** Au lieu de 3 écrans de texte suivis d'un bouton "Commencer à jouer" qui renvoie à un menu, la dernière étape pourrait proposer directement un **mini coup d'essai jouable** : un dé à toucher une fois, avec un pion qui avance sous les yeux de l'utilisateur, avant même d'arriver au menu principal. C'est la différence entre "lire qu'on peut jouer" et "avoir déjà joué" — et c'est ce qui fait la plus grande différence de rétention.
3. **Personnaliser tout de suite.** Demander le prénom (et éventuellement l'avatar) pendant l'onboarding plutôt qu'uniquement à l'écran de configuration de partie ([`setup_screen.dart`](lib/screens/setup_screen.dart)) — voir son propre prénom apparaître ensuite dans l'app ("Bienvenue Camille !") augmente l'attachement dès la première minute.
4. **Garder "Passer" visible mais discret** (déjà bien fait) — ne jamais bloquer l'accès rapide pour un utilisateur pressé.
5. **Animer les transitions avec du relief, pas juste un fondu.** La transition "trou qui s'agrandit en vague" (`_RippleHoleClipper`) déjà codée est un très bon effet, original et mémorable — à garder absolument. Pour aller plus loin : ajouter un **léger parallaxe** pendant le glissement du doigt lui-même (avant même le relâchement) — l'illustration au premier plan bouge un peu plus vite que le fond coloré, ce qui donne une sensation de profondeur physique. Ajouter aussi un petit **retour haptique** (`HapticFeedback.selectionClick()`) à chaque changement de page, exactement comme le reste de l'app le fait déjà pour le dé — la cohérence du toucher renforce la sensation de qualité.
6. **Faire "respirer" le bouton final.** Sur la dernière étape, le bouton "Commencer à jouer" doit avoir une **légère pulsation** (une échelle qui oscille doucement entre 1.0 et 1.03 toutes les 2 secondes, avec une ombre qui grandit et rétrécit en même temps) pour attirer l'œil sans être agaçant — jamais un clignotement brutal.
7. **Après l'onboarding, proposer en premier l'action la plus rapide à essayer.** Sur l'écran d'accueil, le premier choix visible reçoit statistiquement le plus de clics. Le "Défi du jour" (jouable seul, en un tap, sans configuration) est un meilleur candidat pour la première position que "Jouer en local" (qui demande de configurer plusieurs joueurs) si l'objectif est de maximiser le nombre de gens qui jouent une vraie partie dans leur première minute.

---

## 10. Deux boutons ou plus sur un écran : comment bien les organiser

**La règle d'or (Material Design 3)** : **un seul bouton "primaire" (le plus visible, rempli de couleur) par écran**, pour l'action la plus importante. Tout le reste doit être visuellement plus discret — bouton "tonal"/contouré pour une action secondaire qui compte quand même, bouton texte pour une action mineure ou d'annulation.
Sources : [Material 3 — un seul bouton primaire par écran](https://medium.com/@alikasem/one-screen-one-primary-button-material-3-button-hierarchy-in-angular-material-b8953ea58cad), [Cieden — créer la bonne hiérarchie de boutons](https://cieden.com/book/atoms/button/how-to-create-button-hierarchy).

**La règle du pouce (thumb zone)** : sur un téléphone tenu à une main, l'écran se divise en 3 zones — une **zone facile** en bas de l'écran (où le pouce arrive naturellement), une **zone d'étirement** au milieu, et une **zone difficile** tout en haut et dans les coins. Les actions fréquentes doivent être en bas ; les actions rares (une fois par session) peuvent rester en haut sans problème.
Sources : [Parachute Design — zone du pouce](https://parachutedesign.ca/blog/thumb-zone-ux/), [Tim Graf — concevoir pour la zone du pouce](https://timgraf.com/ux-design/designing-for-the-thumb-zone-a-modern-guide-to-mobile-ux-that-respects-human-anatomy/).

**Comment ça s'applique, exemple par exemple, dans ce projet :**

- **Le dé** ([`game_screen.dart`](lib/screens/game_screen.dart), `_buildTurnCard`) est l'action la plus répétée du jeu (des dizaines de fois par partie) : il est déjà bien placé en bas de l'écran. ✅ À garder.
- **Les icônes de l'AppBar** (journal, chat, pause) sont en haut, dans la zone difficile — c'est correct **parce que ce sont des actions rares** (une poignée de fois par partie) : la règle n'est pas "jamais rien en haut", c'est "les actions fréquentes doivent être en bas".
- **Le bouton "Commencer la partie"** ([`setup_screen.dart`](lib/screens/setup_screen.dart)) est tout en bas d'une longue page qui défile (choix des joueurs, thème, plateau...). Sur un écran long, ce bouton primaire peut sortir de vue après le scroll. Recommandation moderne : le transformer en **bouton flottant fixe en bas de l'écran** (qui reste toujours visible pendant le défilement), plutôt qu'en dernier élément d'une liste.
- **La boîte de dialogue de fin de partie** (`_showWinDialog`) a 3 boutons : "Partager" (texte), "Fermer" (texte), "Rejouer" (rempli/primaire). C'est déjà exactement la bonne hiérarchie Material 3 : un seul bouton rempli, à la position la plus engageante. ✅ Bon exemple à reproduire ailleurs.
- **Le menu pause** (`_openPauseMenu`) empile les actions verticalement en ordre de fréquence/sécurité décroissante : Reprendre (la plus sûre) en haut, puis Recommencer, puis Réglages, et enfin **Quitter la partie en rouge tout en bas**. C'est le bon réflexe : toujours mettre l'action destructive en dernier et la colorer différemment pour qu'un clic accidentel soit rare. ✅ Bon exemple, à copier pour tout futur menu à choix multiples.
- **Règle générale à appliquer partout** : dès qu'il y a plus de 2 actions sur un même écran (hors dialogue simple oui/non), les empiler **verticalement** plutôt qu'en ligne horizontale serrée — une rangée de 3-4 boutons horizontaux réduit chaque cible tactile sous la taille recommandée (48×48dp minimum), ce qui fait rater des clics.

---

## 11. Style des boutons

| Règle | Détail | État actuel du projet |
|---|---|---|
| **Coins arrondis** | Se limiter à 2-3 valeurs dans toute l'app : 12px pour les boutons, 16-18px pour les cartes, 20px pour les feuilles/dialogues plein écran | Le projet varie déjà entre 12, 14, 16, 18, 20px selon l'écran — à harmoniser sur ces 3 paliers uniquement |
| **États obligatoires** | Repos / pressé (léger enfoncement + assombrissement) / désactivé (opacité ~40%) / chargement (spinner à la place du texte) | L'état désactivé est déjà bien géré (`Opacity(opacity: canRoll ? 1 : 0.4)` sur le dé) — à généraliser à tous les boutons qui peuvent être indisponibles |
| **Zone tactile minimale** | 48×48dp même si le dessin visuel est plus petit (accessibilité, doigts épais, gants...) | Déjà conforme dans la plupart des cas grâce aux composants Flutter standards |
| **Contraste** | Au moins 3:1 pour le fond du bouton, 4.5:1 pour le texte (norme d'accessibilité WCAG reprise par Material 3) | Le thème "Daltonien" du projet va déjà dans ce sens — étendre cette rigueur à tous les thèmes |
| **Icône + texte** | L'icône toujours avant le texte (français = lecture de gauche à droite), sauf flèche "suivant" qui peut suivre le texte | Déjà respecté partout (`icon:` avant `label:` dans les `FilledButton.icon`) ✅ |
| **Transition d'état** | 150-200ms, toujours en "ease-out" (départ rapide, arrivée douce), jamais un changement instantané | Cohérent avec les animations déjà en place (durées de 150-450ms un peu partout) |
| **Retour haptique** | Un léger `HapticFeedback.selectionClick()` sur chaque bouton qui **démarre** ou **valide** quelque chose d'important | Déjà fait pour le dé — à étendre aux boutons "Commencer la partie", "Démarrer la partie", "Créer un salon", "Rejoindre" |

Source : [Material Design — boutons](https://medium.com/design-bootcamp/exploring-the-world-of-material-design-buttons-3d105e9d4396).

---

## 12. Style des cartes (cards)

Une carte (`Card`/`Container` avec bordure) est le composant que ce projet utilise le plus (accueil, configuration, campagne, statistiques...). Les études d'ergonomie montrent qu'une carte doit toujours suivre le même schéma de lecture pour être comprise instantanément : **icône à gauche → titre en gras → sous-titre gris → flèche ou action à droite**.
Sources : [UX Collective — 8 bonnes pratiques pour les cartes UI](https://uxdesign.cc/8-best-practices-for-ui-card-design-898f45bb60cc), [Eleken — exemples et bonnes pratiques de cartes](https://www.eleken.co/blog-posts/card-ui-examples-and-best-practices-for-product-owners).

- **Padding interne constant : 16px partout.** Le projet varie actuellement entre 10px (cartes joueurs de `setup_screen.dart`), 14px (`_ModeCard` de l'accueil) et 16-20px ailleurs → à harmoniser sur 16px partout pour que l'app entière respire au même rythme.
- **Un seul style de "profondeur" à la fois** : soit une **bordure fine** (outlined), soit une **ombre portée** (elevated), jamais les deux en même temps sur le même écran. Le projet utilise déjà majoritairement le style "contour fin + `elevation: 0`" (`_ModeCard` de l'accueil, cartes de la campagne) — **c'est le bon choix pour un jeu à l'ambiance chaleureuse et dessinée à la main**, à généraliser partout (certains écrans comme `stats_screen.dart` utilisent encore le `Card` Material par défaut avec une ombre — à uniformiser vers le style "contour" du reste de l'app).
- **Le schéma "icône + titre + sous-titre + chevron" de `_ModeCard`** (accueil) est le meilleur exemple du projet — il doit devenir **le gabarit unique** copié pour toute carte cliquable qui mène à un autre écran (campagne, mes plateaux, statistiques...), au lieu des variations actuelles.
- **Le badge d'icône** (petit cercle/carré coloré derrière l'icône) doit toujours utiliser la même intensité de couleur : le projet utilise tantôt 10%, tantôt 20% d'opacité selon l'écran → se fixer sur **12% d'opacité** comme référence unique.
- **Une carte cliquable doit toujours réagir visuellement au toucher** (`InkWell` — déjà fait ✅) et, si elle ouvre un autre écran, toujours afficher un petit chevron `>` à droite pour que ce soit évident avant même de cliquer.
- **Sur mobile, une seule colonne** (déjà respecté grâce aux `ConstrainedBox(maxWidth: 440-480)` sur chaque écran ✅) — ne jamais mettre deux cartes côte à côte sur un téléphone en portrait, ça réduit la lisibilité.

---

## 13. Style des icônes

- **Une seule famille d'icônes dans toute l'app.** Le projet utilise déjà uniquement la variante "arrondie" de Material Icons (suffixe `_rounded` : `Icons.casino_rounded`, `Icons.settings_rounded`...) — c'est déjà cohérent et donne un look doux qui correspond bien à un jeu familial. **Règle à ne jamais casser** : tout nouvel ajout d'icône doit utiliser le suffixe `_rounded`, jamais `_outlined` ou la version sans suffixe (plus anguleuse), sous peine de casser la cohérence visuelle.
Sources : [Guide de conception d'icônes — Tabler](https://tabler.io/icons/icon-design-guide), [Icônes — Material Design](https://www.mdui.org/en/design/1/style/icons.html).
- **Toujours dans un badge coloré**, jamais une icône seule flottant dans le vide, quand elle représente une action ou une catégorie importante (déjà bien fait dans `_ModeCard`, la carte "Mode Campagne", les succès de `stats_screen.dart`).
- **Toujours un `tooltip` sur les icônes seules sans texte** (déjà systématique sur les `IconButton` de l'AppBar — ✅ à garder comme réflexe pour toute nouvelle icône cliquable).
- **Couleur** : suivre la couleur d'accent du thème actif plutôt que des couleurs figées, sauf pour les couleurs "de mode" volontairement fixes (le bleu du Bluetooth, le vert de l'en-ligne, le violet de la campagne) qui aident à reconnaître un mode de jeu d'un coup d'œil — c'est un choix délibéré et cohérent du projet, à conserver.
- **Taille cohérente par contexte** : 18-20px dans un texte/chip, 24px dans une AppBar, 28-32px dans un badge de carte, jamais une taille "au hasard" — le projet respecte déjà globalement cette logique.

---

## 14. Le dé : comment le rendre vraiment "cube" en 3D

Le [`DiceWidget`](lib/widgets/dice_widget.dart) actuel simule déjà un dé en 3D avec de vraies techniques avancées (matrice de perspective `setEntry(3, 2, 0.0028)`, rotation sur 3 axes, rebond élastique à l'arrêt, ombre de contact qui rétrécit quand le dé "monte"). C'est du très bon travail. Voici comment le pousser au niveau des meilleures apps de dés 3D du marché :
Sources : [Dés 3D avec physique réelle (Unity)](https://funkyton.com/rolling-virtual-dice-with-physics/), [Dés 3D en HTML/CSS/JS — animation interactive](https://codetap.org/project/3d-dices).

- **Montrer plusieurs faces à la fois pendant le lancer.** Un vrai cube qui tourne montre toujours 2 ou 3 faces en même temps sur ses angles. Aujourd'hui le widget anime **une seule face plate** avec une matrice 3D (elle "bascule" mais ne révèle jamais ses voisines). Pour un rendu vraiment cubique : empiler les 6 faces comme les 6 côtés d'une vraie boîte (chaque face est un `Transform` positionné et tourné pour représenter le dessus/dessous/les 4 côtés d'un cube), afin qu'aux bons angles de rotation, on voie deux faces se croiser — exactement comme un dé en CSS 3D le fait sur le web.
- **Garder l'ombre de contact dynamique** (`trayScale` qui rétrécit quand le dé monte) — c'est déjà exactement ce que font les meilleures apps, à ne pas toucher. ✅
- **Garder le rebond élastique à l'arrêt** (`Curves.elasticOut`) — un vrai dé physique rebondit une ou deux fois avant de se stabiliser, l'effet actuel simule bien ça. ✅
- **Ajouter un chanfrein lumineux sur les arêtes** : les faces actuelles ont un dégradé radial (bien) mais un bord parfaitement plat. Ajouter une fine ligne blanche semi-transparente sur les 1-2 bords "hauts" (ceux tournés vers la lumière) donnerait l'impression d'un vrai biseau en plastique/résine plutôt qu'un carré plat avec un dégradé peint dessus.
- **Garder le son et la vibration à chaque "tick" de rotation**, pas seulement au résultat final — c'est déjà fait (`SoundService.instance.play(GameSound.diceTick)` + `HapticsService.instance.selectionClick()` à chaque frame de `rollDice()`), et c'est exactement ce qui distingue une app de dé premium d'une app basique. ✅ Ne jamais retirer ça, même en optimisant les performances.
- **Agrandir légèrement la zone tactile invisible autour du dé** (quelques pixels de marge en plus du visuel) pour que le clic ne rate jamais, même sur un petit écran ou avec un pouce imprécis.

---

## 15. Grille d'espacement : pour que tout se ressemble

Le projet utilise déjà, presque partout, des espacements par paliers de 4 (4, 8, 12, 16, 20, 24, 32...) — c'est la fameuse **grille 8pt**, LE standard de l'industrie (Material Design l'impose officiellement pour les marges et les espacements entre cartes : 8, 16, 24 ou 40dp).
Source : [Eleken — espacement et grille dans les cartes UI](https://www.eleken.co/blog-posts/card-ui-examples-and-best-practices-for-product-owners).

**Règle simple à appliquer partout, dans tous les futurs écrans** : n'utiliser **que** les valeurs 4, 8, 12, 16, 20, 24, 32, 40 pour n'importe quel espacement (`SizedBox`, `padding`, `margin`). Le projet contient encore quelques valeurs "hors grille" comme `10` (padding des cartes joueurs de `setup_screen.dart`) ou `14` (padding de `_ModeCard`) — à corriger en les arrondissant au palier le plus proche (10→8 ou 12, 14→16) pour que l'app entière ait un rythme visuel parfaitement régulier, ce qui est justement ce qui distingue un design "pro" d'un design "bricolé".

---

## 16. Application écran par écran

Pour chaque écran actuel de l'app, voici ce qu'il faut vérifier/améliorer pour rivaliser avec les standards du monde moderne (2026) :

### Onboarding ([`onboarding_screen.dart`](lib/screens/onboarding_screen.dart))
- Remplacer l'icône statique par une mini-animation en boucle (voir section 9).
- Ajouter un mini coup d'essai jouable en dernière étape plutôt qu'un simple bouton "Commencer à jouer".
- Ajouter un léger parallaxe pendant le swipe + un retour haptique à chaque changement de page.
- Faire pulser doucement le bouton final.

### Accueil ([`home_mode_screen.dart`](lib/screens/home_mode_screen.dart))
- L'entrée en cascade déjà en place (`_staggered`) est excellente — c'est exactement l'effet "reveal" recommandé pour un écran d'accueil moderne. ✅ À garder.
- Ici, 4 choix de mode égaux en importance : la règle "un seul primaire" (section 10) ne s'applique pas à un menu de choix — garder les 4 `_ModeCard` avec un poids visuel identique est le bon choix.
- Envisager de tester "Défi du jour" en première position (voir section 9, point 7) pour maximiser le nombre de premières parties jouées rapidement.
- Les icônes d'aide et de réglages en haut à droite sont dans la "zone difficile" du pouce, ce qui est acceptable car ce sont des actions rares — ✅ correct.

### Configuration partie locale ([`setup_screen.dart`](lib/screens/setup_screen.dart))
- Transformer "Commencer la partie" en bouton flottant fixe en bas de l'écran (voir section 10) pour qu'il reste toujours accessible pendant le défilement.
- Harmoniser le padding des cartes joueurs sur 16px (actuellement 10px).
- La carte "Mode Campagne" en haut de l'écran suit déjà le bon gabarit (icône + titre + sous-titre + chevron) — à copier pour "Mes plateaux".

### Lobby Bluetooth / Lobby en ligne ([`bluetooth_lobby_screen.dart`](lib/screens/bluetooth_lobby_screen.dart), [`online_lobby_screen.dart`](lib/screens/online_lobby_screen.dart))
- Le bouton primaire "Démarrer la partie" / "Créer un salon" est déjà bien un `FilledButton` unique, bien positionné en bas — ✅ bon exemple de hiérarchie à un seul primaire.
- La liste des joueurs qui rejoignent pourrait s'animer à l'arrivée (un léger "glissement + fondu" quand un nouveau joueur apparaît dans la liste) pour donner un sentiment de vie/temps réel plutôt qu'un simple re-rendu instantané.
- Le code du salon ([`online_lobby_screen.dart`](lib/screens/online_lobby_screen.dart)) est déjà mis en valeur visuellement (grand, encadré, copiable) — ✅ bon exemple, c'est l'élément le plus important de l'écran et il est traité comme tel.

### Écran de jeu ([`game_screen.dart`](lib/screens/game_screen.dart))
- Le dé reste l'action principale, bien placé en bas — ✅.
- Les icônes d'AppBar (journal, chat, pause) sont correctement en haut car rares — ✅.
- Le bandeau de connexion (reconnexion Bluetooth/Internet) est déjà bien traité comme une alerte prioritaire tout en haut, au-dessus même du plateau — ✅ bon réflexe, une alerte d'état doit toujours être la chose la plus visible.
- La carte de tour (`_buildTurnCard`) suit déjà bien le principe de hiérarchie (avatar qui pulse + texte + dé) — ✅.

### Campagne ([`campaign_screen.dart`](lib/screens/campaign_screen.dart))
- Chaque monde pourrait s'animer à l'ouverture avec un léger effet de cascade comme sur l'accueil (`_staggered`), pour donner la même sensation de qualité premium partout dans l'app plutôt que seulement à l'écran d'accueil.
- Le badge d'opacité des `CircleAvatar` de monde utilise 20% — à harmoniser sur 12% comme le reste de l'app (section 12).

### Éditeur de plateau ([`board_editor_screen.dart`](lib/screens/board_editor_screen.dart))
- Le message d'instruction contextuel en haut ("Touche la case de départ...") est un excellent exemple de guidage progressif — ✅ à garder et à reproduire dans tout futur écran complexe.
- Le bouton de sauvegarde (icône disquette dans l'AppBar) pourrait devenir un bouton flottant plus visible en bas de l'écran une fois qu'au moins une modification a été faite, pour suivre la règle "l'action de validation reste toujours accessible sans scroll" (section 10).

### Réglages ([`settings_screen.dart`](lib/screens/settings_screen.dart))
- Écran déjà bien organisé en sections avec des `Divider` — ✅ bon usage du regroupement visuel.
- Les `SwitchListTile` et `RadioListTile` sont déjà le bon composant pour ce type d'écran (pas besoin de gros boutons ici, ce sont des réglages, pas des actions).

### Statistiques ([`stats_screen.dart`](lib/screens/stats_screen.dart))
- Harmoniser les `Card` de classement/historique vers le style "contour fin sans ombre" du reste de l'app plutôt que le `Card` Material par défaut (avec ombre) actuellement utilisé, pour rester cohérent avec la section 12.
- La grille de succès (`_AchievementGrid`) pourrait animer chaque badge nouvellement débloqué avec un petit effet de "pop" (léger agrandissement puis retour à la taille normale) au moment où il passe de verrouillé à débloqué, plutôt qu'un changement d'état instantané.

---

## 17. Comment utiliser ce fichier dans le code

Le projet a déjà tout le mécanisme prêt pour accueillir ces designs sans rien casser :

1. **Ajouter un thème** : chaque piste ci-dessus donne directement les 16 couleurs attendues par la classe `BoardTheme` dans [`lib/models/board_theme.dart`](lib/models/board_theme.dart). Il suffit de créer une nouvelle constante `static const indien = BoardTheme(id: 'indien', label: 'Inde royale', icon: Icons.temple_hindu_rounded, ... )` avec les couleurs du tableau, puis de l'ajouter à la liste `BoardTheme.all`.
2. **Adapter le dessin des serpents/échelles** : les descriptions "matériau" (mosaïque, aquarelle, hologramme...) demandent des ajustements dans [`lib/widgets/board_painter.dart`](lib/widgets/board_painter.dart) — par exemple styliser `_drawSnake`/`_drawLadder` différemment selon `theme.id`, comme c'est déjà fait pour les couleurs spécifiques du thème `classic` (`_snakeStyles`).
3. **Adapter le dé** : chaque piste suggère un style de dé différent (glace/bonbon, hologramme filaire, bois sculpté...). Ça correspond à un nouveau cas dans l'enum `DiceSkin` de [`lib/widgets/dice_widget.dart`](lib/widgets/dice_widget.dart), au même endroit où existent déjà `classic`, `digits`, `neon`, `wood`.
4. **Prompt IA pour des visuels marketing** : les "versions courtes" en anglais, à la fin de chaque section, sont prêtes à être collées dans un générateur d'images (Midjourney, DALL·E, Stable Diffusion) pour produire des visuels d'icône d'app, de bannière de store, ou de fond d'écran de menu d'accueil — sans avoir à toucher au code du jeu.

---

## 18. Sources consultées

**Univers visuels (thèmes de plateau)**

- [Dribbble — Snakes and Ladders Game UI (GaurangDK)](https://dribbble.com/shots/17238556-Snakes-and-Ladders-Game-UI)
- [Dribbble — Snakes and Ladder Game UI/UX Design (Capermint)](https://dribbble.com/shots/23090958-Snakes-and-Ladder-Game-UI-UX-Design)
- [Behance — Snake and Ladder Mobile UI Design](https://www.behance.net/gallery/161283855/Snake-and-Ladder-Mobile-UI-Design)
- [Behance — Snake and Ladder Game UI Design (Mahaveer Sharma)](https://www.behance.net/gallery/145261429/Snake-and-Ladder-Game-UI-Design)
- [Behance — recherche "Ludo Game UI"](https://www.behance.net/search/projects/ludo%20game%20ui)
- [Sahapedia — Gyan Chaupar](http://www.sahapedia.org/gyan-chaupar-game-became-snakes-and-ladders-british-india)
- [The Print — l'ancêtre spirituel du jeu](https://theprint.in/pageturner/excerpt/gyan-chaupar-the-spiritual-ancestor-of-snakes-and-ladders/2159905/)
- [Asia Research News — Gyan Chaupar](https://www.asiaresearchnews.com/content/gyan-chaupar%E2%80%94-ancient-board-game-inspired-snakes-and-ladders-0)
- [V&A Museum — plateau Moksha Patam ancien](https://collections.vam.ac.uk/item/O26005)
- [Wikipedia — Zellij](https://en.wikipedia.org/wiki/Zellij)
- [Zouaq — générateur de motifs marocains](https://zouaq.floot.app/)
- [Wikipedia — Scandinavian design](https://en.wikipedia.org/wiki/Scandinavian_design)
- [UX Collective — minimalisme dans les jeux de plateau](https://uxdesign.cc/board-game-ux-minimalist-design-ab812ee5412d)
- [Wikipedia — Kawaii](https://en.wikipedia.org/wiki/Kawaii)
- [Dribbble — Kawaii UI](https://dribbble.com/tags/kawaii-ui)
- [Dribbble — Candy Crush Game UI](https://dribbble.com/shots/21285246-Candy-Crush-Game-UI)
- [Game UI Database — Candy Crush Saga](https://www.gameuidatabase.com/gameData.php?id=147)
- [Pixune — meilleurs exemples d'UI de jeux mobiles (2026)](https://pixune.com/blog/best-examples-mobile-game-ui-design/)
- [Tubik Studio — tendances de design UI 2026](https://tubikstudio.com/blog/ui-design-trends-2026/)

**Système d'interface moderne (onboarding, boutons, cartes, icônes, dé)**

- [UXCam — 12 apps avec un super onboarding (2026)](https://uxcam.com/blog/10-apps-with-great-user-onboarding/)
- [VWO — guide complet de l'onboarding mobile (2026)](https://vwo.com/blog/mobile-app-onboarding-guide/)
- [UserGuiding — 100+ statistiques sur l'onboarding utilisateur (2026)](https://userguiding.com/blog/user-onboarding-statistics)
- [Eleken — bonnes pratiques d'onboarding mobile (2026)](https://www.eleken.co/blog-posts/mobile-app-onboarding-best-practices)
- [Medium — un seul bouton primaire par écran (Material 3)](https://medium.com/@alikasem/one-screen-one-primary-button-material-3-button-hierarchy-in-angular-material-b8953ea58cad)
- [Cieden — comment créer la bonne hiérarchie de boutons](https://cieden.com/book/atoms/button/how-to-create-button-hierarchy)
- [Medium — explorer le monde des boutons Material Design](https://medium.com/design-bootcamp/exploring-the-world-of-material-design-buttons-3d105e9d4396)
- [Parachute Design — maîtriser la zone du pouce](https://parachutedesign.ca/blog/thumb-zone-ux/)
- [Tim Graf — concevoir pour la zone du pouce (2026)](https://timgraf.com/ux-design/designing-for-the-thumb-zone-a-modern-guide-to-mobile-ux-that-respects-human-anatomy/)
- [UX Collective — 8 bonnes pratiques pour les cartes UI](https://uxdesign.cc/8-best-practices-for-ui-card-design-898f45bb60cc)
- [Eleken — exemples et bonnes pratiques de cartes UI](https://www.eleken.co/blog-posts/card-ui-examples-and-best-practices-for-product-owners)
- [Tabler — guide de conception d'icônes](https://tabler.io/icons/icon-design-guide)
- [MDUI — style des icônes (Material Design)](https://www.mdui.org/en/design/1/style/icons.html)
- [Funkyton — dés 3D avec physique réelle (Unity)](https://funkyton.com/rolling-virtual-dice-with-physics/)
- [Codetap — dés 3D interactifs en HTML/CSS/JS](https://codetap.org/project/3d-dices)
