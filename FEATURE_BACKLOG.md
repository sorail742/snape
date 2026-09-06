# Backlog de fonctionnalités professionnelles — Serpents & Échelles Party

Ce document liste **100 fonctionnalités de niveau professionnel** qui peuvent être ajoutées au
projet, groupées par catégorie. Chaque fonctionnalité a :
- un **Impact / Effort** estimé (Élevé/Moyen/Faible) pour aider à prioriser,
- un **Pourquoi**, la valeur apportée,
- un **Prompt d'implémentation** prêt à copier-coller dans une session Claude Code : il donne le
  contexte, les fichiers concernés et les critères de validation, pour qu'une IA (ou un·e dev) puisse
  l'implémenter directement sans repartir de zéro.

Les prompts supposent l'architecture actuelle du projet (voir `lib/game/game_controller.dart`,
`lib/network/network_transport.dart`, `lib/services/*.dart`) — à relire avant implémentation, le
code ayant pu évoluer entre-temps.

---

## 1. Gameplay & modes de jeu

#### 1. Mode Tournoi à élimination (Impact: Élevé · Effort: Élevé)
**Pourquoi :** Donne un objectif structuré pour 4 à 16 joueurs en local/Bluetooth, au-delà d'une simple partie.

**Prompt d'implémentation :**
> Ajoute un mode "Tournoi" accessible depuis `SetupScreen` : l'utilisateur saisit 4/8/16 joueurs (noms + avatars, réutilisant `PlayerAvatar` et `playerAvatarEmojis`), l'app génère un bracket à élimination directe (nouvelle classe `Tournament` dans `lib/models/tournament.dart` avec `List<TournamentRound>`), et enchaîne automatiquement les `GameScreen` pour chaque match en poussant vers l'écran de bracket entre deux parties. Persiste la progression du tournoi en cours (SharedPreferences, format JSON) pour survivre à une fermeture d'app. Ajoute un écran `TournamentBracketScreen` affichant l'arbre et le vainqueur final avec confettis (réutilise `ConfettiOverlay`). Critère de validation : un tournoi à 8 joueurs se termine avec un vainqueur unique et le bracket reste visible/correct après avoir quitté et rouvert l'app en cours de tournoi.

#### 2. Mode Équipes (2v2, 3v3) (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Ouvre une dynamique sociale différente : les pions d'une même équipe avancent ensemble.

**Prompt d'implémentation :**
> Étends `Player` (lib/models/player.dart) avec un champ optionnel `teamId`, et `GameController` avec une règle : quand un pion atteint FINISH, l'équipe entière est marquée gagnante (`winner` devient l'équipe, pas un joueur seul — introduis une classe `Team` regroupant des `Player`). Adapte `_buildPlayersList`/`_buildTurnCard` dans `GameScreen` pour grouper visuellement par équipe (couleur de fond commune). Dans `SetupScreen`, ajoute un sélecteur d'équipe par joueur (2 ou 3 équipes). Critère de validation : une partie 2v2 se termine dès qu'un des deux pions d'une équipe atteint FINISH, et l'écran de victoire affiche les deux membres de l'équipe gagnante.

#### 3. Plateau classique 100 cases (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Le plateau 23 cases est une simplification ; la variante "100 cases / 10x10" est la référence internationale du jeu.

**Prompt d'implémentation :**
> Généralise `boardCols`/`boardRows`/`totalCells` dans `lib/models/board_data.dart` (actuellement des constantes globales figées à 7x5/23) en un objet `BoardShape` paramétrable, et crée `BoardShape.grid10x10`. Adapte `cellRowCol`/`cellCenter` pour prendre un `BoardShape` en paramètre plutôt que les constantes globales. Ajoute une `BoardLayout.classic100` avec des échelles/serpents équivalents au plateau traditionnel. Propage le `BoardShape` choisi à `GameController`, `BoardPainter` et `GameScreen._buildBoard`. Critère de validation : on peut lancer une partie locale sur le plateau 100 cases et gagner en atteignant la case 100, avec un rendu correct de `BoardPainter`.

#### 4. Générateur procédural de plateau (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Variété infinie sans travail de design manuel, complète l'éditeur manuel existant.

**Prompt d'implémentation :**
> Ajoute `BoardLayoutGenerator.generate({required int seed, required double difficulty})` dans `lib/services/`, qui produit un `BoardLayout` aléatoire en respectant des contraintes (pas de boucle échelle→serpent→échelle infinie, nombre de cases bonus/malus proportionnel à `difficulty`). Réutilise la logique de non-chevauchement déjà présente dans `DailyChallengeService.todayLayout` comme base. Ajoute un bouton "Plateau aléatoire" dans `SetupScreen` avec un slider de difficulté, qui appelle le générateur et l'assigne à `_boardLayout`. Critère de validation : générer 100 plateaux avec des seeds différents ne produit jamais de configuration où une case renvoie vers elle-même ou crée un cycle infini.

#### 5. Règles maison configurables (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Beaucoup de familles jouent avec des variantes (case exacte pour finir, pas de triple-six, etc.) ; les rendre configurables augmente la rétention.

**Prompt d'implémentation :**
> Crée une classe `HouseRules` (lib/models/house_rules.dart) avec des booléens : `exactFinishRequired`, `tripleSixEnabled`, `bonusMalusEnabled`, `extraTurnOnSix`. Passe une instance à `GameController` et adapte `_applyRoll`/`_nextTurn` pour respecter chaque règle (ex : si `exactFinishRequired` et que `target > totalCells`, ne pas avancer au lieu de l'actuel "tour passé"). Ajoute un écran `HouseRulesScreen` accessible depuis `SetupScreen` avec des `SwitchListTile`, persisté via `SettingsService`. Critère de validation : désactiver `tripleSixEnabled` empêche la perte de tour même après 3 six consécutifs, vérifiable par un test unitaire sur `GameController`.

#### 6. Mode Contre-la-montre (Impact: Faible · Effort: Faible)
**Pourquoi :** Variante rapide et mesurable, complémentaire au défi du jour.

**Prompt d'implémentation :**
> Ajoute une option "Contre la montre" dans `SetupScreen` qui, une fois activée, affiche un chronomètre visible dans `GameScreen` (réutilise le `Stopwatch` déjà présent dans `_GameScreenState`) et enregistre le meilleur temps par plateau/thème dans une nouvelle méthode `StatsService.saveBestTime(String boardId, int seconds)`. Affiche le record personnel dans `SetupScreen` à côté du plateau sélectionné. Critère de validation : rejouer plus vite qu'un record existant met à jour le meilleur temps affiché, rejouer plus lentement ne l'écrase pas.

#### 7. Handicap manuel de départ (Impact: Faible · Effort: Faible)
**Pourquoi :** Équilibre les parties entre joueurs de niveaux très différents (enfant vs adulte).

**Prompt d'implémentation :**
> Dans `SetupScreen`, ajoute un slider par joueur ("case de départ avancée", 0 à 5) qui initialise `Player.position` à cette valeur au lieu de 0 dans `GameController`'s constructeur (actuellement toujours 0 via `Player.reset()`/init). Vérifie que cette avance initiale ne déclenche pas d'événement de jeu (pas de son/log) puisqu'elle précède le premier lancer. Critère de validation : un joueur démarrant en case 3 apparaît immédiatement sur cette case au premier rendu du plateau, sans animation ni log d'événement.

#### 8. Indices/hints en solo (Impact: Faible · Effort: Faible)
**Pourquoi :** Aide les nouveaux joueurs ou les enfants sans dénaturer le hasard du dé.

**Prompt d'implémentation :**
> Ajoute un bouton "Indice" (icône ampoule) dans `GameScreen`, visible uniquement en mode local/campagne, qui affiche une info-bulle non intrusive basée sur `layout.snakesAndLadders`/`bonusCells` autour de la position actuelle du joueur ("Attention, un serpent se cache en case 17 !"). Purement informatif, ne modifie aucune règle de `GameController`. Critère de validation : l'indice mentionne correctement la prochaine case dangereuse/bonus dans un rayon de 6 cases (portée max d'un dé), sans jamais faire référence à des cases hors de portée du prochain lancer.

#### 9. Replay visuel d'une partie terminée (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Le journal actuel n'est que du texte ; un replay visuel est beaucoup plus engageant à partager.

**Prompt d'implémentation :**
> Enregistre la séquence complète des `GameEvent` + positions à chaque étape dans `GameHistoryEntry` (nouveau champ `List<Map<String,dynamic>> moveLog`, sérialisé en JSON compact). Crée un écran `ReplayScreen` qui rejoue l'animation du `BoardPainter` + tokens à vitesse x2/x4 à partir de ce log, sans logique de jeu réelle (juste une réanimation des positions). Accessible depuis `StatsScreen` en tapant sur une entrée d'historique. Critère de validation : le replay d'une partie affiche exactement le même vainqueur et la même séquence d'échelles/serpents que la partie originale.

#### 10. Sauvegarde/reprise de partie en pause (Impact: Élevé · Effort: Moyen)
**Pourquoi :** Actuellement, fermer l'app pendant une partie locale la perd définitivement.

**Prompt d'implémentation :**
> Sérialise l'état complet de `GameController` (joueurs, positions, tour, layout, events) en JSON à chaque `notifyListeners()` en mode local uniquement (throttle à 1x/sec pour éviter les écritures excessives), stocké via `SharedPreferences` sous une clé `paused_local_game`. Au lancement de `HomeModeScreen`, si une sauvegarde existe, propose "Reprendre la partie en cours" en plus du bouton "Jouer en local". Supprime la sauvegarde à la victoire ou à l'abandon explicite. Critère de validation : tuer l'app en plein milieu d'une partie locale à 3 joueurs puis la rouvrir restaure exactement les positions et le tour courant.

#### 11. Plateaux saisonniers/événementiels (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Crée une raison de revenir à des dates précises (Halloween, Noël).

**Prompt d'implémentation :**
> Ajoute un système d'événements dans `lib/models/seasonal_event.dart` : une liste de `SeasonalEvent(startDate, endDate, theme, layout, id)`. Dans `HomeModeScreen`, si `DateTime.now()` tombe dans une fenêtre active, affiche une carte de mode supplémentaire avec le thème de l'événement (nouvelle palette dans `BoardTheme`, ex. `BoardTheme.halloween`). Réutilise le mécanisme du défi du jour (`DailyChallengeService`) pour le suivi de complétion. Critère de validation : changer la date système pour tomber dans la fenêtre Halloween fait apparaître automatiquement la carte d'événement sans redéploiement.

#### 12. Mode spectateur en ligne (Impact: Faible · Effort: Moyen)
**Pourquoi :** Permet à un ami de suivre une partie en ligne sans y participer (ex. arbitre, famille).

**Prompt d'implémentation :**
> Dans `OnlineLobbyScreen`/`FirestoreTransport`, ajoute un rôle `spectator` : rejoindre avec un code affiche le plateau en lecture seule (un `GameController` avec `isHost: false` et un `localPlayerIndex` hors bornes désactive déjà `canLocalPlayerRoll` — vérifie ce comportement). Masque les contrôles de dé/chat d'envoi pour les spectateurs mais garde la réception du chat. Ajoute un compteur de spectateurs visible par l'hôte. Critère de validation : un spectateur voit le plateau se mettre à jour en temps réel mais ne peut jamais déclencher de lancer de dé.

