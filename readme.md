# daydrainOS

**daydrainOS** est un système d’exploitation personnalisé pour [OpenComputers](https://www.curseforge.com/minecraft/mc-mods/opencomputers) (et [OpenComputers: Rebooted](https://github.com/PC-Logix/OpenComputers) également à present), basé sur [LiskelOS](https://github.com/cyntachs/LiskelOS).  
Ce projet est dédié à mon frère **Daydrain**, contre qui je dois protéger ma base ! 🛡️🏰

---

## 🎯 Objectif

Développer un OS sécurisé et robuste pour gérer et protéger ma base Minecraft, tout en restant léger et modulable.  
**daydrainOS** est conçu pour :

- 💣 Résister aux intrusions coûte que coûte  
- 🔒 Offrir un contrôle précis des accès  
- ⚡ Être rapide et facile à maintenir  

---

## 🚀 Fonctionnalités principales

- [x] 💥 Système de **tourelles automatiques** (OpenSecurity)  
- [x] 🚪 Système de **portes automatiques** (OpenSecurity)  
- [x] 🛗 Système **d'ascenseur automatique** (Thut's Elevators)  
- [x] 🚨 Système **d'alarme automatique** (OpenSecurity)  
- [x] 🔦 Système **d’éclairage automatique** (OpenLights)  
- [ ] 📦 Système de **gestion du stockage** (Applied Energistics 2)  
- [x] ⚡ Système de **gestion de la production d’énergie** (Extreme Reactors)  (Draconic Evolution)  
- [x] 🕳️ Système de **protection anti-tunnel** (OpenSecurity)  
- [x] 🌱 Système de **Production de ressources** :
  - [x] 🌾🥔🥕🍠 Champs classiques (9×9) 
  - [x] 🍉 Champs en ligne
    - [x] 🍉 Melon  
    - [x] 🎃 Citrouille  
    - [x] 🎋 Sugar Cane  
    - [ ] 🟫 Cocoa Beans  
    - [ ] 🌵 Cactus 
  - [ ] 🐄 Fermes animales
    - [ ] 🐄 Vaches  
    - [ ] 🐑 Moutons  
    - [ ] 🐔 Poulets  
    - [ ] 🐖 Cochons  
  - [ ] ⛏️ Mine
  - [ ] 🌳 Tree farm
- [ ] 🪖 Système **d’armée de drones**  

---

## 💡 Installation

### En 1.12.2:

1. Télécharger ou cloner le dépôt  
2. Utiliser [OpenDisks](https://legacy.curseforge.com/minecraft/mc-mods/opendisks) pour charger le dossier dans une disquette en jeu  
3. Suivre la procédure de démarrage.

### En 1.21.1:

pour [OpenComputers: Rebooted](https://github.com/PC-Logix/OpenComputers)

1. Se rendre dans le dossier `datapacks` de votre monde (voir [ici](https://minecraft.wiki/w/Tutorial:Creating_a_data_pack) si besoin est)
2. Créer un dossier et y entrer (ex : `mkdir DaydrainOS && cd DaydrainOS/`)
3. Créer un fichier `pack.mcmeta` et y écrire :

```json
{
  "pack": {
    "pack_format": 48,
    "description": "Daydrain OS datapack"
  }
}
```

4. Créer le répertoire `data/daydrainos/opencomputers/loot_disks` et y entrer (ex: `mkdir -P data/daydrainos/opencomputers/loot_disks`)

5. Créer un fichier `daydrainos.json` et y écrire :

```json
{
  "label": "Daydrain OS",
  "color": "cyan",
  "weight": 1,
  "recipe_cycling": true
}
```

6. Cloner le dépôt dans un nouveau dossier à créer : `daydrainos` (ex: `git clone https://github.com/Grahmindol/DaydrainOS.git daydrainos`)

7. En jeu, éxecuter `/reload` et suivre la procédure de démarrage.

---

## 🔧 Procédure de démarrage

1. Démarrer **l’ordinateur central** avant tout autre appareil :
   - Il doit être équipé d’un **écran** et d’une **carte graphique**
   - Il doit être connecté au **réseau**
2. Démarrer ensuite chaque **esclave**, un par un.

Chaque esclave détecte automatiquement son rôle au démarrage, selon les **périphériques connectés**.

### 📦 Configuration des esclaves

| Type d'esclave | Périphériques requis |
|----------------|----------------------|
| Contrôleur de porte | Porte (DoorController ou RollingDoor), clavier (Keypad), lecteur de carte magnétique, RFID, lecteur biométrique |
| Alarme | Sirène + écran |
| Éclairage | Lumières (OpenLights) + écran |
| Réacteur | Réacteur/turbine (Extreme Reactors) + écran |
| Détection d’intrusion | Détecteur de mouvement + NanoFog ou tourelle (juxtaposée au-dessus) |
| Serveur central | Écran + graveur de cartes + lecteur biométrique |

🛜 **Tous les ordinateurs doivent être en réseau et équipés d’une carte Data tier III.**

---

# Utilisation de l'IA

- Des LLM sont utilisés en tant que moteur de recherche, correcteur orthographique et traducteur.
- Les LLM ne sont jamais utilisés pour aluciner du code. Ce ne sont que des perroquets stochastiques qui sont vu et utilisés comme tel.
- Greenpaece à raison : https://www.greenpeace.org/international/story/82486/ai-energy-environment-democracy/

---

Made with ❤️ and vengeance.

Under MIT Licence.

