/* =========================================================
   MultiClips — main window concepts (Version History + Credits)
   Static preview. No app code is touched by this file.
   ========================================================= */

const S = (d, extra = '') =>
  `<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4"
     stroke-linecap="round" stroke-linejoin="round" ${extra}>${d}</svg>`;

const ICON = {
  tray: S(`<path d="M2.1 8.7h3.1l.9 1.5h3.8l.9-1.5h3.1"/>
           <path d="M2.1 8.7 3.7 4.8a1.1 1.1 0 0 1 1-.7h6.6a1.1 1.1 0 0 1 1 .7l1.6 3.9v2.5a1.1 1.1 0 0 1-1.1 1.1H3.2a1.1 1.1 0 0 1-1.1-1.1z"/>`),
  star: S(`<path d="M8 2.3 9.75 5.9l3.95.57-2.86 2.79.68 3.94L8 11.34 4.48 13.2l.68-3.94L2.3 6.47l3.95-.57z"/>`),
  doc: S(`<path d="M4 2.2h4.4L12 5.6V13a.8.8 0 0 1-.8.8H4a.8.8 0 0 1-.8-.8V3a.8.8 0 0 1 .8-.8z"/>
          <path d="M8.3 2.4v3.3h3.4"/><path d="M5.6 9.2h4.2M5.6 11.3h2.9"/>`),
  photo: S(`<rect x="2" y="3.5" width="12" height="9" rx="2"/><circle cx="5.6" cy="6.9" r=".95"/>
            <path d="M2.6 11.6 6 8.5l2.3 2 2.2-1.9 2.9 2.9"/>`),
  play: S(`<rect x="2" y="3.5" width="12" height="9" rx="2"/>
           <path d="M6.9 6.3 10.3 8l-3.4 1.7z" fill="currentColor" stroke-width="1"/>`),
  folder: S(`<path d="M2.1 5.1a1.2 1.2 0 0 1 1.2-1.2h2.4l1.3 1.6h4.8a1.2 1.2 0 0 1 1.2 1.2v4.6a1.2 1.2 0 0 1-1.2 1.2H3.3a1.2 1.2 0 0 1-1.2-1.2z"/>`),
  link: S(`<path d="M6.8 9.2a2.6 2.6 0 0 0 3.7 0l2.1-2.1a2.6 2.6 0 0 0-3.7-3.7l-1 1"/>
           <path d="M9.2 6.8a2.6 2.6 0 0 0-3.7 0l-2.1 2.1a2.6 2.6 0 0 0 3.7 3.7l1-1"/>`),
  clock: S(`<circle cx="8" cy="8" r="6"/><path d="M8 4.6V8l2.3 1.4"/>`),
  gear: S(`<circle cx="8" cy="8" r="2.1"/>
           <path d="M12.9 9.7a1.1 1.1 0 0 0 .22 1.21l.04.04a1.33 1.33 0 1 1-1.88 1.88l-.04-.04a1.1 1.1 0 0 0-1.21-.22 1.1 1.1 0 0 0-.67 1v.11a1.33 1.33 0 0 1-2.66 0v-.06a1.1 1.1 0 0 0-.72-1 1.1 1.1 0 0 0-1.21.22l-.04.04a1.33 1.33 0 1 1-1.88-1.88l.04-.04a1.1 1.1 0 0 0 .22-1.21 1.1 1.1 0 0 0-1-.67h-.11a1.33 1.33 0 1 1 0-2.66h.06a1.1 1.1 0 0 0 1-.72 1.1 1.1 0 0 0-.22-1.21l-.04-.04A1.33 1.33 0 1 1 4.7 2.79l.04.04a1.1 1.1 0 0 0 1.21.22h.05a1.1 1.1 0 0 0 .67-1v-.11a1.33 1.33 0 1 1 2.66 0v.06a1.1 1.1 0 0 0 .67 1 1.1 1.1 0 0 0 1.21-.22l.04-.04a1.33 1.33 0 1 1 1.88 1.88l-.04.04a1.1 1.1 0 0 0-.22 1.21v.05a1.1 1.1 0 0 0 1 .67h.11a1.33 1.33 0 0 1 0 2.66h-.06a1.1 1.1 0 0 0-1 .67z"/>`),
  trash: S(`<path d="M2.9 4.4h10.2"/><path d="M6.4 4.4V3.1h3.2v1.3"/>
            <path d="M4.4 4.4l.58 8.2a.9.9 0 0 0 .9.84h4.24a.9.9 0 0 0 .9-.84l.58-8.2"/>`),
  person: S(`<circle cx="8" cy="8" r="6"/><circle cx="8" cy="6.4" r="1.9"/>
             <path d="M4.2 12.4a4 4 0 0 1 7.6 0"/>`),
  history: S(`<circle cx="8" cy="8" r="5.9"/><path d="M8 4.7V8l2.2 1.3"/>
              <path d="m10.6 11.6 1.3 1.3 2.2-2.4" stroke-width="1.5"/>`),
  refresh: S(`<circle cx="8" cy="8" r="6"/><path d="M8 4.8V8l2.2 1.3"/>`),
  check: S(`<circle cx="8" cy="8" r="6"/><path d="m5.4 8.2 1.8 1.8 3.5-3.7"/>`),
  arrowUpRight: S(`<path d="M5.2 10.8 10.8 5.2"/><path d="M6.2 5.2h4.6v4.6"/>`),
  code: S(`<path d="M5.6 5.4 2.9 8l2.7 2.6"/><path d="M10.4 5.4 13.1 8l-2.7 2.6"/><path d="M9.2 3.7 6.8 12.3"/>`),
  people: S(`<circle cx="6.2" cy="6" r="2.1"/><path d="M2.4 12.6a3.9 3.9 0 0 1 7.6 0"/>
             <path d="M10.6 4.2a2.1 2.1 0 0 1 0 3.7"/><path d="M11.4 9.4a3.9 3.9 0 0 1 2.2 3.2"/>`),
  sidebar: S(`<rect x="1.9" y="3" width="12.2" height="10" rx="2"/><path d="M6.2 3v10"/>`)
};

