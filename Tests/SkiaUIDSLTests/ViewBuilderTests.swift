// ViewBuilderTests.swift – SkiaUIDSL test suite
// Tests for ViewBuilder result builder composition and view-to-element conversion.

import Testing
@testable import SkiaUIDSL
import SkiaUIElement
import SkiaUIText

@Suite struct ViewBuilderTests {
    @Test func emptyViewBuilder() {
        let view = EmptyView()
        let element = view.asElement()
        #expect(element == .empty)
    }

    @Test func textView() {
        let view = Text("Hello")
        let element = view.asElement()
        if case .text(let s, _) = element {
            #expect(s == "Hello")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func rectangleView() {
        let view = Rectangle()
        let element = view.asElement()
        if case .rectangle = element {
            // pass
        } else {
            Issue.record("Expected rectangle element")
        }
    }

    @Test func spacerView() {
        let view = Spacer(minLength: 10)
        let element = view.asElement()
        if case .spacer(let min) = element {
            #expect(min == 10)
        } else {
            Issue.record("Expected spacer element")
        }
    }

    @Test func vstackWithChildren() {
        let view = VStack {
            Text("A")
            Text("B")
            Text("C")
        }
        let element = view.asElement()
        if case .container(let props, let children) = element {
            if case .vstack(let spacing, _) = props.layout {
                #expect(spacing == 8)
            } else {
                Issue.record("Expected vstack layout")
            }
            #expect(children.count == 3)
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func hstackWithChildren() {
        let view = HStack(spacing: 12) {
            Text("Left")
            Spacer()
            Text("Right")
        }
        let element = view.asElement()
        if case .container(let props, let children) = element {
            if case .hstack(let spacing, _) = props.layout {
                #expect(spacing == 12)
            } else {
                Issue.record("Expected hstack layout")
            }
            #expect(children.count == 3)
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func zstackWithChildren() {
        let view = ZStack {
            Rectangle()
            Text("Overlay")
        }
        let element = view.asElement()
        if case .container(let props, let children) = element {
            if case .zstack = props.layout {
                // pass
            } else {
                Issue.record("Expected zstack layout")
            }
            #expect(children.count == 2)
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func conditionalViewPresent() {
        let showText = true
        @ViewBuilder func build() -> some View {
            if showText {
                Text("Visible")
            }
        }
        let element = ViewToElementConverter.convert(build())
        if case .text(let s, _) = element {
            #expect(s == "Visible")
        } else {
            Issue.record("Expected text element, got: \(element)")
        }
    }

    @Test func conditionalViewAbsent() {
        let showText = false
        @ViewBuilder func build() -> some View {
            if showText {
                Text("Visible")
            }
        }
        let element = ViewToElementConverter.convert(build())
        #expect(element == .empty)
    }

    @Test func anyViewWrapping() {
        let view = AnyView(Text("Wrapped"))
        let element = view.asElement()
        if case .text(let s, _) = element {
            #expect(s == "Wrapped")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func nestedStacks() {
        let view = VStack {
            HStack {
                Text("A")
                Text("B")
            }
            Text("C")
        }
        let element = view.asElement()
        if case .container(_, let children) = element {
            #expect(children.count == 2)
            if case .container(_, let innerChildren) = children[0] {
                #expect(innerChildren.count == 2)
            } else {
                Issue.record("Expected inner container")
            }
        } else {
            Issue.record("Expected outer container")
        }
    }

    @Test func rectangleWithModifiers() {
        let view = Rectangle().fill(.blue).cornerRadius(8)
        let element = view.asElement()
        if case .rectangle(let props) = element {
            #expect(props.cornerRadius == 8)
            #expect(props.fillColor.b > 0.4) // blue component
        } else {
            Issue.record("Expected rectangle element")
        }
    }

    @Test func textWithModifiers() {
        let view = Text("Styled").fontSize(24).bold().foregroundColor(.red)
        let element = view.asElement()
        if case .text(let s, let props) = element {
            #expect(s == "Styled")
            #expect(props.fontSize == 24)
            #expect(props.fontWeight == 700)
            #expect(props.foregroundColor != nil)
            #expect(props.foregroundColor?.r == 1.0)
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func manyChildrenInStack() {
        let view = VStack {
            Text("1")
            Text("2")
            Text("3")
            Text("4")
            Text("5")
        }
        let element = view.asElement()
        if case .container(_, let children) = element {
            #expect(children.count == 5)
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func scrollViewWithChildren() {
        let view = ScrollView {
            Text("A")
            Text("B")
            Text("C")
        }
        let element = view.asElement()
        if case .container(let props, let children) = element {
            if case .scroll(let axis, _) = props.layout {
                #expect(axis == .vertical)
            } else {
                Issue.record("Expected scroll layout")
            }
            // ScrollView wraps children in an inner VStack
            #expect(children.count == 1)
            if case .container(let innerProps, let innerChildren) = children[0] {
                if case .vstack = innerProps.layout {
                    // pass
                } else {
                    Issue.record("Expected inner vstack layout")
                }
                #expect(innerChildren.count == 3)
            } else {
                Issue.record("Expected inner container")
            }
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func scrollViewHorizontalAxis() {
        let view = ScrollView(.horizontal) {
            Text("A")
            Text("B")
        }
        let element = view.asElement()
        if case .container(let props, let children) = element {
            if case .scroll(let axis, _) = props.layout {
                #expect(axis == .horizontal)
            } else {
                Issue.record("Expected scroll layout")
            }
            #expect(children.count == 1)
            if case .container(let innerProps, _) = children[0] {
                if case .hstack = innerProps.layout {
                    // pass — horizontal scroll wraps in HStack
                } else {
                    Issue.record("Expected inner hstack layout")
                }
            } else {
                Issue.record("Expected inner container")
            }
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func compositeView() {
        struct MyView: View {
            var body: some View {
                VStack {
                    Text("Title")
                    Text("Subtitle")
                }
            }
        }
        let element = ViewToElementConverter.convert(MyView())
        if case .container(_, let children) = element {
            #expect(children.count == 2)
        } else {
            Issue.record("Expected container element from composite view")
        }
    }

    @Test func textWithFontFamily() {
        let view = Text("Hi").fontFamily("Courier")
        let element = view.asElement()
        if case .text(let s, let props) = element {
            #expect(s == "Hi")
            #expect(props.fontFamily == "Courier")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func textFontFamilyNilByDefault() {
        let view = Text("Hello")
        let element = view.asElement()
        if case .text(_, let props) = element {
            #expect(props.fontFamily == nil)
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func fontCustomDescriptor() {
        let font = Font.custom("Arial", size: 20)
        #expect(font.descriptor.family == "Arial")
        #expect(font.descriptor.size == 20)
        #expect(font.descriptor.weight == .regular)
    }

    @Test func fontSystemDescriptor() {
        let font = Font.system(size: 16, weight: .bold, design: .monospaced)
        #expect(font.descriptor.family == "monospace")
        #expect(font.descriptor.size == 16)
        #expect(font.descriptor.weight == .bold)
    }

    @Test func fontSemanticStyles() {
        #expect(Font.title.descriptor.size == 28)
        #expect(Font.headline.descriptor.weight == .semibold)
        #expect(Font.body.descriptor.size == 17)
        #expect(Font.caption.descriptor.size == 12)
    }

    @Test func fontWeightChaining() {
        let font = Font.custom("Test", size: 14).bold()
        #expect(font.descriptor.weight == .bold)
        #expect(font.descriptor.family == "Test")
    }

    @Test func fontModifierWithFontStruct() {
        let view = Text("Hello").font(.custom("Monaspace Neon", size: 20))
        let element = view.asElement()
        if case .modified(let inner, .font(let size, let weight, let family)) = element {
            #expect(size == 20)
            #expect(weight == 400)
            #expect(family == "Monaspace Neon")
            if case .text(let s, _) = inner {
                #expect(s == "Hello")
            } else {
                Issue.record("Expected inner text element")
            }
        } else {
            Issue.record("Expected modified element with font modifier, got: \(element)")
        }
    }

    @Test func fontModifierSystemUIFilteredToNil() {
        let view = Text("System").font(.system(size: 17))
        let element = view.asElement()
        if case .modified(_, .font(let size, _, let family)) = element {
            #expect(size == 17)
            #expect(family == nil)
        } else {
            Issue.record("Expected modified element with font modifier")
        }
    }

    @Test func fontDesignFamilyMapping() {
        let defaultFont = Font.system(size: 14, design: .default)
        let monoFont = Font.system(size: 14, design: .monospaced)
        let serifFont = Font.system(size: 14, design: .serif)
        let roundedFont = Font.system(size: 14, design: .rounded)
        #expect(defaultFont.descriptor.family == "system-ui")
        #expect(monoFont.descriptor.family == "monospace")
        #expect(serifFont.descriptor.family == "serif")
        #expect(roundedFont.descriptor.family == "system-ui")
    }

    @Test func fontModifierBoldWithCustomFamily() {
        let font = Font.custom("Monaspace Neon", size: 16).bold()
        let view = Text("Bold").font(font)
        let element = view.asElement()
        if case .modified(_, .font(let size, let weight, let family)) = element {
            #expect(size == 16)
            #expect(weight == 700)
            #expect(family == "Monaspace Neon")
        } else {
            Issue.record("Expected modified element with font modifier")
        }
    }
}
