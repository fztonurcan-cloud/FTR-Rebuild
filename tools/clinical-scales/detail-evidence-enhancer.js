(() => {
  'use strict';
  const db = window.FTR_CLINICAL_SCALES;
  if (!db || !Array.isArray(db.scales)) throw new Error('Clinical scales data missing before detail evidence enhancer');

  const title = document.getElementById('scaleTitle');
  const body = document.getElementById('detailBody');
  const tabs = document.getElementById('detailTabs');
  if (!title || !body || !tabs) return;

  const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  const scaleFromTitle = () => db.scales.find(scale => scale.name === title.textContent.trim());
  const activeTab = () => tabs.querySelector('button.active')?.dataset.tab || '';

  function render() {
    const scale = scaleFromTitle();
    if (!scale) return;
    const tab = activeTab();
    const token = `${scale.id}:${tab}:${db.scoringEvidenceVersion || 'none'}`;
    if (body.dataset.deepEvidenceFor === token) return;

    body.querySelectorAll('.deep-evidence-card').forEach(node => node.remove());

    if (tab === 'score' && Array.isArray(scale.scoringArchitecture) && scale.scoringArchitecture.length) {
      const section = document.createElement('section');
      section.className = 'deep-evidence-card';
      section.setAttribute('aria-label', 'Skor mimarisi');
      section.innerHTML = `
        <div class="deep-evidence-head"><span aria-hidden="true">∑</span><div><b>Skor Mimarisi</b><small>Sürüm ve hak durumuna göre güvenli eğitim özeti</small></div></div>
        <ul>${scale.scoringArchitecture.map(item => `<li>${esc(item)}</li>`).join('')}</ul>
      `;
      body.appendChild(section);
    }

    if (tab === 'about' && scale.evidenceNote) {
      const section = document.createElement('section');
      section.className = 'deep-evidence-card compact';
      section.innerHTML = `<div class="deep-evidence-head"><span aria-hidden="true">✓</span><div><b>Kanıt Notu</b><small>${esc(scale.evidenceDate || '')}</small></div></div><p>${esc(scale.evidenceNote)}</p>`;
      body.appendChild(section);
    }

    if (tab === 'sources' && Array.isArray(scale.turkishEvidence) && scale.turkishEvidence.length) {
      const section = document.createElement('section');
      section.className = 'deep-evidence-card';
      section.innerHTML = `
        <div class="deep-evidence-head"><span aria-hidden="true">TR</span><div><b>Türkçe Psikometrik Kanıt</b><small>Popülasyon ve sürüm ayrımı korunur</small></div></div>
        <ul>${scale.turkishEvidence.map(item => `<li><a href="${esc(item.url)}" target="_blank" rel="noopener">${esc(item.label)}</a></li>`).join('')}</ul>
      `;
      body.appendChild(section);
    }

    body.dataset.deepEvidenceFor = token;
  }

  const observer = new MutationObserver(() => queueMicrotask(render));
  observer.observe(body, {childList:true, subtree:true, characterData:true});
  observer.observe(title, {childList:true, subtree:true, characterData:true});
  tabs.addEventListener('click', () => setTimeout(render, 0));
  document.addEventListener('click', event => {
    if (event.target.closest('.scale-row,.category-card')) setTimeout(render, 0);
  }, true);
  render();
})();
