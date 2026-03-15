// debugOverlay.ts – WebHost
// Developer debug overlay toggled with Ctrl+Shift+D.

export class DebugOverlay {
  private enabled = false;
  private infoEl: HTMLDivElement;

  constructor() {
    this.infoEl = document.createElement('div');
    this.infoEl.id = 'skiaui-debug-info';
    this.infoEl.style.cssText = 'position:fixed;top:8px;right:8px;background:rgba(0,0,0,0.8);color:#0f0;font-family:monospace;font-size:12px;padding:8px;border-radius:4px;display:none;z-index:9999;';
    document.body.appendChild(this.infoEl);

    document.addEventListener('keydown', (e: KeyboardEvent) => {
      if (e.ctrlKey && e.shiftKey && e.key === 'D') {
        this.toggle();
      }
    });
  }

  toggle(): void {
    this.enabled = !this.enabled;
    this.infoEl.style.display = this.enabled ? 'block' : 'none';
    if (this.enabled) {
      this.infoEl.textContent = 'SkiaUI Debug Mode ON (Ctrl+Shift+D to toggle)';
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  updateInfo(info: string): void {
    if (this.enabled) {
      this.infoEl.textContent = info;
    }
  }

  dispose(): void {
    this.infoEl.remove();
  }
}
