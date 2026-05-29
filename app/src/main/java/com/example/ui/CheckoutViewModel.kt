package com.example.ui

import android.app.Application
import android.widget.Toast
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.db.AppDatabase
import com.example.data.model.ChecklistContext
import com.example.data.model.ChecklistItem
import com.example.data.model.CheckoutHistory
import com.example.data.model.UserProfile
import com.example.data.network.WeatherResponse
import com.example.data.repository.CheckoutRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

enum class AppScreen {
    Splash,
    Onboarding,
    Auth,
    Dashboard // Holds sub-tabs (Home, Stats, Settings)
}

enum class HomeTab {
    Home,
    Stats,
    Settings
}

class CheckoutViewModel(application: Application) : AndroidViewModel(application) {

    private val database = AppDatabase.getDatabase(application)
    private val repository = CheckoutRepository(database.checkoutDao())
    
    // Core Navigation States
    private val _currentScreen = MutableStateFlow(AppScreen.Splash)
    val currentScreen: StateFlow<AppScreen> = _currentScreen.asStateFlow()

    private val _currentTab = MutableStateFlow(HomeTab.Home)
    val currentTab: StateFlow<HomeTab> = _currentTab.asStateFlow()

    // Authentication States
    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()
    
    private val _authError = MutableStateFlow<String?>(null)
    val authError: StateFlow<String?> = _authError.asStateFlow()

