/* =========================================================
   MultiClips — menu bar concept gallery
   Static preview. No app code is touched by this file.
   ========================================================= */

/* ---------- icons (SF Symbol stand-ins) ---------- */
const S = (d, extra = '') =>
  `<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor"
     stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" ${extra}>${d}</svg>`;

const ICON = {
  // textformat — the "Aa" glyph in the current build
  textformat: `<svg viewBox="0 0 16 16" width="16" height="16"><text x="8" y="12"
      text-anchor="middle" font-size="11" font-weight="500" fill="currentColor"
      font-family="-apple-system, sans-serif">Aa</text></svg>`,
  link: S(`<path d="M6.8 9.2a2.6 2.6 0 0 0 3.7 0l2.1-2.1a2.6 2.6 0 0 0-3.7-3.7l-1 1"/>
           <path d="M9.2 6.8a2.6 2.6 0 0 0-3.7 0l-2.1 2.1a2.6 2.6 0 0 0 3.7 3.7l1-1"/>`),
  photo: S(`<rect x="2" y="3.5" width="12" height="9" rx="2"/>
            <circle cx="5.6" cy="6.9" r=".95"/>
            <path d="M2.6 11.6 6 8.5l2.3 2 2.2-1.9 2.9 2.9"/>`),
  doc: S(`<path d="M4 2.2h4.4L12 5.6V13a.8.8 0 0 1-.8.8H4a.8.8 0 0 1-.8-.8V3a.8.8 0 0 1 .8-.8z"/>
          <path d="M8.3 2.4v3.3h3.4"/>
          <path d="M5.6 9.2h4.2M5.6 11.3h2.9"/>`),
  archive: S(`<rect x="2.2" y="2.9" width="11.6" height="2.7" rx=".8"/>
              <path d="M3.3 5.6v6.9a.9.9 0 0 0 .9.9h7.6a.9.9 0 0 0 .9-.9V5.6"/>
              <path d="M6.5 8.4h3"/>`),
  play: S(`<rect x="2" y="3.5" width="12" height="9" rx="2"/>
           <path d="M6.9 6.3 10.3 8l-3.4 1.7z" fill="currentColor" stroke-width="1"/>`),
  clipboard: S(`<rect x="3.4" y="2.9" width="9.2" height="11.1" rx="1.8"/>
                <rect x="5.8" y="1.7" width="4.4" height="2.6" rx="1"/>`),
  star: S(`<path d="M8 2.3 9.75 5.9l3.95.57-2.86 2.79.68 3.94L8 11.34 4.48 13.2l.68-3.94L2.3 6.47l3.95-.57z"/>`),
  ellipsis: S(`<circle cx="8" cy="8" r="6.1"/>
               <circle cx="5.3" cy="8" r=".85" fill="currentColor" stroke="none"/>
               <circle cx="8" cy="8" r=".85" fill="currentColor" stroke="none"/>
               <circle cx="10.7" cy="8" r=".85" fill="currentColor" stroke="none"/>`),
  macwindow: S(`<rect x="1.8" y="3" width="12.4" height="10" rx="2.2"/><path d="M1.8 6.1h12.4"/>`),
  'arrow.up.forward.app': S(`<rect x="2.2" y="2.2" width="11.6" height="11.6" rx="3.2"/>
             <path d="M6.2 9.8 10 6"/><path d="M6.9 5.9h3.3v3.3"/>`),
  'rectangle.stack': S(`<rect x="2.1" y="6.3" width="11.8" height="7.5" rx="1.9"/>
             <path d="M4 4.3h8"/><path d="M5.4 2.3h5.2"/>`),
  'square.on.square': S(`<path d="M11.2 4.7V3.9a1.8 1.8 0 0 0-1.8-1.8H3.9A1.8 1.8 0 0 0 2.1 3.9v5.5a1.8 1.8 0 0 0 1.8 1.8h.8"/>
             <rect x="4.8" y="4.8" width="9.1" height="9.1" rx="1.9"/>`),
  'list.bullet.rectangle': S(`<rect x="1.9" y="2.7" width="12.2" height="10.6" rx="2.1"/>
             <circle cx="5.1" cy="6.4" r=".72" fill="currentColor" stroke="none"/>
             <circle cx="5.1" cy="9.6" r=".72" fill="currentColor" stroke="none"/>
             <path d="M7.3 6.4h3.7M7.3 9.6h3.7"/>`),
  tray: S(`<path d="M2.1 8.7h3.1l.9 1.5h3.8l.9-1.5h3.1"/>
             <path d="M2.1 8.7 3.7 4.8a1.1 1.1 0 0 1 1-.7h6.6a1.1 1.1 0 0 1 1 .7l1.6 3.9v2.5a1.1 1.1 0 0 1-1.1 1.1H3.2a1.1 1.1 0 0 1-1.1-1.1z"/>`),
  trash: S(`<path d="M2.9 4.4h10.2"/><path d="M6.4 4.4V3.1h3.2v1.3"/>
            <path d="M4.4 4.4l.58 8.2a.9.9 0 0 0 .9.84h4.24a.9.9 0 0 0 .9-.84l.58-8.2"/>`),
  power: S(`<path d="M8 2.2v5.5"/><path d="M11.5 4.3a4.7 4.7 0 1 1-7 0"/>`),
  xmark: S(`<path d="M4.6 4.6 11.4 11.4M11.4 4.6 4.6 11.4"/>`)
};

