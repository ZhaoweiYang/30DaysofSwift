/**
 * SecureChat - Web Client App Logic
 */

let currentChatContact = null;
let createStep = 0;
let createMnemonic = '';
let createConfirmed = false;
let currentTab = 'chats';
let chatRefreshTimer = null;
let pageStack = [];

// ==================== Init ====================

document.addEventListener('DOMContentLoaded', () => {
  Store.load();
  Store.onChange(() => {
    refreshCurrentView();
    updateBadges();
  });
  if (Store.isLoggedIn) {
    showPage('page-main');
    switchTab('chats');
  }
  // Listen for restore input
  const ri = document.getElementById('restore-input');
  if (ri) ri.addEventListener('input', () => {
    const words = ri.value.trim().split(/\s+/).filter(Boolean);
    document.getElementById('restore-word-count').textContent = `${words.length} / 12 个词`;
    document.getElementById('restore-btn').disabled = words.length !== 12;
  });
});

// ==================== Navigation ====================

function showPage(id, slide = true) {
  const current = document.querySelector('.page.active');
  if (current && current.id !== id) {
    pageStack.push(current.id);
    current.classList.remove('active');
  }
  const target = document.getElementById(id);
  target.classList.add('active');
  if (slide) target.classList.add('slide-in');
  setTimeout(() => target.classList.remove('slide-in'), 300);

  // Page-specific init
  if (id === 'page-create') initCreateFlow();
  if (id === 'page-main') { switchTab(currentTab); updateBadges(); }
}

function closePage(id) {
  const page = document.getElementById(id);
  page.classList.remove('active');
  if (pageStack.length) {
    const prev = pageStack.pop();
    document.getElementById(prev).classList.add('active');
  }
}

// ==================== Create Account Flow ====================

function initCreateFlow() {
  createStep = 0;
  createMnemonic = CryptoUtils.generateMnemonic();
  createConfirmed = false;
  renderCreateStep();
}

function renderCreateStep() {
  const body = document.getElementById('create-body');
  const actions = document.getElementById('create-actions');

  if (createStep === 0) {
    // Step 1: Show mnemonic
    const words = createMnemonic.split(' ');
    body.innerHTML = `
      <div class="step-icon">🔑</div>
      <div class="step-title">您的助记词</div>
      <div class="step-desc">以下12个词是您的账户密钥。<br>请务必安全保存，丢失后无法找回。</div>
      <div class="mnemonic-grid">${words.map((w, i) => `<div class="mnemonic-word"><span class="num">${i + 1}</span><span class="word">${w}</span></div>`).join('')}</div>
      <button class="copy-btn" onclick="copyMnemonic()">📋 复制助记词</button>
    `;
    actions.innerHTML = `<button class="btn btn-primary" onclick="createStep=1;renderCreateStep()">下一步</button>`;
  } else if (createStep === 1) {
    // Step 2: Backup confirmation
    body.innerHTML = `
      <div class="step-icon">⚠️</div>
      <div class="step-title">确认备份</div>
      <div class="step-desc">请确认您已安全保存助记词。<br>这是恢复账户的唯一方式。</div>
      <div class="warning-box">
        <div class="warning-row"><span class="icon">⚠️</span> 助记词是您账户的唯一凭证</div>
        <div class="warning-row"><span class="icon">⚠️</span> 请勿截图或在线存储助记词</div>
        <div class="warning-row"><span class="icon">⚠️</span> 建议手写在纸上并妥善保管</div>
        <div class="warning-row"><span class="icon">⚠️</span> 任何人获得助记词即可控制账户</div>
      </div>
      <div class="checkbox-row"><input type="checkbox" id="confirm-backup" onchange="createConfirmed=this.checked;renderCreateActions()"> <label for="confirm-backup">我已安全保存助记词</label></div>
    `;
    actions.innerHTML = `
      <button class="btn btn-secondary" onclick="createStep=0;renderCreateStep()">返回</button>
      <button class="btn btn-primary" id="create-next-btn" disabled onclick="createStep=2;renderCreateStep()">下一步</button>
    `;
  } else if (createStep === 2) {
    // Step 3: Set name
    const defaultName = CryptoUtils.deriveDisplayName(createMnemonic);
    body.innerHTML = `
      <div class="avatar avatar-lg avatar-round" style="background:#4A90D9">${defaultName[0]}</div>
      <div class="step-title" style="margin-top:16px">设置昵称</div>
      <div class="step-desc">给自己取一个昵称吧</div>
      <div class="input-group"><input id="create-name" placeholder="输入昵称（留空使用默认: ${defaultName}）"></div>
      <div style="font-size:13px;color:var(--text-secondary)">您的ID将在创建后显示</div>
    `;
    actions.innerHTML = `<button class="btn btn-primary" onclick="doCreateAccount()">完成创建</button>`;
  }
}

