# daydrainOS

**daydrainOS** est un système d’exploitation personnalisé pour [OpenComputers](https://www.curseforge.com/minecraft/mc-mods/opencomputers), basé sur [LiskelOS](https://github.com/cyntachs/LiskelOS).  
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

- [x] Système de **tourelles automatiques** (OpenSecurity)  
- [x] Système de **portes automatiques** (OpenSecurity)  
- [x] Système **d'ascenseur automatique** (Thut's Elevators)  
- [x] Système **d'alarme automatique** (OpenSecurity)  
- [x] Système **d’éclairage automatique** (OpenLights)  
- [ ] Système de **gestion du stockage** (Applied Energistics 2)  
- [x] Système de **gestion de la production d’énergie** (Extreme Reactors)  
- [ ] Système de **gestion du stockage d’énergie** (Draconic Evolution)  
- [x] Système de **protection anti-tunnel** (OpenSecurity)  
- [ ] Système **d’armée de drones**  

---

## 💡 Installation

1. Télécharger ou cloner le dépôt  
2. Utiliser [OpenDisks](https://legacy.curseforge.com/minecraft/mc-mods/opendisks) pour charger le dossier dans une disquette en jeu  
3. Suivre la procédure de démarrage :

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

Made with ❤️ and vengeance.
