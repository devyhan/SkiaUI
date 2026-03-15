// main.swift – SkiaUIPreview
// Dashboard preview server: sidebar with example list + selected example preview.
// Serves display list over HTTP, handles tap events from the browser.

import Foundation
import SkiaUI

// MARK: - Example Views

struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Counter Demo")

            Text("Count: \(count)")
                .foregroundColor(.blue)

            HStack(spacing: 16) {
                Text("- Decrease")
                    .padding(12)
                    .background(.red)
                    .foregroundColor(.white)
                    .onTapGesture { count -= 1 }

                Text("+ Increase")
                    .padding(12)
                    .background(.blue)
                    .foregroundColor(.white)
                    .onTapGesture { count += 1 }
            }

            Text("Reset")
                    .padding(12)
                    .background(.gray)
                    .foregroundColor(.white)
                    .onTapGesture { count = 0 }
        }
        .padding(32)
    }
}

struct AccessibilityDemoView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Accessible Counter")
                .font(size: 24, weight: .bold)
                .accessibilityRole("header")
            Text("Count: \(count)")
                .font(size: 32)
                .foregroundColor(.blue)
                .accessibilityLabel("Current count is \(count)")
            HStack(spacing: 16) {
                Text("Decrease")
                    .padding(12)
                    .background(.red)
                    .foregroundColor(.white)
                    .onTapGesture { count -= 1 }
                    .accessibilityLabel("Decrease counter by one")
                    .accessibilityHint("Double tap to decrease")
                Text("Increase")
                    .padding(12)
                    .background(.blue)
                    .foregroundColor(.white)
                    .onTapGesture { count += 1 }
                    .accessibilityLabel("Increase counter by one")
                    .accessibilityHint("Double tap to increase")
            }
        }
        .padding(32)
        .accessibilityRole("container")
    }
}

struct TypographyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Typography").font(size: 24, weight: .bold)

            // FontWeight spectrum
            Text("Light").font(size: 16, weight: .light)
            Text("Regular").font(size: 16)
            Text("Medium").font(size: 16, weight: .medium)
            Text("Semibold").font(size: 16, weight: .semibold)
            Text("Bold").font(size: 16, weight: .bold)
            Text("Black").font(size: 16, weight: .black)

            // Color palette
            Text("Colors").font(size: 18, weight: .bold)
                .padding(top: 8, leading: 0, bottom: 0, trailing: 0)
            HStack(spacing: 16) {
                Text("Red").foregroundColor(.red)
                Text("Blue").foregroundColor(.blue)
                Text("Green").foregroundColor(.green)
            }
            HStack(spacing: 16) {
                Text("Purple").foregroundColor(.purple)
                Text("Orange").foregroundColor(.orange)
                Text("Gray").foregroundColor(.gray)
            }
        }
        .padding(32)
    }
}

struct ShapesColorsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Shapes & Colors").font(size: 24, weight: .bold)

            Text("Solid").font(size: 16, weight: .medium)
            HStack(spacing: 12) {
                Rectangle().fill(.red).frame(width: 60, height: 60)
                Rectangle().fill(.blue).frame(width: 60, height: 60)
                Rectangle().fill(.green).frame(width: 60, height: 60)
            }

            Text("Rounded").font(size: 16, weight: .medium)
            HStack(spacing: 12) {
                Rectangle().fill(.orange).cornerRadius(8).frame(width: 60, height: 60)
                Rectangle().fill(.purple).cornerRadius(16).frame(width: 60, height: 60)
                Rectangle().fill(.yellow).cornerRadius(30).frame(width: 60, height: 60)
            }

            Text("Custom RGB").font(size: 16, weight: .medium)
            HStack(spacing: 12) {
                Rectangle().fill(Color(red: 0.2, green: 0.6, blue: 0.9))
                    .cornerRadius(8).frame(width: 60, height: 60)
                Rectangle().fill(Color(red: 0.9, green: 0.3, blue: 0.5))
                    .cornerRadius(8).frame(width: 60, height: 60)
                Rectangle().fill(Color(white: 0.75))
                    .cornerRadius(8).frame(width: 60, height: 60)
            }
        }
        .padding(32)
    }
}

