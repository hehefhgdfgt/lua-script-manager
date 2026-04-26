# MongoDB Lua Command Manager

A system that stores Lua commands in MongoDB and executes them based on the variables/conditions stored with each command.

## Features

- **MongoDB Storage**: Commands and their variables are stored persistently in MongoDB
- **Web Interface**: Create, manage, and monitor commands through a web UI
- **Variable Injection**: Pass data from MongoDB directly into your Lua scripts
- **Auto-execution**: Lua poller checks for new commands and executes them automatically
- **Execute Once or Repeat**: Control if commands run once or continuously

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Setup MongoDB

Either:
- Install MongoDB locally: https://docs.mongodb.com/manual/installation/
- Use MongoDB Atlas (free tier): https://www.mongodb.com/atlas

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env and add your MongoDB connection string
```

### 4. Start Server

```bash
npm start
```

Visit `http://localhost:3000` to use the web interface.

## How It Works

1. **Create a command** in the web UI with:
   - Lua code to execute
   - Variables (JSON data accessible in your script)
   - Enable/Disable status
   - Execute once or repeat setting

2. **Poller fetches commands** from `/api/commands/pending`

3. **Variables are injected** into the Lua environment before execution

4. **Script executes** with access to the MongoDB variables

5. **Command marked as executed** (if executeOnce is true)

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/commands` | GET | Get all enabled commands |
| `/api/commands/pending` | GET | Get commands ready for execution |
| `/api/commands` | POST | Create new command |
| `/api/commands/:name` | PUT | Update command |
| `/api/commands/:name` | DELETE | Delete command |
| `/api/commands/:name/executed` | POST | Mark as executed |
| `/api/commands/:name/variables` | GET | Get just the variables |

## Example Lua Command

Create this in the web UI:

**Name**: `teleport_player`

**Lua Code**:
```lua
-- Access variables from MongoDB
local targetPos = variables.targetPosition or {x=0, y=0, z=0}
local speed = variables.speed or 50

print("Teleporting to:", targetPos.x, targetPos.y, targetPos.z)
print("Speed:", speed)

-- Your actual teleport logic here
-- e.g., player.Character:SetPrimaryPartCFrame(CFrame.new(targetPos.x, targetPos.y, targetPos.z))
```

**Variables** (JSON):
```json
{
  "targetPosition": {"x": 100, "y": 50, "z": 200},
  "speed": 100
}
```

## Using the Poller

Add the `poller.lua` to your game/script and set the server URL:

```lua
-- In poller.lua, change this line:
local SERVER_URL = "https://your-server.com" -- Your server URL

-- Then run the poller script
```

The poller will:
1. Poll every 5 seconds for new commands
2. Inject variables from MongoDB into the script environment
3. Execute the Lua code
4. Mark commands as executed (if executeOnce is enabled)

## File Structure

```
lua-script-manager/
├── server.js           # Express server with MongoDB API
├── poller.lua          # Lua script that polls and executes
├── public/index.html   # Web management interface
├── package.json        # Node dependencies
├── .env.example        # Environment template
└── README.md           # This file
```

## Customizing for Your Environment

The `poller.lua` has HTTP functions for different environments. Adapt the `httpGet` and `httpPost` functions for:

- **Roblox**: Uses `game.HttpService`
- **Garry's Mod**: Uses `http.Fetch`
- **Other**: Implement your own HTTP

## Security Note

This executes arbitrary Lua code. Only use in trusted environments. Consider adding:
- API key authentication
- Script sandboxing
- Command signing/verification
