package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "user_profile")
data class UserProfile(
    @PrimaryKey val id: Int = 1, // Single-row record
    val displayName: String = "John Doe",
    val profilePicUri: String? = null,
    val isPremium: Boolean = false,
    val streakCount: Int = 0,
    val lastCheckoutTimestamp: Long = 0L,
    val homeLatitude: Double = 37.7749, // Default coordinates
    val homeLongitude: Double = -122.4194,
    val isLocationServiceEnabled: Boolean = true,
    val isNotificationEnabled: Boolean = true,
    val email: String = "user@example.com"
)