/* clipIconName(for:) — ContentView.swift:1405 */
const TYPE_ICON = {
  Texts: 'textformat', Links: 'link', Images: 'photo',
  Documents: 'doc', Files: 'archive', Medias: 'play'
};
const TYPE_LABEL = {
  Texts: 'Text', Links: 'Link', Images: 'Image',
  Documents: 'Doc', Files: 'File', Medias: 'Media'
};
const TYPE_COLOR = {
  Texts: 'var(--accent)', Links: '#0A84FF', Images: '#FF375F',
  Documents: '#FF9F0A', Files: '#5E5CE6', Medias: '#30D158'
};

/* ---------- mock clips ---------- */
const CLIPS = [
  { type: 'Texts',     preview: 'System.out.println(Arrays.toString(result));',            ts: '15 min ago',  starred: false, note: null },
  { type: 'Texts',     preview: 'System.out.println(Arrays.toString(dp[i]));',             ts: '5 sec ago',   starred: false, note: null },
  { type: 'Texts',     preview: 'while(!stack.isEmpty() && nums[stack.peek()] < nums[i])', ts: '30 sec ago',  starred: true,  note: null },
  { type: 'Texts',     preview: 'ICACSDF 2026',                                            ts: '26 min ago',  starred: false, note: 'conference deadline' },
  { type: 'Links',     preview: 'https://developer.apple.com/design/human-interface-guidelines', ts: '42 min ago', starred: true, note: null },
  { type: 'Images',    preview: 'Screenshot 2026-08-03 at 1.14.22 PM.png',                 ts: '1 hr ago',    starred: false, note: null },
  { type: 'Documents', preview: 'ICACSDF-camera-ready.pdf',                                ts: '2 hr ago',    starred: false, note: 'v3, reviewer fixes' },
  { type: 'Files',     preview: 'MultiClips-2.0-build7.zip',                               ts: '3 hr ago',    starred: false, note: null },
  { type: 'Medias',    preview: 'demo-recording.mov',                                      ts: 'yesterday',   starred: false, note: null }
];