/* ---------- data ---------- */
/* releases as shown in-app today (ContentView.swift:1306), split into version + build */
const RELEASES = [
  { ver: 'v2.0', build: 'Build 7', date: '3 Aug 2026', latest: true, points: [
    "Ad-hoc code signing to prevent 'damaged app' errors",
    'Fixed DMG installation issues on macOS',
    'Auto-updater with one-click updates',
    'Build number tracking for accurate update detection'
  ]},
  { ver: 'v1.2.1', build: null, date: '26 Mar 2026', points: [
    'Per-clip actions from menu icon bar rows',
    'Three-dots action dialog with Star and Add Text (Note)',
    'Main app navbar quick note input removed',
    'Clip row click now opens actions dialog in icon bar'
  ]},
  { ver: 'v1.2.0', build: null, date: '26 Mar 2026', points: [
    'Clip search with live filtering across clip content',
    'Tiny note support per clip',
    'Quick add text option in the top bar',
    'App now opens with All Clips by default'
  ]},
  { ver: 'v1.1.0', build: null, date: '19 Mar 2026', points: [
    'Theme customization with multiple color options',
    'Credits page and release tracking screen',
    'Improved contextual icons and relative-time labels',
    'Menu bar open-window behavior improvements'
  ]},
  { ver: 'v1.0.0', build: null, date: 'Initial Release', points: [
    'Clipboard history for text, files, and images',
    'Menu bar quick-copy access',
    'Local persistence with SwiftData'
  ]}
];

/* from the project file + Item.swift — real values, not invented */
const FACTS = [
  ['Version',  'v2.0 (Build 7)'],
  ['Requires', 'macOS 14.6 or later'],
  ['Storage',  'SwiftData, on-device'],
  ['Licence',  'MIT']
];

const LINKS = [
  { t: 'GitHub Profile',   s: 'github.com/nitish1705',        ico: 'code'   },
  { t: 'LinkedIn Profile', s: 'linkedin.com/in/nitish--m',    ico: 'people' }
];

