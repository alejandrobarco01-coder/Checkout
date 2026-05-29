package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.ChecklistContext
import com.example.data.model.ChecklistItem
import com.example.data.model.CheckoutHistory
import com.example.ui.CheckoutViewModel
import com.example.ui.GeofenceAlert
import com.example.ui.HomeTab
import com.example.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(viewModel: CheckoutViewModel) {
    val currentTab by viewModel.currentTab.collectAsState()
    val activeContext by viewModel.activeContext.collectAsState()
    val allContexts by viewModel.allContexts.collectAsState()
    val userProfile by viewModel.userProfile.collectAsState()

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        bottomBar = {
            NavigationBar(
                modifier = Modifier.windowInsetsPadding(WindowInsets.navigationBars),
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 8.dp
            ) {
                NavigationBarItem(
                    selected = currentTab == HomeTab.Home,
                    onClick = { viewModel.selectTab(HomeTab.Home) },
                    icon = { Icon(Icons.Default.Checklist, contentDescription = "Home") },
                    label = { Text("Asistente") },
                    modifier = Modifier.testTag("nav_home_tab")
                )
                NavigationBarItem(
                    selected = currentTab == HomeTab.Stats,
                    onClick = { viewModel.selectTab(HomeTab.Stats) },
                    icon = { Icon(Icons.Default.Analytics, contentDescription = "Stats") },
                    label = { Text("Historial") },
                    modifier = Modifier.testTag("nav_stats_tab")
                )
                NavigationBarItem(
                    selected = currentTab == HomeTab.Settings,
                    onClick = { viewModel.selectTab(HomeTab.Settings) },
                    icon = { Icon(Icons.Default.Settings, contentDescription = "Settings") },
                    label = { Text("Ajustes") },
                    modifier = Modifier.testTag("nav_settings_tab")
                )
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(MaterialTheme.colorScheme.background)
        ) {
            when (currentTab) {
                HomeTab.Home -> HomeTabContent(viewModel)
                HomeTab.Stats -> StatsTabContent(viewModel)
                HomeTab.Settings -> SettingsTabContent(viewModel)
            }
        }
    }
}