struct LayoutDemoView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Layout Demo").font(size: 24, weight: .bold)

            Text("VStack Alignment").font(size: 16, weight: .medium)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Leading"); Text("AB")
                }.padding(8).background(Color(white: 0.9))

                VStack(alignment: .center, spacing: 4) {
                    Text("Center"); Text("AB")
                }.padding(8).background(Color(white: 0.9))

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Trailing"); Text("AB")
                }.padding(8).background(Color(white: 0.9))
            }

            Text("ZStack Overlay").font(size: 16, weight: .medium)
            ZStack {
                Rectangle().fill(.blue).frame(width: 140, height: 50)
                Text("On Top").foregroundColor(.white)
            }

            Text("Spacer Push").font(size: 16, weight: .medium)
            HStack(spacing: 0) {
                Text("Left").padding(8).background(.blue).foregroundColor(.white)
                Spacer()
                Text("Right").padding(8).background(.red).foregroundColor(.white)
            }.frame(width: 300)
        }
        .padding(32)
    }
}

// MARK: - Layout Priority Demo

struct PriorityDemoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Layout Priority").font(size: 24, weight: .bold)

            // 1. Basic priority: high priority child gets space first
            Text("1. Priority Ordering").font(size: 16, weight: .semibold)
            Text("priority(1) gets full size before priority(0)")
                .font(size: 12).foregroundColor(.gray)
            HStack(spacing: 0) {
                Text("Priority 0")
                    .padding(8)
                    .background(Color(red: 0.9, green: 0.3, blue: 0.3))
                    .foregroundColor(.white)
                Text("Priority 1")
                    .padding(8)
                    .background(.blue)
                    .foregroundColor(.white)
                    .layoutPriority(1)
            }.frame(width: 200)

            // 2. Spacer has lowest priority (-infinity)
            Text("2. Spacer = Lowest Priority").font(size: 16, weight: .semibold)
            Text("Spacer absorbs remaining space after all others")
                .font(size: 12).foregroundColor(.gray)
            HStack(spacing: 0) {
                Text("Fixed").padding(8).background(.blue).foregroundColor(.white)
                Spacer()
                Text("Fixed").padding(8).background(.blue).foregroundColor(.white)
            }.frame(width: 350).background(Color(white: 0.92))

            // 3. Multiple spacers = equal distribution
            Text("3. Multiple Spacers = Equal Split").font(size: 16, weight: .semibold)
            HStack(spacing: 0) {
                Spacer()
                Text("A").padding(8).background(.orange).foregroundColor(.white)
                Spacer()
                Text("B").padding(8).background(.purple).foregroundColor(.white)
                Spacer()
            }.frame(width: 350).background(Color(white: 0.92))

            // 4. Priority in VStack
            Text("4. VStack Priority Distribution").font(size: 16, weight: .semibold)
            HStack(spacing: 12) {
                // Without priority: both get equal extra space
                VStack(spacing: 4) {
                    Text("Normal").font(size: 11)
                    Rectangle().fill(.blue).layoutPriority(0)
                    Rectangle().fill(.red).layoutPriority(0)
                }
                .frame(width: 60, height: 120)
                .background(Color(white: 0.92))

                // With priority: blue gets space first
                VStack(spacing: 4) {
                    Text("P:1 / P:0").font(size: 11)
                    Rectangle().fill(.blue).layoutPriority(1)
                    Rectangle().fill(.red)
                }
                .frame(width: 60, height: 120)
                .background(Color(white: 0.92))

                // Reversed priority
                VStack(spacing: 4) {
                    Text("P:0 / P:1").font(size: 11)
                    Rectangle().fill(.blue)
                    Rectangle().fill(.red).layoutPriority(1)
                }
                .frame(width: 60, height: 120)
                .background(Color(white: 0.92))
            }
        }
        .padding(32)
    }
}

// MARK: - Flexible Frame Demo