#### 13. Système de mulligan (relance unique) (Impact: Faible · Effort: Faible)
**Pourquoi :** Réduit la frustration d'un très mauvais lancer sans casser l'équilibre du jeu (usage limité à 1/partie).

**Prompt d'implémentation :**
> Ajoute `Player.mulliganUsed` (bool) et un bouton "Relancer" affiché brièvement après un lancer dans `GameScreen` (avant que le mouvement ne commence — il faut donc découper `rollDice()` dans `GameController` pour exposer un état intermédiaire "résultat affiché, en attente de confirmation" avant `_applyRoll`). Une fois utilisé, le bouton disparaît pour ce joueur pour le reste de la partie. Critère de validation : un joueur ne peut relancer qu'une seule fois par partie, et le deuxième lancer est définitif même s'il est pire que le premier.

#### 14. Variantes de dés (Impact: Faible · Effort: Faible)
**Pourquoi :** Change le rythme du jeu (2 dés = parties plus rapides, dé 8/10/12 faces = plus de portée).

**Prompt d'implémentation :**
> Ajoute un enum `DiceMode { single6, double6, d8, d10, d12 }` choisi dans `SetupScreen`, propagé à `GameController` pour remplacer `_random.nextInt(6) + 1` par une logique paramétrée (pour `double6`, retourne la somme de deux lancers et adapte `DiceWidget` pour afficher deux dés côte à côte). Adapte la détection du "double" équivalent au triple-six pour `double6` (deux dés identiques). Critère de validation : en mode `double6`, la valeur affichée est bien la somme de deux dés à 6 faces indépendants, avec une distribution vérifiable par un test statistique simple (moyenne proche de 7 sur 1000 lancers).

#### 15. Mode Duel IA vs IA (attract mode) (Impact: Faible · Effort: Faible)
**Pourquoi :** Utile en démonstration (salon, vitrine) et pour tester visuellement l'équilibrage de l'IA sans intervention humaine.

**Prompt d'implémentation :**
> Ajoute une option cachée (accessible depuis les Réglages, section développeur) qui lance un `GameScreen` avec deux `Player(isBot: true)` : vérifie que `GameController._maybeTriggerBotTurn` gère déjà ce cas (il ne teste que `currentPlayer.isBot`, donc ça devrait fonctionner tel quel) et ajoute uniquement l'entrée de menu + un bouton "Rejouer automatiquement" en boucle pour enchaîner les parties sans interaction. Critère de validation : lancer ce mode enchaîne au moins 5 parties complètes sans qu'aucune action humaine ne soit nécessaire.

---

## 2. Personnalisation & accessibilité

#### 16. Internationalisation complète (i18n) (Impact: Élevé · Effort: Élevé)
**Pourquoi :** Tout le texte est actuellement codé en dur en français dans les widgets ; impossible de toucher un public non-francophone sans ça.

**Prompt d'implémentation :**
> Intègre le package `intl` + génération ARB (`flutter gen-l10n`). Crée `lib/l10n/app_fr.arb` (extrait de toutes les chaînes actuelles des écrans : `home_mode_screen.dart`, `setup_screen.dart`, `game_screen.dart`, `settings_screen.dart`, `onboarding_screen.dart`, etc.) et `app_en.arb`/`app_es.arb`. Remplace chaque `Text('...')` en dur par `AppLocalizations.of(context)!.xxx`. Ajoute un sélecteur de langue dans `SettingsScreen` (ou suit la langue système par défaut). Critère de validation : changer la langue système vers l'anglais (ou choisir "English" dans les Réglages) traduit 100% des écrans sans qu'aucune chaîne française ne subsiste, vérifiable par une recherche de texte français résiduel dans le code.

#### 17. Support RTL (arabe/hébreu) (Impact: Faible · Effort: Moyen)
**Pourquoi :** Prérequis pour toucher les marchés arabophones, complète l'i18n.

