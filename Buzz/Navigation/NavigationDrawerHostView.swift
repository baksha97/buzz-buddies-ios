import Sharing
import SwiftUI

struct NavigationDrawerHostView<MainContent: View, DrawerContent: View>: View {
  
  @Shared(.activeQrConfiguration)
  var configuration

  private let overlap: CGFloat = 0.7
  private let overlayColor = Color.gray
  private let overlayOpacity = 0.7
  private let dragOpenThreshold = 0.1

  @Binding var isOpen: Bool
  @State private var openFraction: CGFloat
  private let main: () -> MainContent
  private let drawer: () -> DrawerContent

  private let onDrawerIconTap: () -> Void

  init(
    isOpen: Binding<Bool>,
    @ViewBuilder main: @escaping () -> MainContent,
    @ViewBuilder drawer: @escaping () -> DrawerContent,
    onDrawerIconTap: @escaping () -> Void
  ) {
    self._isOpen = isOpen
    self.openFraction = isOpen.wrappedValue ? 1 : 0
    self.main = main
    self.drawer = drawer
    self.onDrawerIconTap = onDrawerIconTap
  }

  // The hamburger icon in the NavigationBar
  private var drawerButton: some View {
    Image(systemName: "line.horizontal.3")
      .imageScale(.large)
      .foregroundColor(.primary)
      .onTapGesture {
        onDrawerIconTap()
      }
  }

  // The main content in a NavigationView so we get a nav bar
  @ViewBuilder
  var mainContentWithNavigationView: some View {
    NavigationView {
      main()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Dim overlay that closes the drawer on tap
        .background(
          Button(action: {
            withAnimation { isOpen.toggle() }
          }) {
            EmptyView()
          }
          .buttonStyle(.plain)
          .background(overlayColor.opacity(openFraction))
        )
        .navigationBarItems(leading: drawerButton)
    }
  }

  var body: some View {
    GeometryReader { proxy in
      let drawerWidth = proxy.size.width * overlap

      ZStack(alignment: .topLeading) {
        // MAIN CONTENT
        mainContentWithNavigationView

        // DRAWER
        drawer()
          .frame(
            minWidth: drawerWidth,
            idealWidth: drawerWidth,
            maxWidth: drawerWidth,
            maxHeight: .infinity
          )
          .offset(x: xOffset(drawerWidth))
      }
      .gesture(dragGesture(proxy.size.width))
      .onChange(of: isOpen) { _, newValue in
        withAnimation {
          openFraction = newValue ? 1 : 0
        }
      }
    }
  }

  // MARK: - Drag Gesture Logic
  private func dragGesture(_ mainWidth: CGFloat) -> some Gesture {
    DragGesture()
      .onChanged { value in
        // If drawer is open, dragging left
        if isOpen, value.translation.width < 0 {
          openFraction = openFraction(value.translation.width, from: -mainWidth...0)
        }
        // If closed, dragging from left edge to the right
        else if !isOpen,
                value.startLocation.x < mainWidth * dragOpenThreshold,
                value.translation.width > 0 {
          openFraction = openFraction(value.translation.width, from: 0...mainWidth)
        }
      }
      .onEnded { value in
        if openFraction == 1 || openFraction == 0 {
          return
        }
        let fromRange = isOpen ? -mainWidth...0 : 0...mainWidth
        let predicted = value.predictedEndTranslation.width
        let predictedFrac = openFraction(predicted, from: fromRange)
        if predictedFrac > 0.5 {
          withAnimation {
            openFraction = 1
            isOpen = true
          }
        } else {
          withAnimation {
            openFraction = 0
            isOpen = false
          }
        }
      }
  }

  private func xOffset(_ drawerWidth: CGFloat) -> CGFloat {
    remap(openFraction, from: 0...1, to: -drawerWidth...0)
  }

  private func openFraction(_ moveX: CGFloat, from range: ClosedRange<CGFloat>) -> CGFloat {
    remap(moveX, from: range, to: 0...1)
  }

  private func remap(
    _ value: CGFloat,
    from source: ClosedRange<CGFloat>,
    to target: ClosedRange<CGFloat> = 0...1
  ) -> CGFloat {
    let sourceDiff = source.upperBound - source.lowerBound
    let targetDiff = target.upperBound - target.lowerBound
    return (value - source.lowerBound) * targetDiff / sourceDiff + target.lowerBound
  }
}

#Preview("NavigationDrawerView") {
  @Previewable
  @State
  var isOpen: Bool = true
  NavigationDrawerHostView(isOpen: $isOpen) {
    Color.red.opacity(0.3)
      .overlay(Text("Main Content"))
  } drawer: {
    Color.blue.opacity(0.3)
      .overlay(Text("Drawer Content"))
  } onDrawerIconTap: {
    isOpen.toggle()
  }
}
