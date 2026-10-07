# Cultivation Roblox Game — Version 1 Roadmap

Oct 7, 2026 · @brexcel

## Goal of version 1

Version 1 answers one question: after a new player reaches their first major breakthrough, do they want to keep cultivating? Everything in this roadmap serves that test, and nothing else gets built yet.

Target: about 8 weeks of part-time work (an estimate; adjust around school). V1 is done when all of these are true:

- [ ] A brand-new player reaches Foundation Establishment in 30–45 minutes of play
- [ ] At least half of 5–10 testers keep cultivating after the breakthrough without being asked
- [ ] Progress saves and loads correctly across rejoins, with zero data-loss reports
- [ ] Qi, breakthroughs, and rewards are server-authoritative, so a client cannot grant itself progress
- [ ] Testers can describe the hidden cave moment to someone else without prompting

## V1 scope

V1 is a solo-playable "first breakthrough" slice: one region, two cultivation methods, three realms, one tribulation, one hidden cave. Sects, beasts, and PvP wait until this loop proves fun.

| Area | In V1 | Out of V1 (later) |
| --- | --- | --- |
| World | One small region: spawn valley, forest, waterfall, cliff | Large map, multiple regions, territory |
| Realms | Mortal → Qi Condensation → Foundation Establishment | Core Formation and above |
| Cultivation | Passive meditation (slow, AFK-safe) and one active Qi circulation minigame (faster when done well) | Body tempering, combat cultivation, forbidden cultivation, sect formations |
| Breakthrough | One dramatic tribulation that can fail, with sky, lightning, and aura VFX | Multiple tribulation types, protection talismans |
| Exploration | One hidden cave behind the waterfall, found through clues, holding one technique | Rotating caves, secret realms, inheritance trials |
| Techniques | Basic Qi Gathering plus one cave technique that changes the circulation pattern | Technique library, builds |
| Social | Players see each other's realm, title, and aura; server message on breakthrough | Sects, ranks, personal disciples, trading |
| Data | Saves realm, Qi, technique, cave discovered | Inventory, beasts, economy |
| Platform | PC and mobile controls for the minigame | Console |
| Excluded entirely | — | Spirit beasts, PvP, monetization, Heavenly Core system, UGC |

## Everything you need

Almost everything here is free; the only real cost is a Claude plan that includes Claude Code. Install in the order listed.

| Item | What it's for | Cost |
| --- | --- | --- |
| PC (Windows or macOS), 16 GB RAM recommended | Running Roblox Studio, Blender, and Claude Code together | Already have |
| Roblox account + latest Roblox Studio | Building, testing, publishing the game | Free |
| Claude plan with Claude Code | Primary builder: Luau, architecture, debugging via MCP | Paid subscription |
| Blender (latest stable) | Props, cave, shrine, aura meshes | Free |
| Git + GitHub account (private repo) | Version history, rollback when AI breaks something | Free |
| VS Code + Luau LSP extension | Reading and fixing generated code | Free |
| Rokit (toolchain manager) + Rojo | Syncs code from your repo into Studio so code lives in Git | Free |
| Node.js (LTS) | Running `npx skills add` installs | Free |
| Python + uv | Running `uvx blender-mcp` | Free |
| ProfileStore library | Safe player data saving (do not hand-roll DataStore code) | Free |
| Gemini (Google AI Pro Student) | Design critique, balance review, screenshot QA | Already have |
| 5–10 testers + a small Discord server | Playtests and feedback | Free |
| Design doc (your session summary) | Source of truth Claude reads before building | Already have |

## Claude Code skills and MCP servers

Install two MCP servers, one Roblox skill pack, and one Blender skill pack; add the animation skill only in Phase 5. Read each SKILL.md and any hook scripts before installing, since community skills can run code on your machine.

