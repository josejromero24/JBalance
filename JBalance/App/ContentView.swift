//
//  ContentView.swift
//  JBalance
//
//  Created by JJ Romero Alvarez on 10/05/2026.
//

import SwiftUI
import UIKit

struct ContentView: View {
    init() {
        let dependencies = JBalanceDependencies.live()
        let rootAppViewModel = dependencies.makeAppViewModel()
        _appViewModel = StateObject(wrappedValue: rootAppViewModel)
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(appViewModel: rootAppViewModel))
        _weightHistoryViewModel = StateObject(wrappedValue: WeightHistoryViewModel(appViewModel: rootAppViewModel))
        _foodDiaryViewModel = StateObject(wrappedValue: dependencies.makeFoodDiaryViewModel(appViewModel: rootAppViewModel))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(appViewModel: rootAppViewModel))
        _onboardingViewModel = StateObject(wrappedValue: dependencies.makeOnboardingViewModel())
        _recipesViewModel = StateObject(wrappedValue: dependencies.makeRecipesViewModel())

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.97, green: 0.98, blue: 1.00, alpha: 1.00)
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.12, green: 0.28, blue: 0.78, alpha: 1.00)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.12, green: 0.28, blue: 0.78, alpha: 1.00)]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.23, green: 0.27, blue: 0.35, alpha: 1.00)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.23, green: 0.27, blue: 0.35, alpha: 1.00)]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    @StateObject private var appViewModel: AppViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var weightHistoryViewModel: WeightHistoryViewModel
    @StateObject private var foodDiaryViewModel: FoodDiaryViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var onboardingViewModel: OnboardingViewModel
    @StateObject private var recipesViewModel: RecipesViewModel

    var body: some View {
        Group {
            if onboardingViewModel.hasCompleted == false && appViewModel.hasCompletedOnboarding == false {
                OnboardingView(viewModel: onboardingViewModel)
            } else {
                TabView(selection: $appViewModel.selectedTab) {
                    DashboardView(viewModel: dashboardViewModel)
                        .tabItem {
                            Label("Resumen", systemImage: "house.fill")
                        }
                        .tag(AppTab.dashboard)

                    WeightHistoryView(viewModel: weightHistoryViewModel)
                        .tabItem {
                            Label("Evolución", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(AppTab.history)

                    FoodDiaryView(viewModel: foodDiaryViewModel)
                        .tabItem {
                            Label("Comida", systemImage: "fork.knife.circle.fill")
                        }
                        .tag(AppTab.food)

                    RecipesView(foodDiaryViewModel: foodDiaryViewModel, viewModel: recipesViewModel)
                        .tabItem {
                            Label("Recetas", systemImage: "carrot.fill")
                        }
                        .tag(AppTab.recipes)

                    ProfileView(viewModel: profileViewModel)
                        .tabItem {
                            Label("Perfil", systemImage: "person.crop.circle.fill")
                        }
                        .tag(AppTab.profile)
                }
                .tint(JBalancePalette.primary)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            appViewModel.reload()
        }
        .task {
            if onboardingViewModel.hasCompleted || appViewModel.hasCompletedOnboarding {
                await appViewModel.importHealthData()
            }
        }
        .onChange(of: onboardingViewModel.hasCompleted) { _, newValue in
            if newValue {
                appViewModel.reload()
            }
        }
    }
}
