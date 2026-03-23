import type { CanvasKit, Typeface } from 'canvaskit-wasm';

export class FontManager {
  private ck: CanvasKit;
  private typefaces: Map<string, Typeface> = new Map();
  private fontData: ArrayBuffer[] = [];
  private defaultTypeface: Typeface | null = null;

  constructor(ck: CanvasKit) {
    this.ck = ck;
  }

  async loadFont(url: string, familyName: string): Promise<void> {
    const data = await fetch(url).then((r) => r.arrayBuffer());
    this.fontData.push(data);
    
    let typeface: Typeface | null = null;
    try {
      typeface = this.ck.Typeface.MakeFreeTypeFaceFromData(data);
    } catch {}
    
    if (typeface) {
      this.typefaces.set(familyName, typeface);
      if (!this.defaultTypeface) {
        this.defaultTypeface = typeface;
      }
    }
  }

  getFontMgr() {
    return this.ck.FontMgr.FromData(...this.fontData);
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