// ----------------------------------------------------
// HOME TAB: Checklist and Reminders Control Panel
// ----------------------------------------------------
@Composable
fun HomeTabContent(viewModel: CheckoutViewModel) {
    val contexts by viewModel.allContexts.collectAsState()
    val activeContext by viewModel.activeContext.collectAsState()
    val activeItems by viewModel.activeItems.collectAsState()
    val weatherState by viewModel.weatherState.collectAsState()
    val weatherLoading by viewModel.weatherLoading.collectAsState()
    val weatherError by viewModel.weatherError.collectAsState()
    val userProfile by viewModel.userProfile.collectAsState()
    val alertHistory by viewModel.geofenceNotificationHistory.collectAsState()

    var showContextCreator by remember { mutableStateOf(false) }
    var newItemName by remember { mutableStateOf("") }

    val isPremium = userProfile?.isPremium == true

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp)
    ) {
        // Upper Greeting Header Card
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(bottomStart = 32.dp, bottomEnd = 32.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.Transparent),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.linearGradient(
                                colors = listOf(Color(0xFF4C51BF), Color(0xFF667EEA))
                            )
                        )
                        .padding(18.dp)
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(
                                modifier = Modifier.weight(1f),
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .background(Color.White.copy(alpha = 0.2f), RoundedCornerShape(8.dp)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("💼", fontSize = 20.sp)
                                }
                                Column {
                                    Text(
                                        text = "CheckOut",
                                        fontWeight = FontWeight.Black,
                                        fontSize = 20.sp,
                                        color = Color.White,
                                        letterSpacing = (-0.5).sp
                                    )
                                    Text(
                                        text = "Centro de Salida Inteligente",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White.copy(alpha = 0.7f)
                                    )
                                }
                            }

                            Row(
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(horizontalAlignment = Alignment.End) {
                                    Text(
                                        text = "PLAN PREMIUM",
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White.copy(alpha = 0.8f),
                                        letterSpacing = 1.sp
                                    )
                                    Text(
                                        text = if (isPremium) "PRO ACTIVO 👑" else "ESTÁNDAR ACTIVO",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Black,
                                        color = Color(0xFFED8936)
                                    )
                                }
                                
                                // Beautiful dynamic avatar matching styling Felix seed
                                Box(
                                    modifier = Modifier
                                        .size(38.dp)
                                        .background(Color.White.copy(alpha = 0.25f), CircleShape)
                                        .border(BorderStroke(1.5.dp, Color.White.copy(alpha = 0.35f)), CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("😎", fontSize = 18.sp)
                                }
                            }
                        }

                        // Smart Weather Integration Widget embedded inside gradient card
                        val weather = weatherState
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color.White.copy(alpha = 0.12f), RoundedCornerShape(16.dp))
                                .border(BorderStroke(1.dp, Color.White.copy(alpha = 0.22f)), RoundedCornerShape(16.dp))
                                .padding(12.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Text(
                                        text = if (weatherLoading) "⏳" else when {
                                            weather?.weather?.firstOrNull()?.main?.contains("Rain", ignoreCase = true) == true -> "🌧️"
                                            weather?.weather?.firstOrNull()?.main?.contains("Snow", ignoreCase = true) == true -> "❄️"
                                            weather?.weather?.firstOrNull()?.main?.contains("Cloud", ignoreCase = true) == true -> "☁️"
                                            else -> "☀️"
                                        },
                                        fontSize = 28.sp
                                    )
                                    Column {
                                        Text(
                                            text = if (weatherLoading) "Actualizando pronóstico..." else if (weather != null) "Clima: " + (weather.weather?.firstOrNull()?.main ?: "Despejado") else "Pronóstico Offline",
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color.White
                                        )
                                        Text(
                                            text = if (weather != null) "${weather.name ?: "Estación"} • ${weather.main?.temp?.toInt() ?: 20}°C" else "Verificar config de coordenadas",
                                            fontSize = 11.sp,
                                            color = Color.White.copy(alpha = 0.8f)
                                        )
                                    }
                                }

                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .background(Color(0xFFED8936), RoundedCornerShape(10.dp))
                                            .padding(horizontal = 8.dp, vertical = 4.dp)
                                    ) {
                                        Text(
                                            text = if (weatherLoading) "SINCRONIZANDO" else "REGLA ACTIVA",
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.ExtraBold,
                                            color = Color.White
                                        )
                                    }
                                    
                                    IconButton(
                                        onClick = { viewModel.triggerWeatherRefresh() },
                                        modifier = Modifier.size(20.dp)
                                    ) {
                                        Icon(
                                            Icons.Default.Refresh, 
                                            contentDescription = "Refresh", 
                                            tint = Color.White,
                                            modifier = Modifier.size(12.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Active Contexts Horizontal Pager Row
        item {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "CONTEXTOS ACTIVOS",
                        fontSize = 11.sp,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.5.sp,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                    )
                    
                    TextButton(
                        onClick = { showContextCreator = true },
                        modifier = Modifier.testTag("add_context_trigger")
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Añadir Nuevo", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
                    }
                }

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    items(contexts) { ctx ->
                        val isSelected = ctx.id == activeContext?.id
                        val contextColor = runCatching { Color(android.graphics.Color.parseColor(ctx.colorHex)) }.getOrDefault(MaterialTheme.colorScheme.primary)

                        Box(
                            modifier = Modifier
                                .width(120.dp)
                                .clip(RoundedCornerShape(20.dp))
                                .background(if (isSelected) contextColor.copy(alpha = 0.12f) else MaterialTheme.colorScheme.surface)
                                .border(
                                    BorderStroke(
                                        width = if (isSelected) 2.dp else 1.dp,
                                        color = if (isSelected) contextColor else MaterialTheme.colorScheme.outlineVariant
                                    ),
                                    shape = RoundedCornerShape(20.dp)
                                )
                                .clickable { viewModel.selectContext(ctx.id) }
                                .padding(14.dp)
                                .testTag("context_card_${ctx.name.lowercase()}"),
                            contentAlignment = Alignment.TopStart
                        ) {
                            Column {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(ctx.icon, fontSize = 24.sp)
                                    if (ctx.isPremium) {
                                        Text("👑", fontSize = 11.sp)
                                    }
                                }
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Text(
                                    text = ctx.name,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    color = if (isSelected) contextColor else MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                }
            }
        }

        // Expanded Dialog for creating new Contexts
        if (showContextCreator) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
                ) {
                    var newContextName by remember { mutableStateOf("") }
                    var selectedEmoji by remember { mutableStateOf("💼") }
                    var selectedHexColor by remember { mutableStateOf("#4C51BF") }

                    val emojis = listOf("💼", "🏋️", "✈️", "🚴", "⛺", "🎓", "🐶", "🛍️")
                    val colors = listOf("#4C51BF", "#ED8936", "#48BB78", "#E53E3E", "#3182CE", "#805AD5", "#DD6B20")

                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Crear Contexto Personalizado", fontWeight = FontWeight.Black, fontSize = 16.sp)
                            IconButton(onClick = { showContextCreator = false }) {
                                Icon(Icons.Default.Close, contentDescription = null)
                            }
                        }

                        if (!isPremium) {
                            Surface(
                                color = StatusWarning.copy(alpha = 0.1f),
                                modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                                shape = MaterialTheme.shapes.small
                            ) {
                                Text(
                                    "✨ Se requiere Premium para guardar múltiples contextos. ¡Puedes desbloquearlo gratis en la pestaña Ajustes!",
                                    color = StatusWarning,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(10.dp)
                                )
                            }
                        }

                        OutlinedTextField(
                            value = newContextName,
                            onValueChange = { newContextName = it },
                            label = { Text("Nombre del Contexto (ej. Senderismo)") },
                            singleLine = true,
                            enabled = isPremium,
                            modifier = Modifier.fillMaxWidth().testTag("custom_context_name_input")
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        Text("Seleccionar Emoji", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface.copy(0.6f))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(vertical = 4.dp)) {
                            emojis.forEach { emo ->
                                val selected = selectedEmoji == emo
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .clip(CircleShape)
                                        .background(if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.15f) else Color.Transparent)
                                        .border(BorderStroke(if (selected) 2.dp else 0.dp, MaterialTheme.colorScheme.primary), CircleShape)
                                        .clickable(enabled = isPremium) { selectedEmoji = emo }
                                        .padding(4.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(emo, fontSize = 20.sp)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        Text("Seleccionar Color de Acento", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface.copy(0.6f))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(vertical = 4.dp)) {
                            colors.forEach { hex ->
                                val selected = selectedHexColor == hex
                                val c = Color(android.graphics.Color.parseColor(hex))
                                Box(
                                    modifier = Modifier
                                        .size(30.dp)
                                        .clip(CircleShape)
                                        .background(c)
                                        .clickable(enabled = isPremium) { selectedHexColor = hex }
                                        .border(BorderStroke(if (selected) 3.dp else 1.dp, if (selected) Color.White else Color.Transparent), CircleShape)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        Button(
                            onClick = {
                                viewModel.createCustomContext(newContextName, selectedEmoji, selectedHexColor)
                                showContextCreator = false
                            },
                            enabled = isPremium && newContextName.isNotBlank(),
                            modifier = Modifier.fillMaxWidth().testTag("add_custom_context_confirm")
                        ) {
                            Text("Crear y Guardar Contexto", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }

        // REAL-TIME WEATHER MODULE CARD
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(Icons.Default.Cloud, contentDescription = "Weather", tint = StatusInfo)
                            Text(
                                "Asistente de Clima en Vivo (Motor Inteligente)",
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        
                        IconButton(
                            onClick = { viewModel.triggerWeatherRefresh() },
                            modifier = Modifier.size(24.dp).testTag("weather_refresh_button")
                        ) {
                            Icon(Icons.Default.Refresh, contentDescription = "Refresh", modifier = Modifier.size(16.dp))
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    if (weatherLoading) {
                        Box(modifier = Modifier.fillMaxWidth().padding(12.dp), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(modifier = Modifier.size(28.dp))
                        }
                    } else if (weatherState != null) {
                        val weather = weatherState!!
                        val mainGroup = weather.weather?.firstOrNull()?.main ?: "Clear"
                        val temp = weather.main?.temp ?: 20.0
                        val description = weather.weather?.firstOrNull()?.description ?: "cielos perfectamente soleados"
                        val locationName = weather.name ?: "Ubicación Desconocida"

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "$locationName | $mainGroup",
                                    fontWeight = FontWeight.Black,
                                    fontSize = 16.sp,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    text = description.replaceFirstChar { it.uppercase() },
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                )
                            }
                            
                            Box(
                                modifier = Modifier
                                    .background(StatusInfo.copy(alpha = 0.1f), CircleShape)
                                    .padding(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Text(
                                    text = "${temp.toInt()} °C",
                                    fontWeight = FontWeight.ExtraBold,
                                    color = StatusInfo,
                                    fontSize = 16.sp
                                )
                            }
                        }

                        // Rule engine banner
                        val hasAdditions = mainGroup.contains("Rain") || mainGroup.contains("Snow") || temp < 10.0 || temp > 28.0
                        AnimatedVisibility(visible = hasAdditions) {
                            Surface(
                                color = StatusWarning.copy(alpha = 0.12f),
                                shape = MaterialTheme.shapes.small,
                                modifier = Modifier.fillMaxWidth().padding(top = 12.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(10.dp),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("☔", fontSize = 20.sp)
                                    Column {
                                        Text(
                                            "Regla Inteligente de Clima: Verdadera",
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 12.sp,
                                            color = StatusWarning
                                        )
                                        Text(
                                            "CheckOut insertó recomendaciones de equipo basadas en el clima a tu lista dinámicamente según el pronóstico.",
                                            fontSize = 10.sp,
                                            lineHeight = 13.sp,
                                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                                        )
                                    }
                                }
                            }
                        }
                    } else if (weatherError != null) {
                        Text(
                            "Error al resolver el pronóstico. Las coordenadas pueden ser inalcanzables.",
                            color = StatusError,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }

        // DETAIL CHECKLIST PANEL
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                shape = RoundedCornerShape(24.dp),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "LISTA DE CONTROL INTELIGENTE",
                            fontSize = 11.sp,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Black,
                            letterSpacing = 1.5.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                        )
                        
                        val checkedCount = activeItems.count { it.isChecked }
                        val totalCount = activeItems.size
                        Box(
                            modifier = Modifier
                                .background(Color(0xFF48BB78).copy(alpha = 0.12f), RoundedCornerShape(12.dp))
                                .padding(horizontal = 8.dp, vertical = 3.dp)
                        ) {
                            Text(
                                text = "$checkedCount / $totalCount HECHO",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF48BB78)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    if (activeItems.isEmpty()) {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(24.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("📭", fontSize = 36.sp)
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    "No hay elementos en esta lista.",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                                )
                            }
                        }
                    } else {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            activeItems.forEach { item ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(16.dp))
                                        .background(
                                            if (item.isChecked) MaterialTheme.colorScheme.surface
                                            else if (item.isAutoSuggested) Color(0xFFFFF7ED)
                                            else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.02f)
                                        )
                                        .border(
                                            BorderStroke(
                                                width = 1.dp, 
                                                color = if (item.isAutoSuggested && !item.isChecked) Color(0xFFED8936).copy(alpha = 0.3f) else MaterialTheme.colorScheme.outlineVariant
                                            ), 
                                            shape = RoundedCornerShape(16.dp)
                                        )
                                        .clickable { viewModel.toggleItemCheck(item) }
                                        .padding(horizontal = 12.dp, vertical = 10.dp)
                                        .testTag("item_row_${item.id}"),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                                        modifier = Modifier.weight(1f)
                                    ) {
                                        Checkbox(
                                            checked = item.isChecked,
                                            onCheckedChange = { viewModel.toggleItemCheck(item) },
                                            modifier = Modifier.testTag("item_checkbox_${item.id}")
                                        )
                                        
                                        Column {
                                            Text(
                                                text = item.name,
                                                fontWeight = if (item.isChecked) FontWeight.Light else FontWeight.Bold,
                                                color = if (item.isChecked) MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f) else MaterialTheme.colorScheme.onSurface,
                                                fontSize = 14.sp
                                            )
                                            if (item.isAutoSuggested) {
                                                Spacer(modifier = Modifier.height(2.dp))
                                                Box(
                                                    modifier = Modifier
                                                        .background(Color(0xFFED8936).copy(alpha = 0.12f), RoundedCornerShape(4.dp))
                                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                                ) {
                                                    Text(
                                                        "INFO CLIMA: RECOMENDACIÓN DINÁMICA",
                                                        fontSize = 8.sp,
                                                        color = Color(0xFFED8936),
                                                        fontWeight = FontWeight.Black
                                                    )
                                                }
                                            }
                                        }
                                    }

                                    IconButton(
                                        onClick = { viewModel.deleteItem(item) },
                                        modifier = Modifier.testTag("item_delete_button_${item.id}")
                                    ) {
                                        Icon(
                                            Icons.Default.Delete,
                                            contentDescription = "Delete Item",
                                            tint = StatusError.copy(alpha = 0.7f),
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Input block to append new custom items instantly
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedTextField(
                            value = newItemName,
                            onValueChange = { newItemName = it },
                            placeholder = { Text("Añadir elemento esencial (ej. Cartera 💳)", fontSize = 12.sp) },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                            keyboardActions = KeyboardActions(onDone = {
                                if (newItemName.isNotBlank()) {
                                    viewModel.addNewItem(newItemName)
                                    newItemName = ""
                                }
                            }),
                            modifier = Modifier.weight(1f).testTag("quick_add_item_input"),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = MaterialTheme.colorScheme.primary
                            )
                        )
                        
                        Button(
                            onClick = {
                                if (newItemName.isNotBlank()) {
                                    viewModel.addNewItem(newItemName)
                                    newItemName = ""
                                }
                            },
                            modifier = Modifier.minimumInteractiveComponentSize().testTag("add_item_action_button")
                        ) {
                            Text("Añadir", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }

        // Bottom Achievement Summary
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)), // slate-900 / dark slate
                shape = RoundedCornerShape(24.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(42.dp)
                                .background(Color.White.copy(alpha = 0.1f), RoundedCornerShape(12.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("🏆", fontSize = 20.sp)
                        }
                        
                        Column {
                            Text(
                                "SIGUIENTE INSIGNIA",
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF94A3B8), // slate-400
                                letterSpacing = 1.2.sp
                            )
                            Spacer(modifier = Modifier.height(2.dp))
                            val currentStreak = userProfile?.streakCount ?: 0
                            val daysRequired = if (currentStreak >= 30) 100 else if (currentStreak >= 15) 30 else if (currentStreak >= 7) 15 else 7
                            val badgeName = if (daysRequired == 7) "Viajero Constante" else if (daysRequired == 15) "Campeón de Rutina" else if (daysRequired == 30) "Mente de Hierro" else "Maestro Absoluto"
                            Text(
                                text = "$badgeName ($currentStreak/$daysRequired Días)",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Black,
                                color = Color.White
                            )
                        }
                    }

                    // Circular ring percentage
                    Box(
                        modifier = Modifier.size(42.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        val currentStreak = userProfile?.streakCount ?: 0
                        val daysRequired = if (currentStreak >= 30) 100 else if (currentStreak >= 15) 30 else if (currentStreak >= 7) 15 else 7
                        val fraction = if (daysRequired > 0) (currentStreak.toFloat() / daysRequired.toFloat()).coerceIn(0f, 1f) else 1f
                        val percentInt = (fraction * 100).toInt()
                        
                        CircularProgressIndicator(
                            progress = { fraction },
                            modifier = Modifier.fillMaxSize(),
                            color = Color(0xFF667EEA),
                            strokeWidth = 3.dp,
                            trackColor = Color.White.copy(alpha = 0.15f)
                        )
                        
                        Text(
                            text = "$percentInt%",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Black,
                            color = Color.White
                        )
                    }
                }
            }
        }

        // GEOFENCING SIMULATED CONSOLE CARD (MANDATORY REQUIREMENT)
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(2.dp, MaterialTheme.colorScheme.secondary.copy(alpha = 0.5f))
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text("📍", fontSize = 24.sp)
                            Column {
                                Text(
                                    "Simulador de Motor de Geocerca",
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 15.sp,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    "Sale de Base (límite de 50m)",
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Text(
                        "Normalmente, al alejarte más de 50 metros, verificamos si tu lista está completa. Si olvidas algo, ¡se enviará una notificación Push! Usa nuestro simulador para probar.",
                        fontSize = 11.sp,
                        lineHeight = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Button(
                        onClick = { viewModel.simulateLeavingHomeBase() },
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary),
                        modifier = Modifier.fillMaxWidth().height(48.dp).testTag("simulate_geofence_button")
                    ) {
                        Text(
                            "Simular Salida de Base 🚀",
                            fontWeight = FontWeight.Black,
                            fontSize = 13.sp
                        )
                    }
                }
            }
        }

        // LOCAL APP NOTIFICATION HISTORY LOGS
        item {
            if (alertHistory.isNotEmpty()) {
                Column {
                    Text(
                        "Registro de Alertas y Notificaciones",
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onBackground,
                        modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
                    )

                    alertHistory.forEach { alert ->
                        val dateString = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date(alert.timestamp))
                        Card(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (alert.isHighPriority) StatusError.copy(alpha = 0.05f) else StatusSuccess.copy(alpha = 0.05f)
                            ),
                            border = BorderStroke(1.dp, if (alert.isHighPriority) StatusError.copy(alpha = 0.3f) else StatusSuccess.copy(alpha = 0.3f))
                        ) {
                            Row(
                                modifier = Modifier.padding(14.dp),
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(alert.contextEmoji, fontSize = 28.sp)
                                
                                Column(modifier = Modifier.weight(1f)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            alert.title,
                                            fontWeight = FontWeight.ExtraBold,
                                            fontSize = 13.sp,
                                            color = if (alert.isHighPriority) StatusError else StatusSuccess
                                        )
                                        Text(
                                            dateString,
                                            fontSize = 10.sp,
                                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                                        )
                                    }
                                    Spacer(modifier = Modifier.height(3.dp))
                                    Text(
                                        alert.body,
                                        fontSize = 11.sp,
                                        lineHeight = 14.sp,
                                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                                    )
                                }

                                IconButton(onClick = { viewModel.deleteNotificationRecord(alert) }, modifier = Modifier.size(20.dp)) {
                                    Icon(Icons.Default.Close, contentDescription = null, modifier = Modifier.size(14.dp))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// ----------------------------------------------------
// STATS TAB: Gamification and Streak metrics
// ----------------------------------------------------
@Composable
fun StatsTabContent(viewModel: CheckoutViewModel) {
    val history by viewModel.allHistory.collectAsState()
    val topForgotten = viewModel.getTopForgottenItems()
    val profile by viewModel.userProfile.collectAsState()

    val totalCount = history.size
    val successfulCount = history.count { it.wasSuccessful }
    val failureCount = totalCount - successfulCount
    val scorePercentage = if (totalCount == 0) 100 else (successfulCount * 100 / totalCount)

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp)
    ) {
        // Stats Streak Header Card
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.15f))
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            "🔥 Contador de Racha Diaria",
                            fontWeight = FontWeight.Black,
                            fontSize = 16.sp,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            "¡Completa el 100% de las listas al salir para mantener tu racha!",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }

                    Box(
                        modifier = Modifier
                            .background(StatusWarning.copy(alpha = 0.1f), CircleShape)
                            .border(BorderStroke(1.dp, StatusWarning), CircleShape)
                            .padding(horizontal = 16.dp, vertical = 10.dp)
                    ) {
                        Text(
                            text = "${profile?.streakCount ?: 0} Días",
                            fontWeight = FontWeight.Black,
                            color = StatusWarning,
                            fontSize = 18.sp
                        )
                    }
                }
            }
        }

        // Progress metrics layout
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Card(
                    modifier = Modifier.weight(1f),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("Precisión", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            "$scorePercentage%",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Black,
                            color = if (scorePercentage > 80) StatusSuccess else if (scorePercentage > 50) StatusWarning else StatusError
                        )
                    }
                }

                Card(
                    modifier = Modifier.weight(1f),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("Salidas Totales", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            "$totalCount Registros",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Black,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                }
            }
        }

        // TOP MOST FORGOTTEN ITEMS ENGINE (MANDATORY REQUIREMENT)
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text(
                        "⚠️ Top 3 Elementos más Olvidados",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        "Calculado automáticamente basado en historial de salidas incompletas. ¡Optimízalos para la próxima!",
                        fontSize = 11.sp,
                        lineHeight = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    if (topForgotten.isEmpty()) {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(12.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "¡Sin fallos! Registro de salidas limpio.",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = StatusSuccess
                            )
                        }
                    } else {
                        topForgotten.forEachIndexed { index, pair ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Surface(
                                        color = if (index == 0) StatusError.copy(alpha = 0.15f) else StatusWarning.copy(alpha = 0.15f),
                                        shape = CircleShape,
                                        modifier = Modifier.size(24.dp)
                                    ) {
                                        Box(contentAlignment = Alignment.Center) {
                                            Text("${index + 1}", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = if (index == 0) StatusError else StatusWarning)
                                        }
                                    }
                                    Text(pair.first, fontWeight = FontWeight.Bold, fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurface)
                                }
                                
                                Text(
                                    "Olvidado ${pair.second}x",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Black,
                                    color = if (index == 0) StatusError else StatusWarning
                                )
                            }
                        }
                    }
                }
            }
        }

        // GAMIFICATION ACHIEVEMENTS BADGES PANEL (MANDATORY BENEFIT)
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text(
                        "🎖️ Insignias de Logros",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        "Consigue consistencia para desbloquear insignias dinámicas.",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    val badgeNewbieUnlocked = totalCount >= 1
                    val badgeConsistentUnlocked = (profile?.streakCount ?: 0) >= 7
                    val badgeIronMindUnlocked = (profile?.streakCount ?: 0) >= 30

                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        // Badge Newbie
                        BadgeItem(
                            title = "Principiante de Listas",
                            description = "Completa al menos 1 validación de salida.",
                            isUnlocked = badgeNewbieUnlocked,
                            emoji = "🔰",
                            colorAccent = StatusInfo
                        )

                        // Badge Consistent
                        BadgeItem(
                            title = "Fuego Constante de 7 Días",
                            description = "Mantén una racha de 7 días de salidas perfectas sin fallos.",
                            isUnlocked = badgeConsistentUnlocked,
                            emoji = "⭐",
                            colorAccent = StatusSuccess
                        )

                        // Badge Iron Mind
                        BadgeItem(
                            title = "Maestro Mente de Hierro de 30 Días",
                            description = "Mantén una racha de salidas perfectas por 30 días.",
                            isUnlocked = badgeIronMindUnlocked,
                            emoji = "🛡️",
                            colorAccent = StatusWarning
                        )
                    }
                }
            }
        }

        // RECENT LOGS LIST
        item {
            Text(
                "Registro Histórico de Salidas Recientes",
                fontWeight = FontWeight.Bold,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )
        }

        if (history.isEmpty()) {
            item {
                Box(modifier = Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) {
                    Text("No hay registros históricos de salidas aún.", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f))
                }
            }
        } else {
            items(history) { log ->
                val formatedDate = SimpleDateFormat("MMM dd, yyyy - HH:mm", Locale.getDefault()).format(Date(log.timestamp))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Salida: ${log.contextName}",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                            
                            Box(
                                modifier = Modifier
                                    .background(if (log.wasSuccessful) StatusSuccess.copy(alpha = 0.15f) else StatusError.copy(alpha = 0.15f), MaterialTheme.shapes.extraSmall)
                                    .padding(horizontal = 8.dp, vertical = 3.dp)
                            ) {
                                Text(
                                    text = if (log.wasSuccessful) "100% LISTO" else "OLVIDADO",
                                    fontWeight = FontWeight.Black,
                                    color = if (log.wasSuccessful) StatusSuccess else StatusError,
                                    fontSize = 10.sp
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        Text(
                            text = formatedDate,
                            fontSize = 10.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                        )

                        if (log.uncheckedItems.isNotBlank()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                "Olvidado: ${log.uncheckedItems}",
                                fontSize = 11.sp,
                                color = StatusError,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        if (log.checkedItems.isNotBlank()) {
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                "Verificado: ${log.checkedItems}",
                                fontSize = 11.sp,
                                color = StatusSuccess,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun BadgeItem(
    title: String,
    description: String,
    isUnlocked: Boolean,
    emoji: String,
    colorAccent: Color
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.small)
            .background(if (isUnlocked) colorAccent.copy(alpha = 0.05f) else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.02f))
            .border(BorderStroke(1.dp, if (isUnlocked) colorAccent.copy(alpha = 0.2f) else MaterialTheme.colorScheme.outlineVariant))
            .padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .background(if (isUnlocked) colorAccent.copy(alpha = 0.1f) else Color.Transparent, CircleShape)
                .border(BorderStroke(if (isUnlocked) 2.dp else 1.dp, if (isUnlocked) colorAccent else MaterialTheme.colorScheme.outlineVariant), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(emoji, fontSize = 24.sp, modifier = Modifier.padding(if (isUnlocked) 0.dp else 4.dp))
            if (!isUnlocked) {
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.45f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Default.Lock, contentDescription = "Locked", tint = Color.White, modifier = Modifier.size(16.dp))
                }
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 13.sp,
                color = if (isUnlocked) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.48f)
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                description,
                fontSize = 10.sp,
                lineHeight = 13.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
            )
        }
    }
}