/* ---------- sidebar ---------- */
function sidebarHTML(active) {
  const item = (ico, label, count, cls = '') => `
    <button class="side__item ${cls}${label === active ? ' is-on' : ''}">
      ${ICON[ico]}<span>${label}</span>
      ${count ? `<span class="side__count">${count}</span>` : ''}
    </button>`;
  return `<aside class="side">
    <div class="lights"><i></i><i></i><i></i></div>
    <div class="side__group">Clips</div>
    ${item('tray', 'All Clips', 11)}
    ${item('star', 'Starred')}
    ${item('doc', 'Texts', 5)}
    ${item('photo', 'Images', 6)}
    ${item('play', 'Media')}
    ${item('folder', 'Files')}
    ${item('link', 'Links')}
    <div class="side__group">History</div>
    ${item('clock', 'Recent Activity')}
    <div class="side__group">Settings</div>
    ${item('gear', 'General Settings')}
    ${item('trash', 'Clear History', null, 'side__danger')}
    <div class="side__group">About</div>
    ${item('person', 'Developer / Credits')}
    ${item('history', 'Version History')}
    ${item('refresh', 'Check for Updates')}
  </aside>`;
}

/* ---------- Version History bodies ---------- */
function timelineHTML() {
  return `<div class="tl">` + RELEASES.map(r => `
    <div class="tl__rel${r.latest ? ' is-latest' : ''}">
      <div class="tl__rail"><span class="tl__node"></span></div>
      <div class="tl__body">
        <div class="tl__head">
          <span class="tl__ver">${r.ver}</span>
          ${r.build ? `<span class="tl__build">${r.build}</span>` : ''}
          ${r.latest ? `<span class="pill">Current</span>` : ''}
          <span class="tl__date">${r.date}</span>
        </div>
        <ul class="tl__list">
          ${r.points.map(p => `<li class="tl__li">${ICON.check}<span>${p}</span></li>`).join('')}
        </ul>
      </div>
    </div>`).join('') + `</div>`;
}

function cardsHTML() {
  return `<div class="rc">` + RELEASES.map(r => `
    <div class="rc__card${r.latest ? ' is-latest' : ''}">
      <div class="rc__head">
        <span class="rc__ver">${r.ver}</span>
        ${r.build ? `<span class="rc__build">${r.build}</span>` : ''}
        ${r.latest ? `<span class="pill">Latest</span>` : ''}
        <span class="rc__date">${r.date}</span>
      </div>
      <div class="rc__grid">
        ${r.points.map(p => `<div class="rc__li">${ICON.check}<span>${p}</span></div>`).join('')}
      </div>
    </div>`).join('') + `</div>`;
}

/* ---------- Credits bodies ---------- */
const linkRowHTML = l => `
  <button class="link">
    <span class="link__ico">${ICON[l.ico]}</span>
    <span class="link__txt"><span class="link__t">${l.t}</span><span class="link__s">${l.s}</span></span>
    <span class="link__go">${ICON.arrowUpRight}</span>
  </button>`;

function heroHTML() {
  return `<div class="hero">
    <div class="hero__ring">N</div>
    <h3 class="hero__name">Nitish</h3>
    <p class="hero__role">Developer &amp; maintainer, MultiClips</p>
    <p class="hero__where">Built with SwiftUI and SwiftData for macOS</p>
    <div class="links">${LINKS.map(linkRowHTML).join('')}</div>
    <div class="facts">
      <h4 class="facts__h">About this app</h4>
      <div class="facts__grid">
        ${FACTS.map(([k, v]) => `<div class="fact"><span class="fact__k">${k}</span><span class="fact__v">${v}</span></div>`).join('')}
      </div>
    </div>
  </div>`;
}

