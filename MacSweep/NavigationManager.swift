import SwiftUI

struct NavState: Equatable {
    let section: AppSection
    let subState: String? // e.g. "general", "about", "scanning", etc.
    
    static func == (lhs: NavState, rhs: NavState) -> Bool {
        return lhs.section == rhs.section && lhs.subState == rhs.subState
    }
}

class NavigationManager: ObservableObject {
    @Published var currentSection: AppSection = .dashboard {
        didSet {
            if !isNavigatingInternally {
                push(NavState(section: currentSection, subState: nil))
            }
        }
    }
    
    @Published var currentState: NavState = NavState(section: .dashboard, subState: nil)
    @Published var history: [NavState] = [NavState(section: .dashboard, subState: nil)]
    @Published var currentIndex: Int = 0
    
    private var isNavigatingInternally = false
    
    /// Navigates to a specific section, optionally with a sub-state.
    /// This is used for internal navigation (e.g. Settings tabs) that should be recorded in history.
    func navigate(to section: AppSection, subState: String? = nil) {
        let newState = NavState(section: section, subState: subState)
        push(newState)
    }

    private func push(_ state: NavState) {
        // If we are selecting the same state, ignore
        guard state != history[currentIndex] else { return }
        
        // Remove forward history if we are in the middle
        if currentIndex < history.count - 1 {
            history.removeSubrange((currentIndex + 1)...)
        }
        
        history.append(state)
        currentIndex = history.count - 1
        
        // Update current state and section without triggering another push
        isNavigatingInternally = true
        currentState = state
        currentSection = state.section
        isNavigatingInternally = false
        
        // Limit history size
        if history.count > 50 {
            history.removeFirst()
            currentIndex -= 1
        }
    }
    
    func goBack() {
        guard canGoBack else { return }
        jump(to: currentIndex - 1)
    }
    
    func goForward() {
        guard canGoForward else { return }
        jump(to: currentIndex + 1)
    }
    
    var canGoBack: Bool {
        currentIndex > 0
    }
    
    var canGoForward: Bool {
        currentIndex < history.count - 1
    }

    var canGoBackInCurrentSection: Bool {
        guard currentIndex > 0 else { return false }
        return history[currentIndex - 1].section == currentSection
    }

    var canGoForwardInCurrentSection: Bool {
        guard currentIndex < history.count - 1 else { return false }
        return history[currentIndex + 1].section == currentSection
    }

    @discardableResult
    func goBackInCurrentSection() -> Bool {
        guard canGoBackInCurrentSection else { return false }
        goBack()
        return true
    }

    @discardableResult
    func goForwardInCurrentSection() -> Bool {
        guard canGoForwardInCurrentSection else { return false }
        goForward()
        return true
    }

    /// Jump back to the most recent state in a different section.
    /// If none exists, falls back to a single-step back.
    @discardableResult
    func goBackToPreviousSection() -> Bool {
        guard canGoBack else { return false }
        let originSection = currentSection
        var targetIndex = currentIndex - 1
        while targetIndex > 0 && history[targetIndex].section == originSection {
            targetIndex -= 1
        }
        if history[targetIndex].section == originSection {
            targetIndex = currentIndex - 1
        }
        jump(to: targetIndex)
        return true
    }

    /// Jump forward to the next state in a different section.
    /// If none exists, falls back to a single-step forward.
    @discardableResult
    func goForwardToNextSection() -> Bool {
        guard canGoForward else { return false }
        let originSection = currentSection
        var targetIndex = currentIndex + 1
        while targetIndex < history.count - 1 && history[targetIndex].section == originSection {
            targetIndex += 1
        }
        if history[targetIndex].section == originSection {
            targetIndex = currentIndex + 1
        }
        jump(to: targetIndex)
        return true
    }

    private func jump(to index: Int) {
        guard history.indices.contains(index) else { return }
        isNavigatingInternally = true
        currentIndex = index
        let state = history[index]
        currentState = state
        currentSection = state.section
        isNavigatingInternally = false
    }
}
