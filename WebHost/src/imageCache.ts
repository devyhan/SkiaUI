import type { CanvasKit, Image } from 'canvaskit-wasm';

export class ImageCache {
  private ck: CanvasKit;
  private cache: Map<string, Image> = new Map();
  private loading: Map<string, Promise<Image | null>> = new Map();

  constructor(ck: CanvasKit) {
    this.ck = ck;
  }

  get(source: string): Image | null {
    return this.cache.get(source) ?? null;
  }

  async load(source: string): Promise<Image | null> {
    if (this.cache.has(source)) {
      return this.cache.get(source)!;
    }

    if (this.loading.has(source)) {
      return this.loading.get(source)!;
    }

    const promise = this.fetchImage(source);
    this.loading.set(source, promise);

    const image = await promise;
    this.loading.delete(source);

    if (image) {
      this.cache.set(source, image);
    }
    return image;
  }

  private async fetchImage(source: string): Promise<Image | null> {
    try {
      const res = await fetch(source);
      if (!res.ok) return null;
      const buffer = await res.arrayBuffer();
      const data = new Uint8Array(buffer);
      const image = this.ck.MakeImageFromEncoded(data);
      return image ?? null;
    } catch {
      return null;
    }
  }

  dispose(): void {
    for (const img of this.cache.values()) {
      img.delete();
    }
    this.cache.clear();
  }
}