struct FlexFrameDemoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Flexible Frames").font(size: 24, weight: .bold)

            // 1. Min/Max width clamping
            Text("1. Min/Max Clamping").font(size: 16, weight: .semibold)
            Text("minWidth: 80, maxWidth: 200")
                .font(size: 12).foregroundColor(.gray)
            VStack(spacing: 8) {
                // Short text: clamped to min
                Text("Hi")
                    .padding(8)
                    .frame(minWidth: 80, maxWidth: 200)
                    .background(.blue)
                    .foregroundColor(.white)
                // Long text: clamped to max
                Text("A very long label here")
                    .padding(8)
                    .frame(minWidth: 80, maxWidth: 200)
                    .background(.blue)
                    .foregroundColor(.white)
                // Medium text: natural width
                Text("Medium")
                    .padding(8)
                    .frame(minWidth: 80, maxWidth: 200)
                    .background(.blue)
                    .foregroundColor(.white)
            }

            // 2. maxWidth: .infinity (full width)
            Text("2. maxWidth = infinity (full width)").font(size: 16, weight: .semibold)
            Text("Stretches to fill available space")
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.2, green: 0.6, blue: 0.9))
                .foregroundColor(.white)

            // 3. Fixed vs Flexible comparison
            Text("3. Fixed vs Flexible").font(size: 16, weight: .semibold)
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    Text("Fixed 80").font(size: 11)
                    Rectangle().fill(.blue).frame(width: 80, height: 40)
                }
                VStack(spacing: 4) {
                    Text("min:40 max:120").font(size: 11)
                    Rectangle().fill(.orange).frame(minWidth: 40, maxWidth: 120, minHeight: 40, maxHeight: 40)
                }
                VStack(spacing: 4) {
                    Text("ideal: 60").font(size: 11)
                    Rectangle().fill(.purple).frame(idealWidth: 60, idealHeight: 40)
                }
            }

            // 4. Min height for consistent row heights
            Text("4. Consistent Row Heights (minHeight)").font(size: 16, weight: .semibold)
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    Text("Short").padding(8).frame(minHeight: 44).background(Color(white: 0.92))
                    Spacer()
                    Text(">").padding(8).foregroundColor(.gray)
                }.frame(width: 300)
                HStack(spacing: 0) {
                    Text("Also Short").padding(8).frame(minHeight: 44).background(Color(white: 0.92))
                    Spacer()
                    Text(">").padding(8).foregroundColor(.gray)
                }.frame(width: 300)
            }
        }
        .padding(32)
    }
}

// MARK: - fixedSize Demo

struct FixedSizeDemoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("fixedSize").font(size: 24, weight: .bold)

            // 1. Without fixedSize: text is constrained
            Text("1. Without fixedSize").font(size: 16, weight: .semibold)
            Text("Text is constrained to proposed width")
                .font(size: 12).foregroundColor(.gray)
            Text("This text will be clipped by frame")
                .padding(8)
                .frame(width: 120)
                .background(Color(white: 0.92))

            // 2. With fixedSize: text uses intrinsic size
            Text("2. With fixedSize()").font(size: 16, weight: .semibold)
            Text("Text ignores proposal, uses ideal size")
                .font(size: 12).foregroundColor(.gray)
            Text("This text uses its full intrinsic width")
                .fixedSize()
                .padding(8)
                .frame(width: 120)
                .background(Color(white: 0.92))

            // 3. fixedSize horizontal only
            Text("3. fixedSize(horizontal: true, vertical: false)").font(size: 14, weight: .semibold)
            Text("Width is intrinsic, height follows proposal")
                .font(size: 12).foregroundColor(.gray)
            Text("Horizontal only")
                .fixedSize(horizontal: true, vertical: false)
                .padding(8)
                .frame(width: 80, height: 60)
                .background(Color(white: 0.92))

            // 4. Comparison side by side
            Text("4. Side-by-side Comparison").font(size: 16, weight: .semibold)
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Normal").font(size: 11).foregroundColor(.gray)
                    Text("Hello World!")
                        .padding(6)
                        .frame(width: 60)
                        .background(.blue)
                        .foregroundColor(.white)
                }
                VStack(spacing: 4) {
                    Text("fixedSize").font(size: 11).foregroundColor(.gray)
                    Text("Hello World!")
                        .fixedSize()
                        .padding(6)
                        .frame(width: 60)
                        .background(.orange)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(32)
    }
}

// MARK: - Advanced Layout Patterns