function renderCreateActions() {
  const btn = document.getElementById('create-next-btn');
  if (btn) btn.disabled = !createConfirmed;
}

function copyMnemonic() {
  navigator.clipboard.writeText(createMnemonic).then(() => {
    const btn = document.querySelector('.create-page .copy-btn');
    if (btn) { btn.textContent = '✅ 已复制'; setTimeout(() => btn.textContent = '📋 复制助记词', 2000); }
  });
}

async function doCreateAccount() {
  const nameInput = document.getElementById('create-name');
  const name = nameInput?.value.trim() || null;
  await Store.createAccount(createMnemonic, name);
  await Store.addDemoContacts();
  showPage('page-main');
  switchTab('chats');
}

// ==================== Restore Account ====================

async function pasteRestore() {
  try {
    const text = await navigator.clipboard.readText();
    document.getElementById('restore-input').value = text;
    document.getElementById('restore-input').dispatchEvent(new Event('input'));
  } catch {}
}

async function doRestore() {
  const input = document.getElementById('restore-input').value.trim().toLowerCase();
  const normalized = input.split(/\s+/).join(' ');
  if (!CryptoUtils.validateMnemonic(normalized)) {
    document.getElementById('restore-error').style.display = 'block';
    document.getElementById('restore-error').textContent = '助记词无效，请检查拼写';
    return;
  }
  document.getElementById('restore-error').style.display = 'none';
  await Store.createAccount(normalized);
  await Store.addDemoContacts();
  showPage('page-main');
  switchTab('chats');
}

// ==================== Tabs ====================

function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.tab-bar .tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tab));
  const content = document.getElementById('tab-content');

  if (tab === 'chats') renderChatsTab(content);
  else if (tab === 'contacts') renderContactsTab(content);
  else if (tab === 'discover') renderDiscoverTab(content);
  else if (tab === 'profile') renderProfileTab(content);
}

function updateBadges() {
  const total = Store.getTotalUnread();
  const badge = document.getElementById('tab-badge-chats');
  if (total > 0) { badge.style.display = 'flex'; badge.textContent = total > 99 ? '99+' : total; }
  else badge.style.display = 'none';
}

// ==================== Chats Tab ====================

function renderChatsTab(container) {
  const contacts = Store.contacts.slice().sort((a, b) => {
    const la = Store.getLastMessage(a.id)?.timestamp || a.addedAt;
    const lb = Store.getLastMessage(b.id)?.timestamp || b.addedAt;
    return lb - la;
  });

  let html = `
    <div class="header" style="position:relative">
      <div style="width:40px">
        ${Store.user ? `<div class="avatar avatar-sm" style="background:${Store.user.avatarColor};cursor:pointer" onclick="switchTab('profile')">${Store.user.displayName[0]}</div>` : ''}
      </div>
      <h2>消息</h2>
      <div class="header-right"><button class="back-btn" style="font-size:22px;margin:0" onclick="showPage('page-add-contact')">➕</button></div>
    </div>
    <div class="search-bar"><div class="search-bar-inner">🔍 搜索</div></div>
  `;

  if (contacts.length === 0) {
    html += `<div class="empty-state"><div class="icon">💬</div><p>暂无会话</p><p style="font-size:13px">添加联系人开始聊天</p></div>`;
  } else {
    html += `<div class="conv-list">`;
    for (const c of contacts) {
      const conv = Store.conversations[c.id];
      const lastMsg = Store.getLastMessage(c.id);
      const unread = conv?.unread || 0;
      const time = lastMsg ? formatTime(lastMsg.timestamp) : '';
      html += `
        <div class="conv-item" onclick="openChat('${c.id}')">
          <div class="avatar avatar-md" style="background:${c.avatarColor}">${c.displayName[0]}</div>
          <div class="info">
            <div class="top"><span class="name">${esc(c.displayName)}</span><span class="time">${time}</span></div>
            <div class="bottom">
              <span class="preview"><span class="lock">🔒</span> <span id="conv-preview-${c.id}">${lastMsg ? '...' : '[加密会话已建立]'}</span></span>
              ${unread > 0 ? `<span class="unread-badge">${unread}</span>` : ''}
            </div>
          </div>
        </div>`;
    }
    html += `</div>`;
  }

  container.innerHTML = html;

  // Async decrypt previews
  for (const c of contacts) {
    const lastMsg = Store.getLastMessage(c.id);
    if (lastMsg) {
      Store.decryptMessage(c.id, lastMsg).then(text => {
        const el = document.getElementById(`conv-preview-${c.id}`);
        if (el) el.textContent = text.length > 20 ? text.slice(0, 20) + '...' : text;
      });
    }
  }
}

