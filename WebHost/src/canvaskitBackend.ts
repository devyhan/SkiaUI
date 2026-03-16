import type { CanvasKit, Surface, Canvas } from 'canvaskit-wasm';
import { DisplayListPlayer } from './displayListPlayer';
import { FontManager } from './fontManager';

export class CanvasKitBackend {
  private ck: CanvasKit;
  private surface: Surface;
  private player: DisplayListPlayer;
  private canvas: Canvas;
  private fontManager: FontManager;

  constructor(ck: CanvasKit, surface: Surface, fontManager?: FontManager) {
    this.ck = ck;
    this.surface = surface;
    this.fontManager = fontManager ?? new FontManager(ck);
    this.player = new DisplayListPlayer(ck, this.fontManager);
    this.canvas = surface.getCanvas();
  }

  submitDisplayList(buffer: ArrayBuffer): void {
    this.canvas.clear(this.ck.Color4f(0.95, 0.95, 0.95, 1.0));
    this.player.play(buffer, this.canvas);
    this.surface.flush();
  }

  requestFrame(callback: () => void): void {
    requestAnimationFrame(callback);
  }

  getViewportSize(): { width: number; height: number } {
    return {
      width: this.surface.width(),
      height: this.surface.height(),
    };
  }

  dispose(): void {
    this.player.dispose();
    this.fontManager.dispose();
    this.surface.delete();
  }
}