struct AdvancedLayoutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Layouts").font(size: 24, weight: .bold)

            // 1. Navigation Bar pattern
            Text("1. Navigation Bar").font(size: 16, weight: .semibold)
            HStack(spacing: 0) {
                Text("Back")
                    .padding(top: 10, leading: 16, bottom: 10, trailing: 16)
                    .foregroundColor(.blue)
                Spacer()
                Text("Page Title").font(size: 16, weight: .bold)
                Spacer()
                Text("Edit")
                    .padding(top: 10, leading: 16, bottom: 10, trailing: 16)
                    .foregroundColor(.blue)
            }
            .frame(width: 350)
            .background(Color(white: 0.96))

            // 2. Card component
            Text("2. Card Layout").font(size: 16, weight: .semibold)
            VStack(alignment: .leading, spacing: 0) {
                // Card header
                Rectangle().fill(.blue).frame(height: 6)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Rectangle().fill(.blue).cornerRadius(16).frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("John Doe").font(size: 14, weight: .bold)
                            Text("Software Engineer").font(size: 12).foregroundColor(.gray)
                        }
                        Spacer()
                        Text("Active")
                            .font(size: 11)
                            .padding(top: 4, leading: 8, bottom: 4, trailing: 8)
                            .background(.green)
                            .foregroundColor(.white)
                    }
                    Rectangle().fill(Color(white: 0.88)).frame(height: 1)
                    Text("Building cross-platform UI frameworks with Swift.")
                        .font(size: 13).foregroundColor(Color(white: 0.4))
                }.padding(12)
            }
            .frame(width: 300)
            .background(Color(white: 0.97))

            // 3. Settings list pattern
            Text("3. Settings List").font(size: 16, weight: .semibold)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Rectangle().fill(.blue).cornerRadius(6).frame(width: 28, height: 28)
                    Text("  General").font(size: 14)
                    Spacer()
                    Text(">").foregroundColor(.gray)
                }.padding(top: 8, leading: 12, bottom: 8, trailing: 12)

                Rectangle().fill(Color(white: 0.88)).frame(height: 1)
                    .padding(top: 0, leading: 52, bottom: 0, trailing: 0)

                HStack(spacing: 0) {
                    Rectangle().fill(.green).cornerRadius(6).frame(width: 28, height: 28)
                    Text("  Privacy").font(size: 14)
                    Spacer()
                    Text(">").foregroundColor(.gray)
                }.padding(top: 8, leading: 12, bottom: 8, trailing: 12)

                Rectangle().fill(Color(white: 0.88)).frame(height: 1)
                    .padding(top: 0, leading: 52, bottom: 0, trailing: 0)

                HStack(spacing: 0) {
                    Rectangle().fill(.orange).cornerRadius(6).frame(width: 28, height: 28)
                    Text("  Notifications").font(size: 14)
                    Spacer()
                    Text(">").foregroundColor(.gray)
                }.padding(top: 8, leading: 12, bottom: 8, trailing: 12)
            }
            .frame(width: 300)
            .background(Color(white: 0.97))

            // 4. Badge / tag bar
            Text("4. Tag Bar").font(size: 16, weight: .semibold)
            HStack(spacing: 6) {
                Text("Swift")
                    .font(size: 12)
                    .padding(top: 4, leading: 10, bottom: 4, trailing: 10)
                    .background(.orange)
                    .foregroundColor(.white)
                Text("UI")
                    .font(size: 12)
                    .padding(top: 4, leading: 10, bottom: 4, trailing: 10)
                    .background(.blue)
                    .foregroundColor(.white)
                Text("Layout")
                    .font(size: 12)
                    .padding(top: 4, leading: 10, bottom: 4, trailing: 10)
                    .background(.purple)
                    .foregroundColor(.white)
                Text("CanvasKit")
                    .font(size: 12)
                    .padding(top: 4, leading: 10, bottom: 4, trailing: 10)
                    .background(.green)
                    .foregroundColor(.white)
            }
        }
        .padding(32)
    }
}

// MARK: - Nested Stack & ZStack Patterns

