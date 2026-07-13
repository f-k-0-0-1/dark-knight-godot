# 🎮 Dark Knight

A 2D action-platformer built from scratch using Godot Engine.

Dark Knight is one of the projects I created during my earlier game development journey. After stepping away from development for some time, I have returned to continue learning, building, and improving my technical skills. This project marks an important milestone in that journey and will continue to evolve as I grow as a developer.

---

## 📖 About The Game

Dark Knight is a side-scrolling action platformer set in a dark fantasy world.

Players control a mysterious knight, battle enemies, explore the environment, and now **team up with friends** in a fully functional multiplayer experience. The game features advanced combat mechanics, a complete shop system, weapon progression, and a variety of visual effects that bring the world to life.

---

## ✨ Current Features

### Core Gameplay
* 🎮 Built entirely in Godot Engine
* ⚔️ 2D action-platformer mechanics
* ❤️ Health and life system with Bonus Heart upgrades
* 🌲 Forest and dark fantasy themed environments
* 📋 Main menu, Level Select, and Credits screens
* ⌨️ Keyboard controls and Cheat Command system
* 🧙 God Mode for testing and experimentation

### Combat & Abilities
* **Sword Combat:** 3-hit combo system (Slash 1 → Slash 2 → Multi-Slash)
* **Fireball Ability:** Ranged projectile attack with cooldown
* **Lightning Ball Ability:** AOE burst damage with a 5-second follow-up and damage cap (500 total)
* **Multiple Enemy Types:** Flying Demons, Slimes, and Shardsouls (tanky mini-bosses)
* **Advanced Enemy AI:** State machines (Patrol, Chase, Attack, Hurt, Death), hit-stun, and invulnerability frames
* **Hit Feedback:** Enemies flash, play hurt animations, and receive camera shake on hit

### Multiplayer System (NEW!)
* **Lobby System:** Role selection popup (Host/Client)
* **WebSocket Networking:** Direct peer-to-peer connections using Godot's `WebSocketPeer`
* **Cloudflare Tunneling:** Automatic generation and sharing of public URLs via `cloudflared`
* **Real-time Player Sync:** Position, animation, and flip state synced at 20Hz
* **Remote Player Spawning:** Seamless spawning and despawn of remote players
* **Chat System:** In-game chat overlay with player name persistence
* **Host-Only Controls:** Level selection and game start restricted to the host
* **5-Second Countdown:** Visual countdown before level launch

### Shop & Weapon Progression (NEW!)
* **Modular Weapon System:** Each weapon type (Sword, Axe, Hoe, Pickaxe, Shovel) has 6 material tiers: Wooden, Stone, Iron, Gold, Diamond, Netherite
* **Dynamic Shop UI:** Items categorized by type, with buy/equip/equipped states
* **Persistent Inventory:** Saved to disk via `ConfigFile` (inventory_data.ini)
* **Visual Feedback:** Clicking `Buy` updates the shop card dynamically
* **ItemData Resource System:** All weapons are data-driven via `.tres` files

### Visual Effects & Polish
* **Dynamic Camera Shake:** Procedural decay-based shake on hits, jumps, and deaths
* **Cinematic Portal Effect:** Screen-warping shader on level transitions
* **Animated Stars:** Level Complete screen with 3-star rating based on speed
* **Ambient Glow Particles:** Floating magical particles in the environment
* **Parallax & Vignette Effects:** Depth and focus for the Credits scene
* **Smooth Camera Zoom:** 3-stage zoom toggle (2x, 5x, 8x)
* **UI Animations:** Button scaling, star pop-ins, and countdown text bouncing

### UI & HUD
* **Real-time Timer:** Tracks level completion time
* **Coins & Currency:** Level coins + persistent global wallet
* **Cooldown Bars:** Visual feedback for Lightning Ball cooldowns
* **Dynamic HUD:** Health bars, star ratings, and best-time tracking
* **Name Persistence:** Popup on first launch to set player name

---

## 👾 Enemies

### Flying Demon
A flying enemy that attacks the player from the air. Features a 3-state AI (Idle, Chase, Attack) and hit-stun mechanics.

### Slime
A ground-based enemy that patrols the environment and challenges the player.

### Shardsoul
A tanky, tough enemy designed as a mini-boss. Requires strong weapon upgrades to defeat.

---

## 🧙 God Mode

Dark Knight includes a special God Mode for experimentation and exploration.

When activated, the player becomes:
* Invincible to enemy attacks
* Able to float freely through the map
* Unrestricted by normal movement limitations

---

## 🎮 Controls

| Action           | Key       |
| ---------------- | --------- |
| Move Left        | A         |
| Move Right       | D         |
| Jump             | W / Space |
| Fireball         | F / Enter |
| Lightning Ball   | Q         |
| Sword Attack     | Left Click / J |
| God Mode         | G         |
| Sprint           | Shift     |
| Menu             | Esc       |
| Cheat Commands   | ` (Backtick) |

---

## 🛠️ Built With

* Godot Engine 4.6.2
* GDScript
* Cloudflare Tunnel (`cloudflared`)
* WebSocket Networking

---

## 📸 Screenshots

<img width="1672" height="941" alt="image" src="https://github.com/user-attachments/assets/1cc45f5c-2886-40f5-9806-977b5342e411" />
<img width="1670" height="942" alt="image" src="https://github.com/user-attachments/assets/6d2b5e69-a521-4c50-a556-a32d64585a61" />
<img width="1672" height="941" alt="image" src="https://github.com/user-attachments/assets/fc8f4ab4-3897-4161-822b-5c51fe56b29c" />
<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/1f338594-43d9-443a-afa0-4246a231fce1" />

---

## 🚀 Future Development

Dark Knight is an active learning project and will continue receiving updates.

**Planned improvements include:**
- 🧟 Boss battles and scripted events
- 🔊 Full sound effects and orchestral background music
- 🏆 Achievements and speedrun tracking
- 🎨 Enhanced particle systems for abilities
- 📦 Inventory management and equipment stats
- 🌍 Procedurally generated levels
- 🧠 Advanced enemy AI with cooperative behaviors
- 🕹️ Controller support
- 🖥️ UI scaling and accessibility options

---

## 💡 Why This Project Matters

Dark Knight represents more than just a game.

It is one of the projects I built independently while learning game development and problem-solving through code. Revisiting and improving this project marks my return to building things, learning new technologies, and pursuing my passion for development.

Every future update to this project will reflect the progress I make as a developer.

---

## ⭐ Support

If you found this project interesting, consider starring the repository and following my journey as I continue building new projects and exploring technology.

Happy coding! 🚀
