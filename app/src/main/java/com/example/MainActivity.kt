package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ui.AppScreen
import com.example.ui.CheckoutViewModel
import com.example.ui.screens.AuthScreen
import com.example.ui.screens.DashboardScreen
import com.example.ui.screens.OnboardingScreen
import com.example.ui.screens.SplashScreen
import com.example.ui.theme.CheckOutTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Setup full-bleed edge-to-edge drawing
        enableEdgeToEdge()
        
        setContent {
            val viewModel: CheckoutViewModel = viewModel()
            val currentScreen by viewModel.currentScreen.collectAsState()

            CheckOutTheme {
                Box(modifier = Modifier.fillMaxSize()) {
                    when (currentScreen) {
                        AppScreen.Splash -> SplashScreen(viewModel) { screen ->
                            viewModel.navigateTo(screen)
                        }
                        AppScreen.Onboarding -> OnboardingScreen(viewModel) {
                            viewModel.finishOnboarding()
                        }
                        AppScreen.Auth -> AuthScreen(viewModel)
                        AppScreen.Dashboard -> DashboardScreen(viewModel)
                    }
                }
            }
        }
    }
}