function splitHTML() {
  return `<div class="split">
    <div class="split__id">
      <div class="split__mono">N</div>
      <h3 class="split__name">Nitish</h3>
      <p class="split__role">Developer &amp; maintainer</p>
      <div class="split__meta">
        ${FACTS.map(([k, v]) => `<div class="split__row"><span>${k}</span><span>${v}</span></div>`).join('')}
      </div>
    </div>
    <div class="split__right">
      <div>
        <h4 class="block__h">Find me</h4>
        <div class="stack">${LINKS.map(linkRowHTML).join('')}</div>
      </div>
      <div>
        <h4 class="block__h">The app</h4>
        <div class="stack">
          <button class="link">
            <span class="link__ico">${ICON.code}</span>
            <span class="link__txt"><span class="link__t">Source &amp; releases</span><span class="link__s">github.com/nitish1705/MultiClips</span></span>
            <span class="link__go">${ICON.arrowUpRight}</span>
          </button>
          <button class="link">
            <span class="link__ico">${ICON.history}</span>
            <span class="link__txt"><span class="link__t">Version History</span><span class="link__s">Every release, newest first</span></span>
            <span class="link__go">${ICON.arrowUpRight}</span>
          </button>
          <button class="link">
            <span class="link__ico">${ICON.refresh}</span>
            <span class="link__txt"><span class="link__t">Check for Updates</span><span class="link__s">You are on the latest build</span></span>
            <span class="link__go">${ICON.arrowUpRight}</span>
          </button>
        </div>
      </div>
    </div>
  </div>`;
}

/* ---------- concepts ---------- */
const CONCEPTS = [
  {
    id: 'tl', num: '01', page: 'Version History', name: 'Timeline',
    sidebar: 'Version History', title: 'Version History', sub: '5 releases',
    body: timelineHTML,
    blurb: 'A rail with a node per release: the current build gets a filled node and a Current pill, everything older is hollow. Version, build chip and date share one line; the highlights below are ordinary label text, so the accent only marks structure instead of colouring every word.',
    port: [
      'Replace the <code>List</code> at <code>ContentView.swift:1359</code> with a <code>ScrollView</code> + <code>LazyVStack</code> — <code>List</code> row insets fight the rail.',
      'Bullets go from <code>activeTheme.color.opacity(0.9)</code> (1370) to <code>.primary</code>; only the <code>checkmark.circle</code> keeps the accent.',
      '<code>AppRelease</code> (42-47) needs a <code>build: String?</code> field so the chip is separate from the version string — today "v2.0 (Build 6)" is one blob.',
      'The stored list still says Build 6 while the project is on Build 7 (<code>CURRENT_PROJECT_VERSION = 7</code>). Read it from the bundle instead of hardcoding, or it drifts again.',
      'Apply the background fix from the top of this page at <code>1378</code>.'
    ]
  },
  {
    id: 'rc', num: '02', page: 'Version History', name: 'Release Cards',
    sidebar: 'Version History', title: 'Version History', sub: '5 releases',
    body: cardsHTML,
    blurb: 'Each release is a card with an accent hairline across the top, brightest on the newest. Version sits large at 21pt so the list scans by number, and the highlights run in two columns — four bullets fit in the height one column needs, which halves the scrolling.',
    port: [
      'Same <code>List</code> → <code>ScrollView</code> + <code>LazyVStack(spacing: 14)</code> swap at <code>ContentView.swift:1359</code>.',
      'Two-column bullets: <code>LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8)</code>. Collapse to one column under ~700pt window width via <code>@Environment(\\.horizontalSizeClass)</code> or a <code>GeometryReader</code>.',
      'Card top edge is a 2pt <code>LinearGradient</code> from accent to <code>accent.opacity(0)</code> — the same on-hue fade the background fix uses.',
      'Latest card gets <code>accent.opacity(0.07)</code> fill and a <code>0.28</code> stroke; the rest stay neutral.',
      'Also needs the <code>build</code> field split on <code>AppRelease</code>.'
    ]
  },
  {
    id: 'hero', num: '03', page: 'Credits', name: 'Profile Hero',
    sidebar: 'Developer / Credits', title: 'Credits', sub: null,
    body: heroHTML,
    blurb: 'Centred and vertical. A monogram replaces the generic person glyph, the two link rows carry their actual handles as subtitles instead of "Open projects and source code", and an About this app grid fills the two-thirds of the window that currently sits empty.',
    port: [
      'Drop the Quick Links block entirely (<code>ContentView.swift:1224-1242</code>) — it duplicates the rows above it, and <code>Link</code> renders system blue regardless of <code>.tint</code>, which is why those capsules never matched the theme.',
      'Monogram: <code>Text(String(developerName.prefix(1)))</code> over a <code>Circle</code>, replacing <code>person.crop.circle.fill</code> (1192).',
      'Row subtitles become the real destinations — the URLs are already there at 1213 and 1220.',
      'Facts grid reads the bundle: <code>Bundle.main.infoDictionary["CFBundleShortVersionString"]</code> and <code>"CFBundleVersion"</code>. Nothing hardcoded.',
      'Wrap in <code>.frame(maxWidth: 560)</code> so it stays centred as the window widens.'
    ]
  },
  {
    id: 'split', num: '04', page: 'Credits', name: 'Split',
    sidebar: 'Developer / Credits', title: 'Credits', sub: null,
    body: splitHTML,
    blurb: 'Two columns: a tinted identity card pinned left with the app facts underneath it, and a right column that groups the personal links separately from the app links — source, version history, updates. Uses the full window width instead of a narrow strip at the top.',
    port: [
      'Same removal of the duplicate Quick Links block (<code>1224-1242</code>).',
      'Layout: <code>HStack(alignment: .top, spacing: 26)</code> with the identity card at <code>.frame(width: 250)</code>; fall back to a <code>VStack</code> under ~900pt.',
      'The three app rows are new but wire to things that already exist — the repo URL, the <code>VersionHistoryView</code> destination, and <code>UpdateManager</code>.',
      '"You are on the latest build" must come from <code>UpdateManager</code>, not a literal, or it will lie the moment a release ships.',
      'Identity card background is an on-hue gradient over <code>--card</code>; do not fade it to <code>.clear</code> either.'
    ]
  }
];