struct NestedLayoutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nested & ZStack").font(size: 24, weight: .bold)

            // 1. ZStack alignment grid
            Text("1. ZStack Alignments").font(size: 16, weight: .semibold)
            HStack(spacing: 8) {
                // Top-leading
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color(white: 0.88)).frame(width: 70, height: 70)
                    Rectangle().fill(.blue).frame(width: 24, height: 24)
                }
                // Center (default)
                ZStack {
                    Rectangle().fill(Color(white: 0.88)).frame(width: 70, height: 70)
                    Rectangle().fill(.orange).frame(width: 24, height: 24)
                }
                // Bottom-trailing
                ZStack(alignment: .bottomTrailing) {
                    Rectangle().fill(Color(white: 0.88)).frame(width: 70, height: 70)
                    Rectangle().fill(.red).frame(width: 24, height: 24)
                }
            }

            // 2. Overlapping labels
            Text("2. Badge Overlay").font(size: 16, weight: .semibold)
            HStack(spacing: 20) {
                ZStack(alignment: .topTrailing) {
                    Rectangle().fill(.blue).cornerRadius(12).frame(width: 50, height: 50)
                    Text("3")
                        .font(size: 11)
                        .padding(top: 2, leading: 6, bottom: 2, trailing: 6)
                        .background(.red)
                        .foregroundColor(.white)
                }
                ZStack(alignment: .topTrailing) {
                    Rectangle().fill(.green).cornerRadius(12).frame(width: 50, height: 50)
                    Text("12")
                        .font(size: 11)
                        .padding(top: 2, leading: 6, bottom: 2, trailing: 6)
                        .background(.red)
                        .foregroundColor(.white)
                }
                ZStack(alignment: .topTrailing) {
                    Rectangle().fill(.purple).cornerRadius(12).frame(width: 50, height: 50)
                    Text("99+")
                        .font(size: 11)
                        .padding(top: 2, leading: 6, bottom: 2, trailing: 6)
                        .background(.red)
                        .foregroundColor(.white)
                }
            }

            // 3. Deeply nested stacks
            Text("3. Three-Column Layout").font(size: 16, weight: .semibold)
            HStack(spacing: 2) {
                // Column 1
                VStack(spacing: 2) {
                    Rectangle().fill(.red).frame(height: 40)
                    Rectangle().fill(Color(red: 0.9, green: 0.3, blue: 0.3)).frame(height: 60)
                }.frame(width: 80)

                // Column 2 (taller)
                VStack(spacing: 2) {
                    Rectangle().fill(.blue).frame(height: 60)
                    Rectangle().fill(Color(red: 0.3, green: 0.5, blue: 0.9)).frame(height: 40)
                }.frame(width: 80)

                // Column 3
                VStack(spacing: 2) {
                    Rectangle().fill(.green).frame(height: 30)
                    Rectangle().fill(Color(red: 0.2, green: 0.7, blue: 0.4)).frame(height: 30)
                    Rectangle().fill(Color(red: 0.1, green: 0.5, blue: 0.3)).frame(height: 40)
                }.frame(width: 80)
            }

            // 4. Complex composition: mini dashboard widget
            Text("4. Dashboard Widget").font(size: 16, weight: .semibold)
            VStack(spacing: 0) {
                // Title bar
                HStack(spacing: 0) {
                    Text("Revenue").font(size: 14, weight: .bold).foregroundColor(.white)
                    Spacer()
                    Text("2025").font(size: 12).foregroundColor(Color(white: 0.8))
                }.padding(top: 10, leading: 14, bottom: 10, trailing: 14)
                .background(.blue)

                // Chart area (bar chart simulation)
                HStack(alignment: .bottom, spacing: 6) {
                    VStack(spacing: 2) {
                        Rectangle().fill(Color(red: 0.3, green: 0.5, blue: 0.9)).frame(width: 24, height: 40)
                        Text("Q1").font(size: 10)
                    }
                    VStack(spacing: 2) {
                        Rectangle().fill(Color(red: 0.3, green: 0.5, blue: 0.9)).frame(width: 24, height: 65)
                        Text("Q2").font(size: 10)
                    }
                    VStack(spacing: 2) {
                        Rectangle().fill(Color(red: 0.3, green: 0.5, blue: 0.9)).frame(width: 24, height: 50)
                        Text("Q3").font(size: 10)
                    }
                    VStack(spacing: 2) {
                        Rectangle().fill(Color(red: 0.3, green: 0.7, blue: 0.4)).frame(width: 24, height: 80)
                        Text("Q4").font(size: 10)
                    }
                }
                .padding(14)
                .background(Color(white: 0.97))

                // Footer stats
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("$1.2M").font(size: 14, weight: .bold)
                        Text("Total").font(size: 10).foregroundColor(.gray)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("+23%").font(size: 14, weight: .bold).foregroundColor(.green)
                        Text("Growth").font(size: 10).foregroundColor(.gray)
                    }
                }.padding(top: 10, leading: 14, bottom: 10, trailing: 14)
                .background(Color(white: 0.94))
            }
            .frame(width: 200)
        }
        .padding(32)
    }
}