// ==================== Contacts Tab ====================

function renderContactsTab(container) {
  let html = `
    <div class="header">
      <div style="width:40px"></div>
      <h2>通讯录</h2>
      <div class="header-right"><button class="back-btn" style="font-size:20px;margin:0" onclick="showPage('page-add-contact')">👤+</button></div>
    </div>
    <div class="section-title">联系人 (${Store.contacts.length})</div>
    <div style="flex:1;overflow-y:auto">
  `;

  for (const c of Store.contacts) {
    const hasKey = !!c.conversationKeyB64;
    html += `
      <div class="contact-item" onclick="openChat('${c.id}')">
        <div class="avatar avatar-md" style="background:${c.avatarColor}">${c.displayName[0]}</div>
        <div class="cinfo">
          <div class="cname">${esc(c.displayName)}</div>
          <div class="cstatus"><span class="dot ${hasKey ? 'on' : 'off'}"></span>${hasKey ? '加密已建立' : '待建立加密'}</div>
        </div>
      </div>`;
  }

  html += `</div>`;
  container.innerHTML = html;
}

// ==================== Discover Tab ====================

function renderDiscoverTab(container) {
  container.innerHTML = `
    <div class="header"><div style="width:40px"></div><h2>发现</h2><div class="header-right"></div></div>
    <div style="flex:1;overflow-y:auto">
      <div class="discover-item"><span class="di-icon">📷</span><span class="di-label">扫一扫</span></div>
      <div class="discover-item"><span class="di-icon">📱</span><span class="di-label">摇一摇</span></div>
      <div style="height:12px;background:var(--bg)"></div>
      <div class="discover-item"><span class="di-icon">🧩</span><span class="di-label">小程序</span></div>
    </div>
  `;
}

// ==================== Profile Tab ====================

function renderProfileTab(container) {
  const user = Store.user;
  if (!user) return;
  container.innerHTML = `
    <div class="header"><div style="width:40px"></div><h2>个人信息</h2><div class="header-right"></div></div>
    <div style="flex:1;overflow-y:auto">
      <div class="profile-header">
        <div class="avatar avatar-lg avatar-round" style="background:${user.avatarColor}">${user.displayName[0]}</div>
        <div class="name">${esc(user.displayName)}</div>
        <div class="uid">ID: ${user.id} <button class="copy-btn" style="font-size:12px;padding:2px 8px" onclick="copyText('${user.id}',this)">复制</button></div>
      </div>
      <div style="height:8px;background:var(--bg)"></div>
      <div class="section-title">安全</div>
      <div class="settings-item" onclick="viewMnemonic()"><span class="si-icon">🔑</span><span class="si-label">查看助记词</span><span class="si-arrow">›</span></div>
      <div class="settings-item"><span class="si-icon">🔒</span><span class="si-label">加密算法</span><span class="si-value">AES-256-GCM</span></div>
      <div style="height:8px;background:var(--bg)"></div>
      <div class="section-title">数据</div>
      <div class="settings-item"><span class="si-icon">👥</span><span class="si-label">联系人</span><span class="si-value">${Store.contacts.length}</span></div>
      <div class="settings-item"><span class="si-icon">💬</span><span class="si-label">会话</span><span class="si-value">${Object.keys(Store.conversations).length}</span></div>
      <div style="height:8px;background:var(--bg)"></div>
      <div style="padding:24px"><button class="btn btn-danger" onclick="doLogout()">退出登录</button></div>
    </div>
  `;
}

function viewMnemonic() {
  const mnemonic = Store.mnemonic;
  if (!mnemonic) return;
  const words = mnemonic.split(' ');
  const body = document.getElementById('mnemonic-view-body');
  body.innerHTML = `
    <div class="step-icon">👁️‍🗨️</div>
    <div class="step-title">您的助记词</div>
    <div class="step-desc">请勿在公共场合展示</div>
    <div class="mnemonic-grid">${words.map((w, i) => `<div class="mnemonic-word"><span class="num">${i + 1}</span><span class="word">${w}</span></div>`).join('')}</div>
    <button class="copy-btn" onclick="copyText('${mnemonic}',this)">📋 复制助记词</button>
  `;
  showPage('page-mnemonic-view');
}

function doLogout() {
  if (confirm('退出后需要助记词才能恢复账户。确认退出？')) {
    Store.logout();
    pageStack = [];
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById('page-welcome').classList.add('active');
  }
}