// ----------------------------------------------------
// SETTINGS TAB: Personalization & Home coordinates
// ----------------------------------------------------
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsTabContent(viewModel: CheckoutViewModel) {
    val profile by viewModel.userProfile.collectAsState()
    
    var tempPhoneLatitude by remember { mutableStateOf("") }
    var tempPhoneLongitude by remember { mutableStateOf("") }
    var tempName by remember { mutableStateOf("") }

    val isPremium = profile?.isPremium == true

    LaunchedEffect(profile) {
        if (profile != null) {
            tempPhoneLatitude = profile!!.homeLatitude.toString()
            tempPhoneLongitude = profile!!.homeLongitude.toString()
            tempName = profile!!.displayName
        }
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp)
    ) {
        // SUBSCRIPTION LEVEL OVERRIDE ACTION BANNER
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = if (isPremium) StatusSuccess.copy(alpha = 0.08f) else LightPrimary.copy(alpha = 0.08f)
                ),
                border = BorderStroke(1.dp, if (isPremium) StatusSuccess else LightPrimary)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = if (isPremium) "CheckOut Premium Activo 👑" else "¿Desbloquear Funciones Premium?",
                            fontWeight = FontWeight.Black,
                            fontSize = 15.sp,
                            color = if (isPremium) StatusSuccess else LightPrimary
                        )
                        
                        Switch(
                            checked = isPremium,
                            onCheckedChange = { viewModel.togglePremiumSubscription() },
                            modifier = Modifier.testTag("premium_subscription_switch")
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(6.dp))
                    
                    Text(
                        text = if (isPremium) 
                            "¡Contextos ilimitados, alertas de geocerca en segundo plano, reglas de OpenWeatherMap y sincronización en la nube activadas!"
                        else "Obtén acceso a contextos ilimitados, pronóstico inteligente de coordenadas automático y registros interactivos de alertas de salida.",
                        fontSize = 11.sp,
                        lineHeight = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
        }

        // Display Profile settings
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text(
                        "👤 Ajustes del Perfil Personal",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    OutlinedTextField(
                        value = tempName,
                        onValueChange = { tempName = it },
                        label = { Text("Nombre a Mostrar") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth().testTag("settings_name_input")
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Button(
                        onClick = { viewModel.updateProfileName(tempName) },
                        modifier = Modifier.align(Alignment.End).testTag("save_profile_name_button")
                    ) {
                        Text("Guardar Cambio")
                    }
                }
            }
        }

        // HOME COORDINATES SELECTOR LOGIC (MANDATORY BENEFIT)
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text(
                        "📍 Configurar GPS de Base",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        "Cambia tus objetivos lat/lng para actualizar el centro de la geocerca, afectando clima y alertas.",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = tempPhoneLatitude,
                            onValueChange = { tempPhoneLatitude = it },
                            label = { Text("Latitud") },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.weight(1f).testTag("settings_lat_input")
                        )

                        OutlinedTextField(
                            value = tempPhoneLongitude,
                            onValueChange = { tempPhoneLongitude = it },
                            label = { Text("Longitud") },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.weight(1f).testTag("settings_lon_input")
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        // Quick Presets
                        Button(
                            onClick = {
                                viewModel.updateHomeCoordinates(51.5074, -0.1278) // London
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary.copy(alpha = 0.1f), contentColor = MaterialTheme.colorScheme.secondary),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Preset Londres ☔", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }

                        Button(
                            onClick = {
                                viewModel.updateHomeCoordinates(-25.2744, 133.7751) // Australia Extreme Sunny
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary.copy(alpha = 0.1f), contentColor = MaterialTheme.colorScheme.secondary),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Preset Desierto ☀️", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Button(
                        onClick = {
                            val latVal = tempPhoneLatitude.toDoubleOrNull()
                            val lonVal = tempPhoneLongitude.toDoubleOrNull()
                            if (latVal != null && lonVal != null) {
                                viewModel.updateHomeCoordinates(latVal, lonVal)
                            } else {
                                viewModel.updateHomeCoordinates(37.7749, -122.4194)
                            }
                        },
                        modifier = Modifier.fillMaxWidth().testTag("save_coords_button")
                    ) {
                        Text("Guardar Coordenadas Base", fontWeight = FontWeight.ExtraBold)
                    }
                }
            }
        }

        // ALERTS & PERMISSIONS CONTROLS
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text(
                        "⚙️ Interruptores de Alertas y Permisos",
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Servicios de Ubicación Activos", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        Switch(
                            checked = profile?.isLocationServiceEnabled == true,
                            onCheckedChange = { viewModel.updateNotificationToggles(it, profile?.isNotificationEnabled == true) }
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Notificaciones Locales de Alta Prioridad", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        Switch(
                            checked = profile?.isNotificationEnabled == true,
                            onCheckedChange = { viewModel.updateNotificationToggles(profile?.isLocationServiceEnabled == true, it) }
                        )
                    }
                }
            }
        }

        // SIGN OUT OR RESET LOGS DB
        item {
            Button(
                onClick = { viewModel.logOut() },
                colors = ButtonDefaults.buttonColors(containerColor = StatusError.copy(alpha = 0.15f), contentColor = StatusError),
                modifier = Modifier.fillMaxWidth().height(48.dp).testTag("log_out_button")
            ) {
                Text("Cerrar Sesión del Espacio Seguro", fontWeight = FontWeight.Black)
            }
        }
    }
}