// MARK: - Dashboard Layout

struct DashboardView: View {
    @State private var selectedExample = 0
    let counterView = CounterView()
    let typographyView = TypographyView()
    let shapesColorsView = ShapesColorsView()
    let layoutDemoView = LayoutDemoView()
    let accessibilityView = AccessibilityDemoView()
    let priorityDemoView = PriorityDemoView()
    let flexFrameDemoView = FlexFrameDemoView()
    let fixedSizeDemoView = FixedSizeDemoView()
    let advancedLayoutView = AdvancedLayoutView()
    let nestedLayoutView = NestedLayoutView()

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("SkiaUI")
                    .font(size: 20, weight: .bold)
                    .padding(16)

                // Section: Basics
                Text("Basics")
                    .font(size: 11, weight: .bold)
                    .foregroundColor(.gray)
                    .padding(top: 12, leading: 16, bottom: 4, trailing: 16)

                Text("Counter")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 0 ? .blue : .clear)
                    .foregroundColor(selectedExample == 0 ? .white : .black)
                    .onTapGesture { selectedExample = 0 }

                Text("Typography")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 1 ? .blue : .clear)
                    .foregroundColor(selectedExample == 1 ? .white : .black)
                    .onTapGesture { selectedExample = 1 }

                Text("Shapes & Colors")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 2 ? .blue : .clear)
                    .foregroundColor(selectedExample == 2 ? .white : .black)
                    .onTapGesture { selectedExample = 2 }

                // Section: Layout System
                Text("Layout System")
                    .font(size: 11, weight: .bold)
                    .foregroundColor(.gray)
                    .padding(top: 16, leading: 16, bottom: 4, trailing: 16)

                Text("Basic Layout")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 3 ? .blue : .clear)
                    .foregroundColor(selectedExample == 3 ? .white : .black)
                    .onTapGesture { selectedExample = 3 }

                Text("Priority")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 4 ? .blue : .clear)
                    .foregroundColor(selectedExample == 4 ? .white : .black)
                    .onTapGesture { selectedExample = 4 }

                Text("Flex Frame")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 5 ? .blue : .clear)
                    .foregroundColor(selectedExample == 5 ? .white : .black)
                    .onTapGesture { selectedExample = 5 }

                Text("fixedSize")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 6 ? .blue : .clear)
                    .foregroundColor(selectedExample == 6 ? .white : .black)
                    .onTapGesture { selectedExample = 6 }

                Text("Nested & ZStack")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 7 ? .blue : .clear)
                    .foregroundColor(selectedExample == 7 ? .white : .black)
                    .onTapGesture { selectedExample = 7 }

                // Section: Patterns
                Text("Patterns")
                    .font(size: 11, weight: .bold)
                    .foregroundColor(.gray)
                    .padding(top: 16, leading: 16, bottom: 4, trailing: 16)

                Text("Advanced")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 8 ? .blue : .clear)
                    .foregroundColor(selectedExample == 8 ? .white : .black)
                    .onTapGesture { selectedExample = 8 }

                Text("Accessibility")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 9 ? .blue : .clear)
                    .foregroundColor(selectedExample == 9 ? .white : .black)
                    .onTapGesture { selectedExample = 9 }

                Spacer()
            }
            .frame(width: 200)
            .background(Color(white: 0.94))

            // Preview area
            Spacer()

            if selectedExample == 0 {
                counterView
            } else if selectedExample == 1 {
                typographyView
            } else if selectedExample == 2 {
                shapesColorsView
            } else if selectedExample == 3 {
                layoutDemoView
            } else if selectedExample == 4 {
                priorityDemoView
            } else if selectedExample == 5 {
                flexFrameDemoView
            } else if selectedExample == 6 {
                fixedSizeDemoView
            } else if selectedExample == 7 {
                nestedLayoutView
            } else if selectedExample == 8 {
                advancedLayoutView
            } else {
                accessibilityView
            }

            Spacer()
        }
    }
}

// MARK: - Setup rendering

let host = RootHost()
host.setViewport(width: 800, height: 600)