    // Local DB Observers
    val allContexts: StateFlow<List<ChecklistContext>> = repository.allContexts.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
    val allHistory: StateFlow<List<CheckoutHistory>> = repository.allHistory.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
    val userProfile: StateFlow<UserProfile?> = repository.userProfile.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = null
    )

    // Active Context States
    private val _selectedContextId = MutableStateFlow<Int?>(null)
    val selectedContextId: StateFlow<Int?> = _selectedContextId.asStateFlow()

    val activeContext: StateFlow<ChecklistContext?> = combine(allContexts, _selectedContextId) { contexts, id ->
        contexts.find { it.id == id } ?: contexts.firstOrNull()
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    val activeItems: StateFlow<List<ChecklistItem>> = _selectedContextId.flatMapLatest { id ->
        if (id != null) {
            repository.getItemsForContext(id)
        } else {
            flowOf(emptyList())
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Weather States
    private val _weatherState = MutableStateFlow<WeatherResponse?>(null)
    val weatherState: StateFlow<WeatherResponse?> = _weatherState.asStateFlow()

    private val _weatherLoading = MutableStateFlow(false)
    val weatherLoading: StateFlow<Boolean> = _weatherLoading.asStateFlow()

    private val _weatherError = MutableStateFlow<String?>(null)
    val weatherError: StateFlow<String?> = _weatherError.asStateFlow()

    // Geofencing Logger Simulator
    private val _geofenceNotificationHistory = MutableStateFlow<List<GeofenceAlert>>(emptyList())
    val geofenceNotificationHistory: StateFlow<List<GeofenceAlert>> = _geofenceNotificationHistory.asStateFlow()

    init {
        // Seed default items and configurations on startup
        viewModelScope.launch {
            repository.initializeDefaultDataIfNeeded()
            // Default select first available context
            allContexts.first { it.isNotEmpty() }.let { contexts ->
                _selectedContextId.value = contexts.firstOrNull()?.id
                // Trigger initial weather pull for local base coordinate
                triggerWeatherRefresh()
            }
        }
    }

    // Navigation triggers
    fun navigateTo(screen: AppScreen) {
        _currentScreen.value = screen
    }

    fun selectTab(tab: HomeTab) {
        _currentTab.value = tab
    }

    fun selectContext(contextId: Int) {
        _selectedContextId.value = contextId
        triggerWeatherRefresh()
    }

    // Onboarding finished
    fun finishOnboarding() {
        _currentScreen.value = AppScreen.Auth
    }

    // Authentication Actions (Fail-safe credentials or Mock guest login)
    fun performLogin(email: String, password: String, isRegister: Boolean = false) {
        _authError.value = null
        viewModelScope.launch {
            if (email.isBlank() || password.isBlank()) {
                _authError.value = "Email and password fields cannot be blank."
                return@launch
            }
            if (!email.contains("@")) {
                _authError.value = "Please input a valid email."
                return@launch
            }
            if (password.length < 6) {
                _authError.value = "Password must be at least 6 characters."
                return@launch
            }

            // Simple fail-safe login simulation
            val currentProfile = userProfile.value ?: UserProfile()
            repository.updateUserProfile(currentProfile.copy(
                email = email,
                displayName = email.substringBefore("@").replaceFirstChar { it.uppercase() }
            ))
            _isLoggedIn.value = true
            _currentScreen.value = AppScreen.Dashboard
        }
    }

    fun bypassAuthAsGuest() {
        // Safe 1-tap fail-safe developer bypass
        _isLoggedIn.value = true
        _currentScreen.value = AppScreen.Dashboard
    }

    fun logOut() {
        _isLoggedIn.value = false
        _currentScreen.value = AppScreen.Auth
    }

    // Checklist Operations
    fun toggleItemCheck(item: ChecklistItem) {
        viewModelScope.launch {
            repository.updateItem(item.copy(isChecked = !item.isChecked))
        }
    }

    fun addNewItem(name: String) {
        val cid = _selectedContextId.value ?: return
        if (name.isBlank()) return
        viewModelScope.launch {
            repository.addItem(ChecklistItem(contextId = cid, name = name))
        }
    }

    fun deleteItem(item: ChecklistItem) {
        viewModelScope.launch {
            repository.deleteItem(item)
        }
    }

    // Context Custom Operations (Premium tier allowed)
    fun createCustomContext(name: String, icon: String, colorHex: String) {
        val profile = userProfile.value ?: return
        if (!profile.isPremium) {
            Toast.makeText(getApplication(), "Premium subscription required for multiple custom contexts!", Toast.LENGTH_LONG).show()
            return
        }
        if (name.isBlank()) return
        viewModelScope.launch {
            repository.addContext(ChecklistContext(
                name = name,
                icon = icon,
                colorHex = colorHex,
                isPremium = true
            ))
        }
    }

    fun deleteContext(context: ChecklistContext) {
        viewModelScope.launch {
            repository.deleteContext(context)
            if (_selectedContextId.value == context.id) {
                _selectedContextId.value = allContexts.value.firstOrNull { it.id != context.id }?.id
            }
        }
    }

    // Weather Refresher & Rule Compiler
    fun triggerWeatherRefresh() {
        val profile = userProfile.value ?: return
        val currentContextId = _selectedContextId.value ?: return
        viewModelScope.launch {
            _weatherLoading.value = true
            _weatherError.value = null
            try {
                // Fetch using coordinates saved in the profile status
                val response = repository.fetchWeather(profile.homeLatitude, profile.homeLongitude, "MY_WEATHER_KEY")
                _weatherState.value = response

                val mainGroup = response.weather?.firstOrNull()?.main
                val tempVal = response.main?.temp

                // Run smart recommendation rule insertions
                repository.applyWeatherRules(currentContextId, mainGroup, tempVal)

            } catch (e: Exception) {
                _weatherError.value = e.localizedMessage ?: "Network connection failed"
            } finally {
                _weatherLoading.value = false
            }
        }
    }

    // Geofence Leaving Base Simulator
    fun simulateLeavingHomeBase() {
        val profile = userProfile.value ?: return
        val context = activeContext.value ?: return
        val items = activeItems.value

        if (items.isEmpty()) {
            Toast.makeText(getApplication(), "Your checklist has no items to verify!", Toast.LENGTH_SHORT).show()
            return
        }

        viewModelScope.launch {
            val uncheckedAndAuto = items.filter { !it.isChecked }
            val checked = items.filter { it.isChecked }
            
            val serializedChecked = checked.joinToString(",") { it.name }
            val serializedUnchecked = uncheckedAndAuto.joinToString(",") { it.name }

            val success = uncheckedAndAuto.isEmpty()
            
            // Insert log record to DB history
            repository.insertHistory(CheckoutHistory(
                contextName = context.name,
                checkedItems = serializedChecked,
                uncheckedItems = serializedUnchecked,
                wasSuccessful = success
            ))

            if (!success) {
                // Trigger smart local high priority push alert logs
                val warningMessage = "Wait! You forgot essential items for ${context.name}! Left unmarked: ${uncheckedAndAuto.joinToString(", ") { it.name }}"
                
                val currentLog = _geofenceNotificationHistory.value.toMutableList()
                currentLog.add(0, GeofenceAlert(
                    title = "CheckOut Alert: Unmarked Items!",
                    body = warningMessage,
                    isHighPriority = true,
                    contextEmoji = context.icon
                ))
                _geofenceNotificationHistory.value = currentLog

                // Reset Streak on forgotten item departure
                repository.updateUserProfile(profile.copy(streakCount = 0))
                Toast.makeText(getApplication(), "⚠️ High-priority Alert Issued!", Toast.LENGTH_LONG).show()
            } else {
                // Successfully checked out! Increase fire streak counts, check timestamps
                val activeStreak = profile.streakCount + 1
                repository.updateUserProfile(profile.copy(
                    streakCount = activeStreak,
                    lastCheckoutTimestamp = System.currentTimeMillis()
                ))

                val successLog = _geofenceNotificationHistory.value.toMutableList()
                successLog.add(0, GeofenceAlert(
                    title = "Successful Departure! 👍",
                    body = "Amazing! You verified 100% of your ${context.name} items before departure. Multi-point check passed.",
                    isHighPriority = false,
                    contextEmoji = context.icon
                ))
                _geofenceNotificationHistory.value = successLog
                Toast.makeText(getApplication(), "🎉 Success! Perfect departure certified.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    // Toggle subscription status
    fun togglePremiumSubscription() {
        val profile = userProfile.value ?: return
        viewModelScope.launch {
            repository.updateUserProfile(profile.copy(isPremium = !profile.isPremium))
        }
    }

    fun updateHomeCoordinates(latitude: Double, longitude: Double) {
        val profile = userProfile.value ?: return
        viewModelScope.launch {
            repository.updateUserProfile(profile.copy(
                homeLatitude = latitude,
                homeLongitude = longitude
            ))
            Toast.makeText(getApplication(), "Base coordinates successfully locked!", Toast.LENGTH_SHORT).show()
            triggerWeatherRefresh()
        }
    }

    fun updateProfileName(name: String) {
        val profile = userProfile.value ?: return
        if (name.isBlank()) return
        viewModelScope.launch {
            repository.updateUserProfile(profile.copy(displayName = name))
        }
    }

    fun updateNotificationToggles(isLocationEnabled: Boolean, isNotificationsEnabled: Boolean) {
        val profile = userProfile.value ?: return
        viewModelScope.launch {
            repository.updateUserProfile(profile.copy(
                isLocationServiceEnabled = isLocationEnabled,
                isNotificationEnabled = isNotificationsEnabled
            ))
        }
    }

    fun deleteNotificationRecord(alert: GeofenceAlert) {
        val current = _geofenceNotificationHistory.value.toMutableList()
        current.remove(alert)
        _geofenceNotificationHistory.value = current
    }

    fun getTopForgottenItems(): List<Pair<String, Int>> {
        val historyList = allHistory.value
        val itemsMap = mutableMapOf<String, Int>()
        historyList.forEach { log ->
            if (log.uncheckedItems.isNotBlank()) {
                val names = log.uncheckedItems.split(",")
                names.forEach { name ->
                    val clean = name.trim()
                    if (clean.isNotEmpty()) {
                        itemsMap[clean] = (itemsMap[clean] ?: 0) + 1
                    }
                }
            }
        }
        return itemsMap.toList().sortedByDescending { it.second }.take(3)
    }
}

data class GeofenceAlert(
    val title: String,
    val body: String,
    val timestamp: Long = System.currentTimeMillis(),
    val isHighPriority: Boolean,
    val contextEmoji: String
)