// ==================== Chat View ====================

function openChat(contactId) {
  const contact = Store.getContact(contactId);
  if (!contact) return;
  currentChatContact = contactId;
  document.getElementById('chat-title').textContent = contact.displayName;

  const hasKey = !!contact.conversationKeyB64;
  document.getElementById('chat-key-banner').style.display = hasKey ? 'none' : 'flex';
  document.getElementById('chat-lock-btn').textContent = hasKey ? '🔒' : '🔓';
  document.getElementById('chat-send-btn').disabled = !hasKey;

  Store.markRead(contactId);
  showPage('page-chat');
  renderMessages();

  // Auto-refresh messages
  clearInterval(chatRefreshTimer);
  chatRefreshTimer = setInterval(() => {
    if (currentChatContact === contactId) renderMessages();
  }, 500);
}

function closeChat() {
  clearInterval(chatRefreshTimer);
  currentChatContact = null;
  closePage('page-chat');
  if (currentTab === 'chats') {
    const content = document.getElementById('tab-content');
    renderChatsTab(content);
  }
}

async function renderMessages() {
  const contactId = currentChatContact;
  if (!contactId) return;
  const conv = Store.conversations[contactId];
  if (!conv) return;
  const container = document.getElementById('chat-messages');
  const userId = Store.user?.id;
  const contact = Store.getContact(contactId);

  Store.markRead(contactId);

  let html = '';
  for (const msg of conv.messages) {
    const isMine = msg.senderId === userId;
    const text = await Store.decryptMessage(contactId, msg);
    const time = formatTimeShort(msg.timestamp);
    const avatar = isMine
      ? `<div class="avatar avatar-sm" style="background:${Store.user.avatarColor}">${Store.user.displayName[0]}</div>`
      : `<div class="avatar avatar-sm" style="background:${contact.avatarColor}">${contact.displayName[0]}</div>`;

    html += `
      <div class="msg-row ${isMine ? 'mine' : ''}">
        ${avatar}
        <div>
          <div class="msg-bubble ${isMine ? 'mine' : 'other'}" onclick="toggleEncrypted(this,'${msg.encrypted.slice(0, 60).replace(/'/g, "\\'")}...')">
            <span class="decrypted-text">${esc(text)}</span>
          </div>
          <div class="msg-meta msg-time">${time}</div>
        </div>
      </div>`;
  }

  container.innerHTML = html;
  container.scrollTop = container.scrollHeight;
}

function toggleEncrypted(el, encrypted) {
  const dec = el.querySelector('.decrypted-text');
  const enc = el.querySelector('.encrypted-text');
  if (enc) {
    enc.remove();
    dec.style.display = '';
  } else {
    dec.style.display = 'none';
    const span = document.createElement('span');
    span.className = 'encrypted-text';
    span.textContent = '🔒 ' + encrypted;
    el.appendChild(span);
  }
}

async function sendMsg() {
  const input = document.getElementById('chat-input');
  const text = input.value.trim();
  if (!text || !currentChatContact) return;
  input.value = '';
  await Store.sendMessage(currentChatContact, text);
  renderMessages();
}

// ==================== Key Info ====================

async function showKeyInfo() {
  const contactId = currentChatContact;
  const contact = Store.getContact(contactId);
  if (!contact) return;

  const body = document.getElementById('key-info-body');
  const hasKey = !!contact.conversationKeyB64;

  if (hasKey) {
    const key = await CryptoUtils.importKey(contact.conversationKeyB64);
    const fingerprint = key ? await CryptoUtils.keyFingerprint(key) : 'N/A';

    body.innerHTML = `
      <div class="avatar avatar-lg avatar-round" style="background:#2ECC71;font-size:36px">🔒</div>
      <div class="step-title" style="margin-top:16px">加密信息</div>
      <div style="width:100%;margin-top:16px">
        <div class="info-card"><span class="label">加密状态</span><span class="value green">已建立</span></div>
        <div class="info-card"><span class="label">加密算法</span><span class="value">AES-256-GCM</span></div>
        <div class="info-card"><span class="label">密钥指纹</span><span class="value">${fingerprint}</span></div>
      </div>
      <div style="margin-top:24px;text-align:center">
        <div class="step-desc">分享密钥给 ${esc(contact.displayName)}<br>对方输入后即可解密您发送的消息</div>
        <button class="btn btn-primary btn-small" onclick="copyText('${contact.conversationKeyB64}',this)" style="margin:0 auto">📋 复制密钥</button>
      </div>
      <div class="flow-box">
        <div class="flow-title">ℹ️ 加密流程说明</div>
        <div class="flow-text">发送方用密钥在本地加密消息 →<br>平台转发加密数据 →<br>接收方用相同密钥在本地解密</div>
      </div>
    `;
  } else {
    body.innerHTML = `
      <div class="avatar avatar-lg avatar-round" style="background:var(--orange);font-size:36px">🔓</div>
      <div class="step-title" style="margin-top:16px">加密信息</div>
      <div class="step-desc">尚未建立加密连接<br>您需要获取对方的密钥或生成新密钥</div>
      <button class="btn btn-primary btn-small" onclick="generateKeyForContact('${contactId}')">🔑 生成新密钥</button>
      <div style="height:16px"></div>
      <button class="btn btn-secondary btn-small" onclick="closePage('page-key-info');showPage('page-key-input')">📥 输入对方密钥</button>
    `;
  }

  showPage('page-key-info');
}