**Prompt d'implémentation :**
> Une fois l'i18n en place (#16), ajoute l'arabe (`app_ar.arb`) et vérifie manuellement chaque écran avec `Directionality(textDirection: TextDirection.rtl)` : `BoardPainter` doit rester en LTR visuellement (le plateau physique ne s'inverse pas) même si le reste de l'UI (AppBar, listes, boutons) passe en RTL — encapsule le board dans un `Directionality(textDirection: TextDirection.ltr, child: ...)` explicite pour l'isoler. Critère de validation : en langue arabe, les listes/menus s'affichent bien de droite à gauche mais le plateau de jeu reste visuellement identique au mode LTR.

#### 18. Échelle de police liée aux réglages système (Impact: Faible · Effort: Faible)
**Pourquoi :** Accessibilité de base pour les malvoyants, actuellement `MaterialApp` ne semble pas gérer explicitement `textScaleFactor`.

**Prompt d'implémentation :**
> Dans `main.dart`, vérifie que `MediaQuery.textScalerOf(context)` du système est bien respecté (ne pas l'écraser par un `MediaQuery` custom). Audite chaque écran pour des tailles de police en `double` fixes qui casseraient le layout à x1.5/x2 (notamment `SettingsScreen`, `HomeModeScreen` titres). Ajoute un test manuel avec les réglages d'accessibilité Android "Taille de police" à 200%. Critère de validation : à l'échelle de police maximale du système, aucun texte n'est tronqué de façon illisible sur les écrans principaux (Home, Setup, Game, Settings).

#### 19. Support lecteur d'écran (Semantics) (Impact: Élevé · Effort: Moyen)
**Pourquoi :** Le plateau (CustomPainter) et le dé (widget custom) ne sont pas nativement lisibles par TalkBack/VoiceOver.

**Prompt d'implémentation :**
> Enveloppe `DiceWidget` dans un `Semantics(label: 'Dé, valeur $value', button: true, onTap: ...)`. Pour `BoardPainter`/tokens dans `GameScreen._buildBoard`, ajoute une liste parallèle de `Semantics` invisibles positionnées sur chaque case occupée annonçant "Case X, [nom du joueur]". Assure que chaque `IconButton` de l'AppBar a un `tooltip` explicite (déjà en grande partie le cas) et vérifie qu'ils sont bien lus par le lecteur d'écran. Critère de validation : activer TalkBack et naviguer une partie complète au clavier/lecteur d'écran permet de comprendre l'état du jeu sans voir l'écran.

#### 20. Mode contraste élevé additionnel (Impact: Faible · Effort: Faible)
**Pourquoi :** Le thème "Daltonien" existe déjà mais un mode contraste élevé générique (grand public malvoyant) est différent.

**Prompt d'implémentation :**
> Ajoute une `BoardTheme.highContrast` (lib/models/board_theme.dart) avec un fond noir pur, bordures blanches épaisses, texte de bonus/malus en jaune/blanc à contraste maximal (respecter WCAG AAA, ratio ≥ 7:1). Ajoute-la à `BoardTheme.all`. Critère de validation : mesurer le ratio de contraste des couleurs de texte/fond de ce thème avec un outil WCAG et confirmer qu'il dépasse 7:1 pour tous les textes.

#### 21. Réglage de vitesse d'animation (Impact: Faible · Effort: Faible)
**Pourquoi :** Les animations de déplacement pas-à-pas peuvent gêner (motion sickness) ou simplement ralentir des joueurs qui veulent aller vite.

**Prompt d'implémentation :**
> Ajoute un `SettingsService.loadAnimationSpeed()/setAnimationSpeed(double multiplier)` (0.5x/1x/2x/instantané). Multiplie toutes les `Duration` d'animation dans `GameController._animateMoveTo`/`_slideMoveTo` et `DiceWidget`/`_PulsingAvatar` par ce facteur (0 = pas d'attente, mouvement instantané). Ajoute un `SegmentedButton` dans `SettingsScreen`. Critère de validation : en mode "instantané", une partie se termine en quelques secondes de lancers de dé sans aucune animation intermédiaire, sans casser la logique de victoire.

#### 22. Éditeur d'avatar avancé (Impact: Faible · Effort: Moyen)
**Pourquoi :** Va au-delà du choix emoji/photo actuel avec un recadrage et des filtres simples.

**Prompt d'implémentation :**
> Dans le flux de `_pickAvatar` de `SetupScreen`, après `ImagePicker().pickImage`, ajoute une étape de recadrage circulaire avec le package `crop_your_image` ou équivalent CDN-compatible, avant de sauvegarder le chemin dans `Player.avatarImagePath`. Ajoute 2-3 filtres simples (niveaux de gris, sépia, contraste) appliqués via `ColorFiltered` au moment de l'affichage dans `PlayerAvatar` (stocke le filtre choisi comme métadonnée du profil dans `SettingsService.upsertProfile`). Critère de validation : une photo importée peut être recadrée en cercle et un filtre appliqué est conservé après redémarrage de l'app.

#### 23. Éditeur de thème personnalisé (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Permet à chaque joueur de créer sa propre identité visuelle au-delà des 4 thèmes fixes.

**Prompt d'implémentation :**
> Ajoute un écran `CustomThemeEditorScreen` avec des `ColorPicker` pour les champs clés de `BoardTheme` (background, paperColor, accent, snakeBody, ladderRail...). Persiste le thème créé via `CustomBoardService`-like service (`CustomThemeService`, JSON dans SharedPreferences) et ajoute-le dynamiquement à la liste sélectionnable dans `SetupScreen`/`SettingsScreen` (qui itèrent actuellement sur `BoardTheme.all`, une liste statique — il faut la rendre extensible avec les thèmes custom chargés au démarrage). Critère de validation : un thème custom créé apparaît dans le sélecteur de thème au même titre que "Classique"/"Néon" et est appliqué correctement au `BoardPainter`.

#### 24. Musique de fond sélectionnable (Impact: Faible · Effort: Moyen)
**Pourquoi :** `SoundService` ne gère que les effets ponctuels, pas de musique d'ambiance continue.

**Prompt d'invocation :**
> Ajoute à `SoundService` un second `AudioPlayer` dédié à une piste de fond en boucle (`ReleaseMode.loop`), avec un volume indépendant du volume SFX (`SettingsService.loadMusicVolume`/`setMusicVolume`). Ajoute 2-3 pistes libres de droits dans `assets/music/` et un sélecteur dans `SettingsScreen`. Démarre/coupe la musique à l'entrée/sortie de `GameScreen`. Critère de validation : la musique tourne en boucle sans coupure audible pendant une partie complète et son volume est indépendant de celui des effets sonores.

#### 25. Sons personnalisés enregistrables (Impact: Faible · Effort: Moyen)
**Pourquoi :** Personnalisation ludique forte (enregistrer son propre cri de victoire).

**Prompt d'implémentation :**
> Ajoute le package `record` pour capturer un clip audio court (max 3s) depuis `SettingsScreen`, sauvegardé en fichier local et référencé dans `SettingsService`. Adapte `SoundService.play(GameSound.win)` pour vérifier d'abord si un chemin custom existe (`AudioPlayer.play(DeviceFileSource(path))`) avant de retomber sur l'asset par défaut. Critère de validation : après avoir enregistré un son "victoire" personnalisé, il est bien joué à la fin de la prochaine partie gagnée, et un bouton "Réinitialiser" restaure le son par défaut.

#### 26. Mode une main (Impact: Faible · Effort: Faible)
**Pourquoi :** Confort d'usage sur grand téléphone tenu à une main.

**Prompt d'implémentation :**
> Ajoute un réglage "Mode une main" dans `SettingsScreen` qui, activé, réorganise `GameScreen._buildBottomControls` pour rapprocher le bouton dé du bord inférieur atteignable au pouce (padding/alignement réduit, éventuellement un `Align(alignment: Alignment.bottomCenter)` avec un décalage horizontal réglable par un petit slider gauche/droite). Critère de validation : en mode une main activé côté droit, le bouton dé est positionné dans le tiers inférieur-droit de l'écran, atteignable sans changer de prise en main.

#### 27. Verrouillage d'orientation (Impact: Faible · Effort: Faible)
**Pourquoi :** Certains joueurs préfèrent forcer le portrait ou le paysage plutôt que de suivre la rotation automatique.

**Prompt d'implémentation :**
> Ajoute un réglage "Orientation" (Auto/Portrait/Paysage) dans `SettingsScreen`, persisté via `SettingsService`, appliqué au démarrage de `main()` via `SystemChrome.setPreferredOrientations([...])` selon la valeur chargée. Critère de validation : choisir "Portrait" empêche l'app de tourner même si le téléphone physique est mis à l'horizontale, sur toutes les écrans de l'app.

---

## 3. Multijoueur & social

#### 28. Comptes utilisateurs (Firebase Auth) (Impact: Élevé · Effort: Élevé)
**Pourquoi :** Prérequis pour toute sauvegarde cloud, amis, classement global — actuellement rien n'est lié à une identité persistante.

**Prompt d'implémentation :**
> Ajoute `firebase_auth` avec connexion Google/Apple/anonyme (fallback pour ne pas forcer un compte). Crée `AuthService` (lib/services/auth_service.dart) exposant `currentUser`/`signInWithGoogle`/`signInAnonymously`/`signOut`. Au premier lancement après `OnboardingScreen`, propose (sans forcer) de se connecter pour sauvegarder sa progression. Stocke l'UID Firebase comme clé de document dans les futures fonctionnalités cloud (#29). Critère de validation : se connecter avec un compte Google, désinstaller l'app, la réinstaller et se reconnecter doit permettre (une fois #29 fait) de retrouver le même profil.

#### 29. Sauvegarde cloud des stats/succès/campagne (Impact: Élevé · Effort: Moyen)
**Pourquoi :** Actuellement tout (`StatsService`, `CampaignService`, profils) est local via `SharedPreferences` et perdu au changement d'appareil.

**Prompt d'implémentation :**
> Une fois `AuthService` en place (#28), ajoute une synchronisation optionnelle Firestore (`users/{uid}/stats`, `users/{uid}/campaign`) : à chaque écriture locale dans `StatsService.addEntry`/`CampaignService.unlockLevel`, réplique aussi vers Firestore si connecté (fire-and-forget, ne bloque jamais le jeu local si offline). Au login sur un nouvel appareil, propose de fusionner (garder le meilleur des deux : le niveau de campagne le plus élevé, l'historique combiné dédupliqué par date). Critère de validation : jouer sur l'appareil A, se connecter sur l'appareil B avec le même compte, et retrouver le même niveau de campagne débloqué.

#### 30. Liste d'amis + invitations directes (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Remplace le partage de code de salon à l'aveugle par une vraie liste de contacts de jeu.

**Prompt d'implémentation :**
> Avec les comptes (#28), ajoute une collection Firestore `users/{uid}/friends` (liste d'UIDs + pseudo/avatar mis en cache). Ajoute un flux d'ajout d'ami par recherche de pseudo unique (champ `username` réservé de façon atomique via une transaction Firestore sur une collection `usernames/{username}` → `uid`). Dans `OnlineLobbyScreen`, ajoute un onglet "Inviter un ami" qui envoie une notification (voir #41) contenant le code de salon. Critère de validation : ajouter un ami par son pseudo fonctionne dans les deux sens (visible dans les deux listes), et l'inviter à un salon lui envoie bien une notification cliquable.

#### 31. Matchmaking aléatoire en ligne (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Permet de jouer sans connaître personne, essentiel pour la croissance au-delà du cercle d'amis.

**Prompt d'implémentation :**
> Ajoute une Cloud Function `findMatch` : les joueurs qui cliquent "Partie rapide" écrivent un document dans `matchmaking_queue/{uid}` ; la fonction (déclenchée par écriture, ou un job planifié toutes les 5s) apparie deux entrées disponibles, crée un `rooms/{code}` comme le fait déjà `_createRoom` dans `OnlineLobbyScreen`, et écrit le code dans les deux documents de queue pour que les clients (qui écoutent leur propre doc) redirigent automatiquement vers `GameScreen`. Nettoie les entrées de plus de 60s sans match (timeout, message "Aucun adversaire trouvé, réessaie"). Critère de validation : deux appareils qui cliquent "Partie rapide" à quelques secondes d'intervalle se retrouvent automatiquement dans la même partie sans échanger de code.

#### 32. Classement ELO / classement global (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Donne un sens de progression compétitive aux parties en ligne.

**Prompt d'implémentation :**
> Ajoute un champ `eloRating` (int, défaut 1000) sur `users/{uid}`. À la fin d'une partie en ligne classée (nouveau flag `ranked: true` choisi à la création du salon), une Cloud Function `onGameEnd` (déclenchée par l'écriture de `status: 'finished'` sur `rooms/{code}`) calcule le nouvel ELO des deux joueurs (formule ELO standard, K=32) et l'écrit sur leurs documents utilisateur. Ajoute un écran `LeaderboardScreen` listant le top 100 par `eloRating` (requête Firestore avec `orderBy` + pagination). Critère de validation : gagner une partie classée contre un joueur d'ELO plus élevé augmente son propre ELO de plus de points que gagner contre un ELO plus faible.

#### 33. Salons privés avec mot de passe (Impact: Faible · Effort: Faible)
**Pourquoi :** Le code à 5 caractères actuel est déjà semi-privé, mais un mot de passe explicite rassure sur les salons publics/listés (#34).

**Prompt d'implémentation :**
> Ajoute un champ optionnel `passwordHash` (SHA-256 côté client, jamais le mot de passe en clair) au document `rooms/{code}` créé dans `OnlineLobbyScreen._createRoom`. Dans `_joinRoom`, si le document a un `passwordHash`, affiche un champ de saisie supplémentaire et vérifie le hash avant d'écrire dans `players` via `arrayUnion`. Critère de validation : rejoindre un salon protégé avec le mauvais mot de passe affiche une erreur claire et n'ajoute pas le joueur à la liste.

#### 34. Salons publics listés (Impact: Faible · Effort: Moyen)
**Pourquoi :** Alternative au matchmaking (#31) pour les joueurs qui veulent choisir leur partie (voir les pseudos avant de rejoindre).

**Prompt d'implémentation :**
> Ajoute un flag `isPublic: true` optionnel à la création de salon. Ajoute un onglet "Parties publiques" dans `OnlineLobbyScreen` qui requête `rooms` où `isPublic == true` et `status == 'lobby'`, triés par `createdAt` décroissant, avec pagination. Affiche le nombre de joueurs déjà présents et le thème choisi. Critère de validation : une partie créée avec `isPublic: true` apparaît dans la liste d'un autre appareil dans les 2 secondes, et disparaît de la liste dès que son statut passe à "playing".

#### 35. Support de salons en ligne à plus de 4 joueurs (Impact: Moyen · Effort: Moyen)
**Pourquoi :** `_availableColors` limite actuellement à 4 couleurs/joueurs dans les lobbies ; un jeu de plateau familial en supporte souvent plus.

**Prompt d'implémentation :**
> Étends `_availableColors` (dans `OnlineLobbyScreen`/`BluetoothLobbyScreen`) à 8 couleurs distinctes, et vérifie que `GameScreen._tokenOffset` (qui répartit les pions sur une case partagée) reste lisible avec 8 pions sur la même case (peut nécessiter un mini-indicateur "+3" au lieu d'afficher tous les avatars empilés au-delà de 4). Retire toute limite dure à 4 dans les écrans de lobby. Critère de validation : une partie en ligne à 8 joueurs se déroule normalement, avec un affichage lisible même quand plusieurs pions partagent la même case.

#### 36. Filtre anti-grossièretés sur le chat (Impact: Moyen · Effort: Faible)
**Pourquoi :** Nécessaire dès que le jeu s'ouvre à des inconnus (matchmaking #31, salons publics #34).

**Prompt d'implémentation :**
> Ajoute une fonction `String sanitizeChatText(String input)` (lib/services/chat_moderation.dart) basée sur une liste de mots interdits (FR/EN a minima), appliquée dans `ChatController.send` avant l'envoi au transport. Pour le online, réplique aussi la vérification côté serveur (Cloud Function `onChatWrite` qui supprime/marque les messages non filtrés côté client trafiqué). Critère de validation : envoyer un message contenant un mot de la liste noire l'affiche censuré (`***`) chez tous les destinataires, y compris si le client de l'expéditeur a été modifié pour contourner le filtre local.

#### 37. Signalement/blocage de joueur (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Nécessaire pour la modération dès que le jeu inclut des inconnus.

**Prompt d'implémentation :**
> Ajoute un bouton "Signaler" sur chaque message de `ChatPanel` et sur le profil d'un adversaire dans `GameScreen._buildPlayersList`, qui écrit un document dans `reports/{autoId}` (uid signalé, motif, contexte). Ajoute un blocage local (`SettingsService.blockedUserIds`) qui masque les futurs messages de cet UID (`ChatController._onMessage` filtre si `message['from']` correspond à un UID bloqué). Critère de validation : bloquer un joueur masque immédiatement ses messages de chat pour le reste de la session, et un signalement crée bien un document consultable côté Firestore console.

#### 38. Historique de chat persistant par salon (Impact: Faible · Effort: Faible)
**Pourquoi :** Actuellement `ChatController.messages` est perdu à la fermeture de l'app ; utile de le retrouver en cas de reconnexion.

**Prompt d'implémentation :**
> Pour `FirestoreTransport`, au lieu de ne lire que les nouveaux docs (`docChanges` de type `added` depuis l'ouverture du listener), charge d'abord l'historique existant de `_chatRef` (requête simple `orderBy('ts').limit(100)`) au moment de la construction du transport, avant de souscrire aux changements en direct. Critère de validation : rejoindre un salon en cours de partie affiche les messages échangés avant l'arrivée du joueur, pas seulement les nouveaux.

#### 39. Invitation par lien profond (deep link) (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Un lien cliquable est plus fluide qu'un code à retaper manuellement.

**Prompt d'implémentation :**
> Configure `app_links` (ou Firebase Dynamic Links si toujours disponible) avec un schéma `serpentsparty://join/{code}` et un lien universel HTTPS de secours. Dans `main.dart`, écoute les liens entrants et, si l'app est sur `HomeModeScreen`, navigue automatiquement vers `OnlineLobbyScreen` avec le code pré-rempli dans `_codeController`. Adapte `_shareResult`/l'invitation d'ami (#30) pour générer ce lien via `share_plus` (déjà utilisé pour le partage de victoire). Critère de validation : cliquer sur un lien d'invitation partagé par SMS ouvre l'app directement sur l'écran de rejoindre le bon salon.

#### 40. Invitation par QR code (Impact: Faible · Effort: Faible)
**Pourquoi :** Pratique quand les deux joueurs sont physiquement ensemble (pas besoin de partager un lien à distance).

**Prompt d'implémentation :**
> Ajoute `qr_flutter` pour afficher un QR code encodant le lien profond (#39) dans `OnlineLobbyScreen` à côté du code textuel du salon. Ajoute un scanner (`mobile_scanner`) accessible par un bouton caméra dans l'écran de rejoindre, qui décode le QR et pré-remplit `_codeController`. Critère de validation : scanner le QR code affiché sur l'écran de l'hôte avec le bouton scanner du second appareil rejoint le salon sans taper aucun caractère.

#### 41. Notifications push "c'est ton tour" (Impact: Élevé · Effort: Élevé)
**Pourquoi :** Indispensable pour les parties en ligne asynchrones (#42) — sans notification, un joueur ne sait jamais quand revenir.

**Prompt d'implémentation :**
> Ajoute `firebase_messaging`, enregistre le token FCM de chaque joueur sur son document `users/{uid}` (ou `rooms/{code}/players/{uid}` pour les invités sans compte). Ajoute une Cloud Function `onTurnChange`, déclenchée par la mise à jour du champ `state.currentPlayerIndex` sur `rooms/{code}`, qui envoie une notification au joueur dont c'est maintenant le tour ("C'est ton tour contre {adversaire} !") avec un lien profond (#39) vers la partie. Gère les permissions de notification (iOS/Android 13+) au premier lancement d'une partie en ligne. Critère de validation : fermer l'app après avoir joué son tour déclenche une notification sur l'appareil de l'adversaire dans les secondes suivant l'écriture Firestore.

#### 42. Mode asynchrone "par tour" (Impact: Élevé · Effort: Élevé)
**Pourquoi :** Permet de jouer une partie en ligne sur plusieurs heures/jours, comme Words With Friends, sans garder les deux joueurs connectés simultanément.

**Prompt d'implémentation :**
> Ajoute un flag `asyncMode: true` au salon (choisi à la création). En mode async, `FirestoreTransport` ne dépend plus d'un `StreamSubscription` maintenu en continu par `GameScreen` : chaque coup se résout entièrement côté serveur (nécessite de porter la logique de `GameController._applyRoll` dans une Cloud Function `rollDice(roomCode)` appelée via un callable HTTPS, pour que le tour se joue même si l'autre appareil est fermé). Combine avec les notifications (#41) pour prévenir quand c'est reparti. Critère de validation : le joueur A ferme l'app après son tour ; le joueur B ouvre l'app plus tard, joue son tour, et A reçoit une notification et retrouve l'état à jour à sa prochaine ouverture — sans qu'aucun des deux appareils n'ait eu besoin d'être connecté en simultané.

---

## 4. Rétention & live-ops

#### 43. Séries (streaks) du défi du jour (Impact: Moyen · Effort: Faible)
**Pourquoi :** Un compteur de série est un des leviers de rétention les plus efficaces et peu coûteux à implémenter.

**Prompt d'implémentation :**
> Dans `DailyChallengeService`, ajoute `loadStreak()`/le calcul automatique : à chaque `saveTodayResult(won: true)`, vérifie si une entrée existait pour `hier` (clé `daily_challenge_{yesterdayKey}`) avec `won: true` ; si oui incrémente un compteur persisté (`daily_streak`), sinon le remet à 1. Affiche ce compteur avec une icône flamme dans la carte "Défi du jour" de `HomeModeScreen` (à côté du texte existant sur `_dailyResult`). Critère de validation : gagner le défi 3 jours d'affilée affiche "🔥 3", et rater un jour remet le compteur à 0 le jour suivant.

#### 44. Calendrier des défis passés (Impact: Faible · Effort: Moyen)
**Pourquoi :** Permet de revenir sur un défi manqué ou de comparer ses performances passées.

**Prompt d'implémentation :**
> Ajoute un écran `DailyChallengeCalendarScreen` (`TableCalendar` ou grille custom) qui liste les 30 derniers jours, marquant chaque case selon `daily_challenge_{key}` existant en local (victoire/défaite/non joué). Taper sur un jour passé relance ce plateau spécifique en lecture "rejouer pour le fun" (le résultat n'écrase pas l'original car `saveTodayResult` ne s'applique qu'à `todayKey`). Critère de validation : le calendrier affiche correctement l'état des 7 derniers jours réellement joués sur l'appareil de test.

#### 45. Notifications locales de rappel quotidien (Impact: Moyen · Effort: Faible)
**Pourquoi :** Rappelle de revenir jouer le défi du jour sans dépendre d'un serveur (notification locale, pas push).

**Prompt d'implémentation :**
> Ajoute `flutter_local_notifications`, programme une notification quotidienne (heure configurable dans `SettingsScreen`, ex. 18h) qui ne se déclenche que si `DailyChallengeService.loadTodayResult()` est encore `null` à ce moment (vérifié au moment de la programmation côté OS — utilise un job répétitif simple plutôt qu'un contenu dynamique). Ajoute un toggle "Me rappeler le défi du jour" avec demande de permission explicite. Critère de validation : avec la notification activée et le défi non joué, une notification apparaît à l'heure configurée ; si le défi est déjà joué avant cette heure, aucune notification ne doit apparaître ce jour-là.

#### 46. Tournoi hebdomadaire en ligne (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Crée un rendez-vous récurrent compétitif au-delà du 1v1 classé (#32).

**Prompt d'implémentation :**
> Ajoute une Cloud Function planifiée (`pubsub.schedule('every monday 00:00')`) qui archive le classement de la semaine précédente (collection `weekly_leaderboards/{weekId}`) et remet à zéro un compteur `weeklyScore` sur chaque profil utilisateur. Les points hebdomadaires s'accumulent à chaque victoire en ligne classée (+10) via la même Cloud Function `onGameEnd` que #32. Ajoute un onglet "Cette semaine" dans `LeaderboardScreen`. Critère de validation : le classement hebdomadaire se réinitialise automatiquement chaque lundi et l'ancien classement reste consultable en historique.

#### 47. Défis quotidiens à objectifs (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Complète le défi du jour "gagner" par des objectifs variés qui donnent plusieurs raisons de rejouer le même jour.

**Prompt d'implémentation :**
> Ajoute 2-3 objectifs quotidiens dérivés (ex. "Gagne en moins de 15 lancers", "Gagne sans tomber sur un serpent") calculés côté client à partir des `GameEvent` de la partie du défi du jour en cours, sans toucher à `DailyChallengeService.todayLayout`. Stocke leur complétion (`daily_objectives_{todayKey}`) séparément du résultat principal. Affiche les 3 objectifs avec coche/croix dans l'écran du défi du jour. Critère de validation : terminer une partie du défi en 12 lancers coche automatiquement l'objectif "moins de 15 lancers" sans action supplémentaire du joueur.

#### 48. Missions hebdomadaires avec récompenses (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Objectifs à plus long terme ("gagne 5 parties cette semaine") pour la rétention hebdomadaire.

**Prompt d'implémentation :**
> Ajoute `WeeklyMissionService` générant 3 missions aléatoires chaque lundi (parmi un pool : "gagne N parties", "joue N parties en Bluetooth", "débloque 1 niveau de campagne"), suivies via des compteurs incrémentés aux moments pertinents (fin de `GameScreen._recordHistory`, `CampaignService.unlockLevel`). Récompense en monnaie virtuelle (#55) à la complétion. Affiche la progression dans un nouvel onglet de `StatsScreen`. Critère de validation : une mission "gagne 3 parties" passe de 0/3 à 3/3 après 3 victoires dans la semaine et déclenche la récompense une seule fois.

#### 49. Notification de réactivation ("reviens jouer") (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Récupère les joueurs inactifs, avec un opt-in explicite pour rester conforme RGPD.

**Prompt d'implémentation :**
> Combine avec les comptes (#28) et FCM (#41 déjà en place pour l'infra) : une Cloud Function planifiée quotidienne (`pubsub.schedule('every day 10:00')`) requête les utilisateurs dont `lastPlayedAt` date de plus de 3 jours et `pushOptIn == true`, et leur envoie une notification douce ("Ton IA t'attend pour une revanche !"). Ajoute le toggle d'opt-in explicite (défaut désactivé) dans `SettingsScreen`, avec texte clair sur son usage. Critère de validation : aucune notification de réactivation n'est envoyée à un utilisateur qui n'a pas explicitement activé l'opt-in, vérifiable en lisant les logs de la Cloud Function.

#### 50. Écran "Nouveautés" après mise à jour (Impact: Faible · Effort: Faible)
**Pourquoi :** Valorise les nouvelles fonctionnalités auprès des joueurs existants qui ne liraient pas un changelog externe.

**Prompt d'implémentation :**
> Compare la version stockée (`SettingsService`, nouvelle clé `last_seen_version`) à `PackageInfo.fromPlatform().version` au lancement de `AppEntryScreen`. Si différente, affiche une modale/écran listant 2-3 points de changelog (contenu statique par version, `Map<String, List<String>>` dans le code) avant `HomeModeScreen`, puis met à jour `last_seen_version`. Critère de validation : après une mise à jour simulée (changer la version dans `pubspec.yaml`), l'écran "Nouveautés" apparaît une seule fois puis plus jamais pour cette version.

#### 51. Feature flags / Remote Config (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Permet d'activer/désactiver des fonctionnalités à distance (ex. couper le online en cas de souci Firestore) sans nouvelle publication.

**Prompt d'implémentation :**
> Ajoute `firebase_remote_config`, définis des clés (`online_mode_enabled`, `matchmaking_enabled`, `min_supported_version`). Au démarrage (`main.dart`), fetch+activate avec un cache court (15 min). Dans `HomeModeScreen`, masque/désactive la carte "En ligne" si `online_mode_enabled == false`, avec un message explicite. Ajoute une vérification de version minimale qui bloque l'app avec un message de mise à jour requise. Critère de validation : basculer `online_mode_enabled` à `false` dans la console Firebase désactive la carte "En ligne" sur un appareil de test dans les 15 minutes suivantes sans mise à jour de l'app.

#### 52. A/B testing (Impact: Faible · Effort: Moyen)
**Pourquoi :** Permet de tester objectivement des variantes (ex. deux formulations du bouton "Commencer") avant de généraliser.

**Prompt d'implémentation :**
> Combine Remote Config (#51) avec Firebase A/B Testing (config côté console). Ajoute un helper `ExperimentService.variant(String key)` qui lit la valeur Remote Config assignée au groupe de l'utilisateur, et logge un événement Analytics (#72) `experiment_exposure` à chaque affichage de variante. Applique un premier test simple sur le libellé du bouton principal de `HomeModeScreen`. Critère de validation : deux appareils de test peuvent recevoir des variantes différentes du même texte, et l'événement d'exposition apparaît bien dans Analytics avec le nom de variante correct.

#### 53. Sondage de satisfaction in-app (NPS) (Impact: Faible · Effort: Faible)
**Pourquoi :** Recueille un signal qualitatif de satisfaction sans dépendre des avis stores.

**Prompt d'implémentation :**
> Après la Nème partie terminée (compteur `SettingsService`, ex. déclenché à 10, puis tous les 50), affiche une modale simple "Sur 10, recommanderais-tu ce jeu ?" avec un score, sauvegardé anonymement dans Firestore (`nps_responses`) ou juste loggé en Analytics. Ne jamais redemander avant N parties supplémentaires même si l'utilisateur ferme la modale sans répondre. Critère de validation : la modale apparaît exactement à la 10e partie terminée puis pas avant la 60e, quel que soit le nombre de fermetures sans réponse entre-temps.

#### 54. Widget d'écran d'accueil (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Rappel visuel permanent du défi du jour directement sur l'écran d'accueil du téléphone.

**Prompt d'implémentation :**
> Utilise `home_widget` (package Flutter cross-platform pour App Widgets Android / WidgetKit iOS). Crée un widget affichant le statut du défi du jour (`DailyChallengeService.loadTodayResult()`), mis à jour à chaque changement via `HomeWidget.saveWidgetData` appelé depuis `HomeModeScreen._loadDailyResult`. Taper le widget ouvre l'app directement sur le défi du jour (deep link, #39). Critère de validation : terminer le défi du jour dans l'app met à jour le widget d'écran d'accueil sans avoir besoin de rouvrir l'app.

---

## 5. Progression & récompenses

#### 55. Monnaie virtuelle cosmétique (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Base nécessaire pour la boutique cosmétique (#56) et les récompenses de missions (#48), sans lien avec de l'argent réel.

**Prompt d'implémentation :**
> Ajoute `CurrencyService` (SharedPreferences, clé `coins_balance`) avec `earn(int amount, {required String reason})`/`spend(int amount)`. Attribue des gains à des moments clés existants : fin de partie (+5), victoire (+10), niveau de campagne débloqué (+20). Affiche le solde dans l'AppBar de `HomeModeScreen`. Critère de validation : le solde affiché augmente immédiatement après chaque partie gagnée du montant attendu, et ne peut jamais devenir négatif (`spend` échoue proprement si solde insuffisant).

#### 56. Boutique cosmétique (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Donne un usage à la monnaie virtuelle (#55) et une source de personnalisation supplémentaire.

**Prompt d'implémentation :**
> Ajoute un écran `ShopScreen` listant des cosmétiques (thèmes de plateau exclusifs, skins de `DiceWidget`, cadres d'avatar) chacun avec un prix en pièces (#55) et un statut possédé/non possédé (`SettingsService.ownedCosmetics`, `Set<String>`). L'achat déduit via `CurrencyService.spend` et débloque l'item dans les sélecteurs existants (`BoardTheme` sélection dans `SetupScreen`, etc. — filtrer les items premium par possession). Critère de validation : un thème premium n'apparaît pas sélectionnable tant qu'il n'est pas acheté, et le solde de pièces diminue exactement du prix affiché après achat.

#### 57. Niveaux de compte (XP global) (Impact: Faible · Effort: Moyen)
**Pourquoi :** Sens de progression au-delà de la seule campagne, valorise aussi le mode local/Bluetooth/en ligne.

**Prompt d'implémentation :**
> Ajoute `XpService` : chaque partie terminée octroie de l'XP (formule simple : 10 + 5×victoire), accumulée dans un total persisté, avec une courbe de niveaux (`level = sqrt(xp / 50).floor()` par exemple). Affiche le niveau/barre de progression dans `StatsScreen` en haut, avec une icône de palier (bronze/argent/or/platine selon tranche de niveaux). Critère de validation : le niveau affiché correspond exactement à la formule appliquée au total d'XP accumulé, vérifiable par un test unitaire sur `XpService`.

#### 58. Succès à paliers (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Les 7 succès actuels de `Achievement.compute` sont tout-ou-rien ; des paliers (bronze/argent/or) prolongent l'engagement bien après le premier déblocage.

**Prompt d'implémentation :**
> Refactore `Achievement.compute` (lib/models/achievement.dart) pour que chaque succès expose des seuils multiples (ex. "Habitué·e" : 5/20/50/100 parties → bronze/argent/or/platine) au lieu d'un seul booléen `isUnlocked`. Adapte `_AchievementGrid` dans `StatsScreen` pour afficher le palier actuel avec une couleur de médaille correspondante, et une barre de progression vers le palier suivant. Critère de validation : passer de 19 à 20 parties jouées fait visuellement passer le succès correspondant du palier bronze à argent, avec la bonne couleur de badge.

#### 59. Intégration Play Games Services / Game Center (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Succès et classements natifs reconnus par la plateforme, avec sauvegarde cloud native indépendante de Firebase.

**Prompt d'implémentation :**
> Ajoute `games_services` (ou `google_play_games_services_v2` selon compatibilité actuelle), configure les IDs de succès/classements dans les consoles Google Play/App Store Connect miroir des succès de `Achievement.compute`. À chaque déblocage détecté dans `GameScreen._recordHistory`, appelle aussi `GamesServices.unlock(achievement: ...)`. Ajoute un bouton "Voir les classements" natifs. Critère de validation : débloquer un succès dans l'app le fait apparaître dans l'app native Play Games/Game Center du téléphone de test.

#### 60. Cosmétiques déverrouillables par succès (Impact: Faible · Effort: Faible)
**Pourquoi :** Complète la boutique payante (#56) par une voie de déblocage gratuite basée sur le mérite.

**Prompt d'implémentation :**
> Associe certains cosmétiques de la boutique (#56) à un succès plutôt qu'à un prix en pièces (champ `unlockCondition` : `AchievementUnlock('champion_3_wins')` ou `CoinPrice(200)`). Adapte `ShopScreen` pour afficher "Débloqué par : Succès Champion" au lieu d'un prix quand applicable, et le débloquer automatiquement dès que `Achievement.compute` détecte la condition remplie. Critère de validation : décrocher le succès "Champion (3 victoires)" débloque immédiatement le cosmétique associé sans passage par la boutique/achat.

#### 61. Export PDF/CSV des statistiques (Impact: Faible · Effort: Faible)
**Pourquoi :** Utile pour les familles/écoles qui suivent des tournois sur la durée, ou juste pour garder une trace.

**Prompt d'implémentation :**
> Ajoute un bouton "Exporter" dans `StatsScreen` qui génère soit un CSV simple (une ligne par `GameHistoryEntry`) soit un PDF sommaire (package `pdf` + `printing`) reprenant classement et historique, puis propose le partage via `share_plus` (déjà une dépendance du projet). Critère de validation : l'export CSV ouvert dans un tableur affiche exactement le même nombre de lignes que l'historique visible dans `StatsScreen`, avec les bonnes colonnes (date, mode, joueurs, vainqueur, durée).

#### 62. Fiche joueur partageable (image) (Impact: Faible · Effort: Moyen)
**Pourquoi :** Format viral naturel pour les réseaux sociaux, plus engageant que le texte de `_shareResult` actuel.

**Prompt d'implémentation :**
> Crée un widget `PlayerCardWidget` (avatar, nom, stats clés : parties jouées, % victoires, succès marquants) rendu hors-écran, capturé en image via `RepaintBoundary`/`toImage`, puis partagé avec `share_plus` (`ShareParams(files: [XFile(path)])` au lieu du seul `text` actuel dans `GameScreen._shareResult`). Accessible depuis `StatsScreen`. Critère de validation : le partage produit un fichier image (pas juste du texte) affichable directement dans l'aperçu de partage du téléphone.

#### 63. Badge de champion de tournoi (Impact: Faible · Effort: Faible)
**Pourquoi :** Récompense visible et durable pour le mode Tournoi (#1).

**Prompt d'implémentation :**
> À la fin d'un tournoi (#1), enregistre une entrée dans un nouveau `TournamentHistoryEntry` (date, nombre de participants, vainqueur), et affiche un badge "🏆 Vainqueur de tournoi" sur le profil du joueur correspondant dans `SettingsService.upsertProfile` (nouveau champ `tournamentWins`). Affiche ce badge à côté de l'avatar dans `PlayerAvatar` si `tournamentWins > 0`. Critère de validation : gagner un tournoi ajoute visiblement le badge sur l'avatar du joueur dans les parties suivantes.

#### 64. Partage du "meilleur coup" (Impact: Faible · Effort: Moyen)
**Pourquoi :** Capture et partage instantanément un moment fort (grosse échelle, retournement de situation), format court et viral.

**Prompt d'implémentation :**
> Détecte dans `GameController` un "moment fort" (ex. un joueur en dernière position remonte en tête via une échelle, ou une victoire sur le dernier lancer possible), expose-le via un nouvel événement `GameEventType.highlight`. Dans `GameScreen`, sur cet événement, capture automatiquement une image du plateau au moment du pic (`RepaintBoundary` sur `_buildBoard`) et propose un bouton de partage immédiat. Critère de validation : une remontée spectaculaire (ex. depuis la case 2 vers la case 20 via une échelle) déclenche bien la capture et le bouton de partage dans les 2 secondes suivant l'animation.

---

## 6. Sécurité & robustesse backend

#### 65. Règles de sécurité Firestore strictes (Impact: Élevé · Effort: Moyen)
**Pourquoi :** Le mode en ligne actuel est décrit comme "Firestore en mode test" (règles permissives) dans les instructions données à l'utilisateur — n'importe qui avec la config peut lire/écrire toute la base.

**Prompt d'implémentation :**
> Écris des `firestore.rules` strictes : un document `rooms/{code}` n'est lisible/inscriptible que par les UIDs listés dans son champ `players` (nécessite d'abord les comptes #28, ou a minima un `deviceId` généré et stocké côté client comme identifiant faible), limite la taille des champs `state`/`chat`/`emotes` pour éviter l'abus, et interdit toute lecture/écriture sur les collections hors `rooms/*`. Teste avec l'émulateur Firestore (`firebase emulators:start`) et le package `firebase_rules_unit_testing` (ou son équivalent Dart) pour couvrir les cas d'accès refusé/autorisé. Critère de validation : une tentative de lecture d'un salon dont on n'est pas membre échoue avec `PERMISSION_DENIED`, vérifiée par un test automatisé sur l'émulateur.

#### 66. Validation serveur des coups (anti-triche) (Impact: Élevé · Effort: Élevé)
**Pourquoi :** Actuellement, l'hôte du salon fait autorité sur toute la logique de jeu côté client (`GameController.rollDice`) — un client modifié peut tricher sur les valeurs de dé envoyées.

**Prompt d'implémentation :**
> Porte la logique critique de `GameController._applyRoll` (calcul du lancer, application des bonus/malus/échelles/serpents, détection de victoire) dans une Cloud Function callable `resolveTurn(roomCode)` qui génère elle-même le nombre aléatoire (jamais fourni par le client), applique les règles à partir du `layout` stocké côté serveur, et écrit le nouvel état dans `rooms/{code}`. Le client garde uniquement la responsabilité de déclencher l'appel (bouton dé) et de rejouer l'animation à partir du résultat reçu, sans jamais faire autorité sur le résultat en mode en ligne classé. Critère de validation : modifier manuellement (via un outil de debug) la valeur de dé envoyée par un client ne doit avoir aucun effet — l'état final du salon reflète toujours le résultat calculé côté serveur.

#### 67. Firebase App Check (Impact: Moyen · Effort: Faible)
**Pourquoi :** Empêche des clients non authentiques (scripts, apps clonées) d'accéder à Firestore/Cloud Functions.

**Prompt d'implémentation :**
> Ajoute `firebase_app_check`, active-le avec Play Integrity (Android) et DeviceCheck/App Attest (iOS) en production, et le provider debug en développement. Initialise-le juste après `Firebase.initializeApp` dans `FirebaseBootstrap.ensureInitialized`. Active l'enforcement App Check dans la console Firebase pour Firestore et les Cloud Functions une fois le déploiement validé sur les stores. Critère de validation : une requête Firestore envoyée sans jeton App Check valide (simulée via curl/Postman avec la clé d'API seule) est rejetée une fois l'enforcement activé.

#### 68. Rate limiting sur les écritures Firestore (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Protège contre le spam de chat ou de `roll_request` par un client malveillant ou buggé.

**Prompt d'implémentation :**
> Ajoute une vérification dans les règles Firestore (#65) limitant la fréquence d'écriture par UID sur `rooms/{code}/chat` et `requests` (ex. en comparant le `ts` du dernier document du même auteur, refusé si moins de 500ms d'écart — nécessite un champ `ts: request.time` côté règles). En complément, ajoute un debounce côté client dans `ChatController.send` et `GameController.rollDice` pour éviter les envois accidentels en rafale. Critère de validation : envoyer 20 messages de chat en boucle rapide via un script de test ne fait passer que les messages respectant l'intervalle minimal, les autres étant rejetés silencieusement par les règles.

#### 69. Nettoyage automatique des salons inactifs (Impact: Moyen · Effort: Faible)
**Pourquoi :** Les documents `rooms/{code}` créés par chaque partie en ligne (`_createRoom`) s'accumulent indéfiniment dans Firestore sans purge actuellement.

**Prompt d'implémentation :**
> Ajoute une Cloud Function planifiée quotidienne qui supprime (avec ses sous-collections `chat`/`emotes`/`requests`) tout document `rooms/{code}` dont `createdAt` a plus de 7 jours, ou dont `status == 'finished'` depuis plus de 24h. Utilise `firebase-tools` ou une fonction récursive de suppression de sous-collections (Firestore ne supprime pas les sous-collections automatiquement). Critère de validation : un salon de test créé puis marqué "finished" disparaît de Firestore (racine + sous-collections) après le déclenchement suivant de la fonction planifiée.

#### 70. Chiffrement des données locales sensibles (Impact: Faible · Effort: Faible)
**Pourquoi :** Les profils (`SettingsService.upsertProfile`) incluent des chemins de photos et noms d'enfants potentiellement sensibles, actuellement en clair dans `SharedPreferences`.

**Prompt d'implémentation :**
> Remplace le stockage des clés sensibles (`saved_profiles_v1`, `last_local_players`) par `flutter_secure_storage` (Keychain/Keystore natif) au lieu de `SharedPreferences`, en gardant `SharedPreferences` pour les préférences non sensibles (volume, thème). Ajoute une migration au premier lancement post-mise à jour qui déplace les données existantes vers le stockage sécurisé puis les supprime de l'ancien emplacement. Critère de validation : inspecter le fichier `SharedPreferences` brut sur un appareil de test après migration ne révèle plus aucun nom/chemin de photo de joueur.

#### 71. Firebase Crashlytics (Impact: Élevé · Effort: Faible)
**Pourquoi :** Aucun suivi de plantage en production actuellement — les bugs remontés par les utilisateurs (comme les erreurs Bluetooth déjà gérées défensivement dans `NearbyTransport`) ne sont pas centralisés.

**Prompt d'implémentation :**
> Ajoute `firebase_crashlytics`, initialise-le dans `main()` avec `FlutterError.onError` et `PlatformDispatcher.instance.onError` redirigés vers `FirebaseCrashlytics.instance.recordFlutterFatalError`/`recordError`. Remplace les `debugPrint` d'erreurs déjà présents dans le code (ex. `GameController.notifyListeners`, `NearbyTransport._sendBytesSafely`) par des `FirebaseCrashlytics.instance.recordError(e, st, fatal: false)` en plus du log local. Critère de validation : déclencher intentionnellement une exception non fatale (ex. couper le Bluetooth en plein envoi) fait apparaître un rapport dans la console Crashlytics dans les minutes suivantes.

#### 72. Firebase Analytics (Impact: Moyen · Effort: Faible)
**Pourquoi :** Aucune télémétrie d'usage actuellement — impossible de savoir quels modes/fonctionnalités sont réellement utilisés pour prioriser les futurs développements.

**Prompt d'implémentation :**
> Ajoute `firebase_analytics`, crée un `AnalyticsService` centralisant des événements clés : `game_started` (mode, nb joueurs), `game_finished` (mode, durée, vainqueur bot/humain), `campaign_level_unlocked`, `daily_challenge_completed`. Appelle ces événements depuis les points existants (`GameScreen._recordHistory`, `CampaignScreen._unlockNext`, `DailyChallengeService.saveTodayResult`). Respecte le consentement RGPD (#96) avant toute collecte pour les utilisateurs UE. Critère de validation : terminer une partie en local logge bien un événement `game_finished` visible (en mode debug) dans le "DebugView" de la console Firebase Analytics.

#### 73. Migration versionnée des sauvegardes locales (Impact: Moyen · Effort: Faible)
**Pourquoi :** `StatsService`/`CustomBoardService`/`SettingsService` stockent du JSON sans version de schéma ; toute évolution future de format (ex. ajout d'un champ obligatoire) risque de faire planter la désérialisation sur les données existantes des utilisateurs.

**Prompt d'implémentation :**
> Ajoute un champ `schemaVersion` à chaque blob JSON persisté (`GameHistoryEntry`, `CustomBoard`, profils). Ajoute un `MigrationService` exécuté une fois au démarrage qui détecte une version antérieure et applique des transformations successives (ex. v1→v2 ajoute un champ avec valeur par défaut) avant de réécrire les données. Toutes les méthodes `fromJson` existantes doivent tolérer l'absence du champ `schemaVersion` (traité comme v1). Critère de validation : charger un historique de parties sauvegardé avec l'ancien format (sans `schemaVersion`) ne plante pas et est transparently migré au nouveau format à la prochaine sauvegarde.

#### 74. Export/import manuel des données (Impact: Faible · Effort: Faible)
**Pourquoi :** Permet une sauvegarde/restauration sans compte cloud (#29), utile en attendant cette fonctionnalité ou pour changer d'appareil manuellement.

**Prompt d'implémentation :**
> Ajoute dans `SettingsScreen` un bouton "Exporter mes données" qui sérialise l'ensemble des clés `SharedPreferences` pertinentes (stats, campagne, profils, plateaux custom, réglages) en un seul fichier JSON partagé via `share_plus`, et un bouton "Importer" qui relit un tel fichier (via `file_picker`) et réécrit les clés correspondantes après confirmation explicite (avertissement "ceci remplacera vos données actuelles"). Critère de validation : exporter puis réimporter sur une installation fraîche de l'app restaure exactement le même niveau de campagne, historique de parties et profils qu'avant l'export.

---

## 7. Qualité, tests & CI/CD

#### 75. Tests unitaires de GameController (Impact: Élevé · Effort: Moyen)
**Pourquoi :** `GameController` concentre toute la logique de règles (bonus/malus, échelles/serpents, triple-six, victoire, tour de jeu) et n'a aujourd'hui aucun test dédié — seul `test/widget_test.dart` (probablement le template par défaut) existe.

**Prompt d'implémentation :**
> Crée `test/game/game_controller_test.dart` couvrant au minimum : une case bonus déplace bien le joueur du montant attendu (`_applyRoll` avec un `BoardLayout` de test), un serpent/une échelle transporte à la bonne destination, 3 six consécutifs font perdre le tour sans déplacer le joueur, un lancer dépassant `totalCells` ne déplace pas le joueur ("tour passé"), atteindre exactement `totalCells` déclenche `isGameOver`/`winner`, et `turnLimit` dépassé déclenche `isDefeat`. Utilise un `Random` injectable ou teste sur plusieurs graines pour couvrir le non-déterminisme du dé (ou refactore `GameController` pour accepter un `Random` optionnel au constructeur, facilitant les tests déterministes). Critère de validation : `flutter test test/game/game_controller_test.dart` passe avec au moins 8 cas couvrant les règles ci-dessus, et une régression volontaire (ex. commenter la vérification du triple-six) fait échouer le test correspondant.

#### 76. Tests widget des écrans clés (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Aucun test d'intégration UI n'existe sur les écrans centraux (`SetupScreen`, `GameScreen`, `CampaignScreen`), qui contiennent une logique d'état non triviale (profils, thèmes, plateaux custom).

**Prompt d'implémentation :**
> Ajoute `test/screens/setup_screen_test.dart` (vérifie que changer le nombre de joueurs affiche le bon nombre de cartes, qu'activer l'IA sur un joueur désactive son champ de texte) et `test/screens/game_screen_test.dart` (vérifie qu'un tap sur le dé pendant `isRolling` ne déclenche pas de second lancer, que le dialogue de victoire s'affiche à la fin d'une partie mockée avec un `GameController` déjà en `isGameOver`). Utilise `mockito`/`mocktail` pour simuler `SettingsService`/`StatsService` sans dépendre de `SharedPreferences` réel dans les tests. Critère de validation : `flutter test test/screens/` passe et couvre au moins les deux scénarios décrits ci-dessus par écran.

#### 77. Golden tests pour BoardPainter (Impact: Moyen · Effort: Moyen)
**Pourquoi :** `BoardPainter` génère un rendu custom complexe (plateau à main levée, serpents stylés par thème) ; une régression visuelle silencieuse (ex. mauvaise couleur après un refactor de `BoardTheme`) ne serait détectée par aucun test actuel.

**Prompt d'implémentation :**
> Ajoute `test/widgets/board_painter_golden_test.dart` utilisant `matchesGoldenFile` pour chacun des 4 thèmes (`classic`, `neon`, `nature`, `colorblind`) sur `BoardLayout.classic`, générant les images de référence dans `test/goldens/` via `flutter test --update-goldens`. Ajoute un cas supplémentaire sur un `BoardLayout` custom avec beaucoup de bonus/malus pour couvrir le rendu des labels. Documente dans `analysis_options.yaml`/README de test comment régénérer les goldens après un changement volontaire de rendu. Critère de validation : modifier volontairement une couleur de `BoardTheme.classic` fait échouer le golden test correspondant avec un diff d'image visible.

#### 78. Pipeline CI (GitHub Actions) (Impact: Élevé · Effort: Faible)
**Pourquoi :** Aucune intégration continue actuellement (pas de dépôt git même) — chaque régression n'est détectée que manuellement.

**Prompt d'implémentation :**
> Une fois le projet dans un dépôt git (à initialiser), ajoute `.github/workflows/ci.yml` qui, à chaque push/PR : installe Flutter (action `subosito/flutter-action`, version épinglée à celle du projet), lance `flutter pub get`, `flutter analyze --fatal-infos`, et `flutter test`. Ajoute un job séparé `flutter build apk --debug` pour vérifier que le build ne casse pas (sans signer). Critère de validation : une pull request introduisant une erreur d'analyse ou un test cassé fait échouer le workflow CI visible dans l'onglet "Checks" de la PR.

#### 79. Rapport de couverture de code (Impact: Faible · Effort: Faible)
**Pourquoi :** Complète la CI (#78) en rendant visible objectivement les zones non testées, en particulier après l'ajout des tests #75/#76/#77.

**Prompt d'implémentation :**
> Dans le workflow CI (#78), lance `flutter test --coverage` puis génère un rapport HTML (`lcov`/`genhtml`) ou upload `coverage/lcov.info` vers Codecov via son action GitHub. Ajoute un badge de couverture dans le README du projet. Fixe un seuil minimal (ex. échec si couverture globale < 40% au départ, à relever progressivement) via l'action `codecov` configurée avec `fail_ci_if_error`/seuils. Critère de validation : le badge de couverture dans le README reflète un pourcentage cohérent avec `coverage/lcov.info`, et une PR faisant chuter la couverture sous le seuil est marquée en échec.

#### 80. Tests d'intégration end-to-end (Impact: Moyen · Effort: Élevé)
**Pourquoi :** Valide un parcours complet réel (lancement app → setup → partie → victoire) sur un appareil/émulateur, ce qu'aucun test unitaire/widget isolé ne couvre.

**Prompt d'implémentation :**
> Ajoute le package `integration_test`, crée `integration_test/full_local_game_test.dart` qui pilote l'app depuis `AppEntryScreen` : passe l'onboarding, va sur "Jouer en local", configure 2 joueurs, lance la partie, tape sur le dé en boucle jusqu'à victoire (avec un timeout raisonnable et éventuellement un `BoardLayout` de test à faible nombre de cases pour accélérer), vérifie que le dialogue de victoire apparaît. Exécute-le en CI (#78) via `flutter test integration_test/ -d <device>` sur un émulateur Android headless. Critère de validation : le test complet passe de façon reproductible en CI en moins de 2 minutes, sans intervention manuelle.

#### 81. Linting strict supplémentaire (Impact: Faible · Effort: Faible)
**Pourquoi :** `analysis_options.yaml` n'utilise probablement que le set par défaut de `flutter_lints` ; des règles plus strictes attrapent des bugs tôt (imports inutilisés, `unawaited` manquants déjà partiellement traités manuellement dans le code actuel).

**Prompt d'implémentation :**
> Étends `analysis_options.yaml` avec des règles supplémentaires du package `lints`/`very_good_analysis` (ou une sélection manuelle) : `always_declare_return_types`, `avoid_print` (remplacé par `debugPrint`, déjà la convention du code existant — donc à faire respecter strictement), `unnecessary_await_in_return`, `prefer_final_locals`. Corrige les violations existantes révélées par `flutter analyze` après l'ajout des règles. Critère de validation : `flutter analyze` ne remonte aucune violation après la mise à jour, et la CI (#78) échoue si une nouvelle violation est introduite.

#### 82. Détection de chaînes non traduites en CI (Impact: Faible · Effort: Faible)
**Pourquoi :** Une fois l'i18n en place (#16), évite les régressions où un développeur réintroduit une chaîne française en dur au lieu d'utiliser `AppLocalizations`.

**Prompt d'implémentation :**
> Ajoute un script `tool/check_hardcoded_strings.dart` qui scanne `lib/**/*.dart` à la recherche de motifs `Text\('[^']*[à-üÀ-Ü][^']*'\)` (accents français) hors des fichiers `l10n`/générés, et échoue si des occurrences sont trouvées hors d'une liste blanche explicite (ex. les prompts/logs de debug). Ajoute ce script comme étape du workflow CI (#78) après `flutter analyze`. Critère de validation : introduire volontairement un `Text('Nouveau texte en dur')` dans un écran fait échouer le script et donc la CI.

#### 83. Tests de performance du BoardPainter (Impact: Faible · Effort: Moyen)
**Pourquoi :** `BoardPainter` recalcule des chemins "à main levée" (`_wobblyRectPath`) et des courbes de serpent à chaque repaint ; sur bas de gamme, ça peut saccader les animations de déplacement.

**Prompt d'implémentation :**
> Ajoute un test de performance (`flutter test --profile` ou un benchmark custom avec `Stopwatch` autour de `BoardPainter.paint` appelé directement sur un `Canvas` de test/`PictureRecorder`) mesurant le temps de rendu d'une frame sur `BoardLayout.classic`. Si le temps dépasse un budget (ex. 8ms pour viser 120fps, 16ms pour 60fps), envisage de mettre en cache les `Path` de cases/serpents (ils ne changent que si `layout`/`theme` changent, pas à chaque frame de déplacement de pion) via un `shouldRepaint` plus fin ou un `Picture` pré-rendu. Critère de validation : le temps de rendu mesuré d'une frame reste sous le budget cible sur l'environnement de test CI, avec une alerte si une régression future le fait dépasser.

#### 84. Changelog automatique (Impact: Faible · Effort: Faible)
**Pourquoi :** Une fois un dépôt git en place, formalise l'historique des changements pour les utilisateurs (#50) et les développeurs.

**Prompt d'implémentation :**
> Adopte la convention "Conventional Commits" (`feat:`, `fix:`, `chore:`...) pour les messages de commit futurs. Ajoute un outil (`conventional-changelog` ou l'action GitHub `release-please`) qui génère/maintient automatiquement un `CHANGELOG.md` à la racine et propose des pull requests de version à chaque merge sur la branche principale. Relie ce changelog au contenu affiché dans l'écran "Nouveautés" (#50) pour éviter la duplication manuelle. Critère de validation : merger un commit `feat: ajoute le mode tournoi` sur la branche principale met à jour automatiquement `CHANGELOG.md` avec cette entrée lors du prochain cycle de release.

---

## 8. Plateforme, distribution & intégrations OS

#### 85. Layout adaptatif tablette/desktop complet (Impact: Moyen · Effort: Moyen)
**Pourquoi :** `GameScreen` gère déjà un layout large (`isWide` dans `_buildBoard`/`LayoutBuilder`) mais les autres écrans (`SetupScreen`, `CampaignScreen`, `StatsScreen`) restent contraints à `maxWidth: 440-480`, sous-exploitant l'espace sur tablette/desktop.

**Prompt d'implémentation :**
> Audite chaque écran utilisant `ConstrainedBox(constraints: BoxConstraints(maxWidth: ...))` et remplace par un layout à deux colonnes au-delà d'un seuil de largeur (ex. `LayoutBuilder` avec `constraints.maxWidth > 900` → panneau de navigation latéral persistant + contenu, façon layout "master-detail"). Vérifie particulièrement `CampaignScreen` (grille de niveaux qui pourrait afficher plusieurs mondes côte à côte) et `SetupScreen` (formulaire + aperçu du plateau simultanés). Critère de validation : sur une fenêtre desktop de 1200px de large, au moins 3 écrans exploitent l'espace supplémentaire au lieu de rester centrés dans une colonne étroite avec du vide de chaque côté.

#### 86. Mode multi-fenêtre foldables (Impact: Faible · Effort: Élevé)
**Pourquoi :** Différenciation sur les appareils pliables (Galaxy Fold, Pixel Fold) de plus en plus courants.

**Prompt d'implémentation :**
> Utilise le package `flutter_displaymode`/`dual_screen` (ou les APIs Jetpack WindowManager via un plugin) pour détecter un pli d'écran (`MediaQuery` hinge info si disponible) et adapter `GameScreen` pour afficher le plateau sur un panneau et les contrôles/chat sur l'autre en configuration dépliée. Doit se dégrader proprement (comportement actuel inchangé) sur tout appareil non pliable. Critère de validation : sur un émulateur configuré en mode pliable (Android Studio propose des profils foldables), l'app détecte le pli et réorganise l'affichage sans crasher sur un appareil non pliable classique.

#### 87. Raccourcis d'application (Impact: Faible · Effort: Faible)
**Pourquoi :** Accès rapide depuis l'icône de l'app (appui long) directement vers "Défi du jour" ou "Partie rapide", sans passer par `HomeModeScreen`.

**Prompt d'implémentation :**
> Ajoute `quick_actions` (cross-platform App Shortcuts/Quick Actions), déclare 2 raccourcis statiques ("Défi du jour", "Partie rapide en local") dans `main.dart` via `QuickActions().initialize(...)`, chacun naviguant directement vers l'écran correspondant en contournant `HomeModeScreen` au démarrage. Gère le cas où l'app est lancée froide depuis un raccourci (vérifier l'action initiale au lancement, pas seulement les callbacks à chaud). Critère de validation : un appui long sur l'icône de l'app affiche les 2 raccourcis, et les sélectionner ouvre directement le bon écran même si l'app était complètement fermée.

#### 88. Badge d'icône pour tour en attente (Impact: Faible · Effort: Moyen)
**Pourquoi :** Complète le mode asynchrone (#42)/notifications (#41) par un indicateur visuel discret sur l'icône même sans ouvrir la notification.

**Prompt d'implémentation :**
> Utilise `flutter_app_badger` (ou l'équivalent maintenu actuel) pour afficher un badge numérique sur l'icône de l'app égal au nombre de parties asynchrones où c'est le tour du joueur (calculé depuis les documents `rooms` où il est membre et `currentPlayerIndex` pointe vers lui). Met à jour le badge à chaque changement pertinent reçu via FCM en arrière-plan (background handler) ou à chaque ouverture de l'app. Critère de validation : avoir 2 parties asynchrones en attente de son tour affiche "2" sur l'icône de l'app sur l'écran d'accueil du téléphone.

#### 89. Partage social enrichi avec image générée (Impact: Faible · Effort: Faible)
**Pourquoi :** `_shareResult` dans `GameScreen` ne partage actuellement que du texte brut ; une image est bien plus engageante sur les réseaux sociaux.

**Prompt d'implémentation :**
> Réutilise l'approche de la fiche joueur (#62) mais orientée résultat de partie : capture le plateau final avec les pions (`RepaintBoundary` sur `_buildBoard` au moment de la victoire) superposé d'un bandeau "🏆 {vainqueur} a gagné !", et partage ce fichier image via `SharePlus.instance.share(ShareParams(files: [...], text: ...))` au lieu du seul `text` actuel. Critère de validation : le partage déclenché depuis le dialogue de victoire propose une image du plateau final dans l'aperçu de partage, pas seulement le texte actuel.

#### 90. Invite à noter l'application (Impact: Faible · Effort: Faible)
**Pourquoi :** Sollicite un avis store au bon moment (après une victoire, pas au hasard) pour maximiser les notes positives.

**Prompt d'implémentation :**
> Ajoute `in_app_review`, déclenche `InAppReview.instance.requestReview()` après une condition de satisfaction probable (ex. 3e victoire d'une session, ou juste après un succès débloqué dans `GameScreen._handleGameOver`), avec un compteur (`SettingsService`) empêchant de redemander avant 30 jours ou après un premier refus explicite. Ne jamais afficher si l'utilisateur vient de vivre une défaite de campagne. Critère de validation : la demande d'avis natif n'apparaît jamais deux fois dans les 30 jours suivant un premier déclenchement, vérifiable en forçant la condition deux fois de suite en test.

#### 91. Vérification de mise à jour disponible (Impact: Faible · Effort: Faible)
**Pourquoi :** Encourage la mise à jour vers les dernières fonctionnalités/correctifs sans attendre la mise à jour automatique du store.

**Prompt d'implémentation :**
> Sur Android, ajoute `in_app_update`, vérifie au démarrage (`AppEntryScreen`) si une mise à jour flexible est disponible via `InAppUpdate.checkForUpdate()`, et propose-la avec `startFlexibleUpdate`. Sur iOS (pas d'équivalent natif), compare simplement la version de `PackageInfo` à une valeur minimale lue depuis Remote Config (#51) et affiche un bandeau non bloquant "Une nouvelle version est disponible" avec un lien vers l'App Store. Critère de validation : publier une version supérieure sur une piste de test Android Play Console déclenche bien la proposition de mise à jour flexible au prochain lancement de l'app sur cette piste.

#### 92. Compagnon Wear OS (Impact: Faible · Effort: Élevé)
**Pourquoi :** Fonctionnalité de différenciation forte mais coûteuse — permet de voir/déclencher son tour depuis la montre pendant une partie de groupe.

**Prompt d'implémentation :**
> Crée un module Wear OS séparé (projet Android natif dans `android/wear/`, communiquant avec l'app téléphone via l'API `Wearable` Data Layer) affichant uniquement : de qui c'est le tour, et un bouton "Lancer le dé" actif si `canLocalPlayerRoll` (état répliqué depuis `GameController` via un canal `MethodChannel`/`EventChannel` custom vers le module Wear). Limite le scope à la lecture/déclenchement, aucune UI de plateau sur la montre. Critère de validation : sur une montre Wear OS appairée, le bouton "Lancer le dé" s'active/désactive en cohérence avec le tour réel de la partie en cours sur le téléphone.

#### 93. Support clavier physique complet (Impact: Faible · Effort: Faible)
**Pourquoi :** Utile sur desktop/tablette avec clavier — actuellement tout est pensé tactile uniquement.

**Prompt d'implémentation :**
> Ajoute un `Focus`/`Shortcuts`+`Actions` au niveau de `GameScreen` : barre d'espace ou Entrée déclenche `_controller.rollDice()` si `canLocalPlayerRoll`, Échap ouvre le menu pause (`_openPauseMenu`), flèches gauche/droite naviguent dans un futur historique d'événements. Vérifie que ça ne rentre pas en conflit avec la saisie de texte du chat (`ChatPanel`) quand celui-ci a le focus. Critère de validation : sur un appareil desktop/tablette avec clavier connecté, appuyer sur Espace lance le dé quand c'est le tour du joueur local, sans effet quand le champ de chat a le focus.

#### 94. Optimisation de la taille de l'application (Impact: Faible · Effort: Faible)
**Pourquoi :** Le projet a accumulé de nombreuses dépendances (Firebase, sensors_plus, image_picker, dynamic_color...) ; certaines pourraient être inutilisées sur certaines plateformes ou trop larges pour ce qu'elles apportent.

**Prompt d'implémentation :**
> Lance `flutter build appbundle --analyze-size` (Android) et l'équivalent iOS pour identifier les plus gros contributeurs à la taille de l'app. Vérifie l'usage réel de chaque dépendance de `pubspec.yaml` (recherche des imports) pour détecter des packages ajoutés puis jamais utilisés. Active le "app bundle" avec des APK splits par ABI si pas déjà fait pour Android. Documente les résultats et actions prises dans un commentaire de `pubspec.yaml` ou une note de release. Critère de validation : la taille de téléchargement de l'app (mesurée via `--analyze-size` ou la Play Console) diminue mesurablement par rapport à la version précédente, sans perte de fonctionnalité.

---

## 9. Confidentialité, conformité & support

#### 95. Politique de confidentialité + CGU intégrées (Impact: Élevé · Effort: Faible)
**Pourquoi :** Obligatoire pour toute publication sur les stores dès que l'app collecte des données (comptes #28, analytics #72, notifications #41) — actuellement rien n'existe.

**Prompt d'implémentation :**
> Rédige (ou fais rédiger juridiquement) une politique de confidentialité et des CGU couvrant les données réellement collectées (analytics, compte, photos locales, notifications). Héberge-les en HTML statique (ex. GitHub Pages ou Firebase Hosting) et ajoute un lien dans `SettingsScreen` (`ListTile` supplémentaire) ouvrant l'URL via `url_launcher`. Ajoute aussi les liens requis dans les fiches Play Store/App Store Connect. Critère de validation : le lien "Politique de confidentialité" dans les Réglages ouvre bien un document à jour reflétant les fonctionnalités actuellement actives de l'app.

#### 96. Bandeau de consentement RGPD (Impact: Élevé · Effort: Moyen)
**Pourquoi :** Nécessaire dès l'ajout d'Analytics (#72) ou de notifications de réactivation (#49) pour les utilisateurs situés dans l'UE.

**Prompt d'implémentation :**
> Ajoute un écran de consentement affiché une fois après `OnboardingScreen` (avant `HomeModeScreen`) uniquement si la localisation détectée (ou simplement systématiquement, par prudence) l'exige : deux toggles distincts "Autoriser les statistiques d'usage anonymes" / "Autoriser les notifications". Ne configure `firebase_analytics`/les notifications qu'après acceptation explicite (`FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(consent)`). Permet de revenir modifier ce choix depuis `SettingsScreen` à tout moment. Critère de validation : refuser le consentement analytics au premier lancement fait qu'aucun événement `game_started`/`game_finished` (#72) n'est envoyé, vérifiable en DebugView Firebase.

#### 97. Écran d'aide/FAQ + formulaire de retour (Impact: Moyen · Effort: Faible)
**Pourquoi :** Aucun canal de support/feedback structuré actuellement au-delà de l'avis store.

**Prompt d'implémentation :**
> Ajoute un écran `HelpScreen` accessible depuis `SettingsScreen` avec des `ExpansionTile` de FAQ statique (règles du jeu, résolution des soucis Bluetooth fréquents — réutilise le contenu déjà écrit dans `BluetoothLobbyScreen._buildErrorCard`). En bas, un formulaire simple (texte + email optionnel) qui envoie le retour via un email pré-rempli (`url_launcher` avec un lien `mailto:`) ou une fonction Cloud Function légère écrivant dans `feedback/{autoId}`. Critère de validation : soumettre le formulaire de retour crée bien une entrée consultable (email ouvert avec le bon contenu, ou document Firestore créé) sans jamais faire planter l'app si l'appareil n'a pas de client mail configuré.

#### 98. Contrôle parental (Impact: Moyen · Effort: Moyen)
**Pourquoi :** Le jeu ciblant potentiellement les enfants (avatars ludiques, campagne), les modes en ligne/chat avec inconnus (#31/#34) méritent un verrou parental optionnel.

**Prompt d'implémentation :**
> Ajoute dans `SettingsScreen` une section "Contrôle parental" protégée par un code PIN à 4 chiffres défini une première fois (stocké haché via `crypto`/SHA-256, jamais en clair). Une fois activé, masque les cartes "En ligne"/"Bluetooth" de `HomeModeScreen` et désactive l'accès au chat, sauf saisie correcte du PIN pour déverrouiller temporairement. Critère de validation : avec le contrôle parental activé, la carte "En ligne" n'apparaît plus dans `HomeModeScreen` tant que le PIN correct n'a pas été saisi dans l'écran de déverrouillage dédié.

#### 99. Export/suppression des données personnelles (Impact: Élevé · Effort: Moyen)
**Pourquoi :** Droit RGPD à la portabilité/à l'oubli, obligatoire dès qu'un compte (#28) et des données cloud (#29) existent.

**Prompt d'implémentation :**
> Ajoute dans `SettingsScreen` (section compte) deux actions : "Exporter mes données" (regroupe toutes les données Firestore liées à l'UID — profil, stats, campagne, historique de chat envoyé — en un fichier JSON téléchargeable, via une Cloud Function callable `exportUserData`) et "Supprimer mon compte" (Cloud Function `deleteUserData` qui supprime `users/{uid}` et anonymise ses messages dans les salons partagés, puis `AuthService.currentUser.delete()`). Demande une double confirmation avant suppression définitive. Critère de validation : déclencher la suppression de compte fait disparaître toutes les données liées à cet UID de Firestore (vérifiable côté console) et déconnecte immédiatement l'utilisateur de l'app.

#### 100. Support in-app avec logs de diagnostic (Impact: Faible · Effort: Faible)
**Pourquoi :** Complète le formulaire de retour (#97) par un canal technique plus riche pour diagnostiquer les bugs réseau (Bluetooth/Firestore) déjà partiellement gérés défensivement dans le code actuel.

**Prompt d'implémentation :**
> Ajoute un bouton "Signaler un problème" dans `HelpScreen` (#97) qui collecte automatiquement : version de l'app (`PackageInfo`), plateforme/OS, et les 50 dernières lignes de logs applicatifs pertinents (centralise les `debugPrint` existants du projet — `GameController`, `NearbyTransport`, `FirestoreTransport` — dans un `AppLogger` en mémoire à buffer circulaire au lieu de `debugPrint` brut). Joint ce contexte en pièce jointe texte à l'email de support (`mailto:` avec pièce jointe non supportée nativement — bascule vers un envoi via Cloud Function/`http` si une pièce jointe est nécessaire, sinon inclut les logs dans le corps du mail). Critère de validation : signaler un problème après une déconnexion Bluetooth simulée inclut bien dans le rapport les logs `NearbyTransport` pertinents entourant l'incident, sans exposer de données personnelles d'autres joueurs.

---

## Comment utiliser ce document

1. Trie les fonctionnalités par **Impact/Effort** pour construire une roadmap (privilégier Impact élevé / Effort faible en premier : #16 i18n, #43 streaks, #71 Crashlytics, #78 CI, #95 politique de confidentialité).
2. Certaines fonctionnalités sont des **prérequis** d'autres (ex. #28 Comptes est nécessaire à #29, #30, #32, #99 ; #65 Règles Firestore devrait précéder toute ouverture au public comme #31/#34). Les prompts le mentionnent explicitement quand c'est le cas.
3. Pour implémenter une fonctionnalité, copie tel quel son "Prompt d'implémentation" dans une session Claude Code à la racine du projet — il contient déjà les fichiers concernés et le critère de validation attendu.
4. Ce backlog doit être relu/mis à jour à mesure que le code évolue : les chemins de fichiers cités reflètent l'état du projet au 2026-09-06.
