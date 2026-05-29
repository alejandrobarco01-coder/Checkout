package com.example.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.ExperimentalAnimationApi
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.with
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.AppScreen
import com.example.ui.CheckoutViewModel
import com.example.ui.theme.*

@OptIn(ExperimentalAnimationApi::class)
@Composable
fun OnboardingScreen(viewModel: CheckoutViewModel, onFinished: () -> Unit) {
    var currentStep by remember { mutableStateOf(0) }
    
    val steps = listOf(
        OnboardingItem(
            title = "Nunca olvides tus esenciales",
            description = "Llaves, equipo de gimnasio o gafas de sol—CheckOut actúa como tu recordatorio inteligente, creando listas de control según el contexto de tu rutina diaria.",
            emoji = "💼",
            accentBrush = Brush.horizontalGradient(listOf(LightPrimary, LightSecondary))
        ),
        OnboardingItem(
            title = "Se adapta al pronóstico",
            description = "¿Lluvia, nieve o calor inesperado? Nuestra integración inteligente del clima agrega dinámicamente equipo esencial a tus listas.",
            emoji = "☔",
            accentBrush = Brush.horizontalGradient(listOf(StatusInfo, LightPrimary))
        ),
        OnboardingItem(
            title = "Alertas Inteligentes de Geocerca",
            description = "Configura tu 'Base'. Si te alejas a un radio mayor de 50 metros con elementos sin marcar, CheckOut enviará una notificación instantánea de alta prioridad.",
            emoji = "📍",
            accentBrush = Brush.horizontalGradient(listOf(LightSecondary, StatusWarning))
        ),
        OnboardingItem(
            title = "Gamifica tu Rutina",
            description = "Acumula rachas, récords históricos y desbloquea insignias. Rastrea tus 'Elementos más olvidados' para optimizar tu lista diaria.",
            emoji = "🔥",
            accentBrush = Brush.horizontalGradient(listOf(StatusSuccess, LightSecondary))
        )
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(24.dp)
            .windowInsetsPadding(WindowInsets.safeDrawing),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxSize()
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "CheckOut",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.ExtraBold,
                    color = MaterialTheme.colorScheme.primary
                )
                
                TextButton(
                    onClick = onFinished,
                    modifier = Modifier.testTag("skip_onboarding_button")
                ) {
                    Text("Omitir", color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f))
                }
            }

            // Animated Slider Body
            AnimatedContent(
                targetState = currentStep,
                transitionSpec = {
                    fadeIn(animationSpec = tween(300)) with fadeOut(animationSpec = tween(300))
                },
                modifier = Modifier.weight(1f),
                label = "onboarding_step_transitions"
            ) { stepIdx ->
                val item = steps[stepIdx]
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.fillMaxSize().padding(16.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(140.dp)
                            .clip(CircleShape)
                            .background(item.accentBrush),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(item.emoji, fontSize = 64.sp)
                    }

                    Spacer(modifier = Modifier.height(36.dp))

                    Text(
                        text = item.title,
                        style = MaterialTheme.typography.headlineMedium.copy(
                            fontWeight = FontWeight.Black,
                            fontSize = 24.sp
                        ),
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onBackground
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = item.description,
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                        lineHeight = 22.sp
                    )
                }
            }

            // Navigation Bottom Indicators
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
            ) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(bottom = 24.dp)
                ) {
                    steps.forEachIndexed { index, _ ->
                        Box(
                            modifier = Modifier
                                .padding(horizontal = 4.dp)
                                .size(width = if (index == currentStep) 24.dp else 8.dp, height = 8.dp)
                                .clip(CircleShape)
                                .background(
                                    if (index == currentStep) MaterialTheme.colorScheme.primary
                                    else MaterialTheme.colorScheme.onBackground.copy(alpha = 0.2f)
                                )
                        )
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (currentStep > 0) {
                        OutlinedButton(
                            onClick = { currentStep-- },
                            modifier = Modifier
                                .weight(1f)
                                .padding(end = 8.dp)
                                .minimumInteractiveComponentSize()
                                .testTag("onboarding_prev_button")
                        ) {
                            Text("Atrás")
                        }
                    }

                    Button(
                        onClick = {
                            if (currentStep < steps.size - 1) {
                                currentStep++
                            } else {
                                onFinished()
                            }
                        },
                        modifier = Modifier
                            .weight(2f)
                            .minimumInteractiveComponentSize()
                            .testTag("onboarding_next_button")
                    ) {
                        Text(if (currentStep == steps.size - 1) "Empezar 🚀" else "Siguiente")
                    }
                }
            }
        }
    }
}

data class OnboardingItem(
    val title: String,
    val description: String,
    val emoji: String,
    val accentBrush: Brush
)
