import type { CanvasKit, Surface, Canvas } from 'canvaskit-wasm';
import { DisplayListPlayer } from './displayListPlayer';

export class CanvasKitBackend {
  private ck: CanvasKit;
  private surface: Surface;
  private player: DisplayListPlayer;
  private canvas: Canvas;

  constructor(ck: CanvasKit, surface: Surface) {
    this.ck = ck;
    this.surface = surface;
    this.player = new DisplayListPlayer(ck);
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
    this.surface.delete();
  }
}
