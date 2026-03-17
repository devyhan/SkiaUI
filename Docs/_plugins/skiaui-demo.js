// skiaui-demo.js – Docsify plugin
// Renders <skiaui-demo> custom elements as iframe-embedded SkiaUI WASM demos.
//
// Usage in markdown:
//   <skiaui-demo id="text-demo" width="400" height="300"></skiaui-demo>

(function () {
  const DOCS_HOST_BASE = '/demos';

  function initPlugin(hook) {
    hook.doneEach(function () {
      const demos = document.querySelectorAll('skiaui-demo');
      demos.forEach(function (el) {
        const demoId = el.getAttribute('id') || 'default';
        const width = el.getAttribute('width') || '100%';
        const height = el.getAttribute('height') || '400';

        const iframe = document.createElement('iframe');
        iframe.src = DOCS_HOST_BASE + '/?demo=' + encodeURIComponent(demoId);
        iframe.style.width = width.includes('%') ? width : width + 'px';
        iframe.style.height = height + 'px';
        iframe.style.border = '1px solid #e0e0e0';
        iframe.style.borderRadius = '8px';
        iframe.style.display = 'block';
        iframe.style.margin = '16px 0';
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('sandbox', 'allow-scripts allow-same-origin');

        el.replaceWith(iframe);
      });
    });
  }

  // Register as Docsify plugin
  if (window.$docsify) {
    window.$docsify.plugins = (window.$docsify.plugins || []).concat(initPlugin);
  }
})();