/* ---------- concepts ---------- */
const CONCEPTS = [
  {
    id: 'current', cls: 'c-current', num: '00', name: 'Current', width: 300, rowH: 52, listH: 280,
    blurb: 'What ships today, rebuilt here for side-by-side comparison. Flat 10% theme wash on header and footer, 52pt rows, one type size doing all the work.',
    port: ['This is the baseline — <code>MenuBarView</code>, ContentView.swift:841.']
  },
  {
    id: 'glass', cls: 'c-glass', num: '01', name: 'Tahoe Glass', width: 300, rowH: 50, listH: 286,
    blurb: 'The native read. Layered vibrancy instead of a flat tint: frosted header and footer bars with a hairline top highlight, rows that become rounded capsules on hover, and each type icon seated in its own circular well.',
    port: [
      'Width unchanged at 300 — <code>.frame(width: 300)</code> stays.',
      'Row height 50 → set the list constant to <code>count * 50 + 12</code> (ContentView.swift:897).',
      'Replace both gradients (856-870, 934-940) with <code>.background(.regularMaterial)</code> plus a <code>.white.opacity(0.08)</code> top hairline.',
      'Icon well = <code>Circle().fill(.quaternary)</code> behind the existing symbol, 27pt.'
    ]
  },
  {
    id: 'console', cls: 'c-console', num: '02', name: 'Compact Console', width: 280, rowH: 38, listH: 266,
    blurb: 'Density for the way this app actually gets used — the clip list is mostly code. Previews go SF Mono, the timestamp becomes a right-aligned tabular column so it scans vertically, and hairlines replace gaps. Nine clips visible where five fit before.',
    port: [
      'Width 300 → 280.',
      'Row height 38 → list constant <code>count * 38 + 4</code>.',
      'Preview: <code>.font(.system(size: 11.5, design: .monospaced))</code>.',
      'Move the timestamp out of the VStack onto the trailing edge with <code>.monospacedDigit()</code> and a fixed 62pt frame.',
      'Drop the row <code>cornerRadius(6)</code>; use full-bleed hover + a 2pt leading accent bar.'
    ]
  },
  {
    id: 'cards', cls: 'c-cards', num: '03', name: 'Gradient Cards', width: 340, rowH: 58, listH: 296,
    blurb: 'The expressive one. Every clip is a card with a colour-coded left bar keyed to its type, a tinted icon tile, and real lift on hover. Header is a full theme gradient band; footer actions become tinted pills. Loud, and unmistakably not a system menu.',
    port: [
      'Width 300 → 340.',
      'Row height 58 → list constant <code>count * 58 + 16</code>, spacing 6 not 2.',
      'Per-type colour needs a new computed property on <code>ClipType</code> — the one place this concept adds code.',
      'Header gradient opacity 0.10 → 0.55 with a 115° angle.',
      'Footer buttons get <code>.background(.quaternary, in: RoundedRectangle(cornerRadius: 9))</code>.'
    ]
  },
  {
    id: 'quiet', cls: 'c-quiet', num: '04', name: 'Editorial Quiet', width: 320, rowH: 56, listH: 280,
    blurb: 'Near-monochrome restraint. The type icon is replaced by a small letterspaced word, rows breathe at 12pt vertical, hairlines separate instead of hover blocks. The accent appears exactly twice: an active star, and a 2pt bar that grows in on hover.',
    port: [
      'Width 300 → 320.',
      'Row height 56 → list constant <code>count * 56</code>, spacing 0.',
      'Swap <code>Image(systemName:)</code> for <code>Text(clip.type.shortLabel).font(.system(size: 8.5, weight: .semibold)).tracking(1.2)</code> in a 40pt frame.',
      'Remove both header/footer gradients entirely.',
      'Footer loses its icons — text only.'
    ]
  },
  {
    id: 'rail', cls: 'c-rail', num: '05', name: 'Rail Hybrid', footer: 'rail', width: 360, rowH: 54, listH: 286,
    blurb: 'Calm at rest, complete on hover. A left rail holds the type icon in a rounded tinted well; star and ellipsis fade in only when a row is hovered, so the default state is just content. The footer collapses to three icon buttons with labels underneath.',
    port: [
      'Width 300 → 360.',
      'Row height 54 → list constant <code>count * 54 + 10</code>.',
      'Actions get <code>.opacity(isHovered || clip.isStarred ? 1 : 0)</code> — a starred clip must stay visible at rest.',
      'Footer <code>VStack</code> → <code>HStack</code> of three <code>VStack(icon, label)</code> buttons.',
      'Widest concept — check it against a menu bar item near the right edge of the screen.'
    ]
  },
  {
    id: 'mix', cls: 'c-mix', num: '06', name: 'Bridge', footer: 'rail', width: 300, rowH: 52, listH: 280,
    blurb: 'Assembled to order: the frosted header from 01, the row layout shipping today in 00, and the side-by-side footer plus reveal-on-hover actions from 05 — all at the current 300pt width. Clear History is gone from the menu bar entirely, leaving two deliberate actions — and Quit carries the red now, the only coloured thing in the footer.',
    port: [
      'Width unchanged at 300 — <code>.frame(width: 300)</code> stays.',
      'Row height unchanged at 52 — <code>min(count * 52 + 20, 280)</code> at ContentView.swift:897 needs no edit. <b>This is the only concept that touches neither the row body nor the list constant.</b>',
      'Header (856-870): swap the <code>LinearGradient</code> for <code>.background(.regularMaterial)</code> + a <code>.white.opacity(0.08)</code> top hairline; wrap the <code>clipboard.fill</code> in a 22pt <code>RoundedRectangle(cornerRadius: 7)</code> filled <code>themeColor.opacity(0.20)</code>.',
      'Footer (902-940): <code>VStack</code> → <code>HStack</code> of two <code>VStack(icon, label)</code> buttons at <code>.frame(maxWidth: .infinity)</code>; labels shorten to Open / Quit.',
      '<b>Delete the Clear History button (913-921) and the <code>Divider()</code> at 923.</b> The <code>clips.forEach { modelContext.delete($0) }</code> loop goes with it — destructive bulk delete then lives only in the main window, behind its existing confirm alert (<code>showDeleteAllAlert</code>, ContentView.swift:55).',
      'Reveal-on-hover (from 05): put <code>.opacity(isHovered || clip.isStarred ? 1 : 0)</code> on each action button individually — not on the enclosing <code>HStack</code>, or a starred clip fades out at rest too. <code>isHovered</code> already exists at ContentView.swift:1009.',
      'Quit takes the red: move <code>.foregroundStyle(.red)</code> off the deleted Clear button (918) onto the Quit button (928). It is the only tinted control left in the footer.',
      'Open button icon is still being chosen — see the picker under the panel.'
    ]
  }
];