/* ---------- render ---------- */
function specHTML(c) {
  return `
    <section class="spec" data-concept="${c.id}">
      <div class="spec__head">
        <span class="spec__num">${c.num}</span>
        <h2 class="spec__name">${c.name}</h2>
        <span class="spec__page">${c.page}</span>
      </div>
      <p class="spec__blurb">${c.blurb}</p>
      <div class="win">
        ${sidebarHTML(c.sidebar)}
        <div class="pane">
          <div class="pane__bar">
            <span class="pane__title">${c.title}</span>
            ${c.sub ? `<span class="pane__sub">${c.sub}</span>` : ''}
          </div>
          <div class="pane__body">${c.body()}</div>
        </div>
      </div>
      <details class="spec__port">
        <summary>Porting notes</summary>
        <ul>${c.port.map(p => `<li>${p}</li>`).join('')}</ul>
      </details>
    </section>`;
}

const gallery = document.getElementById('gallery');
const solo = document.getElementById('soloSelect');

function applySolo(value) {
  if (!value || value === 'all') delete gallery.dataset.solo;
  else gallery.dataset.solo = value;
  gallery.querySelectorAll('.spec')
    .forEach(s => s.classList.toggle('is-solo', s.dataset.concept === value));
}

function renderAll() {
  gallery.innerHTML = CONCEPTS.map(specHTML).join('');
  applySolo(gallery.dataset.solo);
}

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

CONCEPTS.forEach(c => solo.add(new Option(`${c.num} · ${c.page} — ${c.name}`, c.id)));
solo.addEventListener('change', () => applySolo(solo.value));

/* ---------- deep link: #theme=blue&mode=light&view=tl ---------- */
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

  const view = q.get('view') || 'all';
  const valid = CONCEPTS.some(c => c.id === view) ? view : 'all';
  solo.value = valid;
  applySolo(valid);
  renderAll();
}

window.addEventListener('hashchange', applyHash);
applyHash();
