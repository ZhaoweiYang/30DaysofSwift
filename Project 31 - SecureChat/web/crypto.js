/**
 * SecureChat Crypto Module
 * - Mnemonic generation (BIP39-inspired)
 * - AES-256-GCM encryption/decryption via Web Crypto API
 * - Key derivation from mnemonic (PBKDF2 + SHA-256)
 */

const WORD_LIST = [
  "abandon","ability","able","about","above","absent","absorb","abstract",
  "absurd","abuse","access","accident","account","accuse","achieve","acid",
  "acoustic","acquire","across","act","action","actor","actress","actual",
  "adapt","add","addict","address","adjust","admit","adult","advance",
  "advice","aerobic","affair","afford","afraid","again","age","agent",
  "agree","ahead","aim","air","airport","aisle","alarm","album",
  "alcohol","alert","alien","all","alley","allow","almost","alone",
  "alpha","already","also","alter","always","amateur","amazing","among",
  "amount","amused","analyst","anchor","ancient","anger","angle","angry",
  "animal","ankle","announce","annual","another","answer","antenna","antique",
  "anxiety","any","apart","apology","appear","apple","approve","april",
  "arch","arctic","area","arena","argue","arm","armed","armor",
  "army","around","arrange","arrest","arrive","arrow","art","artefact",
  "artist","artwork","ask","aspect","assault","asset","assist","assume",
  "asthma","athlete","atom","attack","attend","attitude","attract","auction",
  "audit","august","aunt","author","auto","autumn","average","avocado",
  "avoid","awake","aware","awesome","awful","awkward","axis","baby",
  "bachelor","bacon","badge","bag","balance","balcony","ball","bamboo",
  "banana","banner","bar","barely","bargain","barrel","base","basic",
  "basket","battle","beach","bean","beauty","because","become","beef",
  "before","begin","behave","behind","believe","below","belt","bench",
  "benefit","best","betray","better","between","beyond","bicycle","bid",
  "bike","bind","biology","bird","birth","bitter","black","blade",
  "blame","blanket","blast","bleak","bless","blind","blood","blossom",
  "blow","blue","blur","blush","board","boat","body","boil",
  "bomb","bone","bonus","book","boost","border","boring","borrow",
  "boss","bottom","bounce","box","boy","bracket","brain","brand",
  "brass","brave","bread","breeze","brick","bridge","brief","bright",
  "bring","brisk","broccoli","broken","bronze","broom","brother","brown",
  "brush","bubble","buddy","budget","buffalo","build","bulb","bulk",
  "bullet","bundle","bunny","burden","burger","burst","bus","business",
  "busy","butter","buyer","buzz","cabbage","cabin","cable","cactus"
];

const CryptoUtils = {
  // ==================== Mnemonic ====================

  generateMnemonic(wordCount = 12) {
    const arr = new Uint8Array(wordCount);
    crypto.getRandomValues(arr);
    return Array.from(arr).map(b => WORD_LIST[b % WORD_LIST.length]).join(' ');
  },

  validateMnemonic(mnemonic) {
    const words = mnemonic.trim().toLowerCase().split(/\s+/);
    return words.length === 12 && words.every(w => WORD_LIST.includes(w));
  },

  // ==================== Key Derivation ====================

  async deriveKeyFromMnemonic(mnemonic) {
    const enc = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey(
      'raw', enc.encode(mnemonic), 'PBKDF2', false, ['deriveBits', 'deriveKey']
    );
    return crypto.subtle.deriveKey(
      { name: 'PBKDF2', salt: enc.encode('SecureChat'), iterations: 100000, hash: 'SHA-256' },
      keyMaterial, { name: 'AES-GCM', length: 256 }, true, ['encrypt', 'decrypt']
    );
  },

  async deriveUserID(mnemonic) {
    const enc = new TextEncoder();
    const hash = await crypto.subtle.digest('SHA-256', enc.encode(mnemonic));
    return Array.from(new Uint8Array(hash).slice(0, 8))
      .map(b => b.toString(16).padStart(2, '0')).join('');
  },

  deriveDisplayName(mnemonic) {
    const words = mnemonic.trim().split(/\s+/);
    if (words.length < 2) return 'User';
    return words.slice(0, 2).map(w => w[0].toUpperCase() + w.slice(1)).join('');
  },

  // ==================== Conversation Key ====================

  async generateConversationKey() {
    return crypto.subtle.generateKey({ name: 'AES-GCM', length: 256 }, true, ['encrypt', 'decrypt']);
  },

  async exportKey(key) {
    const raw = await crypto.subtle.exportKey('raw', key);
    return btoa(String.fromCharCode(...new Uint8Array(raw)));
  },

  async importKey(base64) {
    try {
      const raw = Uint8Array.from(atob(base64), c => c.charCodeAt(0));
      return crypto.subtle.importKey('raw', raw, { name: 'AES-GCM' }, true, ['encrypt', 'decrypt']);
    } catch { return null; }
  },

  async keyFingerprint(key) {
    const raw = await crypto.subtle.exportKey('raw', key);
    const hash = await crypto.subtle.digest('SHA-256', raw);
    return Array.from(new Uint8Array(hash).slice(0, 4))
      .map(b => b.toString(16).toUpperCase().padStart(2, '0')).join(':');
  },

  // ==================== Encrypt / Decrypt ====================

  async encrypt(plaintext, key) {
    const enc = new TextEncoder();
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const ciphertext = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv }, key, enc.encode(plaintext)
    );
    // Combine IV + ciphertext
    const combined = new Uint8Array(iv.length + ciphertext.byteLength);
    combined.set(iv);
    combined.set(new Uint8Array(ciphertext), iv.length);
    return btoa(String.fromCharCode(...combined));
  },

  async decrypt(ciphertextB64, key) {
    try {
      const combined = Uint8Array.from(atob(ciphertextB64), c => c.charCodeAt(0));
      const iv = combined.slice(0, 12);
      const ciphertext = combined.slice(12);
      const decrypted = await crypto.subtle.decrypt(
        { name: 'AES-GCM', iv }, key, ciphertext
      );
      return new TextDecoder().decode(decrypted);
    } catch { return null; }
  }
};

window.CryptoUtils = CryptoUtils;
