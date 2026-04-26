
## 🤖 n8n Automation: Multi-User Disaster Alert Broadcasting

### Overview

This n8n workflow automatically fetches active disaster alerts from Firebase Firestore and broadcasts them to **all subscribed users** via Telegram every 1-2 minutes.

---

### 🔄 Workflow Flow

```
Schedule (every 1.5 min)
        ↓
    ┌───┴───┐
    ↓       ↓
Alerts    Users
 (GET)    (GET)
    ↓       ↓
 Parse    Parse
    ↓       ↓
    └───┬───┘
        ↓
  Cross Join (Alert × User)
        ↓
    Groq AI (Generates message in English/Hindi/Marathi)
        ↓
  Format Message (Adds verification + buttons)
        ↓
  Send to All Users (Telegram)
```

---

### ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Auto-Trigger** | Runs every 1-2 minutes automatically |
| **Multi-User Broadcast** | Each alert sent to EVERY user in database |
| **Multilingual AI** | Groq generates messages in English, Hindi, or Marathi |
| **Cross Join Logic** | Properly pairs each alert with each user |
| **Inline Buttons** | Understood / Not Clear / Re-Verify for feedback |
| **Explainable AI** | Includes trust score and verification reason |

---

### 📁 Required Firebase Collections

#### `alerts` collection
| Field | Type |
|-------|------|
| `isActive` | Boolean |
| `title` | String |
| `description` | String |
| `severity` | String |
| `trustScore` | Number |
| `disasterType` | String |

#### `users` collection
| Field | Type |
|-------|------|
| `chat_id` | String (Telegram chat ID) |
| `name` | String |
| `preferred_language` | String (english/hindi/marathi) |

---

### 🔑 APIs Used

| Service | Purpose |
|---------|---------|
| **Firestore REST API** | Fetch alerts and users |
| **Groq Cloud (LLaMA 3.3)** | Generate multilingual alert messages |
| **Telegram Bot API** | Deliver messages with inline buttons |

---

### 📱 Telegram Message Example

```
🚨 FLOOD ALERT
📍 Mumbai, Andheri Subway
⚠️ Severe waterlogging at 4 feet. Local trains delayed.
✅ Avoid travel through Andheri subway.

---
🔍 Verification: Cross-checked with Times of India and IMD

✅ Understood    ❓ Not Clear    🔄 Re-Verify
```

---

### ⚙️ Setup Checklist

- [ ] Firebase service account with Firestore read access
- [ ] Groq API key (LLaMA 3.3)
- [ ] Telegram bot token from @BotFather
- [ ] Users collection with valid `chat_id` fields

---

### 🚀 Benefits

- **Scalable** — 1 alert × 100 users = 100 messages instantly
- **Bilingual** — Each user gets their preferred language
- **Trackable** — Inline buttons provide real-time comprehension analytics
- **Resilient** — Cross join ensures no user is missed

---

**Status:** ✅ Production Ready | **Schedule:** Every 1-2 minutes | **Languages:** English, Hindi, Marathi

---