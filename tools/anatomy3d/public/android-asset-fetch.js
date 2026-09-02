/* Android WebView does not consistently fetch file:///android_asset URLs.
   Keep normal browser fetch untouched and bridge only packaged local assets. */
(() => {
  'use strict';
  if (window.__FTR_ANDROID_ASSET_FETCH__ || typeof window.fetch !== 'function') return;
  window.__FTR_ANDROID_ASSET_FETCH__ = true;
  const nativeFetch = window.fetch.bind(window);

  function mime(url) {
    const path = url.pathname.toLowerCase();
    if (path.endsWith('.json')) return 'application/json; charset=utf-8';
    if (path.endsWith('.glb')) return 'model/gltf-binary';
    if (path.endsWith('.wasm')) return 'application/wasm';
    if (path.endsWith('.js')) return 'text/javascript; charset=utf-8';
    return 'application/octet-stream';
  }

  window.fetch = function ftrAssetFetch(input, init) {
    const raw = typeof input === 'string' || input instanceof URL ? String(input) : input?.url;
    let url;
    try {
      url = new URL(raw, document.baseURI);
    } catch (_) {
      return nativeFetch(input, init);
    }
    if (location.protocol !== 'file:' || url.protocol !== 'file:' || !url.pathname.includes('/android_asset/')) {
      return nativeFetch(input, init);
    }

    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open((init?.method || input?.method || 'GET').toUpperCase(), url.href, true);
      xhr.responseType = 'arraybuffer';
      xhr.onload = () => {
        if ((xhr.status === 0 && xhr.response) || (xhr.status >= 200 && xhr.status < 300)) {
          resolve(new Response(xhr.response, {
            status: 200,
            statusText: 'OK',
            headers: { 'Content-Type': mime(url), 'Content-Length': String(xhr.response.byteLength) }
          }));
        } else {
          reject(new TypeError(`Android asset okunamadı (${xhr.status}): ${url.pathname}`));
        }
      };
      xhr.onerror = () => reject(new TypeError(`Android asset bağlantısı açılamadı: ${url.pathname}`));
      xhr.onabort = () => reject(new DOMException('İstek iptal edildi', 'AbortError'));
      if (init?.signal) {
        if (init.signal.aborted) {
          xhr.abort();
          return;
        }
        init.signal.addEventListener('abort', () => xhr.abort(), { once: true });
      }
      xhr.send();
    });
  };
})();