| Name | Type | What it does for you | How to install | When |
| --- | --- | --- | --- | --- |
| [Roblox Studio MCP (official)](https://create.roblox.com/docs/en-us/studio/mcp) | MCP | Lets Claude read the DataModel, edit scripts, run Luau, and control playtests | Studio: Assistant panel → turn on "Enable Studio as MCP server" → quick connect Claude Code | Phase 0 |
| [Blender MCP](https://www.mdskills.ai/mcp-servers/blender-mcp) | MCP | Lets Claude build and edit meshes in a running Blender | Install the addon in Blender, then `claude mcp add blender uvx blender-mcp` | Phase 0 |
| [dstack](https://github.com/HungryKelvin123/dstack) | Roblox skill plugin | Architecture skill for typed modules, remotes, persistence; Luau review agents | Clone the repo, then `claude --plugin-dir ./plugins/dstack` | Phase 0 |
| [luau-best-practices](https://claudemarketplaces.com/skills/dig1t/skills/luau-best-practices) | Skill | Production Luau patterns, error handling for DataStore and HTTP | `npx -y skills add dig1t/skills --skill luau-best-practices --agent claude-code` | Phase 0 |
| [blender-skills (arjun988)](https://github.com/arjun988/blender-skills) | Blender skill pack | Blockout-to-engine-export pipeline for game assets | Clone and copy the skills into your project's `.claude/skills/` | Phase 5 |
| [animate-roblox-characters](https://claudskills.com/skills/animate-roblox-characters/SKILL.md) | Skill (optional) | R15 meditation pose and breakthrough animations via Blender, exported for Roblox | Copy into `.claude/skills/`; written for Codex, expect tweaks | Phase 5 |

Alternative if dstack doesn't suit you: [roblox-game-skill](https://github.com/brockmartin/roblox-game-skill). Use one Roblox pack, not both, so their instructions don't conflict. For a reference of a finished AI-built Roblox project, read [roblox-flex-with-friends](https://github.com/bsantanna/roblox-flex-with-friends).

## Project structure and CLAUDE.md rules

Set the structure in Phase 0 and never let it drift; a clean module layout is what keeps vibe-coded projects from turning into spaghetti by week 4.

```
cultivation-game/
├── CLAUDE.md                 # rules Claude reads every session
├── default.project.json      # Rojo config
├── docs/
│   ├── design.md             # your session summary
│   └── v1-roadmap.md         # this roadmap
├── src/
│   ├── server/services/      # DataService, CultivationService, BreakthroughService, CaveService
│   ├── client/controllers/   # MeditationController, QiCirculationController, UIController
│   └── shared/
│       ├── config/           # Realms.luau, Techniques.luau, Balance.luau
│       └── remotes/          # all RemoteEvents/Functions defined in one place
└── assets/
    ├── blender/              # .blend source files
    └── exports/              # .fbx / .obj ready for Studio
```

Put these rules in CLAUDE.md:

1. Read `docs/design.md` and `docs/v1-roadmap.md` before starting any task; build only what the current phase lists.
2. The server owns all Qi, realm, breakthrough, and reward logic. Clients only send inputs and show results.
3. Validate every remote: type-check arguments, rate-limit calls, reject impossible values.
4. All player data goes through DataService using ProfileStore. Never call DataStoreService directly anywhere else.
5. Balance numbers live only in `shared/config`, never hard-coded in services.
6. Use typed Luau (`--!strict`) in every module.
7. One feature per task. After each task, playtest through Studio MCP, check the Output for errors, and report what changed.
8. Never delete or restructure folders without asking first.
9. Commit after every working feature with a clear message.

## Roadmap: 7 phases over about 8 weeks

Each phase ends with a gate; don't start the next phase until the gate passes. Week numbers assume part-time work and will stretch around exams and thesis deadlines.

### Phase 0 — Setup (week 1)

- [x] Install everything in "Everything you need" and connect both MCP servers to Claude Code
- [x] Create the private GitHub repo, Rojo project, and folder structure above
- [x] Write CLAUDE.md and copy the design doc into `docs/`
- [x] Install dstack and luau-best-practices
- [x] Ask Claude to build a hello-world: a part that changes color when touched, synced via Rojo, committed to Git

**Gate:** Claude can edit code, run a playtest through Studio MCP, and read the Output window.

Starter prompt: *"Read CLAUDE.md and docs/design.md. Using the dstack architect skill, propose the module layout and remote list for V1 only. Don't write code yet."*

### Phase 1 — Data and passive meditation (week 2)

- [x] DataService with ProfileStore: realm, Qi, technique, cave flag
- [x] Cultivate button: character sits cross-legged, Qi rises slowly on the server
- [x] Qi bar and realm label on screen
- [x] Test: leave and rejoin, Qi is still there

**Gate:** Progress survives 10 rejoins and a server shutdown.

### Phase 2 — Realms and active Qi circulation (weeks 3–4)

- [x] Realm config: Mortal, Qi Condensation, Foundation Establishment with Qi thresholds
- [x] Active circulation minigame: follow the meridian path (head, arms, core, dantian) with PERFECT/GREAT timing and a combo multiplier
- [x] Active done well should be about 3–5× faster than passive (tune in Balance.luau)
- [x] Mobile tap controls for the minigame
- [x] Server validates minigame results so clients can't fake combos

**Gate:** You still enjoy the minigame on your 30th run. If not, redesign it before moving on.

### Phase 3 — Breakthrough and tribulation (week 5)

- [x] Breakthrough becomes available at full Qi
- [x] Tribulation event: sky darkens, lightning strikes, the player must survive or complete a short challenge
- [x] Failure costs some Qi but never wipes the realm
- [x] Success: new aura, title, and a server-wide message

**Gate:** A friend watching your screen says "wait, do that again."

### Phase 4 — Hidden cave and technique (week 6)

- [ ] Clues in the world (glowing stones, an old inscription) pointing toward the waterfall
- [x] Hidden formation behind the waterfall; entering shows "You have entered the Tomb of ..."
- [x] Reward: one technique that changes the circulation pattern and boosts active cultivation
- [x] Cave access saved per player

**Gate:** A tester finds the cave from clues alone, without you telling them.

### Phase 5 — Art pass with Blender (week 7)

- [ ] Install the blender-skills pack (and optionally the animation skill) — not installed; built props by scripting Blender MCP directly instead
- [x] Low-poly props: meditation platform, shrine, cave entrance, waterfall rocks, tomb interior
- [ ] Meditation pose and breakthrough animation on R15
- [x] Aura and lightning VFX with particle emitters in Studio
- [ ] Use Gemini to critique screenshots for readability and style consistency

**Gate:** The game looks consistent in one screenshot, even if simple.

### Phase 6 — Polish, security, playtest (week 8)

- [x] Ask Claude to audit every remote for exploits and every data path for loss
- [x] Onboarding: first 2 minutes teach meditation and hint at the minigame
- [ ] Publish as a private or friends-only experience
- [ ] Run the playtest plan below

**Gate:** Passes the success criteria at the top of this doc.

## Playtest plan and decision gate

Run two sessions with 5–10 testers, a week apart, and decide what V2 is from what you observe, not what testers say they'd like.

During each session:

1. Give no instructions beyond "try this cultivation game."
2. Watch silently (in person or screen-share) and note where they get confused or stop.
3. Track: minutes to first breakthrough, active vs passive time, whether they find the cave, whether they keep playing after the breakthrough.
4. Afterward ask three questions: what was the best moment, what was boring, would you invite a friend?

| What you see | What V2 should be |
| --- | --- |
| Most keep cultivating after the breakthrough and hunt for more secrets | Add spirit beasts and more caves next |
| They love the breakthrough but quit soon after | Add the next realm and a stronger reason to return (daily cave, events) before anything social |
| They skip the minigame and go AFK | Redesign active cultivation before adding content |
| They ask "can I play this with my friends?" | Start a minimal sect system (create, join, shared formation bonus) |
| They're bored before the first breakthrough | Rework the first 10 minutes; don't add systems yet |

## Risks and pitfalls

The biggest risk isn't the code; it's scope creep and building systems before the core loop is fun. Check this list at the end of every phase.

- [ ] **Scope creep:** adding sects or beasts "because it's quick with AI." Fallback: anything not in the V1 scope table goes into a `docs/later.md` list.
- [ ] **Data loss:** a save bug wipes tester progress. Fallback: ProfileStore only, test rejoins every phase.
- [ ] **Exploits:** client-side Qi or combo logic. Fallback: Phase 6 remote audit, server validation from Phase 1.
- [ ] **AI spaghetti:** patches piling up until nothing can change safely. Fallback: one feature per task, commit often, ask Claude to refactor at each gate.
- [ ] **Breaking the project with no way back:** Fallback: Git commit before every big prompt; roll back instead of asking Claude to "fix it" five times.
- [ ] **Generic-looking assets:** AI Blender output looks bland. Fallback: pick one art direction (stylized low-poly, jade and gold palette) and reuse it everywhere.
- [ ] **Burnout alongside thesis:** Fallback: phases are gates, not deadlines; pause between phases during heavy school weeks.
- [ ] **Two AIs editing at once:** Fallback: Claude is the only writer; Gemini only reviews screenshots, clips, and docs.
