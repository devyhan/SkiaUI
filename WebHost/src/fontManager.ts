import type { CanvasKit, Typeface } from 'canvaskit-wasm';

export class FontManager {
  private ck: CanvasKit;
  private typefaces: Map<string, Typeface> = new Map();
  private defaultTypeface: Typeface | null = null;

  constructor(ck: CanvasKit) {
    this.ck = ck;
  }

  async loadFont(url: string, familyName: string): Promise<void> {
    const fontData = await fetch(url).then((r) => r.arrayBuffer());
    let typeface: Typeface | null = null;
    try {
      typeface = this.ck.Typeface.MakeFreeTypeFaceFromData(fontData);
    } catch {}
    if (!typeface) {
      try {
        typeface = this.ck.FontMgr.RefDefault().MakeTypefaceFromData(fontData);
      } catch {}
    }
    if (typeface) {
      this.typefaces.set(familyName, typeface);
      if (!this.defaultTypeface) {
        this.defaultTypeface = typeface;
      }
    }
  }

  getTypeface(familyName: string | null): Typeface | null {
    if (familyName) {
      const tf = this.typefaces.get(familyName);
      if (tf) return tf;
    }
    return this.defaultTypeface;
  }

  dispose(): void {
    for (const tf of this.typefaces.values()) {
      tf.delete();
    }
    this.typefaces.clear();
    this.defaultTypeface = null;
  }
}
