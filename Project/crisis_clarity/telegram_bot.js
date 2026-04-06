const TelegramBot = require('node-telegram-bot-api');

// ⚠️ PUT YOUR REAL TOKEN HERE ⚠️
const BOT_TOKEN = '8755222399:AAFl0kpgvolsRyzoCCftftWLq90-lwx6j_Y';

// Check if token is provided
if (!BOT_TOKEN || BOT_TOKEN === 'YOUR_REAL_BOT_TOKEN_HERE') {
  console.error('❌ ERROR: Please add your real bot token!');
  console.log('Get it from @BotFather on Telegram');
  process.exit(1);
}

let bot;
try {
  bot = new TelegramBot(BOT_TOKEN, { polling: true });
  console.log('✅ Telegram bot is running!');
} catch (error) {
  console.error('❌ Failed to start bot:', error.message);
  process.exit(1);
}

// Handle polling errors
bot.on('polling_error', (error) => {
  console.error('Polling error:', error.message);
  if (error.message.includes('404')) {
    console.error('❌ Invalid bot token! Please check your token.');
    console.log('Get a new token from @BotFather using /newtoken');
  }
});

// Handle webhook errors
bot.on('webhook_error', (error) => {
  console.error('Webhook error:', error.message);
});

// /start command handler
bot.onText(/\/start(.+)?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = match[1] ? match[1].trim() : null;

  console.log(`📨 Message from chat ${chatId}, userId: ${userId || 'none'}`);

  try {
    if (userId && userId.length > 0) {
      // Send verification code and chat ID
      await bot.sendMessage(
        chatId,
        `🔐 *Verification Code:* \`${userId}\`\n\n` +
        `📱 *Your Chat ID:* \`${chatId}\`\n\n` +
        `📋 *How to verify:*\n` +
        `1️⃣ Copy the Verification Code\n` +
        `2️⃣ Copy the Chat ID\n` +
        `3️⃣ Go back to Crisis Clarity app\n` +
        `4️⃣ Paste both fields\n` +
        `5️⃣ Tap "VERIFY & LINK"\n\n` +
        `✅ You will start receiving alerts immediately!`,
        { parse_mode: 'Markdown' }
      );
      console.log(`✅ Sent verification to user ${userId}`);
    } else {
      // Welcome message
      await bot.sendMessage(
        chatId,
        `🤖 *Welcome to Crisis Clarity Bot!*\n\n` +
        `This bot sends you real-time crisis alerts for your area.\n\n` +
        `*Your Chat ID:* \`${chatId}\`\n\n` +
        `📱 *To get started:*\n` +
        `1. Open the Crisis Clarity app\n` +
        `2. Complete signup\n` +
        `3. Click "Open Telegram Bot"\n` +
        `4. Come back here and press Start\n` +
        `5. Copy the verification code\n\n` +
        `⚠️ *Note:* Only users who sign up through the app will receive alerts.`,
        { parse_mode: 'Markdown' }
      );
      console.log(`📢 Welcome message sent to chat ${chatId}`);
    }
  } catch (error) {
    console.error('Error sending message:', error.message);
  }
});

// /ping command to test if bot is alive
bot.onText(/\/ping/, async (msg) => {
  const chatId = msg.chat.id;
  await bot.sendMessage(chatId, '🏓 Pong! Bot is working!');
  console.log(`🏓 Ping received from ${chatId}`);
});

// Handle any other messages
bot.on('message', async (msg) => {
  const chatId = msg.chat.id;
  const text = msg.text;

  // Ignore commands (already handled)
  if (!text || text.startsWith('/')) return;

  await bot.sendMessage(
    chatId,
    `🤖 *Crisis Clarity Bot*\n\n` +
    `This bot automatically sends you crisis alerts.\n` +
    `You don't need to send messages here.\n\n` +
    `*Your Chat ID:* \`${chatId}\``,
    { parse_mode: 'Markdown' }
  );
});

console.log('Bot is listening for commands...');
console.log('Commands: /start, /ping');