async function generateKeyForContact(contactId) {
  const key = await CryptoUtils.generateConversationKey();
  const keyB64 = await CryptoUtils.exportKey(key);
  Store.updateContactKey(contactId, keyB64);

  // Refresh views
  if (currentChatContact === contactId) {
    document.getElementById('chat-key-banner').style.display = 'none';
    document.getElementById('chat-lock-btn').textContent = '🔒';
    document.getElementById('chat-send-btn').disabled = false;
  }
  closePage('page-key-info');
  showKeyInfo(); // Re-open to show updated info
}

// ==================== Key Input ====================

async function pasteKeyInput() {
  try {
    const text = await navigator.clipboard.readText();
    document.getElementById('key-input-text').value = text.trim();
  } catch {}
}

async function doImportKey() {
  const keyB64 = document.getElementById('key-input-text').value.trim();
  const key = await CryptoUtils.importKey(keyB64);
  if (!key) {
    document.getElementById('key-input-error').style.display = 'block';
    document.getElementById('key-input-error').textContent = '密钥格式无效，请检查后重试';
    return;
  }
  document.getElementById('key-input-error').style.display = 'none';
  Store.updateContactKey(currentChatContact, keyB64);
  document.getElementById('chat-key-banner').style.display = 'none';
  document.getElementById('chat-lock-btn').textContent = '🔒';
  document.getElementById('chat-send-btn').disabled = false;
  document.getElementById('key-input-text').value = '';
  closePage('page-key-input');
}

// ==================== Add Contact ====================

function toggleManualKey() {
  const autoKey = document.getElementById('add-contact-auto-key').checked;
  document.getElementById('add-contact-key-group').style.display = autoKey ? 'none' : 'block';
}

async function doAddContact() {
  const id = document.getElementById('add-contact-id').value.trim();
  const name = document.getElementById('add-contact-name').value.trim();
  if (!id || !name) return alert('请填写用户ID和备注名');

  const autoKey = document.getElementById('add-contact-auto-key').checked;
  let keyB64 = null;
  if (autoKey) {
    const key = await CryptoUtils.generateConversationKey();
    keyB64 = await CryptoUtils.exportKey(key);
  } else {
    keyB64 = document.getElementById('add-contact-key').value.trim() || null;
  }

  await Store.addContact(id, name, keyB64);

  // Clear form
  document.getElementById('add-contact-id').value = '';
  document.getElementById('add-contact-name').value = '';
  document.getElementById('add-contact-key').value = '';
  document.getElementById('add-contact-auto-key').checked = true;
  toggleManualKey();

  closePage('page-add-contact');
}

// ==================== Helpers ====================

function refreshCurrentView() {
  if (currentChatContact) renderMessages();
  const content = document.getElementById('tab-content');
  if (content && document.getElementById('page-main').classList.contains('active')) {
    switchTab(currentTab);
  }
}

function esc(s) {
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}

function formatTime(ts) {
  const d = new Date(ts);
  const now = new Date();
  const isToday = d.toDateString() === now.toDateString();
  if (isToday) return d.toTimeString().slice(0, 5);
  const yesterday = new Date(now); yesterday.setDate(yesterday.getDate() - 1);
  if (d.toDateString() === yesterday.toDateString()) return '昨天';
  return `${(d.getMonth() + 1).toString().padStart(2, '0')}/${d.getDate().toString().padStart(2, '0')}`;
}

function formatTimeShort(ts) {
  return new Date(ts).toTimeString().slice(0, 5);
}

function copyText(text, btn) {
  navigator.clipboard.writeText(text).then(() => {
    if (btn) {
      const orig = btn.textContent;
      btn.textContent = '✅ 已复制';
      setTimeout(() => btn.textContent = orig, 2000);
    }
  });
}