var currentDisplayList = Data()
host.setOnDisplayList { bytes in
    currentDisplayList = Data(bytes)
}

let view = DashboardView()
host.render(view)

// Also write static file for initial browser load
let projectRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let publicDir = projectRoot.appendingPathComponent("WebHost/public")
try FileManager.default.createDirectory(at: publicDir, withIntermediateDirectories: true)
try currentDisplayList.write(to: publicDir.appendingPathComponent("displaylist.bin"))

print("[SkiaUIPreview] Initial render: \(currentDisplayList.count) bytes")
print("[SkiaUIPreview] Starting server on http://localhost:3001")

// MARK: - Minimal HTTP server

let serverFd = socket(AF_INET, SOCK_STREAM, 0)
guard serverFd >= 0 else { fatalError("Failed to create socket") }

var opt: Int32 = 1
setsockopt(serverFd, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout<Int32>.size))

var addr = sockaddr_in()
addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
addr.sin_family = sa_family_t(AF_INET)
addr.sin_port = UInt16(3001).bigEndian
addr.sin_addr.s_addr = INADDR_ANY

let bindResult = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        bind(serverFd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
    }
}
guard bindResult == 0 else { fatalError("bind failed: \(errno)") }
listen(serverFd, 5)

print("[SkiaUIPreview] Server ready. Waiting for requests...")

while true {
    let clientFd = accept(serverFd, nil, nil)
    guard clientFd >= 0 else { continue }

    // Read request
    var buffer = [UInt8](repeating: 0, count: 65536)
    let n = recv(clientFd, &buffer, buffer.count, 0)
    guard n > 0 else { close(clientFd); continue }

    let raw = String(decoding: buffer[..<n], as: UTF8.self)
    let firstLine = raw.prefix(while: { $0 != "\r" && $0 != "\n" })
    let parts = firstLine.split(separator: " ")
    let method = parts.count > 0 ? String(parts[0]) : ""
    let path = parts.count > 1 ? String(parts[1]) : ""

    // Extract body (after \r\n\r\n)
    var body: Data? = nil
    if let range = raw.range(of: "\r\n\r\n") {
        let bodyStr = raw[range.upperBound...]
        if !bodyStr.isEmpty { body = Data(bodyStr.utf8) }
    }

    var status = 200
    var responseBody = Data()

    if method == "OPTIONS" {
        // CORS preflight
        responseBody = Data()
    } else if path == "/api/displaylist" {
        responseBody = currentDisplayList
    } else if method == "POST" && path == "/api/viewport" {
        // Browser sends viewport size → re-render with new dimensions
        if let body = body,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let w = (json["width"] as? NSNumber)?.floatValue,
           let h = (json["height"] as? NSNumber)?.floatValue {
            host.setViewport(width: w, height: h)
            host.render(view)
        }
        responseBody = currentDisplayList
    } else if method == "POST" && path == "/api/tap" {
        if let body = body,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let x = (json["x"] as? NSNumber)?.floatValue,
           let y = (json["y"] as? NSNumber)?.floatValue {
            // Update viewport if provided
            if let w = (json["viewportWidth"] as? NSNumber)?.floatValue,
               let h = (json["viewportHeight"] as? NSNumber)?.floatValue {
                host.setViewport(width: w, height: h)
            }
            if let tapId = host.hitTest(x: x, y: y) {
                tapHandlers[tapId]?()
            }
            host.render(view)
        }
        responseBody = currentDisplayList
    } else {
        status = 404
        responseBody = Data("Not Found".utf8)
    }

    let header = [
        "HTTP/1.1 \(status) \(status == 200 ? "OK" : "Not Found")",
        "Content-Length: \(responseBody.count)",
        "Content-Type: application/octet-stream",
        "Access-Control-Allow-Origin: *",
        "Access-Control-Allow-Methods: GET, POST, OPTIONS",
        "Access-Control-Allow-Headers: Content-Type",
        "Connection: close",
        "", ""
    ].joined(separator: "\r\n")

    let headerData = Data(header.utf8)
    _ = headerData.withUnsafeBytes { send(clientFd, $0.baseAddress!, headerData.count, 0) }
    _ = responseBody.withUnsafeBytes { send(clientFd, $0.baseAddress!, responseBody.count, 0) }
    close(clientFd)
}
