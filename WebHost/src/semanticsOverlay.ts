// semanticsOverlay.ts – WebHost
// Creates a DOM overlay mirroring the semantics tree for accessibility.

interface SemanticsNode {
  id: number;
  role: string;
  label?: string;
  hint?: string;
  frame: { x: number; y: number; width: number; height: number };
  actions: string[];
  children: SemanticsNode[];
  isHidden: boolean;
}

export class SemanticsOverlay {
  private container: HTMLDivElement;
  private clickHandler: ((tapId: number) => void) | null = null;

  constructor() {
    this.container = document.createElement('div');
    this.container.id = 'skiaui-semantics';
    this.container.style.cssText = 'position:absolute;top:0;left:0;pointer-events:none;';
    const canvas = document.getElementById('skia-canvas');
    if (canvas?.parentElement) {
      canvas.parentElement.style.position = 'relative';
      canvas.parentElement.appendChild(this.container);
    }
  }

  update(json: string): void {
    try {
      const root = JSON.parse(json) as SemanticsNode;
      this.container.innerHTML = '';
      this.renderNode(root, this.container);
    } catch (e) {
      console.error('Failed to parse semantics tree:', e);
    }
  }

  private renderNode(node: SemanticsNode, parent: HTMLElement): void {
    if (node.isHidden) return;

    const el = document.createElement('div');
    el.style.cssText = `position:absolute;left:${node.frame.x}px;top:${node.frame.y}px;width:${node.frame.width}px;height:${node.frame.height}px;`;

    // Set ARIA attributes
    const ariaRole = this.mapRole(node.role);
    if (ariaRole) el.setAttribute('role', ariaRole);
    if (node.label) el.setAttribute('aria-label', node.label);
    if (node.hint) el.setAttribute('aria-description', node.hint);

    // Make interactive elements focusable
    if (node.actions.includes('tap')) {
      el.tabIndex = 0;
      el.style.pointerEvents = 'auto';
      el.style.cursor = 'pointer';
      el.addEventListener('click', () => {
        this.clickHandler?.(node.id);
      });
      el.addEventListener('keydown', (e: KeyboardEvent) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          this.clickHandler?.(node.id);
        }
      });
    }

    parent.appendChild(el);

    for (const child of node.children) {
      this.renderNode(child, el);
    }
  }

  private mapRole(role: string): string | null {
    switch (role) {
      case 'button': return 'button';
      case 'text': return 'text';
      case 'image': return 'img';
      case 'header': return 'heading';
      case 'link': return 'link';
      case 'textField': return 'textbox';
      case 'slider': return 'slider';
      case 'checkbox': return 'checkbox';
      case 'container': return 'group';
      default: return null;
    }
  }

  setClickHandler(handler: (tapId: number) => void): void {
    this.clickHandler = handler;
  }

  dispose(): void {
    this.container.remove();
  }
}
