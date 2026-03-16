// InterceptorTests.swift – SkiaUIDSL test suite
// Tests for ViewToElement interceptor mechanism.

import Testing
@testable import SkiaUIDSL
import SkiaUIElement

@Suite(.serialized) struct InterceptorTests {
    @Test func interceptorFiresForCompositeView() {
        struct MyView: View {
            var body: some View {
                Text("Hello")
            }
        }

        var interceptorCalled = false
        let element = ViewToElementConverter.withInterceptor({ path, evaluator in
            interceptorCalled = true
            return evaluator()
        }, convert: MyView())

        #expect(interceptorCalled)
        if case .text(let s, _) = element {
            #expect(s == "Hello")
        } else {
            Issue.record("Expected text element, got: \(element)")
        }
    }

    @Test func interceptorSkipsPrimitiveView() {
        var interceptorCalled = false
        let element = ViewToElementConverter.withInterceptor({ path, evaluator in
            interceptorCalled = true
            return evaluator()
        }, convert: Text("Primitive"))

        #expect(!interceptorCalled) // Text is PrimitiveView — no interception
        if case .text(let s, _) = element {
            #expect(s == "Primitive")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func structuralPathTracking() {
        struct Parent: View {
            var body: some View {
                VStack {
                    ChildA()
                    ChildB()
                }
            }
        }
        struct ChildA: View {
            var body: some View { Text("A") }
        }
        struct ChildB: View {
            var body: some View { Text("B") }
        }

        var callCount = 0
        let element = ViewToElementConverter.withInterceptor({ path, evaluator in
            callCount += 1
            #expect(!path.isEmpty, "Path should be non-empty")
            return evaluator()
        }, convert: Parent())

        // Interceptor fires for each composite view: Parent + ChildA + ChildB
        #expect(callCount >= 3)
        // Output matches non-intercepted conversion
        let expected = ViewToElementConverter.convert(Parent())
        #expect(element == expected)
    }

    @Test func interceptorDisabledByDefault() {
        struct MyView: View {
            var body: some View { Text("Default") }
        }
        // Without withInterceptor, _activeInterceptor is nil → standard path
        let element = ViewToElementConverter.convert(MyView())
        if case .text(let s, _) = element {
            #expect(s == "Default")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func withoutInterceptorProducesSameElement() {
        struct MyView: View {
            var body: some View {
                VStack {
                    Text("A")
                    Text("B")
                }
            }
        }

        let withoutInterceptor = ViewToElementConverter.convert(MyView())
        let withInterceptor = ViewToElementConverter.withInterceptor({ _, evaluator in
            evaluator()
        }, convert: MyView())

        #expect(withoutInterceptor == withInterceptor)
    }
}
