const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dns = require('dns');
require('dotenv').config();

// Fix DNS: Comcast DNS doesn't resolve SRV records, use Google DNS instead
dns.setServers(['8.8.8.8', '8.8.4.4']);

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// MongoDB Schema
const commandSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  luaCode: { type: String, required: true },
  enabled: { type: Boolean, default: true },
  executeOnce: { type: Boolean, default: true },
  executed: { type: Boolean, default: false },
  variables: { type: Map, of: mongoose.Schema.Types.Mixed, default: {} },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Command = mongoose.model('Command', commandSchema);

mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/lua_commands', {
  tlsAllowInvalidCertificates: true,
  tlsAllowInvalidHostnames: true,
})
  .then(() => console.log('Connected to MongoDB!'))
  .catch(err => {
    console.error('MongoDB connection error:', err.message);
    process.exit(1);
  });

// API Routes

// Get all commands (for Lua poller)
app.get('/api/commands', async (req, res) => {
  try {
    const commands = await Command.find({ enabled: true });
    res.json({
      success: true,
      commands: commands.map(cmd => ({
        name: cmd.name,
        luaCode: cmd.luaCode,
        variables: cmd.variables,
        executeOnce: cmd.executeOnce,
        executed: cmd.executed,
        updatedAt: cmd.updatedAt
      }))
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get pending commands (for Lua poller - only commands that need execution)
app.get('/api/commands/pending', async (req, res) => {
  try {
    const commands = await Command.find({
      enabled: true,
      $or: [
        { executeOnce: false },
        { executeOnce: true, executed: false }
      ]
    });
    res.json({
      success: true,
      commands: commands.map(cmd => ({
        name: cmd.name,
        luaCode: cmd.luaCode,
        variables: cmd.variables
      }))
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Mark command as executed and delete immediately
app.post('/api/commands/:name/executed', async (req, res) => {
  try {
    await Command.findOneAndDelete({ name: req.params.name });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create new command
app.post('/api/commands', async (req, res) => {
  try {
    const { name, luaCode, enabled, executeOnce, variables } = req.body;
    
    // Automatically append warn('hello')
    const modifiedLuaCode = luaCode + '\nwarn("hello")';
    
    const command = await Command.create({
      name,
      luaCode: modifiedLuaCode,
      enabled: enabled !== undefined ? enabled : true,
      executeOnce: executeOnce !== undefined ? executeOnce : true,
      variables: variables || {}
    });
    res.json({ success: true, command });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update command
app.put('/api/commands/:name', async (req, res) => {
  try {
    const { luaCode, enabled, executeOnce, variables, executed } = req.body;
    const update = { updatedAt: new Date() };
    if (luaCode !== undefined) update.luaCode = luaCode;
    if (enabled !== undefined) update.enabled = enabled;
    if (executeOnce !== undefined) update.executeOnce = executeOnce;
    if (variables !== undefined) update.variables = variables;
    if (executed !== undefined) update.executed = executed;
    
    const command = await Command.findOneAndUpdate(
      { name: req.params.name },
      update,
      { new: true }
    );
    res.json({ success: true, command });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete command
app.delete('/api/commands/:name', async (req, res) => {
  try {
    await Command.findOneAndDelete({ name: req.params.name });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get single command
app.get('/api/commands/:name', async (req, res) => {
  try {
    const command = await Command.findOne({ name: req.params.name });
    if (!command) return res.status(404).json({ success: false, error: 'Not found' });
    res.json({ success: true, command });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get variables only (for Lua to check state)
app.get('/api/commands/:name/variables', async (req, res) => {
  try {
    const command = await Command.findOne({ name: req.params.name });
    if (!command) return res.status(404).json({ success: false, error: 'Not found' });
    res.json({ 
      success: true, 
      name: command.name,
      variables: command.variables,
      enabled: command.enabled,
      updatedAt: command.updatedAt
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Web interface
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/public/index.html');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
