/**
 * SecureChat Data Store
 * - User account, contacts, conversations
 * - Persistent via localStorage
 * - Simulated message relay (platform only sees ciphertext)
 */

const Store = {
  _listeners: [],
  _data: {
    user: null,
    mnemonic: null,
    contacts: [],      // { id, displayName, avatarColor, conversationKeyB64, addedAt }
    conversations: {},  // contactId -> { messages: [{ id, senderId, recipientId, encrypted, timestamp, isRead }], unread: 0 }
  },

  // ==================== Persistence ====================

  save() {
    localStorage.setItem('secureChat', JSON.stringify(this._data));
    this._notify();
  },

  load() {
    const raw = localStorage.getItem('secureChat');
    if (raw) {
      try { this._data = JSON.parse(raw); } catch {}
    }
  },

  clear() {
    this._data = { user: null, mnemonic: null, contacts: [], conversations: {} };
    localStorage.removeItem('secureChat');
    this._notify();
  },

  // ==================== Reactivity ====================

  onChange(fn) { this._listeners.push(fn); },
  _notify() { this._listeners.forEach(fn => fn(this._data)); },

  // ==================== Getters ====================

  get user() { return this._data.user; },
  get mnemonic() { return this._data.mnemonic; },
  get contacts() { return this._data.contacts; },
  get conversations() { return this._data.conversations; },
  get isLoggedIn() { return !!this._data.user; },

  // ==================== Account ====================

  async createAccount(mnemonic, displayName) {
    const id = await CryptoUtils.deriveUserID(mnemonic);
    const name = displayName || CryptoUtils.deriveDisplayName(mnemonic);
    const colors = ['#4A90D9','#E74C3C','#2ECC71','#F39C12','#9B59B6','#1ABC9C','#E67E22','#3498DB'];
    this._data.user = { id, displayName: name, avatarColor: colors[Math.abs(hashCode(id)) % colors.length], createdAt: Date.now() };
    this._data.mnemonic = mnemonic;
    this.save();
  },

  logout() { this.clear(); },

  // ==================== Contacts ====================

  async addContact(id, displayName, keyB64) {
    if (this._data.contacts.find(c => c.id === id)) return;
    const colors = ['#E74C3C','#2ECC71','#F39C12','#9B59B6','#1ABC9C','#4A90D9'];
    this._data.contacts.push({
      id, displayName,
      avatarColor: colors[Math.abs(hashCode(id)) % colors.length],
      conversationKeyB64: keyB64 || null,
      addedAt: Date.now()
    });
    this._data.conversations[id] = { messages: [], unread: 0 };
    this.save();
  },

  updateContactKey(contactId, keyB64) {
    const c = this._data.contacts.find(c => c.id === contactId);
    if (c) c.conversationKeyB64 = keyB64;
    this.save();
  },

  getContact(id) { return this._data.contacts.find(c => c.id === id); },

  // ==================== Messages ====================

  async sendMessage(contactId, plaintext) {
    const contact = this.getContact(contactId);
    if (!contact?.conversationKeyB64 || !this._data.user) return false;
    const key = await CryptoUtils.importKey(contact.conversationKeyB64);
    if (!key) return false;
    const encrypted = await CryptoUtils.encrypt(plaintext, key);
    const msg = {
      id: uid(), senderId: this._data.user.id, recipientId: contactId,
      encrypted, timestamp: Date.now(), isRead: true
    };
    this._data.conversations[contactId].messages.push(msg);
    this.save();
    // Simulate reply
    this._simulateReply(contactId, key);
    return true;
  },

  async decryptMessage(contactId, msg) {
    const contact = this.getContact(contactId);
    if (!contact?.conversationKeyB64) return '[需要密钥解密]';
    const key = await CryptoUtils.importKey(contact.conversationKeyB64);
    if (!key) return '[密钥无效]';
    return await CryptoUtils.decrypt(msg.encrypted, key) || '[解密失败]';
  },

  markRead(contactId) {
    const conv = this._data.conversations[contactId];
    if (conv) { conv.unread = 0; conv.messages.forEach(m => m.isRead = true); this.save(); }
  },

  getLastMessage(contactId) {
    const msgs = this._data.conversations[contactId]?.messages;
    return msgs?.length ? msgs[msgs.length - 1] : null;
  },

  getTotalUnread() {
    return Object.values(this._data.conversations).reduce((s, c) => s + (c.unread || 0), 0);
  },

  // ==================== Simulated Reply ====================

  async _simulateReply(contactId, key) {
    const replies = ['收到！','好的，明白了','👍','稍等一下','没问题','我看看','这个不错','同意','OK!','马上处理','谢谢','晚点再聊'];
    const delay = 1500 + Math.random() * 2000;
    setTimeout(async () => {
      const reply = replies[Math.floor(Math.random() * replies.length)];
      const encrypted = await CryptoUtils.encrypt(reply, key);
      const contact = this.getContact(contactId);
      if (!contact) return;
      const msg = {
        id: uid(), senderId: contactId, recipientId: this._data.user.id,
        encrypted, timestamp: Date.now(), isRead: false
      };
      this._data.conversations[contactId].messages.push(msg);
      this._data.conversations[contactId].unread++;
      this.save();
    }, delay);
  },

  // ==================== Demo Data ====================

  async addDemoContacts() {
    const k1 = await CryptoUtils.generateConversationKey();
    const k2 = await CryptoUtils.generateConversationKey();
    const k3 = await CryptoUtils.generateConversationKey();
    await this.addContact('demo001', 'Alice', await CryptoUtils.exportKey(k1));
    await this.addContact('demo002', 'Bob', await CryptoUtils.exportKey(k2));
    await this.addContact('demo003', '小明', await CryptoUtils.exportKey(k3));
  }
};

// ==================== Helpers ====================

function uid() { return Date.now().toString(36) + Math.random().toString(36).slice(2, 9); }
function hashCode(s) { let h = 0; for (let i = 0; i < s.length; i++) { h = ((h << 5) - h) + s.charCodeAt(i); h |= 0; } return h; }

window.Store = Store;