/* candidates for 06's Open button — swap live with the picker under the panel */
const OPEN_ICONS = [
  { id: 'macwindow',             label: 'macwindow',             note: 'current' },
  { id: 'arrow.up.forward.app',  label: 'arrow.up.forward.app',  note: 'opens elsewhere' },
  { id: 'rectangle.stack',       label: 'rectangle.stack',       note: 'the clip stack' },
  { id: 'square.on.square',      label: 'square.on.square',      note: 'softer window' },
  { id: 'list.bullet.rectangle', label: 'list.bullet.rectangle', note: 'the history list' },
  { id: 'tray',                  label: 'tray',                  note: 'matches sidebar' }
];
let openIcon = 'macwindow';

/* ---------- state ---------- */
const state = {};
CONCEPTS.forEach(c => {
  state[c.id] = { clips: CLIPS.map(x => ({ ...x })), sheet: null, draft: '' };
});
let isEmpty = false;

/* ---------- render ---------- */
const esc = s => String(s).replace(/[&<>"]/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[m]));

function headerHTML(c) {
  const n = state[c.id].clips.length;
  switch (c.id) {
    case 'console':
      return `<div class="p-head"><span class="p-head__name">MultiClips</span>
              <span class="p-head__count">${isEmpty ? 0 : n}</span></div>`;
    case 'quiet':
      return `<div class="p-head"><span class="p-head__name">MultiClips</span>
              <span class="p-head__rule"></span></div>`;
    case 'rail':
      return `<div class="p-head"><span class="p-head__mark">${ICON.clipboard}</span>
              <span class="p-head__name">MultiClips</span>
              <span class="p-head__count">${isEmpty ? 0 : n}</span></div>`;
    case 'glass':
      return `<div class="p-head"><span class="p-head__mark">${ICON.clipboard}</span>
              <span class="p-head__name">MultiClips</span></div>`;
    default:
      return `<div class="p-head"><span class="p-head__mark">${ICON.clipboard}</span>
              <span class="p-head__name">MultiClips</span></div>`;
  }
}

function leadingHTML(c, clip) {
  if (c.id === 'quiet') return `<span class="row__type">${TYPE_LABEL[clip.type]}</span>`;
  return `<span class="row__icon">${ICON[TYPE_ICON[clip.type]]}</span>`;
}

function rowHTML(c, clip, i) {
  const sub = clip.note
    ? `<span class="row__sub is-note">${esc(clip.note)}</span>`
    : `<span class="row__sub">${esc(clip.ts)}</span>`;
  return `
    <div class="row" role="button" tabindex="0" data-act="copy" data-i="${i}"
         style="--type-color:${TYPE_COLOR[clip.type]}">
      ${leadingHTML(c, clip)}
      <span class="row__body">
        <span class="row__title">${esc(clip.preview)}</span>
        ${sub}
      </span>
      <span class="row__acts">
        <button class="iconbtn star${clip.starred ? ' is-on' : ''}" data-act="star" data-i="${i}"
                aria-label="${clip.starred ? 'Unstar' : 'Star'}">${ICON.star}</button>
        <button class="iconbtn" data-act="sheet" data-i="${i}" aria-label="Clip actions">${ICON.ellipsis}</button>
      </span>
    </div>`;
}

function listHTML(c) {
  if (isEmpty) {
    return `<div class="empty">
      <span class="empty__glyph"><svg viewBox="0 0 16 16" width="34" height="34" fill="none"
        stroke="currentColor" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round">
        <rect x="3.4" y="2.9" width="9.2" height="11.1" rx="1.8"/>
        <rect x="5.8" y="1.7" width="4.4" height="2.6" rx="1"/></svg></span>
      <span class="empty__t1">No clips yet</span>
      <span class="empty__t2">Copy something to get started</span>
    </div>`;
  }
  const rows = state[c.id].clips.map((clip, i) => rowHTML(c, clip, i)).join('');
  return `<div class="p-list" style="max-height:${c.listH}px">${rows}</div>`;
}

function footerHTML(c) {
  /* 06 drops Clear entirely — Clear History stays available in the main window */
  if (c.id === 'mix') {
    return `<div class="p-foot">
      <button class="fbtn" data-act="noop" style="flex:1">${ICON[openIcon]}<span>Open</span></button>
      <button class="fbtn is-danger" data-act="noop" style="flex:1">${ICON.power}<span>Quit</span></button>
    </div>`;
  }
  if (c.footer === 'rail') {
    return `<div class="p-foot">
      <button class="fbtn" data-act="noop" style="flex:1">${ICON.macwindow}<span>Open</span></button>
      <button class="fbtn is-danger" data-act="noop" style="flex:1">${ICON.trash}<span>Clear</span></button>
      <button class="fbtn" data-act="noop" style="flex:1">${ICON.power}<span>Quit</span></button>
    </div>`;
  }
  return `<div class="p-foot">
    <button class="fbtn" data-act="noop">${ICON.macwindow}<span>Open MultiClips</span></button>
    <button class="fbtn is-danger" data-act="noop">${ICON.trash}<span>Clear History</span></button>
    <div class="hair"></div>
    <button class="fbtn" data-act="noop">${ICON.power}<span>Quit MultiClips</span></button>
  </div>`;
}

function sheetHTML(c) {
  const st = state[c.id];
  const clip = st.sheet === null ? null : st.clips[st.sheet];
  const starred = clip ? clip.starred : false;
  const draft = clip ? st.draft : '';
  return `
    <div class="scrim" data-act="close-sheet"></div>
    <div class="sheet" role="dialog" aria-label="Clip Actions">
      <div class="sheet__head">
        <span class="sheet__title">Clip Actions</span>
        <button class="sheet__x" data-act="close-sheet" aria-label="Close">${ICON.xmark}</button>
      </div>
      <div class="hair"></div>
      <button class="sheet__star" data-act="sheet-star">
        <span class="star${starred ? ' is-on' : ''}">${ICON.star}</span>
        <span>${starred ? 'Unstar' : 'Star'}</span>
      </button>
      <div class="hair"></div>
      <div class="sheet__note">
        <span class="sheet__lbl">Note<span class="sheet__count">${draft.length}/60</span></span>
        <input class="sheet__field" type="text" maxlength="60" placeholder="Add a short note…"
               value="${esc(draft)}" data-act="note">
        <div class="sheet__btns">
          <button class="sbtn" data-act="close-sheet">Cancel</button>
          <button class="sbtn is-primary" data-act="save-note">Save</button>
        </div>
      </div>
    </div>`;
}

function pickerHTML(c) {
  if (c.id !== 'mix') return '';
  const opts = OPEN_ICONS.map(o => `
    <button class="pick${o.id === openIcon ? ' is-on' : ''}" data-icon="${o.id}"
            title="${o.note}">
      ${ICON[o.id]}<span class="pick__name">${o.label}</span>
    </button>`).join('');
  return `<div class="picker">
    <span class="picker__label">Open icon — pick one</span>
    <div class="picker__row">${opts}</div>
  </div>`;
}

function panelHTML(c) {
  return `
    <section class="spec" data-concept="${c.id}">
      <div class="spec__head">
        <span class="spec__num">${c.num}</span>
        <h2 class="spec__name">${c.name}</h2>
        <span class="spec__meta">${c.width}pt · ${c.rowH}pt row</span>
      </div>
      <p class="spec__blurb">${c.blurb}</p>
      <div class="panel ${c.cls}${state[c.id].sheet !== null ? ' is-sheet' : ''}"
           data-concept="${c.id}" style="--w:${c.width}px">
        ${headerHTML(c)}
        ${listHTML(c)}
        ${footerHTML(c)}
        <div class="toast">Copied</div>
        ${sheetHTML(c)}
      </div>
      ${pickerHTML(c)}
      <details class="spec__port">
        <summary>Porting notes</summary>
        <ul>${c.port.map(p => `<li>${p}</li>`).join('')}</ul>
      </details>
    </section>`;
}

const gallery = document.getElementById('gallery');

function applySolo(value) {
  if (!value || value === 'all') delete gallery.dataset.solo;
  else gallery.dataset.solo = value;
  gallery.querySelectorAll('.spec')
    .forEach(s => s.classList.toggle('is-solo', s.dataset.concept === value));
}

function renderAll() {
  gallery.innerHTML = CONCEPTS.map(panelHTML).join('');
  applySolo(gallery.dataset.solo);
}

function renderPanel(id) {
  const c = CONCEPTS.find(x => x.id === id);
  const old = gallery.querySelector(`.spec[data-concept="${id}"]`);
  if (!old) return;
  const tmp = document.createElement('div');
  tmp.innerHTML = panelHTML(c);
  const fresh = tmp.firstElementChild;
  const wasOpen = old.querySelector('.spec__port').open;
  fresh.querySelector('.spec__port').open = wasOpen;
  old.replaceWith(fresh);
  applySolo(gallery.dataset.solo);
  const field = fresh.querySelector('.sheet__field');
  if (state[id].sheet !== null && field) {
    field.focus();
    field.setSelectionRange(field.value.length, field.value.length);
  }
}

/* ---------- interactions ---------- */
gallery.addEventListener('click', e => {
  const pick = e.target.closest('[data-icon]');
  if (pick) {
    openIcon = pick.dataset.icon;
    renderPanel('mix');
    return;
  }

  const hit = e.target.closest('[data-act]');
  if (!hit) return;
  const panel = hit.closest('.panel');
  if (!panel) return;
  const id = panel.dataset.concept;
  const st = state[id];
  const act = hit.dataset.act;
  const i = hit.dataset.i !== undefined ? +hit.dataset.i : null;

  if (act === 'star') {
    e.stopPropagation();
    st.clips[i].starred = !st.clips[i].starred;
    const btn = panel.querySelectorAll('.row .star')[i];
    btn.classList.toggle('is-on', st.clips[i].starred);
    btn.setAttribute('aria-label', st.clips[i].starred ? 'Unstar' : 'Star');
    if (st.clips[i].starred) {
      btn.classList.add('just-set');
      setTimeout(() => btn.classList.remove('just-set'), 220);
    }
    return;
  }

  if (act === 'sheet') {
    e.stopPropagation();
    st.sheet = i;
    st.draft = st.clips[i].note || '';
    renderPanel(id);
    return;
  }

  if (act === 'close-sheet') {
    st.sheet = null;
    renderPanel(id);
    return;
  }

  if (act === 'sheet-star') {
    st.clips[st.sheet].starred = !st.clips[st.sheet].starred;
    renderPanel(id);
    return;
  }

  if (act === 'save-note') {
    const v = st.draft.trim();
    st.clips[st.sheet].note = v ? v.slice(0, 60) : null;
    st.sheet = null;
    renderPanel(id);
    return;
  }

  if (act === 'copy') {
    panel.classList.add('is-copied');
    clearTimeout(panel._t);
    panel._t = setTimeout(() => panel.classList.remove('is-copied'), 900);
  }
});

gallery.addEventListener('input', e => {
  if (e.target.dataset.act !== 'note') return;
  const panel = e.target.closest('.panel');
  const st = state[panel.dataset.concept];
  st.draft = e.target.value.slice(0, 60);
  if (e.target.value !== st.draft) e.target.value = st.draft;
  panel.querySelector('.sheet__count').textContent = `${st.draft.length}/60`;
});

gallery.addEventListener('keydown', e => {
  if (e.target.dataset.act === 'note' && e.key === 'Enter') {
    e.target.closest('.sheet').querySelector('[data-act="save-note"]').click();
  }
  if (e.key === 'Escape') {
    const panel = e.target.closest('.panel');
    if (panel && state[panel.dataset.concept].sheet !== null) {
      state[panel.dataset.concept].sheet = null;
      renderPanel(panel.dataset.concept);
    }
  }
  if (e.key === 'Enter' && e.target.classList.contains('row')) e.target.click();
});

/* ---------- controls ---------- */
document.getElementById('swatches').addEventListener('click', e => {
  const b = e.target.closest('.sw');
  if (!b) return;
  document.documentElement.dataset.theme = b.dataset.theme;
  document.querySelectorAll('.sw').forEach(s => s.setAttribute('aria-checked', String(s === b)));
});

document.getElementById('modeSeg').addEventListener('click', e => {
  const b = e.target.closest('button');
  if (!b) return;
  document.documentElement.dataset.mode = b.dataset.mode;
  b.parentElement.querySelectorAll('button').forEach(x => x.classList.toggle('is-on', x === b));
});

document.getElementById('stateSeg').addEventListener('click', e => {
  const b = e.target.closest('button');
  if (!b) return;
  isEmpty = b.dataset.state === 'empty';
  b.parentElement.querySelectorAll('button').forEach(x => x.classList.toggle('is-on', x === b));
  CONCEPTS.forEach(c => { state[c.id].sheet = null; });
  renderAll();
});

const solo = document.getElementById('soloSelect');
CONCEPTS.forEach(c => solo.add(new Option(`${c.num} · ${c.name}`, c.id)));
solo.addEventListener('change', () => applySolo(solo.value));

/* ---------- deep link: #theme=blue&mode=light&view=quiet&state=empty ---------- */
function applyHash() {
  const q = new URLSearchParams(location.hash.slice(1));

  const theme = q.get('theme');
  const swatch = theme && document.querySelector(`.sw[data-theme="${theme}"]`);
  if (swatch) {
    document.documentElement.dataset.theme = theme;
    document.querySelectorAll('.sw').forEach(s => s.setAttribute('aria-checked', String(s === swatch)));
  }

  const mode = q.get('mode');
  if (mode === 'light' || mode === 'dark') {
    document.documentElement.dataset.mode = mode;
    document.querySelectorAll('#modeSeg button').forEach(b => b.classList.toggle('is-on', b.dataset.mode === mode));
  }

  isEmpty = q.get('state') === 'empty';
  document.querySelectorAll('#stateSeg button')
    .forEach(b => b.classList.toggle('is-on', (b.dataset.state === 'empty') === isEmpty));

  const view = q.get('view') || 'all';
  const valid = CONCEPTS.some(c => c.id === view) ? view : 'all';
  solo.value = valid;
  applySolo(valid);

  CONCEPTS.forEach(c => { state[c.id].sheet = null; });
  renderAll();
}

window.addEventListener('hashchange', applyHash);
applyHash();
